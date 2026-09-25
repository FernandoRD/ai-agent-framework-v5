#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent.parent
ROLES = {
    "luna_explorer": "Low-cost read-only explorer for targeted codebase mapping and compact context capsules.",
    "luna_worker": "Efficient worker for narrow, well-specified, low-risk implementation and mechanical tasks.",
    "terra_worker": "Balanced implementation worker for normal engineering changes across related files.",
    "terra_reviewer": "Independent read-only reviewer for correctness, regressions, and missing tests.",
    "sol_specialist": "High-capability specialist for difficult implementation and ambiguous multi-step reasoning.",
    "sol_reviewer": "Independent read-only reviewer for complex or high-risk engineering changes.",
    "sol_critical": "Read-only critical analyst for security boundaries, data loss, concurrency, and production incidents.",
}
LEGACY_SKILLS = (
    "task-router", "complexity-score", "deep-analysis", "implementation",
    "testing", "refactor", "final-review", "model-usage-report",
    "security-review", "code-review", "dependency-review", "documentation",
)
CURRENT_SKILLS = ("security-review", "code-review", "dependency-review", "documentation")


def role_of(path: Path) -> str:
    match = re.search(r'^\s*name\s*=\s*"([^"]+)"', path.read_text(encoding="utf-8-sig"), re.M)
    return match.group(1) if match else path.stem


