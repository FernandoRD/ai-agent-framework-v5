#!/usr/bin/env python3
from __future__ import annotations
import getpass, hashlib, json, os, py_compile, re, shutil, subprocess, sys, tempfile
from pathlib import Path

if sys.version_info < (3, 11):
    sys.exit("Python 3.11+ is required (tomllib).")
import tomllib

ROOT = Path(__file__).resolve().parent.parent
ERRORS: list[str] = []
def check(value: bool, message: str) -> None:
    if not value: ERRORS.append(message)

check(re.fullmatch(r"\d+\.\d+\.\d+", (ROOT / "VERSION").read_text().strip()) is not None, "VERSION is not MAJOR.MINOR.PATCH")
agents_md = (ROOT / ".codex" / "AGENTS.md").read_text(encoding="utf-8")
check("CODEX-GLOBAL-FRAMEWORK:BEGIN v5" in agents_md, "v5 AGENTS marker missing")
weights = [int(x) for x in re.findall(r"\| [^|]+ \| (\d+) \|", agents_md)]
check(sum(weights[:12]) == 100, "routing weights do not sum to 100")
for band in ("- 0-34: Luna tier.", "- 35-69: Terra tier.", "- 70-100: Sol tier."):
    check(band in agents_md, f"score band missing: {band}")

expected = {
    "luna_explorer": ("gpt-5.6-luna", "medium", "read-only"),
    "luna_worker": ("gpt-5.6-luna", "low", "workspace-write"),
    "terra_worker": ("gpt-5.6-terra", "medium", "workspace-write"),
    "terra_reviewer": ("gpt-5.6-terra", "high", "read-only"),
    "sol_specialist": ("gpt-5.6-sol", "high", "workspace-write"),
    "sol_reviewer": ("gpt-5.6-sol", "xhigh", "read-only"),
    "sol_critical": ("gpt-5.6-sol", "max", "read-only"),
}
check(not any((ROOT / ".codex" / "agents").glob("*.toml")), "package must not ship auto-discovered framework agents")
for role, values in expected.items():
    path = ROOT / ".codex" / "agent-configs" / f"{role}.toml"
    check(path.exists(), f"missing layer {role}")
    if not path.exists(): continue
    try: data = tomllib.loads(path.read_text(encoding="utf-8"))
    except Exception as exc: ERRORS.append(f"invalid TOML {role}: {exc}"); continue
    check("name" not in data and "description" not in data, f"standalone-only fields in {role}")
    check((data.get("model"), data.get("model_reasoning_effort"), data.get("sandbox_mode")) == values, f"wrong layer values for {role}")
    check(bool(data.get("developer_instructions")), f"missing instructions for {role}")

skill_names = {"security-review", "code-review", "dependency-review", "documentation"}
actual = {p.name for p in (ROOT / ".agents" / "skills").iterdir() if p.is_dir()}
check(actual == skill_names, f"unexpected Skills: {actual}")
for name in skill_names:
    skill = ROOT / ".agents" / "skills" / name / "SKILL.md"
    meta = ROOT / ".agents" / "skills" / name / "agents" / "openai.yaml"
    text = skill.read_text(encoding="utf-8")
    check(re.match(r"^---\n.*?^name:\s*" + re.escape(name) + r"\s*$.*?^---$", text, re.M | re.S) is not None, f"invalid Skill {name}")
    meta_text = meta.read_text(encoding="utf-8")
    check(f"${name}" in meta_text and "allow_implicit_invocation: true" in meta_text, f"invalid metadata {name}")

ALL_OPTIONAL_SPECS = [
    "zabbix-specialist",
    "grafana-specialist",
    "ansible-specialist",
    "loki-specialist",
    "prometheus-specialist",
    "netops-specialist",
    "sre-incident-specialist",
    "database-tuning-specialist",
    "proxmox-specialist",
    "shell-python-specialist",
    "docker-kubernetes-specialist",
]
for spec in ALL_OPTIONAL_SPECS:
    opt_skill = ROOT / "optional" / spec / ".agents" / "skills" / spec
    check((opt_skill / "SKILL.md").is_file(), f"optional {spec} skill missing")
    check(not any((ROOT / "optional" / spec / ".codex" / "agents").glob("*.toml")), f"optional {spec} must not ship a native Codex agent")

