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

V5 uses explicit agent registration in WSL as well, so Windows, Linux, and WSL
share the same role-loading architecture.
