# Codex Global Framework v5

Global budget-aware routing for Codex on Windows, Linux, and WSL, with automatic
discovery and cleanup of v3/v4 residue.

V5 keeps mandatory routing in `~/.codex/AGENTS.md`. It registers the seven agent
roles explicitly in `config.toml`, pointing to non-autodiscovered layers under
`~/.codex/agent-configs`. This avoids the duplicate role discovery observed with
standalone files under `~/.codex/agents` on Codex for Windows.

The policy assigns each bounded unit to the smallest capable named agent. A
larger parent delegates lower-tier units unless a documented concrete exception
applies. It requires targeted `luna_explorer` discovery for large or unfamiliar
repositories, a delegated unit for uncertain or coordinated multi-file work,
and independent review before applicable multi-component, compatibility,
public-contract, or high-risk changes are completed.

Routine, authorized publication of validated changes is a separate Luna unit: delegate scoped staging, commit, push, and remote-hash verification to `luna_worker`, even after a higher-tier implementation. Reuse completed validation and escalate only an affected step when its risk requires it. Credentials and sandbox restrictions require access handling, not a stronger model. Publication authority and safety checks remain unchanged.

## What the installer discovers and cleans

- marked v1-v4 framework blocks in global `AGENTS.md`;
- legacy `task-router` and auxiliary Skills under both `.codex/skills` and
  `.agents/skills`, moved only when their `SKILL.md` proves they belong to the
  framework (it references the Luna/Terra/Sol roles, the framework markers or
  `task-router`);
- v3/v4 agent files by internal `name`, including hyphen/underscore filename
  variants;
- duplicate or old `[agents.<role>]` registrations;
- previous `mandatory-router` hook definitions;
- copies of the four v5 Skills under `<codex-home>/skills` (the legacy root):
  moved to the backup only when identical to the package or proven to belong
  to the framework. A divergent copy is kept and reported; a divergent copy of
  a v5 Skill in the Skills home aborts the installation for manual merging.
  A Skills home that is the same directory as `<codex-home>/skills` (also
  through symlinks) is treated as the live root and never moved.

Affected items in the global installation are backed up under
`$CODEX_HOME/backups/framework-v5-<timestamp>`. Exceptions: in project mode
(`--target`) `AGENTS.md` is edited in place without a backup, and the
`hooks/mandatory-router.*` scripts are overwritten without a backup copy.
Unrelated configuration,
personal AGENTS text, unrelated agents, Skills, and hooks are preserved.

The v5 Skills (`security-review`, `code-review`, `dependency-review`,
`documentation`) are handled by content: an identical installed copy is reused
untouched, an absent one is installed, and a copy with different content is a
conflict. Generic legacy names (`testing`, `refactor`, `implementation`, ...)
whose content is not provably from the framework are left intact and reported
as a note. Optional specialist files and the hooks.json, `AGENTS.md` and
`config.toml` markers are checked the same way.

The installer validates everything before applying: the complete plan is computed first and any conflict
(divergent Skill, differing optional file, invalid `hooks.json`, unbalanced
framework markers, missing `python3`/`jq` to merge an existing `hooks.json`)
aborts before any file is changed. There is no rollback if the application
itself fails midway (for example a full disk); restore from the backup
directory in that case. `--audit-only` reports the same conflicts and exits
non-zero without writing to disk.

## Known limitations

- The hook stores the absolute `CODEX_HOME` path. If the home is moved or a
  dotfiles setup is shared across users, reinstall to regenerate `hooks.json`.
- Removing the routing hook drops the whole `UserPromptSubmit` group that
  contains `mandatory-router`; a user hook placed in that same group is removed
  with it (install and uninstall). Keep your own hooks in separate groups.
- WSL specifics (`/mnt/<x>` translation, `wslpath`) are listed in `docs/WSL.md`.

## Install

### Optional Specialists

The 11 optional specialists (`zabbix-specialist`, `grafana-specialist`, `ansible-specialist`,
`loki-specialist`, `prometheus-specialist`, `netops-specialist`, `sre-incident-specialist`,
`database-tuning-specialist`, `proxmox-specialist`, `shell-python-specialist`,
and `docker-kubernetes-specialist`) are not installed by default and do not change the seven
framework roles or Luna/Terra/Sol routing. Add `--with-<spec>-specialist` or `--with-all-specialists`
to install domain skills. For a project target it also installs optional knowledge
and evaluations; global installation adds only the skills under `~/.agents/skills/`.