def move_to_backup(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        raise RuntimeError(f"backup collision: {destination}")
    shutil.move(str(source), str(destination))


def audit(codex: Path, skills: Path) -> list[tuple[str, str, str]]:
    findings: list[tuple[str, str, str]] = []
    agents_md, override = codex / "AGENTS.md", codex / "AGENTS.override.md"
    if override.exists() and override.stat().st_size:
        findings.append(("shadow", str(override), "manual review required"))
    if agents_md.exists():
        text = agents_md.read_text(encoding="utf-8-sig")
        if re.search(r"CODEX-GLOBAL-FRAMEWORK:BEGIN v[1-4]", text):
            findings.append(("legacy AGENTS", str(agents_md), "replace marked framework block"))
        if re.search(r"task-router", text, re.I) and "CODEX-GLOBAL-FRAMEWORK:BEGIN" not in text:
            findings.append(("unmarked AGENTS", str(agents_md), "preserve and warn for manual review"))
    standalone = codex / "agents"
    if standalone.exists():
        for file in standalone.glob("*.toml"):
            if role_of(file) in ROLES or file.stem in ROLES:
                findings.append(("standalone agent", str(file), "backup; register explicitly"))
    for root in (codex / "skills", skills):
        for name in LEGACY_SKILLS:
            path = root / name
            if path.exists():
                action = "backup and replace with v5" if root == skills and name in CURRENT_SKILLS else "move legacy Skill to backup"
                findings.append(("legacy Skill", str(path), action))
    config = codex / "config.toml"
    if config.exists():
        text = config.read_text(encoding="utf-8-sig")
        for role in ROLES:
            if re.search(rf"^\s*\[agents\.{re.escape(role)}\]\s*$", text, re.M):
                findings.append(("agent registration", f"{config} [{role}]", "normalize to one v5 block"))
    hooks = codex / "hooks.json"
    if hooks.exists() and "mandatory-router" in hooks.read_text(encoding="utf-8-sig"):
        findings.append(("routing hook", str(hooks), "replace framework hook"))
    return findings


def main() -> int:
    home = Path.home().resolve()
    parser = argparse.ArgumentParser(description="Install Codex Global Framework v5")
    parser.add_argument("--target", default=None, help="Target directory (project or home)")
    parser.add_argument("--global", "-g", dest="is_global", action="store_true", help="Install globally to home directory")
    parser.add_argument("--codex-home", default=None, help="Explicit Codex home directory (defaults to ~/.codex)")
    parser.add_argument("--skills-home", default=None, help="Explicit skills home directory (defaults to ~/.agents/skills)")
    parser.add_argument("--no-hook", action="store_true")
    parser.add_argument("--audit-only", action="store_true")
    parser.add_argument("--apply", action="store_true", help="Apply installation (default when not --audit-only)")
    args = parser.parse_args()

    is_project = False
    if args.target:
        target_path = Path(args.target).expanduser().resolve()
        if not args.is_global and target_path != home:
            is_project = True

    if is_project:
        target_path = Path(args.target).expanduser().resolve()
        if not target_path.exists() or not target_path.is_dir():
            raise SystemExit(f"Target directory does not exist or is not a directory: {target_path}")
        agents_file = target_path / "AGENTS.md"
        print("Codex Framework v5 project preflight")
        print(f"Project target: {target_path}")
        print(f"Agents file: {agents_file}")
        if agents_file.exists():
            text = agents_file.read_text(encoding="utf-8-sig")
            if "CODEX-GLOBAL-FRAMEWORK:BEGIN" in text:
                print("- legacy/existing AGENTS: replace marked framework block")
            else:
                print("- existing AGENTS: append framework block preserving personal text")
        else:
            print("- new AGENTS: create AGENTS.md with framework block")
        if args.audit_only:
            print("Audit-only mode: no files changed.")
            return 0
        existing = agents_file.read_text(encoding="utf-8-sig") if agents_file.exists() else ""
        personal = re.sub(r"<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN.*?<!-- CODEX-GLOBAL-FRAMEWORK:END.*?-->\s*", "", existing, flags=re.S).strip()
        block = (PACKAGE / ".codex" / "AGENTS.md").read_text(encoding="utf-8").strip()
        agents_file.write_text((personal + "\n\n" if personal else "") + block + "\n", encoding="utf-8")
        print(f"\nCodex Framework v5 installed for project: {target_path}")
        return 0

    codex = Path(args.codex_home or os.environ.get("CODEX_HOME", str(home / ".codex"))).expanduser().resolve()
    skills = Path(args.skills_home or str(home / ".agents" / "skills")).expanduser().resolve()
    if codex == Path(codex.anchor) or skills == Path(skills.anchor):
        raise SystemExit("Refusing unsafe target path.")
    hooks_file = codex / "hooks.json"
    if hooks_file.exists():
        try:
            json.loads(hooks_file.read_text(encoding="utf-8-sig"))
        except Exception as exc:
            raise SystemExit(f"Existing hooks.json is invalid; no changes made: {exc}")

    findings = audit(codex, skills)
    print("Codex Global Framework v5 preflight")
    print(f"Codex home: {codex}\nSkills home: {skills}")
    for category, path, action in findings:
        print(f"- {category}: {action}: {path}")
    if not findings:
        print("No v3/v4 residue detected.")
    if args.audit_only:
        print("Audit-only mode: no files changed.")
        return 0

    backup = codex / "backups" / f"framework-v5-{datetime.now():%Y%m%d-%H%M%S-%f}"
    backup.mkdir(parents=True)
    skills.mkdir(parents=True, exist_ok=True)
    for directory in (codex / "agents", codex / "agent-configs", codex / "hooks"):
        directory.mkdir(parents=True, exist_ok=True)
    for source, relative in ((codex / "AGENTS.md", "codex/AGENTS.md"), (codex / "config.toml", "codex/config.toml"), (hooks_file, "codex/hooks.json")):
        if source.exists():
            destination = backup / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)

    for file in list((codex / "agents").glob("*.toml")):
        if role_of(file) in ROLES or file.stem in ROLES:
            move_to_backup(file, backup / "codex" / "standalone-agents" / file.name)
    for role in ROLES:
        target = codex / "agent-configs" / f"{role}.toml"
        if target.exists():
            destination = backup / "codex" / "agent-configs" / target.name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, destination)
        shutil.copy2(PACKAGE / ".codex" / "agent-configs" / target.name, target)

    config_file = codex / "config.toml"
    config = config_file.read_text(encoding="utf-8-sig") if config_file.exists() else ""
    config = re.sub(r"# BEGIN CODEX GLOBAL FRAMEWORK V[345] AGENTS.*?# END CODEX GLOBAL FRAMEWORK V[345] AGENTS\s*", "", config, flags=re.S)
    for role in ROLES:
        config = re.sub(rf"^\s*\[agents\.{re.escape(role)}\]\s*\n.*?(?=^\s*\[|\Z)", "", config, flags=re.M | re.S)
    lines = ["# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS"]
    for role, description in ROLES.items():
        lines += ["", f"[agents.{role}]", f'description = "{description}"', f'config_file = "agent-configs/{role}.toml"']
    lines += ["", "# END CODEX GLOBAL FRAMEWORK V5 AGENTS"]
    config_file.write_text(config.rstrip() + ("\n\n" if config.rstrip() else "") + "\n".join(lines) + "\n", encoding="utf-8")

    for root, label in ((codex / "skills", "legacy-codex-skills"), (skills, "user-skills")):
        for name in LEGACY_SKILLS:
            target = root / name
            if target.exists():
                move_to_backup(target, backup / label / name)
        if root.exists() and not any(root.iterdir()):
            root.rmdir()
    skills.mkdir(parents=True, exist_ok=True)
    for name in CURRENT_SKILLS:
        shutil.copytree(PACKAGE / ".agents" / "skills" / name, skills / name)

    agents_file = codex / "AGENTS.md"
    existing = agents_file.read_text(encoding="utf-8-sig") if agents_file.exists() else ""
    personal = re.sub(r"<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN.*?<!-- CODEX-GLOBAL-FRAMEWORK:END.*?-->\s*", "", existing, flags=re.S).strip()
    block = (PACKAGE / ".codex" / "AGENTS.md").read_text(encoding="utf-8").strip()
    agents_file.write_text((personal + "\n\n" if personal else "") + block + "\n", encoding="utf-8")

    if not args.no_hook:
        hook_dir = codex / "hooks"
        shutil.copy2(PACKAGE / ".codex" / "hooks" / "mandatory-router.sh", hook_dir / "mandatory-router.sh")
        shutil.copy2(PACKAGE / ".codex" / "hooks" / "mandatory-router.ps1", hook_dir / "mandatory-router.ps1")
        (hook_dir / "mandatory-router.sh").chmod(0o755)
        data = json.loads(hooks_file.read_text(encoding="utf-8-sig")) if hooks_file.exists() else {"description": "User hooks.", "hooks": {}}
        groups = data.setdefault("hooks", {}).setdefault("UserPromptSubmit", [])
        groups[:] = [g for g in groups if "mandatory-router" not in json.dumps(g)]
        groups.append({"hooks": [{"type": "command", "command": 'sh "${CODEX_HOME:-$HOME/.codex}/hooks/mandatory-router.sh"', "commandWindows": 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\\.codex\\hooks\\mandatory-router.ps1"', "timeout": 5, "statusMessage": "Applying global routing policy"}]})
        hooks_file.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"\nCodex Global Framework v5 installed.\nBackup: {backup}")
    if (codex / "AGENTS.override.md").exists() and (codex / "AGENTS.override.md").stat().st_size:
        print("WARNING: AGENTS.override.md shadows the global AGENTS.md.")
    print(f"Run: {PACKAGE / 'scripts' / 'diagnose.sh'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
