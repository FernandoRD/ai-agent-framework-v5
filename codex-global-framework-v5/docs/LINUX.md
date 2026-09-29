# Linux

```bash
chmod +x scripts/*.sh scripts/install.fish
./scripts/install.sh --audit-only
./scripts/install.sh
./scripts/diagnose.sh
```

The installer applies by default (with backup); `--audit-only` audits without
writing, and `--apply` is accepted as a no-op. Any conflict aborts before changes.

The default destinations are `${CODEX_HOME:-$HOME/.codex}` and
`$HOME/.agents/skills`. Custom paths are supported:

```bash
./scripts/install.sh --codex-home /path/to/.codex --skills-home /path/to/skills
```

The installed hook command stores the absolute path of that Codex directory;
setting `CODEX_HOME` in the later Codex session is not required. The same
options work for `diagnose.sh` and `uninstall.sh`. Merging an existing
`hooks.json` needs `python3` or `jq` (also for `uninstall.sh`); an invalid `hooks.json` aborts the install.

Restart Codex, open `/hooks`, inspect the v5 command, and mark it trusted. Use
`--no-hook` if you want `AGENTS.md` enforcement without a lifecycle hook.