hook_result = subprocess.run(["sh", str(ROOT / ".codex" / "hooks" / "mandatory-router.sh")], capture_output=True, text=True)
try: context = json.loads(hook_result.stdout)["hookSpecificOutput"]["additionalContext"]; check(len(context) <= 120, "hook context too long")
except Exception as exc: ERRORS.append(f"invalid hook output: {exc}")

for script in ("install.sh", "diagnose.sh", "uninstall.sh"):
    result = subprocess.run(["bash", "-n", str(ROOT / "scripts" / script)], capture_output=True, text=True)
    check(result.returncode == 0, f"bash syntax error in {script}: {result.stderr}")
for script in ("install.fish", "diagnose.fish", "uninstall.fish"):
    path = ROOT / "scripts" / script
    check(path.exists(), f"missing fish script: {script}")
    if shutil.which("fish") and path.exists():
        result = subprocess.run(["fish", "-n", str(path)], capture_output=True, text=True)
        check(result.returncode == 0, f"fish syntax error in {script}: {result.stderr}")
with tempfile.TemporaryDirectory() as compiled:
    for script in ROOT.glob("scripts/*.py"):
        try: py_compile.compile(str(script), cfile=str(Path(compiled) / f"{script.name}.pyc"), doraise=True)
        except Exception as exc: ERRORS.append(f"Python syntax error in {script.name}: {exc}")

# ---- Installer behaviour in temporary directories (never touches the real home) ----
ENV = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
ENV.pop("CODEX_HOME", None); ENV.pop("SKILLS_HOME", None)

def run(cmd, **kw):
    return subprocess.run([str(c) for c in cmd], capture_output=True, text=True, env=kw.pop("env", ENV), **kw)

def snapshot(*roots: Path) -> dict[str, str]:
    out = {}
    for root in roots:
        if root.exists():
            for p in sorted(root.rglob("*")):
                if p.is_file() and "backups" not in p.relative_to(root).parts:
                    out[str(p)] = hashlib.sha256(p.read_bytes()).hexdigest()
    return out

SKILLS_V5 = sorted(skill_names)
V5_MARK = "CODEX-GLOBAL-FRAMEWORK:BEGIN v5"

def router_groups(codex: Path) -> list:
    """UserPromptSubmit groups that reference mandatory-router, re-read from disk."""
    data = json.loads((codex / "hooks.json").read_text(encoding="utf-8"))
    return [g for g in data["hooks"]["UserPromptSubmit"] if "mandatory-router" in json.dumps(g)]

USER_HOOKS = {"description": "mine", "hooks": {
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "echo mine"}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "echo stop"}]}]}}
USER_CONFIG = 'model = "my-model"\n\n[my_table]\nkey = "value"\n'
USER_AGENTS = "# My personal notes\nKeep answers short.\n"

def seed_user_data(codex: Path) -> None:
    codex.mkdir(parents=True, exist_ok=True)
    (codex / "hooks.json").write_text(json.dumps(USER_HOOKS), encoding="utf-8")
    (codex / "config.toml").write_text(USER_CONFIG, encoding="utf-8")
    (codex / "AGENTS.md").write_text(USER_AGENTS, encoding="utf-8")

def user_data_problems(codex: Path) -> list[str]:
    out = []
    try:
        hooks = json.loads((codex / "hooks.json").read_text(encoding="utf-8"))["hooks"]
        if hooks.get("Stop") != USER_HOOKS["hooks"]["Stop"]: out.append("foreign Stop hook changed")
        if USER_HOOKS["hooks"]["UserPromptSubmit"][0] not in hooks["UserPromptSubmit"]: out.append("foreign UserPromptSubmit group lost")
    except Exception as exc: out.append(f"hooks.json unreadable: {exc}")
    cfg = (codex / "config.toml").read_text(encoding="utf-8")
    if 'model = "my-model"' not in cfg or "[my_table]" not in cfg or 'key = "value"' not in cfg: out.append("config.toml user keys/tables lost")
    if "Keep answers short." not in (codex / "AGENTS.md").read_text(encoding="utf-8"): out.append("AGENTS.md personal text lost")
    return out

