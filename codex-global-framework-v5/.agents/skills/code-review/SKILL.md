---
name: code-review
description: Review a branch, pull request, diff, patch, or completed implementation for correctness, regressions, maintainability risks, and missing tests; use when the user asks for review rather than implementation.
---

# Code Review

Determine the review baseline and inspect the actual changes plus the relevant
call paths. Focus on bugs, behavior regressions, broken contracts, unsafe edge
cases, and missing or misleading tests. Do not turn the review into a style
audit unless style obscures correctness or maintainability.

List findings first, ordered by severity. Each finding must identify the file or
symbol, explain the observable impact, and give a concise correction direction.
Use reproduction steps or a failing-test sketch when useful. Keep questions and
non-blocking suggestions separate.

Do not edit reviewed code unless the user separately asks for fixes. If no
material issue is supported by evidence, say so and note remaining test gaps or
uncertainties.
