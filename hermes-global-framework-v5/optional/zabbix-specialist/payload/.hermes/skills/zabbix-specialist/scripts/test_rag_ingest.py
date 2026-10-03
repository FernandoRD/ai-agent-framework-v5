#!/usr/bin/env python3
"""Focused offline tests for rag_ingest.py; run with python3 test_rag_ingest.py."""
import importlib.util, json, os, tempfile, unittest
from pathlib import Path
from unittest.mock import Mock, patch
import urllib.error

HERE = Path(__file__).parent
SPEC = importlib.util.spec_from_file_location("rag_ingest", HERE / "rag_ingest.py")
rag = importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(rag)

class FakeResponse:
    def __init__(self, data): self.data, self.offset = data, 0
    def read(self, limit):
        result = self.data[self.offset:self.offset + limit]; self.offset += len(result); return result
    def __enter__(self): return self
    def __exit__(self, *_): return False

class RAGTests(unittest.TestCase):
    def git_source(self, repo="https://git.example.invalid/ops/runbooks.git"):
        return {"id":"runbooks", "type":"git", "repo":repo, "ref":"main", "path":"zabbix", "allowed_repos":[repo], "allowed_refs":["main"], "allowed_paths":["zabbix"]}
    def test_git_sync_promote_index_and_sanitize(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); config = {"version":1,"sources":[self.git_source()]}; rag.validate(config); data = root / "data"
            with patch.object(rag, "from_git", return_value=("fixture-commit", [("proxy.md", rag.sanitize("token: very-secret-value\nproxy notes\n"))])):
                rag.sync(config, data)
            candidate = next((data / "candidates" / "runbooks").iterdir()).name
            self.assertIn("[REDACTED]", (data / "candidates" / "runbooks" / candidate / "content.md").read_text())
            self.assertRaises(rag.Error, rag.promote, data, candidate, False); rag.promote(data, candidate, True); rag.index(data)
            self.assertEqual(1, len(json.loads((data / "index" / "catalog.json").read_text())["entries"]))
    def test_jira_requires_https_and_never_logs_token(self):
        source = {"id":"issues","type":"jira","url":"https://jira.example.invalid","project":"OPS","status":"Resolved","jql":"project = OPS","allowed_urls":["https://jira.example.invalid"],"allowed_projects":["OPS"],"allowed_statuses":["Resolved"],"allowed_jql":["project = OPS"],"token_env":"RAG_TEST_TOKEN","limit":1,"timeout_seconds":2}
        rag.validate({"version":1,"sources":[source]}); os.environ["RAG_TEST_TOKEN"] = "never-print-this-token"
        response = json.dumps({"issues":[{"key":"OPS-1","fields":{"summary":"Proxy", "description":"password=hidden", "status":{"name":"Resolved"}}}]}).encode()
        with patch("urllib.request.urlopen", return_value=FakeResponse(response)) as open_url:
            opener = Mock(); opener.open.return_value = FakeResponse(response)
            with patch("urllib.request.build_opener", return_value=opener): digest, docs = rag.from_jira(source)
        self.assertTrue(digest); self.assertIn("[REDACTED]", docs[0][1]); self.assertNotIn("never-print-this-token", repr(open_url.call_args))
        source["url"] = "http://jira.example.invalid"
        with self.assertRaises(rag.Error): rag.validate({"version":1,"sources":[source]})
    def test_jira_redirect_is_rejected_without_following_or_forwarding_token(self):
        source = {"id":"issues","type":"jira","url":"https://jira.example.invalid","project":"OPS","status":"Resolved","jql":"project = OPS","allowed_urls":["https://jira.example.invalid"],"allowed_projects":["OPS"],"allowed_statuses":["Resolved"],"allowed_jql":["project = OPS"],"token_env":"RAG_TEST_TOKEN","limit":1,"timeout_seconds":2}
        os.environ["RAG_TEST_TOKEN"] = "never-forward-this-token"
        opener = Mock(); opener.open.side_effect = urllib.error.HTTPError("https://jira.example.invalid/rest/api/2/search", 302, "Found", {}, None)
        with patch("urllib.request.build_opener", return_value=opener):
            with self.assertRaises(rag.Error): rag.from_jira(source)
        self.assertEqual(1, opener.open.call_count)
        self.assertEqual("Bearer never-forward-this-token", opener.open.call_args.args[0].get_header("Authorization"))
    def test_sanitize_redacts_supported_secret_forms(self):
        text = "\n".join((
            '"api_key": "json-secret"', "'password': 'yaml-secret'", "token: plain-secret",
            "https://alice:password@example.invalid/private", "Authorization: Token abcdefghijkl",
            "Cookie: session=super-secret", "AWS_SECRET_ACCESS_KEY=aws-secret", "DATABASE_URL=postgres://db:secret@example.invalid/db",
            "connection_url: mysql://root:secret@example.invalid/db", "JWT eyJhbGciOiJIUzI1NiJ9.payload.signature", "-----BEGIN PRIVATE KEY-----\\nkey\\n-----END PRIVATE KEY-----"))
        clean = rag.sanitize(text)
        for secret in ("json-secret", "yaml-secret", "plain-secret", "alice:password", "abcdefghijkl", "super-secret", "aws-secret", "postgres://db", "mysql://root", "eyJhbGci", "\\nkey\\n"):
            self.assertNotIn(secret, clean)
        self.assertGreaterEqual(clean.count("[REDACTED]"), 5)
    def test_incomplete_private_key_is_rejected_before_persistence(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            count = rag.store(root, self.git_source(), "commit", [("bad.md", "-----BEGIN PRIVATE KEY-----\\nsecret")])
            self.assertEqual(0, count)
            self.assertFalse(list(root.rglob("*.txt")))
            self.assertFalse(list(root.rglob("content.md")))
    def test_git_rejects_local_and_unsafe_repositories(self):
        for repo in ("file:///tmp/repo", "/tmp/repo", "ext::sh -c bad", "-cfoo", "https://user:pass@git.example.invalid/repo.git", "ssh://git.example.invalid/repo?x=1"):
            with self.assertRaises(rag.Error): rag.validate({"version": 1, "sources": [self.git_source(repo)]})
    def test_git_uses_minimal_protocol_locked_environment(self):
        completed = Mock(stdout=b"ok", stderr=b"")
        with patch.object(rag.subprocess, "run", return_value=completed) as run:
            self.assertEqual(b"ok", rag.git(["--version"]))
        env = run.call_args.kwargs["env"]
        self.assertEqual("https:ssh", env["GIT_ALLOW_PROTOCOL"])
        self.assertEqual("never", env["GIT_CONFIG_VALUE_0"])
        self.assertEqual("never", env["GIT_CONFIG_VALUE_1"])
        self.assertEqual(rag.GIT_TIMEOUT_SECONDS, run.call_args.kwargs["timeout"])
    def test_git_clone_uses_pack_limit_on_posix(self):
        completed, limited_resource = Mock(stdout=b"ok", stderr=b""), Mock(RLIMIT_FSIZE=1)
        with patch.object(rag, "resource", limited_resource), patch.object(rag.subprocess, "run", return_value=completed) as run:
            self.assertEqual(b"ok", rag.git(["clone", "https://git.example.invalid/repo.git"], resource_bound=True))
            run.call_args.kwargs["preexec_fn"]()
        limited_resource.setrlimit.assert_called_once_with(1, (rag.MAX_GIT_CLONE_BYTES, rag.MAX_GIT_CLONE_BYTES))
    def test_git_clone_refuses_platform_without_posix_file_limit(self):
        with patch.object(rag.os, "name", "nt"):
            with self.assertRaisesRegex(rag.Error, "RLIMIT_FSIZE"):
                rag.git(["clone", "https://git.example.invalid/repo.git"], resource_bound=True)
    def test_over_limit_blob_never_calls_git_show(self):
        source = self.git_source()
        calls = []
        def fake_git(args, _cwd=None, resource_bound=False):
            calls.append(args)
            if args[0] == "clone":
                self.assertTrue(resource_bound)
                self.assertIn("--no-checkout", args)
                self.assertIn("--filter=blob:none", args)
                return b""
            if args[:2] == ["rev-parse", "HEAD"]: return b"commit\n"
            if args[0] == "ls-tree": return b"zabbix/large.md\0"
            if args[:2] == ["cat-file", "-s"]:
                self.assertTrue(resource_bound)
                return f"{rag.MAX_FILE + 1}\n".encode()
            self.fail(f"unexpected git call: {args}")
        with patch.object(rag, "git", side_effect=fake_git):
            commit, docs = rag.from_git(source)
        self.assertEqual("commit", commit); self.assertEqual([], docs)
        self.assertFalse(any(call[0] == "show" for call in calls))
    def test_multiple_git_documents_reject_without_blob_operations(self):
        source, calls = self.git_source(), []
        def fake_git(args, _cwd=None, resource_bound=False):
            calls.append(args)
            if args[0] == "clone": return b""
            if args[:2] == ["rev-parse", "HEAD"]: return b"commit\n"
            if args[0] == "ls-tree": return b"zabbix/one.md\0zabbix/two.txt\0"
            self.fail(f"unexpected blob operation: {args}")
        with patch.object(rag, "git", side_effect=fake_git):
            with self.assertRaisesRegex(rag.Error, "exactly one eligible text document"):
                rag.from_git(source)
        self.assertFalse(any(call[0] in ("cat-file", "show") for call in calls))
    def test_sync_logs_one_source_failure_and_continues(self):
        first, second = self.git_source(), self.git_source("https://git.example.invalid/ops/other.git")
        second.update({"id":"other", "allowed_repos":[second["repo"]]})
        with tempfile.TemporaryDirectory() as temp, patch.object(rag, "from_git", side_effect=[rag.Error("token: should-not-leak"), ("commit", [("ok.md", "ok")])]), patch("sys.stderr") as stderr:
            rag.sync({"version":1, "sources":[first, second]}, Path(temp))
        logged = "".join(call.args[0] for call in stderr.write.call_args_list)
        self.assertIn("[REDACTED]", logged)
        self.assertNotIn("should-not-leak", logged)
    def test_jira_deadline_is_checked_between_reads(self):
        source = {"id":"issues","type":"jira","url":"https://jira.example.invalid","project":"OPS","status":"Resolved","jql":"project = OPS","allowed_urls":["https://jira.example.invalid"],"allowed_projects":["OPS"],"allowed_statuses":["Resolved"],"allowed_jql":["project = OPS"],"token_env":"RAG_TEST_TOKEN","limit":1,"timeout_seconds":2}
        os.environ["RAG_TEST_TOKEN"] = "test-token"
        opener = Mock(); opener.open.return_value = FakeResponse(b'{"issues": []}')
        with patch("urllib.request.build_opener", return_value=opener), patch.object(rag.time, "monotonic", side_effect=[0, 0, 3]):
            with self.assertRaisesRegex(rag.Error, "deadline"): rag.from_jira(source)
if __name__ == "__main__": unittest.main(verbosity=2)