def exercise(label: str, install, uninstall, win_expected: bool = False) -> None:
    """install(codex, skills, *extra) / uninstall(codex, skills) return CompletedProcess."""
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        codex, skills = base / "custom co'dex", base / "custom skills"  # single quote exercises shell_quote and the hook
        # audit must not write anything
        r = install(codex, skills, "--audit", "--all")
        check(r.returncode == 0, f"{label}: audit failed: {r.stderr or r.stdout}")
        check(not codex.exists() and not skills.exists(), f"{label}: audit wrote to disk")
        # apply creates everything, with the absolute hook path
        r = install(codex, skills, "--all")
        check(r.returncode == 0, f"{label}: apply failed: {r.stderr or r.stdout}")
        check(all((codex / "agent-configs" / f"{x}.toml").is_file() for x in expected), f"{label}: agent layers missing")
        check(all((skills / n / "SKILL.md").is_file() for n in SKILLS_V5), f"{label}: Skills missing")
        check(all((skills / n / "SKILL.md").is_file() for n in ALL_OPTIONAL_SPECS), f"{label}: optional specialists missing")
        check(not list(codex.rglob("*.tmp")), f"{label}: leftover .tmp file")
        try:
            groups = json.loads((codex / "hooks.json").read_text(encoding="utf-8"))["hooks"]["UserPromptSubmit"]
            check(len(groups) == 1, f"{label}: expected one hook group")
            check(("commandWindows" in groups[0]["hooks"][0]) == win_expected, f"{label}: commandWindows {'missing' if win_expected else 'unexpectedly present'} outside a /mnt/<x> home")
            cmd = groups[0]["hooks"][0]["command"]
            check(str(codex).replace("'", "'\\''") in cmd and "CODEX_HOME" not in cmd, f"{label}: hook command is not the absolute (shell-quoted) custom path: {cmd}")
            out = subprocess.run(cmd, shell=True, capture_output=True, text=True, env=ENV)
            check(json.loads(out.stdout)["hookSpecificOutput"]["hookEventName"] == "UserPromptSubmit", f"{label}: installed hook output invalid")
        except Exception as exc:
            ERRORS.append(f"{label}: hooks.json check failed: {exc}")
        # idempotent rerun with identical Skills reuses them
        before = snapshot(codex, skills)
        r = install(codex, skills, "--all")
        check(r.returncode == 0, f"{label}: rerun failed: {r.stderr or r.stdout}")
        check(snapshot(codex, skills).keys() == before.keys(), f"{label}: rerun changed the file set")
        check(all(snapshot(skills)[k] == v for k, v in before.items() if k.startswith(str(skills))), f"{label}: rerun changed Skills")
        cfg = (codex / "config.toml").read_text(encoding="utf-8")
        check(cfg.count("BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS") == 1, f"{label}: registration block duplicated")
        try: check(len(router_groups(codex)) == 1, f"{label}: rerun left {len(router_groups(codex))} mandatory-router groups in UserPromptSubmit")
        except Exception as exc: ERRORS.append(f"{label}: rerun hooks.json unreadable: {exc}")
        # divergent v5 Skill: abort before any mutation, in audit and apply
        (skills / "code-review" / "SKILL.md").write_text("divergent\n", encoding="utf-8")
        before = snapshot(codex, skills)
        backups = sorted((codex / "backups").iterdir())
        for extra in (("--audit",), ()):
            r = install(codex, skills, *extra)
            check(r.returncode != 0, f"{label}: divergent Skill did not abort ({extra or 'apply'})")
            check(snapshot(codex, skills) == before, f"{label}: divergent Skill run mutated files ({extra or 'apply'})")
            check(sorted((codex / "backups").iterdir()) == backups, f"{label}: divergent Skill run created a backup")
        (skills / "code-review" / "SKILL.md").write_text((ROOT / ".agents/skills/code-review/SKILL.md").read_text(encoding="utf-8"), encoding="utf-8")
        # invalid or unexpected hooks.json: abort before any mutation (same in both installers)
        hp = codex / "hooks.json"
        for bad in ("{not json", '{"hooks": []}', '{"hooks": {"UserPromptSubmit": {"a": 1}}}', '{"hooks": null}', '{"hooks": false}', '{"hooks": {"UserPromptSubmit": null}}', '{"hooks": {"UserPromptSubmit": false}}'):
            hp.write_text(bad, encoding="utf-8")
            before = snapshot(codex, skills); backups = sorted((codex / "backups").iterdir())
            r = install(codex, skills)
            check(r.returncode != 0 and snapshot(codex, skills) == before and sorted((codex / "backups").iterdir()) == backups, f"{label}: hooks.json {bad!r} was not a clean abort")
        # --no-hook never reads hooks.json, so an invalid one is ignored and left untouched
        hp.write_text("{not json", encoding="utf-8")
        r = install(codex, skills, "--no-hook")
        check(r.returncode == 0 and hp.read_text(encoding="utf-8") == "{not json", f"{label}: --no-hook with invalid hooks.json: {r.stderr or r.stdout}")
        # uninstall must also abort without mutating anything (no backup dir either)
        before = snapshot(codex, skills); backups = sorted((codex / "backups").iterdir())
        r = uninstall(codex, skills)
        check(r.returncode != 0 and snapshot(codex, skills) == before and sorted((codex / "backups").iterdir()) == backups, f"{label}: uninstall did not abort cleanly on invalid hooks.json")
        hp.write_text("{}", encoding="utf-8")
        # uninstall
        r = uninstall(codex, skills)
        check(r.returncode == 0, f"{label}: uninstall failed: {r.stderr or r.stdout}")
        check(not any((skills / n).exists() for n in SKILLS_V5), f"{label}: uninstall left Skills")
    # legacy handling: framework-owned legacy Skill moved, foreign one left intact
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp); codex, skills = base / "c", base / "s"
        (skills / "task-router").mkdir(parents=True); (skills / "task-router" / "SKILL.md").write_text("Route to luna_worker\n")
        (skills / "testing").mkdir(); (skills / "testing" / "SKILL.md").write_text("my own testing skill\n")
        r = install(codex, skills)
        check(r.returncode == 0, f"{label}: legacy scenario failed: {r.stderr or r.stdout}")
        check(not (skills / "task-router").exists(), f"{label}: framework legacy Skill not migrated")
        check((skills / "testing" / "SKILL.md").read_text() == "my own testing skill\n", f"{label}: foreign Skill was touched")
        moved = list((codex / "backups").glob("framework-v5-*/user-skills/task-router/SKILL.md"))
        check(len(moved) == 1 and moved[0].read_text() == "Route to luna_worker\n", f"{label}: migrated Skill not preserved in backup with original content")
    # SKILLS_HOME == CODEX_HOME/skills: the empty-legacy-root cleanup must not remove the live Skills root
    with tempfile.TemporaryDirectory() as tmp:
        codex = Path(tmp) / "d"; skills = codex / "skills"
        r = install(codex, skills)
        check(r.returncode == 0, f"{label}: shared skills root failed: {r.stderr or r.stdout}")
        check(all((skills / n / "SKILL.md").is_file() for n in SKILLS_V5), f"{label}: shared skills root: Skills missing")
        check((codex / "AGENTS.md").is_file() and V5_MARK in (codex / "AGENTS.md").read_text(encoding="utf-8"), f"{label}: shared skills root: AGENTS.md lacks v5 block")
        try: check(len(router_groups(codex)) == 1, f"{label}: shared skills root: hooks.json not updated")
        except Exception as exc: ERRORS.append(f"{label}: shared skills root: hooks.json unreadable: {exc}")
    # user data outside the framework survives install, reinstall and uninstall
    with tempfile.TemporaryDirectory() as tmp:
        codex, skills = Path(tmp) / "pres co'dex", Path(tmp) / "s"
        seed_user_data(codex)
        for step, action in (("install", lambda: install(codex, skills)), ("reinstall", lambda: install(codex, skills)), ("uninstall", lambda: uninstall(codex, skills))):
            r = action()
            check(r.returncode == 0, f"{label}: preservation {step} failed: {r.stderr or r.stdout}")
            for problem in user_data_problems(codex): ERRORS.append(f"{label}: after {step}: {problem}")
        check(V5_MARK not in (codex / "AGENTS.md").read_text(encoding="utf-8") and not router_groups(codex), f"{label}: uninstall left framework content")
    # uninstall with unbalanced markers: abort before any backup or mutation
    for fname, text in (("AGENTS.md", "keep\n<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5 -->\nunterminated\n"), ("config.toml", 'model = "x"\n# END CODEX GLOBAL FRAMEWORK V5 AGENTS\n')):
        with tempfile.TemporaryDirectory() as tmp:
            codex, skills = Path(tmp) / "c", Path(tmp) / "s"; codex.mkdir()
            (codex / fname).write_text(text, encoding="utf-8")
            before = snapshot(codex)
            r = uninstall(codex, skills)
            check(r.returncode != 0 and snapshot(codex) == before and not (codex / "backups").exists(), f"{label}: uninstall with unbalanced markers in {fname} was not a clean abort: {r.stderr or r.stdout}")
    # invalid hooks.json on a fresh home: clean abort, no backup directory created
    with tempfile.TemporaryDirectory() as tmp:
        codex, skills = Path(tmp) / "c", Path(tmp) / "s"; codex.mkdir()
        (codex / "hooks.json").write_text("{not json", encoding="utf-8")
        r = install(codex, skills)
        check(r.returncode != 0 and not (codex / "backups").exists() and not skills.exists(), f"{label}: invalid hooks.json created a backup dir or Skills root")
    # unbalanced markers in config.toml (global install): abort, nothing written
    with tempfile.TemporaryDirectory() as tmp:
        codex, skills = Path(tmp) / "c", Path(tmp) / "s"; codex.mkdir()
        (codex / "config.toml").write_text("# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS\nmodel = \"x\"\n", encoding="utf-8")
        before = snapshot(codex)
        r = install(codex, skills)
        check(r.returncode != 0 and snapshot(codex) == before and not (codex / "backups").exists() and not skills.exists(), f"{label}: unbalanced config.toml markers were not a clean abort")
    # every optional conflict is listed, not only the first
    with tempfile.TemporaryDirectory() as tmp:
        codex, skills = Path(tmp) / "c", Path(tmp) / "s"
        for name in ("zabbix-specialist", "grafana-specialist"):
            (skills / name).mkdir(parents=True); (skills / name / "SKILL.md").write_text("different\n")
        r = install(codex, skills, "--all")
        out = r.stdout + r.stderr
        check(r.returncode != 0 and "zabbix-specialist" in out and "grafana-specialist" in out and not codex.exists(), f"{label}: optional conflicts not all listed / not a clean abort: {out[-400:]}")

