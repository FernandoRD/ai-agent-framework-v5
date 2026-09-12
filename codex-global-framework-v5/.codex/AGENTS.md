<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5 -->
# Global Codex Framework v5

These rules apply to every project. Project-level `AGENTS.md` files may add
project facts, constraints, and commands, but must not silently weaken safety,
authorization, routing, or validation requirements.

## Mandatory classification

Classify every engineering request before choosing an execution strategy. Do
this directly from this file; routing must not depend on `$task-router` or on
implicit Skill invocation.

### Trivial work

A task is trivial only when every condition below is true:

- it has one narrow, clearly stated objective;
- it affects at most one file or one isolated location;
- the cause, required change, and expected result are already known;
- there is no meaningful design decision or uncertain investigation;
- it does not change externally consumed behavior or a shared contract;
- it does not involve any mandatory non-trivial trigger listed below;
- failure would have only local, low-impact consequences;
- it is immediately reversible with one small change; and
- one focused, deterministic check can validate it.

Typical trivial work includes correcting spelling or formatting, updating a
comment, renaming a purely local symbol, or applying an obvious isolated fix
whose cause and result are already established.

File count alone never makes work trivial. A one-line change to authorization,
SQL, networking, deployment, or a public interface is non-trivial.

If any trivial-work condition is false, unknown, or uncertain, classify the
task as non-trivial. Uncertainty increases classification; it never justifies
treating work as trivial.

Handle trivial work directly. Do not spawn an agent, calculate a numeric score,
or produce a routing report unless the user asks for one.

### Mandatory non-trivial triggers

Always classify work as non-trivial when it involves at least one of these:

- an unknown or uncertain root cause;
- more than one component, service, subsystem, or repository;
- coordinated changes across multiple files;
- architecture, data flow, shared state, or cross-component behavior;
- a public API, file format, protocol, schema, or externally consumed contract;
- authentication, authorization, secrets, privacy, or another security boundary;
- persistent data, database writes, migrations, or schema changes;
- concurrency, asynchronous execution, locking, races, or distributed behavior;
- infrastructure, networking, deployment, containers, CI/CD, or production configuration;
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

Route each bounded unit of work independently:

- 0-34: Luna tier.
- 35-69: Terra tier.
- 70-100: Sol tier.

Do not expose the full score calculation unless it helps the user understand a
decision or the user requests it.

### Risk floors

Risk floors override the numeric score:

- At least Terra: authentication behavior, public APIs, persistent-data changes,
  migrations or schemas, production infrastructure, structural refactors,
  compatibility-sensitive changes, or multi-component implementation.
- Sol for the critical portion: critical vulnerabilities, cryptography,
  authorization boundaries, credible data loss or corruption, difficult races
  or deadlocks, high-impact production failures, or ambiguous cross-system
  behavior with a large blast radius.

A risk floor applies to the affected portion, not automatically to the entire
request. Keep mechanical and well-bounded follow-up work in the lowest safe tier.

Missing access, credentials, approval, tools, dependencies, or a usable
environment is a blocker, not a reason to escalate models. Resolve or report
the blocker instead.

## Execution strategy

Use the least expensive model that can safely complete each bounded unit.

- If the active model already meets the required tier and delegation adds no
  clear quality, isolation, or context benefit, execute directly.
- If the active model is below the required tier, delegate the affected unit to
  an agent at or above the required tier.
- Never escalate the entire request when only one bounded unit requires a
  stronger model.
- Do not delegate work merely because it is non-trivial; delegation must improve
  capability, independent review, parallelism, or context efficiency.
- Parallelize only independent tasks with non-overlapping write scopes. Default
  to 2-4 concurrent agents and avoid redundant exploration or review.

For a large or unfamiliar repository, use `luna_explorer` once for targeted,
read-only discovery. Its context capsule must contain only relevant files and
symbols, the execution path, constraints, likely tests, and unresolved
questions. Reuse that capsule; stronger agents must not repeat a broad scan.

## Agent selection

- `luna_explorer`: targeted read-only discovery and compact context capsules.
- `luna_worker`: narrow, well-specified, low-risk implementation or mechanical work.
- `terra_worker`: normal engineering implementation, debugging, and related multi-file changes.
- `terra_reviewer`: independent correctness, regression, and test review.
- `sol_specialist`: difficult implementation or ambiguous, high-impact reasoning.
- `sol_reviewer`: independent review of complex or high-risk changes.
- `sol_critical`: read-only analysis of critical security, data, concurrency, or
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
subagent ran, mention that only when a usage report would otherwise be expected.
<!-- CODEX-GLOBAL-FRAMEWORK:END v5 -->
