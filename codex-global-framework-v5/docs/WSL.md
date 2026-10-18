# WSL

Windows Codex and Codex running inside WSL have different homes by default.
Install inside the environment where Codex actually runs.

From WSL:

```bash
./scripts/install.sh
./scripts/diagnose.sh
```

From Windows PowerShell:

```powershell
.\scripts\install-wsl.ps1 -Distro Ubuntu
```

To share the Windows `.codex` directory while retaining WSL user Skills under
`/home/<user>/.agents/skills`:

```powershell
.\scripts\install-wsl.ps1 -Distro Ubuntu -ShareWindowsCodexHome
```

When sharing, keep `CODEX_HOME` exported consistently in the WSL shell that
launches Codex. Rerun diagnostics from that same shell.

## Hook when the home is shared

`hooks.json` carries two commands: `command` (POSIX `sh`, used by Linux/WSL) and
`commandWindows` (PowerShell, used by native Windows).

- `install.ps1` writes `commandWindows` with the Windows path and translates a
  drive path (`C:\...`) to `/mnt/c/...` for `command`. This assumes the default
  WSL automount root (`/mnt`); a customized `automount.root` is not handled.
- `install.sh` run inside WSL with `CODEX_HOME` under `/mnt/<x>/...` writes the
  matching `commandWindows`; for any other `CODEX_HOME` it omits `commandWindows`.
  Rerun `install.ps1` afterwards if native Windows Codex also uses that home.
- Installing from both sides rewrites only the framework `mandatory-router`
  group, so the last installer to run decides the content of the two commands.

Limitations:

- The hook stores the absolute path of the Codex home. A home that is moved, or
  dotfiles shared between different users/machines, requires reinstalling.
- The `/mnt/<x>` translation (both directions) assumes the default automount
  root; `install-wsl.ps1` relies on `wslpath` returning a `/mnt/<x>/...` path
  for the Windows home and does not handle other roots.
- The whole `UserPromptSubmit` group containing `mandatory-router` is replaced or
  removed, including any user hook placed in that same group. Keep your own
  hooks in separate groups (known pre-existing behavior, not changed here).

None of this was verified against a real Windows + WSL pair in this repository's
tests (only PowerShell on Linux and Bash are exercised); check `/hooks` in both
environments after installing.

V5 uses explicit agent registration in WSL as well, so Windows, Linux, and WSL
share the same role-loading architecture.
