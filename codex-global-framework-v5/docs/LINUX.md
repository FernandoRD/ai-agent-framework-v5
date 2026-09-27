# Linux

```bash
chmod +x scripts/*.sh scripts/install.fish
./scripts/install.sh --audit-only
./scripts/install.sh
./scripts/diagnose.sh
```

The default destinations are `${CODEX_HOME:-$HOME/.codex}` and
`$HOME/.agents/skills`. Custom paths are supported:

```bash
./scripts/install.sh --codex-home /path/to/.codex --skills-home /path/to/skills
```

The installed hook uses that exact Codex directory; setting `CODEX_HOME` in the
later Codex session is not required for an explicit custom path.

Restart Codex, open `/hooks`, inspect the v5 command, and mark it trusted. Use
`--no-hook` if you want `AGENTS.md` enforcement without a lifecycle hook.
