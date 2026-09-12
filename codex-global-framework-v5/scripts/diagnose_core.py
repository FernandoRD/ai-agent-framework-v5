#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROLES = ("luna_explorer", "luna_worker", "terra_worker", "terra_reviewer", "sol_specialist", "sol_reviewer", "sol_critical")
LEGACY = ("task-router", "complexity-score", "deep-analysis", "implementation", "testing", "refactor", "final-review", "model-usage-report")
SKILLS = ("security-review", "code-review", "dependency-review", "documentation")


def main() -> int:
    home = Path.home()
    parser = argparse.ArgumentParser()
    parser.add_argument("--codex-home", default=os.environ.get("CODEX_HOME", str(home / ".codex")))
    parser.add_argument("--skills-home", default=str(home / ".agents" / "skills"))
    args = parser.parse_args()
    codex, skills = Path(args.codex_home).expanduser().resolve(), Path(args.skills_home).expanduser().resolve()
    errors = warnings = 0
    def ok(message: str) -> None: print(f"OK    {message}")
    def warn(message: str) -> None:
        nonlocal warnings; warnings += 1; print(f"WARN  {message}")
    def fail(message: str) -> None:
        nonlocal errors; errors += 1; print(f"FAIL  {message}")
    print(f"Codex home: {codex}\nSkills home: {skills}\n")
    agents_md = codex / "AGENTS.md"
    if agents_md.exists() and "CODEX-GLOBAL-FRAMEWORK:BEGIN v5" in agents_md.read_text(encoding="utf-8-sig"): ok("v5 block found in AGENTS.md")
    else: fail("v5 block missing from AGENTS.md")
    override = codex / "AGENTS.override.md"
    if override.exists() and override.stat().st_size: fail("non-empty AGENTS.override.md shadows AGENTS.md")
    else: ok("no global AGENTS.override.md shadow")
    config_file = codex / "config.toml"
    config = config_file.read_text(encoding="utf-8-sig") if config_file.exists() else ""
    if "# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS" in config: ok("v5 agent registration block found")
    else: fail("v5 agent registration block missing")
    for role in ROLES:
        count = len(re.findall(rf"^\s*\[agents\.{re.escape(role)}\]\s*$", config, re.M))
        if count == 1: ok(f"one registration for {role}")
        else: fail(f"registration count for {role}: {count}")
        layer = codex / "agent-configs" / f"{role}.toml"
        if layer.exists() and not re.search(r"^\s*(name|description)\s*=", layer.read_text(encoding="utf-8-sig"), re.M): ok(f"agent layer {role}")
        else: fail(f"missing or standalone-form layer {role}")
    standalone = codex / "agents"
    if standalone.exists():
        for file in standalone.glob("*.toml"):
            text = file.read_text(encoding="utf-8-sig")
            match = re.search(r'^\s*name\s*=\s*"([^"]+)"', text, re.M)
            role = match.group(1) if match else file.stem
            if role in ROLES or file.stem in ROLES: fail(f"duplicate-prone standalone framework agent: {file}")
    for name in SKILLS:
        skill = skills / name / "SKILL.md"
        if skill.exists() and f"name: {name}" in skill.read_text(encoding="utf-8"): ok(f"skill {name}")
        else: fail(f"missing or invalid skill {name}")
        if (codex / "skills" / name).exists(): fail(f"duplicate legacy .codex/skills copy remains: {name}")
    for name in LEGACY:
        if (skills / name).exists(): fail(f"legacy user Skill remains: {name}")
        if (codex / "skills" / name).exists(): fail(f"legacy .codex/skills copy remains: {name}")
    hooks = codex / "hooks.json"
    if hooks.exists():
        try: data = json.loads(hooks.read_text(encoding="utf-8-sig")); ok("hooks.json is valid JSON")
        except Exception: data = None; fail("hooks.json is invalid")
        framework_hooks = [g for g in (data or {}).get("hooks", {}).get("UserPromptSubmit", []) if "mandatory-router" in json.dumps(g)]
        if len(framework_hooks) == 1: ok("exactly one routing reminder hook is configured")
        elif not framework_hooks: warn("routing hook absent; AGENTS.md still works")
        else: fail(f"duplicate routing hooks: {len(framework_hooks)}")
    else: warn("hooks.json absent; AGENTS.md still works")
    hook = codex / "hooks" / "mandatory-router.sh"
    if hook.exists():
        result = subprocess.run(["sh", str(hook)], capture_output=True, text=True)
        try:
            event = json.loads(result.stdout)["hookSpecificOutput"]["hookEventName"]
            if event == "UserPromptSubmit": ok("routing hook output is valid")
            else: fail("routing hook event is wrong")
        except Exception: fail("routing hook output is invalid")
    if re.search(r"^\s*hooks\s*=\s*false\s*$", config, re.M): warn("hooks disabled in config.toml")
    print()
    if errors: print(f"Result: FAIL ({errors} error(s), {warnings} warning(s))"); return 1
    if warnings: print(f"Result: WARN ({warnings} warning(s))")
    else: print("Result: OK")
    print("Restart Codex after installation. Use /hooks to verify UserPromptSubmit is Active.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
