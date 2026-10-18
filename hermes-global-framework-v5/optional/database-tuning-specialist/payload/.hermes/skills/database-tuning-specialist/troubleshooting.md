# Troubleshooting de Banco de Dados

## 1. Saturação de Conexões (`FATAL: remaining connection slots are reserved`)

- **Causa**: Centenas de instâncias do Grafana ou pollers abrindo conexões simultâneas sem fechá-las.
- **Solução**: Implementar o **PgBouncer** em modo de transação (`transaction pooling`) imediatamente. O Zabbix Server precisa de apenas ~50 conexões reais no PostgreSQL para atender milhares de hosts.

## 2. Inchaço de Tabela (*Table Bloat*) e Falta de Autovacuum

- Em tabelas com muitas atualizações (ex: `triggers`, `hosts`, `items`):
  ```sql
  -- Ajusta autovacuum agressivo para tabelas de alta atualização
  ALTER TABLE triggers SET (
      autovacuum_vacuum_scale_factor = 0.05,
      autovacuum_vacuum_cost_limit = 1000
  );
  ```
- Para recuperar espaço sem travar a tabela para escrita: utilizar a ferramenta `pg_repack`.
