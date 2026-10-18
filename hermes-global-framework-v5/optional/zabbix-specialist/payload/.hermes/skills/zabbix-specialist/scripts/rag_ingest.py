#!/usr/bin/env python3
"""Opt-in, stdlib-only Git/Jira ingestion. Remote text is never executed."""
from __future__ import annotations
import argparse, hashlib, json, os, re, shutil, subprocess, sys, tempfile, time
import urllib.error, urllib.parse, urllib.request
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath

MAX_FILE, MAX_TOTAL, MAX_TREE_ENTRIES = 1_000_000, 10_000_000, 10_000
# A partial clone can still meet a server that ignores blob filtering.
MAX_GIT_CLONE_BYTES = 2_000_000
GIT_TIMEOUT_SECONDS, JIRA_READ_CHUNK = 30, 64 * 1024
TEXT = {".md", ".txt", ".json", ".yaml", ".yml"}
SAFE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")
REDACTIONS = ((re.compile(r"(?im)^(\s*(?:password|passwd|secret|api[_-]?key|access[_-]?token|token)\s*[:=]\s*)([^\r\n]+)$"), r"\1[REDACTED]"), (re.compile(r"(?i)\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{8,}"), r"\1 [REDACTED]"), (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----", re.S), "[REDACTED PRIVATE KEY]"))
SECRET_KEY = r"(?:password|passwd|secret|api[_-]?key|access[_-]?token|token|client_secret|private_key|aws_secret_access_key|database[_-]?url|(?:connection|jdbc)[_-]?(?:url|string)|dsn|authorization|cookie|set[_-]?cookie|session(?:[_-]?(?:id|token|key))?)"
UNSAFE_PRIVATE_KEY = re.compile(r"-----BEGIN [A-Z ]*(?:PRIVATE|OPENSSH) KEY-----", re.I)
HOSTNAME = re.compile(r"(?=.{1,253}\Z)(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)*[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\Z")
try:
    import resource
except ImportError:  # Windows has no stdlib RLIMIT_FSIZE equivalent.
    resource = None

class Error(ValueError): pass
def bad(message): raise Error(message)
def stamp(): return datetime.now(timezone.utc).isoformat()
def sanitize(text):
    # Deliberately conservative best-effort redaction; this is not a DLP system.
    key = r'["\']?' + SECRET_KEY + r'["\']?'
    text = re.sub(r'(?im)(' + key + r'\s*[:=]\s*)["\'][^\r\n]*?["\']', r"\1[REDACTED]", text)
    text = re.sub(r'(?im)(' + key + r'\s*[:=]\s*)[^\s,#}\]\r\n]+', r"\1[REDACTED]", text)
    text = re.sub(r"(?i)\b([a-z][a-z0-9+.-]*://)([^\s/@:]+):([^\s/@]+)@", r"\1[REDACTED]@", text)
    text = re.sub(r"(?im)^(\s*(?:authorization|proxy-authorization|x-api-key|cookie|set-cookie|session(?:[-_]id)?)\s*:\s*)(?:Bearer|Basic|Token|JWT)?\s*[^\r\n]+$", r"\1[REDACTED]", text)
    text = re.sub(r"(?i)\b(Token|JWT|Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{8,}", r"\1 [REDACTED]", text)
    for pattern, replacement in REDACTIONS: text = pattern.sub(replacement, text)
    return text
def sanitized_document(text):
    text = sanitize(text)
    if UNSAFE_PRIVATE_KEY.search(text): bad("document rejected: incomplete private key material")
    return text
def valid_hostname(host): return bool(host and HOSTNAME.fullmatch(host))
def valid_git_repo(repo):
    if not isinstance(repo, str) or not repo or repo.startswith("-") or any(char.isspace() for char in repo): return False
    if re.fullmatch(r"git@[A-Za-z0-9][A-Za-z0-9.-]*:[^\s:]+", repo): return valid_hostname(repo[4:].split(":", 1)[0])
    parsed = urllib.parse.urlsplit(repo)
    return parsed.scheme in ("https", "ssh") and valid_hostname(parsed.hostname) and not parsed.username and not parsed.password and not parsed.query and not parsed.fragment and bool(parsed.path)
def valid_jira_url(url):
    parsed = urllib.parse.urlsplit(url)
    return parsed.scheme == "https" and valid_hostname(parsed.hostname) and not parsed.username and not parsed.password and not parsed.query and not parsed.fragment
def directory(root, *parts):
    result = root.joinpath(*parts); result.mkdir(parents=True, exist_ok=True); return result
def read_config(path):
    try: result = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc: bad(f"cannot read JSON config: {exc}")
    if not isinstance(result, dict) or result.get("version") != 1 or not isinstance(result.get("sources"), list): bad("config must contain version 1 and a sources list")
    return result
def string(source, key):
    value = source.get(key)
    if not isinstance(value, str) or not value: bad(f"source {source.get('id', '<unknown>')!r}: {key} must be a non-empty string")
    return value
def allowed(source, key, value):
    values = source.get(key)
    if not isinstance(values, list) or value not in values: bad(f"source {source.get('id', '<unknown>')!r}: {key} must explicitly allow {value!r}")
def check(source):
    if not isinstance(source, dict): bad("each source must be an object")
    ident, kind = string(source, "id"), string(source, "type")
    if not SAFE.fullmatch(ident): bad(f"unsafe source id {ident!r}")
    if kind == "git":
        repo, ref, path = string(source, "repo"), string(source, "ref"), string(source, "path")
        if not valid_git_repo(repo): bad(f"source {ident!r}: repo must be HTTPS, SSH, or git@host:path with a valid hostname")
        if PurePosixPath(path).is_absolute() or ".." in PurePosixPath(path).parts: bad(f"source {ident!r}: path must be repository-relative")
        for key, value in (("allowed_repos", repo), ("allowed_refs", ref), ("allowed_paths", path)): allowed(source, key, value)
    elif kind == "jira":
        url, project, jql, status = (string(source, key) for key in ("url", "project", "jql", "status"))
        if not valid_jira_url(url): bad(f"source {ident!r}: Jira URL must be a credential-free HTTPS URL with a valid hostname")
        for key, value in (("allowed_urls", url), ("allowed_projects", project), ("allowed_jql", jql), ("allowed_statuses", status)): allowed(source, key, value)
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", string(source, "token_env")): bad(f"source {ident!r}: unsafe token_env")
        for key, low, high in (("limit", 1, 100), ("timeout_seconds", 1, 60)):
            if not isinstance(source.get(key), int) or not low <= source[key] <= high: bad(f"source {ident!r}: {key} must be {low}..{high}")
    else: bad(f"source {ident!r}: unsupported type {kind!r}")
def validate(config):
    ids = set()
    for source in config["sources"]:
        check(source)
        if source["id"] in ids: bad(f"duplicate source id {source['id']!r}")
        ids.add(source["id"])
def git_file_limit():
    resource.setrlimit(resource.RLIMIT_FSIZE, (MAX_GIT_CLONE_BYTES, MAX_GIT_CLONE_BYTES))
def git(args, cwd=None, resource_bound=False):
    if resource_bound and (os.name != "posix" or resource is None):
        bad("remote Git sync is unavailable: this platform lacks a POSIX RLIMIT_FSIZE pack limit")
    env = {"PATH": os.defpath, "LC_ALL": "C", "GIT_CONFIG_NOSYSTEM": "1", "GIT_TERMINAL_PROMPT": "0", "GIT_ALLOW_PROTOCOL": "https:ssh", "GIT_CONFIG_COUNT": "2", "GIT_CONFIG_KEY_0": "protocol.ext.allow", "GIT_CONFIG_VALUE_0": "never", "GIT_CONFIG_KEY_1": "protocol.file.allow", "GIT_CONFIG_VALUE_1": "never"}
    options = {"cwd": cwd, "env": env, "check": True, "stdout": subprocess.PIPE, "stderr": subprocess.PIPE, "timeout": GIT_TIMEOUT_SECONDS}
    if resource_bound: options["preexec_fn"] = git_file_limit
    try: return subprocess.run(["git", *args], **options).stdout
    except subprocess.TimeoutExpired: bad("git retrieval timed out")
    except (OSError, subprocess.SubprocessError, subprocess.CalledProcessError) as exc: bad("git retrieval failed" if not isinstance(exc, subprocess.CalledProcessError) else f"git retrieval failed: {exc.stderr.decode(errors='replace').strip()}")
def from_git(source):
    with tempfile.TemporaryDirectory(prefix="zabbix-rag-") as temp:
        clone = Path(temp) / "repo"; git(["clone", "--no-checkout", "--filter=blob:none", "--no-tags", "--depth", "1", "--branch", source["ref"], source["repo"], str(clone)], resource_bound=True)
        commit = git(["rev-parse", "HEAD"], clone).decode().strip()
        names = [name for name in git(["ls-tree", "-r", "-z", "--name-only", "HEAD", "--", source["path"]], clone).decode().split("\0") if name]
        if len(names) > MAX_TREE_ENTRIES: bad("Git tree exceeds entry limit")
        names = [name for name in names if Path(name).suffix.lower() in TEXT]
        if len(names) != 1: bad("Git source must select exactly one eligible text document")
        name = names[0]
        try: size = int(git(["cat-file", "-s", f"HEAD:{name}"], clone, resource_bound=True).decode().strip())
        except ValueError: bad("git returned an invalid blob size")
        if size < 0: bad("git returned an invalid blob size")
        if size > MAX_FILE or size > MAX_TOTAL: return commit, []
        raw = git(["show", f"HEAD:{name}"], clone, resource_bound=True)
        if len(raw) != size: bad("git blob changed while being read")
        try: return commit, [(name, sanitized_document(raw.decode("utf-8")))]
        except (UnicodeDecodeError, Error): return commit, []
def deadline_check(deadline):
    if time.monotonic() >= deadline: bad("Jira source deadline exceeded")
def from_jira(source):
    token = os.environ.get(source["token_env"])
    if not token: bad(f"source {source['id']!r}: required token environment variable is unset")
    payload = json.dumps({"jql": source["jql"], "maxResults": source["limit"], "fields": ["key", "summary", "description", "status", "resolution", "labels"]}).encode()
    request = urllib.request.Request(source["url"].rstrip("/") + "/rest/api/2/search", data=payload, method="POST", headers={"Accept": "application/json", "Content-Type": "application/json", "Authorization": f"Bearer {token}"})
    deadline = time.monotonic() + source["timeout_seconds"]
    try:
        # Authenticated Jira requests must never follow redirects: a redirect can cross origins.
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, request, fp, code, msg, headers, newurl): return None
        opener = urllib.request.build_opener(NoRedirect())
        with opener.open(request, timeout=source["timeout_seconds"]) as response:
            chunks, total = [], 0
            while True:
                deadline_check(deadline)
                chunk = response.read(min(JIRA_READ_CHUNK, MAX_TOTAL + 1 - total))
                deadline_check(deadline)
                if not chunk: break
                chunks.append(chunk); total += len(chunk)
                if total > MAX_TOTAL: bad("Jira response exceeded size limit")
            raw = b"".join(chunks)
    except (urllib.error.URLError, OSError) as exc: bad(f"Jira retrieval failed: {exc}")
    if len(raw) > MAX_TOTAL: bad("Jira response exceeded size limit")
    try: issues = json.loads(raw.decode("utf-8")).get("issues")
    except (UnicodeDecodeError, json.JSONDecodeError) as exc: bad(f"Jira response was not valid JSON: {exc}")
    if not isinstance(issues, list): bad("Jira response has no issues list")
    docs = []
    for issue in issues[:source["limit"]]:
        deadline_check(deadline)
        if not isinstance(issue, dict) or not isinstance(issue.get("key"), str): continue
        fields = issue.get("fields") if isinstance(issue.get("fields"), dict) else {}
        status = fields.get("status") if isinstance(fields.get("status"), dict) else {}; resolution = fields.get("resolution") if isinstance(fields.get("resolution"), dict) else {}
        text = f"# {issue['key']}: {fields.get('summary') or ''}\n\n{fields.get('description') or ''}\n\nStatus: {status.get('name') or ''}\nResolution: {resolution.get('name') or ''}"
        try: docs.append((issue["key"], sanitized_document(text[:MAX_FILE])))
        except Error: pass
    return hashlib.sha256(raw).hexdigest(), docs
def store(root, source, provenance, docs):
    raw = directory(root, "raw", source["type"], source["id"], provenance); count = 0
    for name, text in docs:
        # Treat every importer as untrusted: sanitize again at the persistence boundary.
        try: text = sanitized_document(text)
        except Error: continue
        digest = hashlib.sha256(text.encode()).hexdigest(); candidate = f"{source['id']}-{digest[:16]}"
        (raw / f"{digest}.txt").write_text(text, encoding="utf-8")
        dest = directory(root, "candidates", source["id"], candidate)
        (dest / "content.md").write_text(text, encoding="utf-8")
        metadata = {"candidate_id": candidate, "source_id": source["id"], "source_type": source["type"], "source_name": name, "provenance": provenance, "retrieved_at": stamp(), "content_sha256": digest, "promotion": "requires --approve"}
        (dest / "metadata.json").write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8"); count += 1
    return count
def sync(config, root):
    for source in config["sources"]:
        try:
            provenance, docs = from_git(source) if source["type"] == "git" else from_jira(source)
            print(json.dumps({"source": source["id"], "candidates": store(root, source, provenance, docs), "provenance": provenance}))
        except Error as exc:
            print(json.dumps({"source": source["id"], "error": sanitize(str(exc))}), file=sys.stderr)
def find_candidate(root, ident):
    if not SAFE.fullmatch(ident): bad("candidate id contains unsafe characters")
    found = list((root / "candidates").glob(f"*/{ident}"))
    if len(found) != 1: bad("candidate id was not found uniquely")
    return found[0]
def promote(root, ident, approved):
    if not approved: bad("promotion requires the explicit --approve flag")
    source = find_candidate(root, ident); metadata = json.loads((source / "metadata.json").read_text(encoding="utf-8")); dest = directory(root, "approved", ident)
    shutil.copyfile(source / "content.md", dest / "content.md"); metadata.update({"promoted_at": stamp(), "promotion": "approved explicitly"})
    (dest / "metadata.json").write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8"); print(json.dumps({"promoted": ident}))
def index(root):
    entries = []
    for path in sorted((root / "approved").glob("*/metadata.json")) if (root / "approved").exists() else []:
        metadata = json.loads(path.read_text(encoding="utf-8")); entries.append({key: metadata.get(key) for key in ("candidate_id", "source_id", "source_type", "source_name", "provenance", "retrieved_at", "promoted_at", "content_sha256")})
    directory(root, "index").joinpath("catalog.json").write_text(json.dumps({"version": 1, "generated_at": stamp(), "entries": entries}, indent=2, sort_keys=True) + "\n", encoding="utf-8"); print(json.dumps({"indexed": len(entries)}))
def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__); sub = parser.add_subparsers(dest="command", required=True)
    for command in ("validate", "sync"):
        item = sub.add_parser(command); item.add_argument("--config", required=True, type=Path)
        if command == "sync": item.add_argument("--data-root", required=True, type=Path)
    item = sub.add_parser("promote"); item.add_argument("--data-root", required=True, type=Path); item.add_argument("--candidate", required=True); item.add_argument("--approve", action="store_true")
    item = sub.add_parser("index"); item.add_argument("--data-root", required=True, type=Path)
    args = parser.parse_args(argv)
    try:
        if args.command in ("validate", "sync"):
            config = read_config(args.config); validate(config)
            if args.command == "validate": print(json.dumps({"valid": True, "sources": len(config["sources"])}))
            else: sync(config, args.data_root)
        elif args.command == "promote": promote(args.data_root, args.candidate, args.approve)
        else: index(args.data_root)
    except Error as exc: print(f"error: {exc}", file=sys.stderr); return 2
    return 0
if __name__ == "__main__": raise SystemExit(main())
