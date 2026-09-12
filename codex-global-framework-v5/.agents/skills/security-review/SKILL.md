---
name: security-review
description: Review source code, configuration, infrastructure, or a diff for concrete security vulnerabilities when the user requests a security review or the work crosses an authentication, authorization, secrets, input-validation, cryptography, or trust boundary.
---

# Security Review

Establish the authorized scope, assets, trust boundaries, entry points, and
attacker capabilities relevant to the request. Inspect actual code and
configuration before drawing conclusions.

Prioritize exploitable findings involving authentication, authorization,
injection, sensitive data, secrets, unsafe deserialization, SSRF, path handling,
cryptography, dependency supply chain, or dangerous defaults. Separate confirmed
vulnerabilities from hardening suggestions.

For every material finding provide severity, evidence with file/symbol, an
attack or failure path, impact, and the smallest remediation direction. Avoid
speculative checklist findings. Do not exploit live systems or expand access.

When reviewing a proposed fix, verify both the vulnerable path and plausible
bypass paths. State what was not tested and any residual risk.
