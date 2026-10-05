# Dashboard Design & UI/UX Principles

Effective Grafana dashboards combine clear information architecture, rapid readability, and strict visual hierarchy. Dashboards designed for NOCs, operations centers, and executive overviews must communicate status in seconds without causing visual fatigue.

## 1. Visual Hierarchy & The 5-Second Rule

- **5-Second Rule**: An operator glancing at a dashboard should immediately discern system health (Normal, Warning, Critical) within 5 seconds.
- **Top-Down Layout**:
  - **Top Row (Executive / Overview)**: Single Stat panels, high-level SLA gauges, overall alert status, and key KPI counters.
  - **Middle Rows (Aggregated Trends)**: Time series showing primary workloads, throughput, error rates, and traffic flows.
  - **Bottom Rows / Collapsed Rows (Drill-down)**: Detailed host-level tables, distribution histograms, debug logs, and raw metrics.
- **Panel Sizing & Grid**:
  - Align panels strictly to Grafana's 24-column grid.
  - Maintain consistent panel heights across rows (e.g. 4–6 units for stat rows, 8–10 units for time series).

## 2. Color Palette & Alert Fatigue Prevention

- **Semantic Color Usage**:
  - Reserve saturated reds, oranges, and yellows **exclusively** for warnings, errors, and threshold violations.
  - Use neutral tones (cool grays, muted slates, deep blues) for normal background grids, axis lines, and non-critical metrics.
  - If everything is bright green or colored, operators suffer from alert fatigue and fail to spot critical incidents.
- **Threshold Standardization**:
  - Normal: Muted blue / cool gray or standard green (`#73BF69`).
  - Warning: Amber / Orange (`#FF9830`).
  - Critical: Vibrant Red (`#F2495C`).
- **Dual Theme Support**:
  - Test all custom colors against both Dark mode (default in NOCs) and Light mode (often used for reports and executive exports).
  - Ensure a contrast ratio of at least 4.5:1 (WCAG AA) for all text against panel backgrounds.

## 3. Variables, Templates & Dynamic Layouts

- **Variable Hierarchy**: Order template variables logically (e.g., `Environment` → `Datacenter` → `Cluster` → `Host`).
- **Multi-Value & All**: Handle `All` options efficiently; use regex or glob matching in queries rather than unbounded multi-value interpolations that overwhelm backend databases or Zabbix proxies.
- **Repeated Rows/Panels**: Use row repeat sparingly on high-cardinality variables to prevent browser crashes when querying hundreds of hosts simultaneously.

## 4. Typography & Readability at a Distance

- Use clear font sizing for wallboard/NOC displays: large single-stat values (24px–36px) with short, unambiguous unit labels (e.g. `req/s`, `ms`, `%`).
- Avoid ambiguous acronyms in panel titles. Use panel descriptions (tooltip icon) to explain query logic or metric source without cluttering the title bar.
