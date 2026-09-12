#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, os, re, shutil
from datetime import datetime
from pathlib import Path

ROLES = ("luna_explorer", "luna_worker", "terra_worker", "terra_reviewer", "sol_specialist", "sol_reviewer", "sol_critical")
SKILLS = ("security-review", "code-review", "dependency-review", "documentation")

def main() -> None:
    home = Path.home(); parser = argparse.ArgumentParser()
    parser.add_argument("--codex-home", default=os.environ.get("CODEX_HOME", str(home / ".codex")))
    parser.add_argument("--skills-home", default=str(home / ".agents" / "skills")); args = parser.parse_args()
    codex, skills = Path(args.codex_home).expanduser().resolve(), Path(args.skills_home).expanduser().resolve()
    backup = codex / "backups" / f"framework-v5-uninstall-{datetime.now():%Y%m%d-%H%M%S-%f}"; backup.mkdir(parents=True)
    for source, rel in ((codex / "AGENTS.md", "AGENTS.md"), (codex / "config.toml", "config.toml"), (codex / "hooks.json", "hooks.json")):
        if source.exists(): shutil.copy2(source, backup / rel)
    agents = codex / "AGENTS.md"
    if agents.exists():
        text = re.sub(r"<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5.*?<!-- CODEX-GLOBAL-FRAMEWORK:END v5 -->\s*", "", agents.read_text(encoding="utf-8-sig"), flags=re.S).strip()
        agents.write_text(text + ("\n" if text else ""), encoding="utf-8")
    config = codex / "config.toml"
    if config.exists():
        text = re.sub(r"# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS.*?# END CODEX GLOBAL FRAMEWORK V5 AGENTS\s*", "", config.read_text(encoding="utf-8-sig"), flags=re.S).rstrip()
        config.write_text(text + ("\n" if text else ""), encoding="utf-8")
    for role in ROLES:
        layer = codex / "agent-configs" / f"{role}.toml"
        if layer.exists():
            destination = backup / "agent-configs" / layer.name; destination.parent.mkdir(parents=True, exist_ok=True); shutil.move(str(layer), str(destination))
    for name in SKILLS:
        skill = skills / name
        if skill.exists():
            destination = backup / "skills" / name; destination.parent.mkdir(parents=True, exist_ok=True); shutil.move(str(skill), str(destination))
    hooks = codex / "hooks.json"
    if hooks.exists():
        data = json.loads(hooks.read_text(encoding="utf-8-sig")); groups = data.get("hooks", {}).get("UserPromptSubmit", [])
        data.get("hooks", {})["UserPromptSubmit"] = [g for g in groups if "mandatory-router" not in json.dumps(g)]
        hooks.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    for hook in (codex / "hooks" / "mandatory-router.sh", codex / "hooks" / "mandatory-router.ps1"):
        if hook.exists(): hook.unlink()
    print(f"Framework v5 removed. Backup: {backup}")

if __name__ == "__main__": main()
