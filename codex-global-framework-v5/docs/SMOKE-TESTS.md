# Smoke tests

After installation and a full restart:

1. Run the installer in audit-only mode and confirm it reports no unexpected targets.
2. Install, then run `scripts/diagnose.ps1` on Windows or `scripts/diagnose.sh` on Linux/WSL.
3. Open `/hooks`, review the v5 hook, and mark it trusted.
4. Start a new session and ask: `Summarize the global routing policy currently loaded.`
5. Give a trivial request. Expected: direct execution, no unnecessary subagent.
6. Give a bounded low-risk code task to a parent above Luna tier. Expected:
   explicit delegation to `luna_worker`, unless it reports a concrete exception
   such as a tiny fully specified operation where handoff exceeds the work, or
   a higher-priority restriction on delegation with no useful parent work that
   can proceed in parallel.
7. Give a multi-file normal engineering task. Expected: Terra tier and at least
   one delegated analysis, implementation, or validation unit; when the
   repository is unfamiliar, first obtain one `luna_explorer` capsule. Before
   completion, expect an independent Terra-or-higher review when the task is
   multi-component, compatibility-sensitive, public-contract, or high-risk.
8. Ask for a critical authorization or data-loss analysis. Expected: the
   critical portion goes to `sol_critical` or an equivalent Sol-tier agent.
9. Ask for `$code-review`. Expected: the Skill loads explicitly.
10. For a delegated task, verify the final report counts actual agent executions,
    does not claim token percentages, and records completed or blocked required
    delegation and review checkpoints.
11. Ask a larger implementation agent to perform a routine, explicitly authorized
    publication with known destinations and validated changes. Expected: the
    complete bounded publication workflow delegates to `luna_worker`, including
    scoped status/diff review, explicit staging, commit, push, and remote-hash
    verification.
12. Provide the publication handoff with compact repository, branch, allowed
    files, destinations, authorization, completed checks, and limitations.
    Expected: valid compact evidence is reused and checks are rerun only for new
    changes, failures, or unresolved concerns.
13. Introduce a publication conflict or uncertain release/deployment condition.
    Expected: only the affected publication unit escalates to Terra or Sol; other
    bounded work stays at its original tier.
14. Remove credentials, network access, or sandbox permission needed for
    publication. Expected: the agent requests normal access and does not escalate
    the model or weaken permissions to compensate.
15. Verify publication to two authorized remotes. Expected: each remote hash is
    checked independently, with partial publication reported if one fails.
