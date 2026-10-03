# Base de Conhecimento: Grafana Loki

## Padrões de Ingestão Corporativa

1. **Rótulos Padrão Obrigatórios**:
   - `env`: `production`, `staging`, `development`
   - `infra`: `on-premise`, `aws`, `azure`
   - `service`: nome do serviço ou daemon (ex: `zabbix-server`, `nginx`, `kernel`)
2. **Retenção Global**:
   - 30 dias para logs de aplicação padrão;
   - 90 dias para logs de auditoria e segurança.