def make_sh(env=ENV):
    def sh_install(codex, skills, *extra):
        args = [a for a in extra if a not in ("--audit", "--all")]
        if "--audit" in extra: args.append("--audit-only")
        if "--all" in extra: args.append("--with-all-specialists")
        return run(["bash", ROOT / "scripts" / "install.sh", "--codex-home", f"{codex}/", "--skills-home", skills, *args], env=env)
    def sh_uninstall(codex, skills):
        return run(["bash", ROOT / "scripts" / "uninstall.sh", "--codex-home", codex, "--skills-home", skills], env=env)
    def sh_diagnose(codex, skills):
        return run(["bash", ROOT / "scripts" / "diagnose.sh", "--codex-home", codex, "--skills-home", skills], env=env)
    return sh_install, sh_uninstall, sh_diagnose

sh_install, sh_uninstall, sh_diagnose = make_sh()
exercise("install.sh", sh_install, sh_uninstall)

# jq branch: PATH with only the needed tools (no python3, no python) plus jq
def tool_dir(tmp: Path, names) -> dict:
    tmp.mkdir(parents=True, exist_ok=True)
    for n in names:
        src = shutil.which(n)
        if src and not (tmp / n).exists(): (tmp / n).symlink_to(src)
    return {**ENV, "PATH": str(tmp)}

