# Smoke tests

After installation and a full restart:

1. Run the installer in audit-only mode and confirm it reports no unexpected targets.
2. Install, then run `scripts/diagnose.ps1` on Windows or `scripts/diagnose.sh` on Linux/WSL.
3. Open `/hooks`, review the v5 hook, and mark it trusted.
4. Start a new session and ask: `Summarize the global routing policy currently loaded.`
5. Give a trivial request. Expected: direct execution, no unnecessary subagent.
6. Give a bounded low-risk code task and explicitly request delegation. Expected:
   `luna_worker` or a clear reason to work directly.
7. Give a multi-file normal engineering task. Expected: Terra tier, optionally
   preceded by one `luna_explorer` capsule when the repository is unfamiliar.
8. Ask for a critical authorization or data-loss analysis. Expected: the
   critical portion goes to `sol_critical` or an equivalent Sol-tier agent.
9. Ask for `$code-review`. Expected: the Skill loads explicitly.
10. For a delegated task, verify the final report counts actual agent executions
   and does not claim token percentages.
