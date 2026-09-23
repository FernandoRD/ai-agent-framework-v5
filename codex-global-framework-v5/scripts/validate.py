#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, py_compile, re, shutil, subprocess, sys, tempfile, tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ERRORS: list[str] = []
def check(value: bool, message: str) -> None:
    if not value: ERRORS.append(message)

check((ROOT / "VERSION").read_text().strip() == "5.0.0", "unexpected VERSION")
agents_md = (ROOT / ".codex" / "AGENTS.md").read_text(encoding="utf-8")
check("CODEX-GLOBAL-FRAMEWORK:BEGIN v5" in agents_md, "v5 AGENTS marker missing")
weights = [int(x) for x in re.findall(r"\| [^|]+ \| (\d+) \|", agents_md)]
check(sum(weights[:12]) == 100, "routing weights do not sum to 100")

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
print(f"Validation OK: {len(expected)} registered agent layers, {len(skill_names)} Skills, weights=100")