BASE_TOOLS = ("bash sh dirname basename cat awk grep sed find sort diff cp mv mkdir rm rmdir cmp date cut ls chmod realpath tr head tail wc touch ln stat readlink env").split()
if shutil.which("jq"):
    with tempfile.TemporaryDirectory() as tools:
        JQ_ENV = tool_dir(Path(tools) / "jq", (*BASE_TOOLS, "jq"))
        check(shutil.which("python3", path=JQ_ENV["PATH"]) is None, "jq scenario PATH still exposes python3")
        jq_install, jq_uninstall, jq_diagnose = make_sh(JQ_ENV)
        exercise("install.sh (jq, no python3)", jq_install, jq_uninstall)
        # python and jq produce equivalent hooks.json from the same user file, then diagnose and uninstall work without python3
        docs = []
        for install in (sh_install, jq_install):
            with tempfile.TemporaryDirectory() as tmp:
                codex, skills = Path(tmp) / "c", Path(tmp) / "s"; seed_user_data(codex)
                r = install(codex, skills)
                check(r.returncode == 0, f"jq equivalence install failed: {r.stderr or r.stdout}")
                docs.append(json.loads((codex / "hooks.json").read_text(encoding="utf-8").replace(str(codex), "<codex>")))
                if install is jq_install:
                    r = jq_diagnose(codex, skills); check(r.returncode == 0 and "exactly one routing reminder hook" in r.stdout, f"diagnose.sh without python3: {r.stdout}")
                    r = jq_uninstall(codex, skills); check(r.returncode == 0 and not router_groups(codex), f"uninstall.sh without python3: {r.stderr or r.stdout}")
                    for problem in user_data_problems(codex): ERRORS.append(f"jq uninstall: {problem}")
        check(docs[0] == docs[1], "python3 and jq produced different hooks.json")
        # neither python3 nor jq: an existing hooks.json aborts install and uninstall before any change
        NONE_ENV = tool_dir(Path(tools) / "none", BASE_TOOLS)
        none_install, none_uninstall, _ = make_sh(NONE_ENV)
        with tempfile.TemporaryDirectory() as tmp:
            codex, skills = Path(tmp) / "c", Path(tmp) / "s"; seed_user_data(codex)
            before = snapshot(codex)
            for name, act in (("install", none_install), ("uninstall", none_uninstall)):
                r = act(codex, skills)
                check(r.returncode != 0 and snapshot(codex) == before and not (codex / "backups").exists() and not skills.exists(), f"{name} without python3/jq was not a clean abort: {r.stderr or r.stdout}")
