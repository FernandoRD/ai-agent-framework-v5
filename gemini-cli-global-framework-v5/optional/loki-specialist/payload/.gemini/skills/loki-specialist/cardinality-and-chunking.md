# Governança de Cardinalidade e Chunking no Loki

## 1. O Problema da Alta Cardinalidade

No Loki, cada combinação única de pares chave-valor de labels cria um **Stream** independente.
- **Bom:** `{env="prod", cluster="sp", app="zabbix-proxy"}` (~10 streams).
- **Desastroso:** `{env="prod", ip="192.168.1.100", user="admin", request_id="uuid"}` (milhões de streams, satura memória do Loki e trava ingesters).

## 2. Regra de Seleção de Labels

| Identificador | Deve ser Label de Stream? | Alternativa Correta |
|---|:---:|---|
| `environment` (prod/dev) | **SIM** | Label estática |
| `cluster` / `datacenter` | **SIM** | Label estática |
| `service` / `job` | **SIM** | Label estática |
| `hostname` | **CUIDADO** | Apenas para frota fixa (NOC); evitar em contêineres dinâmicos |
| `ip_address` | **NÃO** | Extrair via `\| pattern` ou `\| json` |
| `user_id` / `session_id` | **NÃO** | Extrair via parser na query |
| `log_level` (INFO/WARN) | **NÃO** | Use `\|= "ERROR"` ou extraia no parser |

## 3. Configuração de Chunking e Cache

No `loki.yaml`:
```yaml
ingester:
  chunk_idle_period: 30m
  chunk_block_size: 262144        # 256 KB
  max_chunk_age: 2h
  chunk_target_size: 1572864      # 1.5 MB

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h # 7 dias
  ingestion_rate_mb: 20
  ingestion_burst_size_mb: 40
  max_entries_limit_per_query: 10000
```
