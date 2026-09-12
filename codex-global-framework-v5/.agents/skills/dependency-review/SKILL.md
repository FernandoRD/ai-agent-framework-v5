---
name: dependency-review
description: Assess dependency upgrades, vulnerability advisories, lockfile changes, abandoned packages, and version compatibility when a request is specifically about third-party packages or supply-chain risk.
---

# Dependency Review

Identify the package manager, manifests, lockfiles, runtime constraints, and
currently resolved versions. Use authoritative release notes, advisories, and
project documentation when current external facts are required.

For each proposed change assess security relevance, breaking changes, runtime
and peer compatibility, transitive impact, migration work, and rollback path.
Prefer the smallest supported upgrade that resolves the stated problem. Do not
mass-update unrelated packages.

Validate with the repository's install, lockfile-integrity, test, lint, and
build checks as applicable. Report exact versions changed, evidence used,
validation performed, and remaining compatibility risk.