else:
    print("NOTE: jq not found; jq branch not validated.")

# commandWindows derivation (WSL /mnt/<x> only) extracted from install.sh
def sh_func(name: str) -> str:
    m = re.search(rf"^{name}\(\) \{{\n.*?^\}}\n", (ROOT / "scripts" / "install.sh").read_text(encoding="utf-8"), re.M | re.S)
    return m.group(0) if m else ""
for home, want in (("/mnt/c/Users/Ana Lima/.codex", 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\Ana Lima\\.codex\\hooks\\mandatory-router.ps1"'),
                   ("/mnt/d/x/.codex", 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\\x\\.codex\\hooks\\mandatory-router.ps1"'),
                   ("/home/u/.codex", ""), ("/mnt/c", ""), ("/mnt/cc/x", ""), ("/srv/mnt/c/x", "")):
    r = run(["bash", "-c", sh_func("win_hook_command") + '\nwin_hook_command "$1"', "_", home])
    check(sh_func("win_hook_command") != "" and r.returncode == 0 and r.stdout == want, f"win_hook_command({home!r}) = {r.stdout!r}, expected {want!r}")

def shared_skills_root(label, install, diagnose, win_expected=False):
    """Skills root reachable through a symlink (SKILLS_HOME -> CODEX_HOME/skills, or CODEX_HOME itself a link): reruns keep the live Skills."""
    for variant in ("skills-link", "codex-link"):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp); real = base / "real"; (real / "skills").mkdir(parents=True)
            if variant == "skills-link":
                codex, skills = real, base / "skills"; skills.symlink_to(real / "skills", target_is_directory=True)
            else:
                codex, skills = base / "codexlink", real / "skills"; codex.symlink_to(real, target_is_directory=True)
            for run_no in (1, 2):
                r = install(codex, skills)
                check(r.returncode == 0, f"{label} [{variant}] run {run_no} failed: {r.stderr or r.stdout}")
                check(all((real / "skills" / n / "SKILL.md").is_file() for n in SKILLS_V5), f"{label} [{variant}] run {run_no}: Skills missing")
            moved = [p for p in (real / "backups").rglob("*") if p.name in SKILLS_V5 or p.name in ("user-skills", "legacy-codex-skills")]
            check(not moved, f"{label} [{variant}]: active Skills were moved to backup: {moved}")
            r = diagnose(codex, skills)
            check(r.returncode == 0 and "FAIL" not in r.stdout, f"{label} [{variant}]: diagnose reported FAIL: {r.stdout}")

shared_skills_root("diagnose.sh", sh_install, sh_diagnose)

r = run(["bash", ROOT / "scripts" / "install.sh", "--codex-home"]); check(r.returncode != 0, "missing option value must fail")
r = run(["bash", ROOT / "scripts" / "install.sh", "--apply", "--audit-only"]); check(r.returncode != 0, "--apply with --audit-only must fail")
r = run(["bash", ROOT / "scripts" / "install.sh", "--bogus"]); check(r.returncode != 0, "unknown option must fail")

with tempfile.TemporaryDirectory() as tmp:  # project target with trailing slash, audit vs apply
    proj = Path(tmp) / "proj"; proj.mkdir()
    r = run(["bash", ROOT / "scripts" / "install.sh", "--audit-only", "--target", f"{proj}/", "--with-zabbix-specialist"])
    check(r.returncode == 0 and not any(proj.iterdir()), "project audit failed or wrote to disk")
    r = run(["bash", ROOT / "scripts" / "install.sh", "--apply", "--target", f"{proj}/", "--with-zabbix-specialist"])
    check(r.returncode == 0 and (proj / "AGENTS.md").is_file(), f"project apply failed: {r.stderr}")
    (proj / "AGENTS.md").write_text("<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5 -->\nunterminated\n")
    before = snapshot(proj)
    r = run(["bash", ROOT / "scripts" / "install.sh", "--target", proj])
    check(r.returncode != 0 and snapshot(proj) == before, "unbalanced AGENTS markers must abort without changes")

with tempfile.TemporaryDirectory() as tmp:  # diagnose on a fresh install
    codex, skills = Path(tmp) / "c", Path(tmp) / "s"
    sh_install(codex, skills)
    r = sh_diagnose(codex, skills)
    check(r.returncode == 0 and "hooks.json is valid JSON" in r.stdout, f"diagnose.sh failed: {r.stdout}")

def diag_divergent(label: str, install, diagnose) -> None:
    """A divergent v5 Skill in .codex/skills is kept by the installer with a NOTE; diagnose must WARN, not FAIL."""
    with tempfile.TemporaryDirectory() as tmp:
        codex, skills = Path(tmp) / "c", Path(tmp) / "s"
        old = codex / "skills" / "code-review"; old.mkdir(parents=True); (old / "SKILL.md").write_text("my own code review notes\n")
        r = install(codex, skills)
        check(r.returncode == 0 and "NOTE" in r.stdout and old.is_dir(), f"{label}: divergent .codex/skills scenario: {r.stderr or r.stdout}")
        r = diagnose(codex, skills)
        check(r.returncode == 0 and "FAIL" not in r.stdout and "WARN" in r.stdout, f"{label}: diagnose should WARN (not FAIL) for the kept divergent Skill: {r.stdout}")

diag_divergent("diagnose.sh", sh_install, sh_diagnose)

pwsh = shutil.which("pwsh")
print(f"NOTE: pwsh {'found at ' + pwsh if pwsh else 'not found'}.")
if pwsh:
    for script in sorted((ROOT / "scripts").glob("*.ps1")) + sorted((ROOT / ".codex" / "hooks").glob("*.ps1")):
        r = run([pwsh, "-NoProfile", "-Command", "$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($env:PS_SCRIPT,[ref]$null,[ref]$e);if($e){$e|%{$_.Message};exit 1}"], env={**ENV, "PS_SCRIPT": str(script)})
        check(r.returncode == 0, f"PowerShell syntax error in {script.name}: {r.stdout}{r.stderr}")
    def ps_install(codex, skills, *extra):
        args = []
        if "--audit" in extra: args.append("-AuditOnly")
        if "--all" in extra: args.append("-WithAllSpecialists")
        if "--no-hook" in extra: args.append("-NoHook")
        return run([pwsh, "-NoProfile", "-File", ROOT / "scripts" / "install.ps1", "-CodexHome", codex, "-SkillsHome", skills, *args])
    def ps_uninstall(codex, skills):
        return run([pwsh, "-NoProfile", "-File", ROOT / "scripts" / "uninstall.ps1", "-CodexHome", codex, "-SkillsHome", skills])
    ps_diagnose = lambda c, s: run([pwsh, "-NoProfile", "-File", ROOT / "scripts" / "diagnose.ps1", "-CodexHome", c, "-SkillsHome", s])
    exercise("install.ps1", ps_install, ps_uninstall, win_expected=True)
    diag_divergent("diagnose.ps1", ps_install, ps_diagnose)
    shared_skills_root("install.ps1/diagnose.ps1", ps_install, ps_diagnose)
    # ConvertTo-ShPath (Windows drive -> /mnt/<x>) extracted from install.ps1
    for win, want in (("C:\\Users\\Ana Lima\\.codex\\hooks\\mandatory-router.sh", "/mnt/c/Users/Ana Lima/.codex/hooks/mandatory-router.sh"), ("D:/x/y", "/mnt/d/x/y"), ("/home/u/.codex", "/home/u/.codex")):
        r = run([pwsh, "-NoProfile", "-Command", "$ast=[System.Management.Automation.Language.Parser]::ParseFile($env:PS_SCRIPT,[ref]$null,[ref]$null);$f=$ast.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'ConvertTo-ShPath'},$true);. ([scriptblock]::Create($f.Extent.Text));[Console]::Out.Write((ConvertTo-ShPath $env:PS_IN))"], env={**ENV, "PS_SCRIPT": str(ROOT / "scripts" / "install.ps1"), "PS_IN": win})
        check(r.stdout == want, f"ConvertTo-ShPath({win!r}) = {r.stdout!r} {r.stderr[-200:]}, expected {want!r}")
else:
    print("NOTE: PowerShell scripts were not validated (pwsh unavailable).")

zabbix_test = ROOT / "optional" / "zabbix-specialist" / ".agents" / "skills" / "zabbix-specialist" / "scripts" / "test_rag_ingest.py"
if zabbix_test.is_file():
    r = run([sys.executable, zabbix_test])
    check(r.returncode == 0, f"zabbix test_rag_ingest.py failed: {r.stderr[-500:]}")

# ---- Personal paths and token-like strings ----
SECRET_RE = re.compile(r"ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----")
users = {u for u in (getpass.getuser(), Path.home().name) if u and u not in ("root", "user")}
path_re = re.compile("|".join(re.escape(f"/home/{u}") for u in users)) if users else None
for f in sorted(ROOT.rglob("*")):
    if not f.is_file() or f.name == "MANIFEST.sha256":
        continue
    try: text = f.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError): continue
    rel = f.relative_to(ROOT)
    if not f.name.startswith("test_"):  # test fixtures contain deliberate fake secrets
        check(not SECRET_RE.search(text), f"token-like string in {rel}")
    check(not (path_re and path_re.search(text)), f"personal path in {rel}")

manifest = ROOT / "MANIFEST.sha256"
if manifest.exists():
    for line in manifest.read_text().splitlines():
        digest, relative = line.split("  ", 1); target = ROOT / relative
        check(target.exists(), f"manifest target missing: {relative}")
        if target.exists(): check(hashlib.sha256(target.read_bytes()).hexdigest() == digest, f"manifest mismatch: {relative}")

if ERRORS:
    print("Validation failed:")
    for error in ERRORS: print(f"- {error}")
    sys.exit(1)
print(f"Validation OK: {len(expected)} registered agent layers, {len(skill_names)} Skills, weights=100, installers exercised" + ("" if pwsh else " (bash only; pwsh unavailable)"))
