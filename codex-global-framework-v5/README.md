# Codex Global Framework v5

Global budget-aware routing for Codex on Windows, Linux, and WSL, with automatic
discovery and cleanup of v3/v4 residue.

V5 keeps mandatory routing in `~/.codex/AGENTS.md`. It registers the seven agent
roles explicitly in `config.toml`, pointing to non-autodiscovered layers under
`~/.codex/agent-configs`. This avoids the duplicate role discovery observed with
standalone files under `~/.codex/agents` on Codex for Windows.

## What the installer discovers and cleans

- marked v1-v4 framework blocks in global `AGENTS.md`;
- legacy `task-router` and auxiliary Skills under both `.codex/skills` and
  `.agents/skills`;
- v3/v4 agent files by internal `name`, including hyphen/underscore filename
  variants;
- duplicate or old `[agents.<role>]` registrations;
- previous `mandatory-router` hook definitions;
- stale copies of the four specialist Skills.

Every affected item is backed up under
`$CODEX_HOME/backups/framework-v5-<timestamp>`. Unrelated configuration,
personal AGENTS text, unrelated agents, Skills, and hooks are preserved.

## Install

Windows PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install.ps1 -AuditOnly
.\scripts\install.ps1
.\scripts\diagnose.ps1
```

Linux:

```bash
./scripts/install.sh --audit-only
./scripts/install.sh
./scripts/diagnose.sh
```

Fish:

```fish
./scripts/install.fish --audit-only
./scripts/install.fish
./scripts/diagnose.sh
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

The installer modifies `config.toml` only inside exact framework role tables
and the marked v5 registration block. It creates a full pre-change backup.
