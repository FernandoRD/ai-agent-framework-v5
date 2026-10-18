# Grafana API, Automation & Provisioning

Safe automation and version control for Grafana 12, dashboards, datasources, and permissions.

## 1. Safety Gates & Change Protocol

- **Production Mutex**: Direct mutation of production dashboards via API or GUI is prohibited without prior export and approval.
- **Pre-Mutation Checklist**:
  1. Capture dashboard UID, title, and current `version`.
  2. Export the complete current JSON model to a timestamped backup before applying changes.
  3. Validate JSON schema compatibility outside production (staging Grafana or test folder).
  4. Ensure rollback plan: re-importing previous version payload or using Grafana's built-in dashboard version history (`/api/dashboards/uid/:uid/versions`).
- **Floor Requirement**: Automated provisioning, datasource modifications, or batch dashboard overwrites require at least the framework's Pro tier (or Terra/Sonnet equivalent) with an explicit approval gate.

## 2. Grafana HTTP API Automation

- **Authentication**: Use Service Accounts with scoped tokens (Viewer, Editor, Admin) rather than legacy API keys or personal user credentials.
- **Useful Endpoints**:
  - Search/Get Dashboard: `GET /api/dashboards/uid/:uid`
  - Create/Update Dashboard: `POST /api/dashboards/db` (Requires payload `{ dashboard: {...}, overwrite: true, message: "Change note" }`)
  - Version History: `GET /api/dashboards/uid/:uid/versions`
  - Datasource Health: `GET /api/datasources/uid/:uid/health`
- **Idempotency**: Set explicit `uid` in dashboard JSON models to avoid duplicate dashboard sprawl. Increment or preserve version numbers properly to detect concurrent edits.

## 3. Declarative Provisioning (File-Based)

- Store provisioning configs under `/etc/grafana/provisioning/`:
  - `dashboards/`: YAML providers mapping local directories to Grafana folders.
  - `datasources/`: Datasource definitions with credentials populated via environment variables (`${GF_DS_PASSWORD}`).
  - `plugins/`: Plugin configuration and allowlists.
- In Grafana 12, keep `allow_loading_unsigned_plugins` strictly limited to required development plugins (such as custom builds of HTML Graphics) and never allow unsigned plugins globally in production environments.

## 4. Zabbix Datasource Integration

- When querying Zabbix from Grafana via the Alexander Zobnin Zabbix plugin:
  - Prefer direct DB connection (Trends / History DB) for time ranges > 7 days to eliminate API overload on the Zabbix Server.
  - Use item key filters and application/tag filters rather than broad host regexes.
  - Cache dashboard queries where appropriate to reduce proxy and server query queues.
