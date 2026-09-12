# Windows

Run PowerShell in the extracted package directory:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install.ps1 -AuditOnly
.\scripts\install.ps1
.\scripts\diagnose.ps1
```

Default destinations are `%USERPROFILE%\.codex` and
`%USERPROFILE%\.agents\skills`. Override them only when Codex is configured to
use a different home:

```powershell
.\scripts\install.ps1 -CodexHome D:\CodexHome
```

Close every Codex window/process and reopen it. Then use `/hooks` to review the
new `UserPromptSubmit` command and mark it trusted. Until trusted, the hook is
ignored; `AGENTS.md` routing still works.

V5 moves matching v3/v4 TOMLs out of `.codex\agents`, stores clean configuration
layers in `.codex\agent-configs`, and registers each role exactly once in a
marked `config.toml` block. This is the Windows duplicate-role correction.

If diagnostics report that `AGENTS.override.md` shadows `AGENTS.md`, rename or
remove the override after reviewing its contents. Codex intentionally reads the
override instead of the normal global file.
