<!-- GEMINI-CLI-GLOBAL-FRAMEWORK:BEGIN v5 -->
# Global Gemini CLI Framework v5

These rules apply to every project. Project-level `GEMINI.md` files may add
project facts, constraints, and commands, but must not silently weaken safety,
authorization, routing, or validation requirements.

## Mandatory classification

Classify every engineering request before choosing an execution strategy. Do
this directly from this file; routing must not depend on implicit agent
selection or Skill invocation.

### Trivial work

A task is trivial only when every condition below is true:

- it has one narrow, clearly stated objective;
- it affects up to 3 files of the same component (more than that, or different
  components, is not trivial);
- the cause, required change, and expected result are already known;
- there is no meaningful design decision or uncertain investigation;
- it does not change externally consumed behavior or a shared contract;
- it does not involve any mandatory non-trivial trigger listed below;
- failure would have only local, low-impact consequences;
- it is immediately reversible (e.g., git revert/checkout, without losing user changes); and
- one focused, deterministic check can validate it.

A component is the same service or package within the same project (e.g., a
script and its test or README).

Typical trivial work includes correcting spelling or formatting, updating a
comment, renaming a purely local symbol, or applying an obvious isolated fix
whose cause and result are already established.

More than 3 files, or more than one component, is not trivial work. A one-line
change to authorization, SQL, networking, deployment, or a public interface is
non-trivial. Writes to live systems (e.g., creating or deleting hosts in
Zabbix), production messaging or persistence, credentials and secrets, and
deploy/systemd are always non-trivial, whatever the size.

If any trivial-work condition is false, unknown, or uncertain, classify the
task as non-trivial. Uncertainty increases classification; it never justifies
treating work as trivial.

The main agent may handle trivial work directly, without a subagent and
without declaring a blocker, only when every condition above is true. Do not
calculate a numeric score or produce a routing report unless the user asks for
one. Delegation remains required for all non-trivial work, except pinpoint
reading and the tier-equivalent clause below, which never applies to publication, writes to live systems, production messaging/persistence, credentials/secrets or deploy/systemd (see "Boundaries and exceptions").

### Mandatory non-trivial triggers

Always classify work as non-trivial when it involves at least one of these:

- an unknown or uncertain root cause;
- more than one component, service, subsystem, or repository;
- coordinated changes across more than 3 files or across different components (changes to 2-3 files linked by a dependency between them, e.g., a contract and its consumer, are coordinated and non-trivial; independent or mechanical changes are not; the dependency between the files prevails over being mechanical);
- architecture, data flow, shared state, or cross-component behavior;
- a public API, file format, protocol, schema, or externally consumed contract;
- authentication, authorization, secrets, privacy, or another security boundary;
- persistent data, database writes, migrations, or schema changes;
- concurrency, asynchronous execution, locking, races, or distributed behavior;
- infrastructure, networking, deployment, containers, CI/CD, or production configuration;
- writes to a live system, messaging, or production persistence;
- credentials and secrets, and deploy/systemd;
- dependency addition, removal, upgrade, advisory, or supply-chain risk;
- backward compatibility or a supported runtime/platform matrix;
- destructive, difficult-to-reverse, or operationally disruptive actions;
- performance changes whose effect is not obvious and tightly bounded;
- missing, unreliable, broad, or difficult validation; or
- credible risk of regression, privilege escalation, data loss, downtime, or
  meaningful production impact.

## Routing non-trivial work

For non-trivial work, estimate a 0-100 complexity/risk score. Rate each factor
from 0 (none) to 4 (very high), multiply that rating by the factor's maximum
weight, divide by 4, and sum the results:

| Factor | Max |
| --- | ---: |
| Scope and change size | 10 |
| Components affected | 8 |
| Uncertainty and investigation | 10 |
| Architectural impact | 10 |
| Security and authorization | 12 |
| Data, state, or persistence | 10 |
| Concurrency or distributed behavior | 8 |
| Operational or production impact | 10 |
| Irreversibility | 6 |
| Testing difficulty | 6 |
| Compatibility or dependency risk | 5 |
| External integration complexity | 5 |

Route each bounded unit of work independently. In Gemini CLI and Google Antigravity,
work is routed across capability tiers:

- 0-34: Flash tier (`flash-explorer`, `flash-worker`; `gemini-2.5-flash`) for discovery, mechanical tasks, narrow low-risk changes, and routine publication.
- 35-69: Pro tier (`pro-worker`, `pro-reviewer`; `gemini-2.5-pro`) for normal implementation, debugging, multi-file changes, and independent review.
- 70-100: Pro tier for high-risk work (`pro-specialist`, `pro-risk-reviewer`, `pro-critical`; `gemini-2.5-pro`). The package pins the same Pro model for the last two bands; the band selects the agent role, not a different model.

