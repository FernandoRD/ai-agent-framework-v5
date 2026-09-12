# Migration from v3 or v4

Run audit mode first to list every recognized action without changing files:

```powershell
.\scripts\install.ps1 -AuditOnly
```

The real installation creates a timestamped backup and then:

1. replaces marked framework content in global `AGENTS.md`;
2. identifies framework agent TOMLs by internal `name`, not filename;
3. moves matching standalone agents out of `.codex/agents`;
4. installs clean layers in `.codex/agent-configs`;
5. removes old exact role registrations and creates one marked v5 block;
6. moves known framework Skills out of legacy `.codex/skills`;
7. removes auxiliary v3 Skills from `.agents/skills` and replaces the four retained Skills;
8. replaces only the framework `mandatory-router` hook group.

Unknown agents, Skills, hook groups, config keys, and personal AGENTS text are left in place.

## Unmarked legacy AGENTS content

If the installer detects `task-router` in an AGENTS file without framework
markers, it reports the condition but preserves the text. Automatic deletion
would risk removing personal instructions. Review that one section manually.

## Rollback

The installer prints the backup directory. It contains the complete pre-change
`AGENTS.md`, `config.toml`, `hooks.json`, matching agent files, and moved Skills.
The uninstaller also creates its own backup before removing v5.