```bash
./scripts/install.sh --with-ansible-specialist
./scripts/install.sh --with-all-specialists
./scripts/install.sh --target /path/to/project --with-all-specialists
```

PowerShell accepts `-WithZabbixSpecialist`, `-WithGrafanaSpecialist`,
`-WithAnsibleSpecialist`, `-WithLokiSpecialist`, `-WithPrometheusSpecialist`,
`-WithNetopsSpecialist`, `-WithSreSpecialist` (alias `-WithSreIncidentSpecialist`),
`-WithDbTuningSpecialist` (alias `-WithDatabaseTuningSpecialist`),
`-WithProxmoxSpecialist`, `-WithShellPythonSpecialist`,
`-WithDockerKubernetesSpecialist` and `-WithAllSpecialists`. The options
remain subject to the installer's normal audit, backup, and conflict behavior.

Windows PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
# Global install (applies by default; -AuditOnly only audits, -Apply is an accepted no-op):
.\scripts\install.ps1 -AuditOnly
.\scripts\install.ps1
# Custom locations (relative paths and ~ are resolved):
.\scripts\install.ps1 -CodexHome C:\path\to\.codex -SkillsHome C:\path\to\skills

# Project install:
.\scripts\install.ps1 -Target C:\path\to\project

.\scripts\diagnose.ps1
```

Linux:

```bash
# Global install (applies by default; --audit-only only audits, --apply is an accepted no-op):
./scripts/install.sh --audit-only
./scripts/install.sh
# Custom locations:
./scripts/install.sh --codex-home /path/to/.codex --skills-home /path/to/skills

# Project install:
./scripts/install.sh --target /path/to/project

./scripts/diagnose.sh
```

The ZIP contains a top-level `codex-global-framework-v5/` directory, keeping
package files separate from installed configuration even when extracted into
your home directory. Enter that directory before running the commands above:

```bash
unzip codex-global-framework-v5.zip
cd codex-global-framework-v5
```

Installers are pure Bash/PowerShell (no Python required at install time;
`python3` or `jq` is needed only to merge an existing `hooks.json`). Keep
existing configuration and backups in place when re-extracting the package.

Uninstall (backs up first; validates `hooks.json` and the framework markers in
`AGENTS.md`/`config.toml` before creating the backup or changing anything, so
unbalanced markers abort; needs `python3` or `jq` when a `hooks.json` exists;
accepts `--codex-home`/`--skills-home` or `-CodexHome`/`-SkillsHome`):

```bash
./scripts/uninstall.sh --codex-home /path/to/.codex --skills-home /path/to/skills
```

```powershell
.\scripts\uninstall.ps1 -CodexHome C:\path\to\.codex -SkillsHome C:\path\to\skills
```

Validate the package (Python 3.11+; also exercises the installers in temporary
directories and, when `pwsh` exists, the PowerShell scripts):

```bash
python3 scripts/validate.py
```

Fish:

```fish
./scripts/install.fish --audit-only
./scripts/install.fish
./scripts/diagnose.fish
```

WSL from PowerShell:

```powershell
.\scripts\install-wsl.ps1 -Distro Ubuntu
```

Restart Codex. Open `/hooks` and confirm `UserPromptSubmit` is Active. The hook
is optional; use `-NoHook` or `--no-hook` to omit it.

## Installed layout

```text
~/.codex/
├── AGENTS.md
├── config.toml                  # one marked registration block
├── agent-configs/               # not auto-discovered
│   ├── luna_explorer.toml
│   ├── luna_worker.toml
│   ├── terra_worker.toml
│   ├── terra_reviewer.toml
│   ├── sol_specialist.toml
│   ├── sol_reviewer.toml
│   └── sol_critical.toml
├── hooks.json
└── hooks/

~/.agents/skills/
├── security-review/
├── code-review/
├── dependency-review/
└── documentation/
```

The installed hook command uses the absolute installed path, so a custom
`--codex-home` needs no `CODEX_HOME` in the Codex session. `command` is a POSIX
`sh` command; `commandWindows` (PowerShell) is written by `install.ps1` always,
and by `install.sh` only when `CODEX_HOME` is a WSL drive path (`/mnt/<x>/...`).
When `install.ps1` runs on a Windows drive path it writes `command` as the
equivalent `/mnt/<x>/...` path so a WSL shell sharing that home can run it; this
assumes the default WSL mount root and was not verified on a real Windows/WSL
setup (see `docs/WSL.md`). The installer modifies `config.toml` only inside exact framework role tables
and the marked v5 registration block. It creates a full pre-change backup.