### Other providers (not verified)

This package pins only Gemini models (`gemini-2.5-pro`, `gemini-2.5-flash`). Using other providers in Antigravity, `inherit` model inheritance, and programmatic cross-model delegation are unverified and not supported by the Gemini CLI documentation consulted; do not rely on them.
- **Mandatory Flash delegation**: When the active parent session is Flash (`gemini-2.5-flash`), the parent **MUST NOT** retain tasks that reach the Pro risk floor (such as multi-component implementation, schema changes, security boundaries, or critical refactors). It MUST delegate implementation to `pro-worker` (Model: Pro) and verification to `pro-reviewer` (Model: Pro).

Do not expose the full score calculation unless it helps the user understand a
decision or the user requests it.

### Risk floors

Risk floors override the numeric score:

- At least Pro (or active Claude Sonnet / GPT equivalent): authentication behavior, public APIs, persistent-data changes,
  migrations or schemas, production infrastructure, structural refactors,
  compatibility-sensitive changes, or multi-component implementation.
- Pro with a read-only critical analysis before mutation: critical
  vulnerabilities, cryptography, authorization boundaries, credible data loss
  or corruption, difficult races or deadlocks, high-impact production failures,
  or ambiguous cross-system behavior with a large blast radius.

A risk floor applies to the affected portion, not automatically to the entire
request. Keep mechanical and well-bounded follow-up work in the lowest safe tier.

Missing access, credentials, approval, tools, dependencies, or a usable
environment is a blocker, not a reason to escalate models. Resolve or report
the blocker instead.

## Execution strategy

### Primary principle: the smallest capable agent for each unit

First analyze what needs to be done, then assign each bounded unit to the
smallest available agent that can safely complete and validate it. This is the
primary execution objective; increasing the number of agents is not a goal.
Use the routing score and risk floors above to choose Flash or Pro for each
unit independently, including discovery, implementation, and review.

- Before substantial execution, identify the deliverables, dependencies,
  acceptance criteria, and minimum safe tier of each unit. Do only the initial
  reconnaissance needed to route the work; do not complete the investigation
  in the parent before delegating it, except pinpoint reading (see Boundaries
  and exceptions).
- Explicitly delegate lower-tier units to the matching named agent role when
  the parent is a larger model, subject to the boundaries below. The parent's
  ability to do non-trivial work is not a reason to retain it. Reducing unnecessary
  higher-tier execution is itself a concrete delegation benefit.
- Keep the parent focused on decomposition, coordination, integration, and
  acceptance of results. Retain execution only where its capability or
  exclusive access is required, or a concrete exception below applies, and never for publication, writes to live systems, production messaging/persistence, credentials/secrets or deploy/systemd. Do not
  repeat an agent's full investigation or implementation as routine validation.
- Select the smallest sufficient tier immediately. Do not try Flash first when
  the score or a risk floor already requires Pro. Escalate only the affected
  unit when evidence shows the assigned capability is insufficient; keep
  remaining lower-tier work at its original tier.
- Choose an explicit named role so a subagent does not accidentally inherit
  the parent's larger model. Reuse agents when their tier and scope still fit.
- Model capability and independence are separate requirements: use the
  smallest reviewer meeting the review's risk floor, and preserve independent
  review even when the parent is capable of implementing the change.

### Publication uses the smallest capable agent

Commit, push, repository synchronization, and release preparation are separate
units. Route them independently from the implementation they publish; do not
inherit its capability tier because publication is in the same conversation.

- For routine, explicitly authorized publication with known destinations and
  validated changes, delegate the complete bounded workflow to `flash-worker`:
  inspect status and scoped diff, preserve unrelated work, stage explicit
  paths, create the requested commit, push the authorized branch to authorized
  remotes, and verify each remote hash. Reuse an available Flash worker.
- Send compact evidence: repository, branch, allowed files, destinations,
  authorization, completed checks, and known limits. Reuse valid evidence;
  rerun checks only for new changes, failures, or unresolved concerns.
- The main agent coordinates and accepts the result. It must not retain a
  whole routine publication workflow; publication is never handled directly as
  trivial work or pinpoint reading. If delegation is unavailable or prohibited, state the concrete blocker and use
  only the necessary authorized fallback without claiming Flash execution.
- Escalate only the affected unit when conflicts, uncertain scope,
  compatibility, release semantics, deployment, or material risk requires Pro.
  Routine Git commit/push is not itself a migration or production
  infrastructure change; deployment has a separate risk assessment.
