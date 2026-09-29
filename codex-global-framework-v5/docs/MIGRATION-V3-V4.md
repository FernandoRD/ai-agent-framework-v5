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
7. moves auxiliary v3 Skills out of `.agents/skills` only when their content is provably from the framework (otherwise they are left intact with a note), and reuses the four v5 Skills when identical to the package;
8. replaces only the framework `mandatory-router` hook group.

Unknown agents, Skills, hook groups, config keys, and personal AGENTS text are left in place.
If a v5-named Skill differs from the package, or `hooks.json` is invalid, the
installer (and `--audit-only`) stops before changing anything so you can merge manually.

## Resolving a stop caused by a divergent Skill

The message `Skill conflict (content differs from v5; merge manually): <path>`
means a Skill named like a v5 Skill (`security-review`, `code-review`,
`dependency-review`, `documentation`) exists with different content. Nothing was
changed. To continue:

1. compare the folder with the package copy under `.agents/skills/<name>`;
2. keep your changes by moving or renaming the folder (for example
   `mv <path> <path>.mine`), or delete it if it is disposable;
3. rerun the installer; it installs the v5 Skill, and you can merge your notes
   back from the renamed folder.

A divergent copy under `<codex-home>/skills` (not the Skills home) is not a
conflict: it is left in place with a NOTE and `diagnose` reports a WARN.

## Unmarked legacy AGENTS content

If the installer detects `task-router` in an AGENTS file without framework
markers, it reports the condition but preserves the text. Automatic deletion
would risk removing personal instructions. Review that one section manually.

## Rollback

The installer prints the backup directory. It contains the complete pre-change
`AGENTS.md`, `config.toml`, `hooks.json`, matching agent files, and moved Skills.
The uninstaller also creates its own backup before removing v5.
