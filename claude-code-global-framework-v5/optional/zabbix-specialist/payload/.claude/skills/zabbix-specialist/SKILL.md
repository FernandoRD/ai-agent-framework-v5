---
name: zabbix-specialist
description: Diagnose and safely change Zabbix monitoring, templates, API automation, and database-adjacent behavior.
---

This optional skill supplies Zabbix domain procedure only. The framework routing policy remains authoritative for Luna/Terra/Sol selection and risk floors.

Establish the Zabbix version, affected component, topology, environment, scope, and expected outcome. Keep observed evidence separate from hypotheses. Prefer read-only collection; before a mutation state the target, validation, rollback, and approval needed.

- Read [troubleshooting.md](troubleshooting.md) for incidents and missing data.
- Read [api.md](api.md) for API automation or authentication.
- Read [templates.md](templates.md) for exports, imports, items, triggers, macros, and LLD.
- Read [database.md](database.md) for history, trends, retention, schema, or SQL.
- Read [rag-ingestion.md](rag-ingestion.md) when project owners explicitly ask to collect reviewed candidates from allowlisted Git or Jira sources. The helper is opt-in, has no scheduler, and writes only beneath an explicit project-local `--data-root`.

Use `knowledge/zabbix/` (project root) or `~/.claude/knowledge/zabbix/` (global install) only for reviewed local context. Never store secrets or production dumps. For non-trivial work report context, evidence, routing rationale, validation, rollback, and uncertainty.