- Missing credentials, network access, or sandbox approval requires normal
  access handling, not a stronger model or weakened approval.
- Preserve publication authority and safety: check destinations and privacy,
  stage explicit paths, never imply force-push or history rewrite, and verify
  every remote. This policy grants no new authority to publish, deploy, create
  releases, or change repository visibility.

### Required delegation checkpoints

This policy explicitly requests subagent work for the cases below, subject to
higher-priority instructions and available tools. Evaluate the whole active
task, including earlier turns; do not split a substantial task into apparently
trivial turns to avoid these checkpoints.

- For a large or unfamiliar repository, delegate one targeted read-only
  discovery task to `flash-explorer` before broad local exploration. Its
  capsule must contain relevant files and symbols, execution path, constraints,
  likely tests, and unresolved questions. Reuse it instead of repeating the
  scan.
- For an uncertain root cause, multiple components, coordinated changes across more than 3 files or across different components (changes to 2-3 files linked by a dependency between them, e.g., a contract and its consumer, are coordinated and non-trivial; independent or mechanical changes are not; the dependency between the files prevails over being mechanical), or compatibility-sensitive work, delegate at least one concrete
  analysis, implementation, or validation unit. Keep useful complementary work
  with the parent.
- Before completing multi-component, compatibility-sensitive, public-contract,
  or high-risk changes, obtain an independent read-only review from a reviewer
  at the required tier. A discovery or implementation agent does not count as
  an independent reviewer of its own work. Address findings and run relevant
  checks before reporting completion. Schedule this review as a concurrent unit
  while parent validation or complementary integration work proceeds. If no other
  active work remains, dispatching an independent reviewer to verify before completion
  is still required to guarantee objective review.
- Re-evaluate these checkpoints when scope grows, a new component is involved,
  a regression appears, or the investigation changes direction. Reuse existing
  agents for related work instead of repeatedly spawning new ones.

### Active parallelization & batch dispatch (Fan-Out/Fan-In)

- **Prioritize parallel dispatching**: Whenever a non-trivial request can be decomposed into independent subtasks with disjoint read or write boundaries, **actively dispatch 2–4 concurrent subagents in the same turn, when the platform supports concurrent subagent calls,** instead of executing them sequentially.
- **Concurrent exploration & audit**: For large or multi-component discovery, launch parallel explorers targeting distinct domains (e.g. core architecture, test infrastructure, documentation/contracts) concurrently.
- **Partitioned write scopes**: When changes affect distinct modules, services, or platform packages with non-overlapping directory trees, assign each partition to a dedicated concurrent worker.
- **Pipelined review & test execution**: As soon as a deliverable is ready, launch an independent read-only reviewer in parallel with ongoing work (such as test execution, parent integration, or next-phase implementation). Do not serialize review after all work is done if it can proceed alongside parent verification.
- **Shared resource protection**: Keep shared interactive sessions, single-file mutations, or exclusive live resources under a single owner's control to prevent race conditions.

### Boundaries and exceptions

- Trivial work, as defined above (every condition true: up to 3 files of the
  same component, never a live-system write, production messaging or
  persistence, credentials and secrets, or deploy/systemd), may be handled
  directly by the main agent and needs no declared blocker. Do not create
  agents just to meet a quota.
- Pinpoint reading: the main agent may read directly, without editing anything and
  without declaring an exception, to answer a question or prepare a delegation
  brief: at most 3 files and 2 searches per question, and at most 2 consecutive
  questions without delegating. Use only native read, list, and search tools (no shell, no queries to live systems); Glob and Grep (or equivalents) count as searches. Searches must use path-listing or count mode only (files_with_matches/count), never content mode. Never read .env files, keys, tokens, credentials, or files that may contain secrets (e.g., .conf/.ini files with passwords, systemd unit files with Environment=, ~/.aws, ~/.ssh, docker-compose with variables, settings, Ansible vault). If a result exposes a secret, stop and report only the
  path and type, never values. Do not generalize pinpoint reading into an
  investigation: investigation goes to the explorer. Anything beyond this goes
  to the explorer/worker.
- For bounded non-trivial work without the mandatory checkpoints, direct
  execution is allowed if the parent already matches the smallest sufficient
  tier and delegation adds no independent benefit. This clause never applies to
  publication, writes to live systems, production messaging or persistence,
  credentials and secrets, deploy/systemd, or the mandatory non-trivial
  triggers. A larger parent must route lower-tier work to the matching agent
  unless a concrete exception applies.
- Do not generalize the trivial-work or pinpoint-reading exceptions to an
  investigation, a task beyond 3 files of one component, or routine publication.
