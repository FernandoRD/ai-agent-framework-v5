---
name: grafana-specialist
description: Design high-impact dashboards, custom HTML Graphics panels, API automation, and safe Grafana 12+ operations.
---

This optional skill supplies Grafana domain procedures, UI/UX design standards, and HTML Graphics panel development. The framework routing policy remains authoritative for model selection (Flash/Pro, Haiku/Sonnet/Opus, Luna/Terra/Sol) and risk floors.

Establish the Grafana version (prioritizing Grafana 12 while supporting 11.x/10.x), plugin availability, datasource topology, dashboard UID/slug, and target audience. Keep observed data separate from visual assumptions. Prefer read-only exploration and draft panels in test environments before altering production dashboards or provisioning.

- Read [html-graphics.md](html-graphics.md) for the HTML Graphics plugin, lifecycle (onInit vs onRender), SVG manipulation, scoped CSS, and memory-leak prevention.
- Read [dashboard-design.md](dashboard-design.md) for UI/UX guidelines, visual hierarchy, grid layout, semantic color palettes, and dark/light theme support.
- Read [api-and-provisioning.md](api-and-provisioning.md) for Grafana HTTP API, Service Accounts, JSON exports/imports, dashboard versioning, and datasource bindings.
- Read [troubleshooting.md](troubleshooting.md) for panel render debugging, Query Inspector, time range bugs, browser performance, and transformation errors.
- Read [infra-rag.md](infra-rag.md) when a local `infra-rag` index may hold organizational precedents; it is optional and, if unavailable, continue normally.

Use `knowledge/grafana/` (project root) or `~/.claude/knowledge/grafana/` (global install) only for reviewed corporate design tokens, palettes, approved SVG assets, and reusable HTML Graphics templates. Never store API tokens, service account credentials, or production data dumps. For non-trivial work report context, evidence, routing rationale, validation, rollback, and uncertainty.
