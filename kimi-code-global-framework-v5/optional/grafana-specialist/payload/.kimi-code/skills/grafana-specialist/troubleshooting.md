# Troubleshooting Grafana & Panels

Diagnose rendering failures, datasource errors, query timeouts, and performance bottlenecks.

## 1. Systematic Diagnostic Sequence

Trace the observability pipeline from data source to browser rendering:
```
Data Source (Zabbix/Prometheus/SQL)
  → Network / Gateway / Reverse Proxy
  → Grafana Backend (Query Engine / Transforms)
  → Network Payload (DataFrames / JSON)
  → Browser Runtime (Panel Renderer / HTML Graphics JS)
```

1. **Query Inspector**:
   - Open Panel Menu → *Inspect* → *Data* / *Query*.
   - Check query execution time, returned row/point count, and raw response payload.
   - If raw data is returned but the panel is blank, the error is in transformations or panel rendering logic (HTML Graphics / SVG).
   - If the query times out or returns HTTP 500/504, check datasource connectivity, proxy queues, or index performance on the datasource.
2. **Browser Developer Console**:
   - Inspect Console for uncaught JavaScript exceptions originating from custom HTML Graphics code.
   - Check Network tab for CSP (Content Security Policy) violations, blocked external fonts, or blocked inline scripts.
3. **Grafana Server Logs**:
   - Review `/var/log/grafana/grafana.log` for plugin crashes, datasource errors, or rendering timeout warnings.

## 2. Common HTML Graphics Failures

- **Blank Panel after Refresh**:
  - Cause: `onRender` throwing an error when accessing fields that are undefined during loading states.
  - Fix: Add defensive guards (`if (!data || !data.series || !data.series[0]) return;`).
- **Browser Sluggishness / Tab Crash**:
  - Cause: Memory leak caused by registering event listeners inside `onRender` instead of `onInit`, or creating new DOM nodes without removing old ones.
  - Fix: Relocate listener bindings to `onInit` and update attributes in `onRender`.
- **Corrupted Panel Layout**:
  - Cause: Unscoped CSS rules impacting Grafana global elements.
  - Fix: Wrap all rules inside a container class selector.

## 3. Time Zone & Transformation Traps

- Verify dashboard time zone setting (*UTC*, *Browser Time*, or specific region). Discrepancies between Zabbix server time (UTC) and operator local time frequently masquerade as missing data.
- Order of transformations: Ensure *Filter by name* or *Organize fields* runs before mathematical or reduction calculations.