- If the active model is below the required tier, delegate that unit to an
  agent at or above the required tier. Never escalate the entire request when
  only one bounded unit requires Pro.
- Actively apply the parallelization guidelines above whenever independent work exists. Avoid sequential execution bottlenecks when tasks can be safely parallelized.
- Keep a shared browser session, live mutation, or other exclusive resource
  under one owner's control. Delegate local artifact analysis or review of
  captured evidence instead of letting agents interfere with the live session.
- Apart from trivial work and pinpoint reading, exceptions to required delegation must identify a
  concrete blocker: a higher-priority restriction, unavailable tools, explicit
  user request for solo work, or no bounded independent unit that can run
  alongside useful parent work. For non-trivial work, parent capability, task
  familiarity, size, handoff cost, or a generic desire to save time is not
  enough. State the exception briefly and continue authorized work; do not
  claim an independent review that did not happen.

Gemini CLI subagents cannot call other subagents. Only the main agent may plan,
delegate, wait for, verify, and synthesize parallel work.

## Agent selection

- `flash-explorer`: targeted read-only discovery and compact context capsules.
- `flash-worker`: narrow, well-specified, low-risk implementation or mechanical work.
- `pro-worker`: normal engineering implementation, debugging, and related multi-file changes.
- `pro-reviewer`: independent correctness, regression, and test review.
- `pro-specialist`: difficult implementation or ambiguous, high-impact reasoning.
- `pro-risk-reviewer`: independent review of complex or high-risk changes.
- `pro-critical`: read-only analysis of critical security, data, concurrency, or
  production risk before mutation.

Give every delegated agent a bounded deliverable, authorized scope, concise
context, acceptance criteria, expected validation, and a stop condition. The
parent must wait for, verify, and synthesize results and remains accountable for
the final answer.

## Execution and validation

- Preserve user changes and unrelated files.
- Prefer the smallest coherent change that fully satisfies the request.
- Inspect relevant context before editing; do not perform redundant broad scans.
- Match validation to risk: one focused check for small bounded work; relevant
  tests, lint, build, or integration checks for ordinary work; independent
  review and failure-mode testing for high-risk work.
- A reviewer must be independent and must not edit the implementation it reviews.
- Never claim a check, test, or outcome that was not actually observed.
- Report skipped validation, environmental limitations, and unresolved risks.
- Ask only when a missing choice materially changes the result, increases risk,
  or requires new authority. Otherwise use a safe, reversible assumption and
  state it when relevant.

## Skills

Skills are optional specialist capabilities, not the routing control plane.
Use them explicitly or implicitly when their narrow purpose applies:

- `security-review`: requested or risk-triggered security analysis.
- `code-review`: review of a diff, branch, pull request, or completed change.
- `dependency-review`: dependencies, upgrades, advisories, and compatibility.
- `documentation`: standalone or substantial documentation work.

Routing, cost control, delegation, and validation remain mandatory even when no
Skill is discovered or invoked.

## Final report

For substantial work, report the outcome, checks performed, unresolved issues,
and relevant assumptions. If subagents ran, include actual execution counts by
model and percentages of subagent executions. Do not present execution share as
token usage or invent unavailable token, credit, or cost telemetry. If no
subagent ran on non-trivial work (trivial work and pinpoint reading need no
declared blocker), state that fact and the concrete reason for
direct execution. Report which required delegation/review checkpoints were
completed or blocked; do not expose the full numeric routing calculation.

### Model usage report format (Gemini)

The package defines Google agents only: **Flash** (`gemini-2.5-flash`) for lower-tier
executions and **Pro** (`gemini-2.5-pro`) for reasoning, specialist and high-risk review
executions. Report the models that actually ran. Other providers (for example Claude or
ChatGPT in Google Antigravity) are not verified by this package; add a row for one only
if the user configured it and it really executed.

### Utilização dos modelos

| Modelo | Execuções | Utilização |
|---|---:|---:|
| Flash | X | XX% |
| Pro | X | XX% |

**Total de execuções de subagentes:** X

If no subagents were used and work was completed directly by the parent agent,
state that fact clearly as required above, except for trivial work or pinpoint
reading, which need no declaration. If a summary table is presented for
direct execution, record 1 execution (100%) under the active model family and 0 for
the others. Never claim an execution on a model that did not run.
<!-- GEMINI-CLI-GLOBAL-FRAMEWORK:END v5 -->


For read-only reviews, provide the actual diff or a readable diff artifact, changed paths, and observed test results in the assignment. Reviewers cannot execute git or tests. Have the authorized parent run any additional checks they request. Never present configured model names as verified runtime telemetry.
