# Tuning de PostgreSQL e TimescaleDB para Monitoramento

## 1. Parâmetros Essenciais do `postgresql.conf` (Servidor 32GB RAM / SSD)

```ini
# Memória
shared_buffers = 8GB                  # 25% da memória RAM
effective_cache_size = 24GB           # 75% da memória RAM
work_mem = 64MB                       # Para ordenações e hashes complexos
maintenance_work_mem = 2GB            # Acelera VACUUM e criação de índices

# Checkpoint e WAL (Suavização de escrita massiva)
checkpoint_completion_target = 0.9    # Espalha o checkpoint em 90% do intervalo
checkpoint_timeout = 15min            # Reduz a frequência de checkpoints pesados
max_wal_size = 16GB
min_wal_size = 2GB

# Concorrência e Workers
max_worker_processes = 8
max_parallel_workers_per_gather = 2
max_parallel_maintenance_workers = 4

# Otimização de Disco SSD/NVMe
random_page_cost = 1.1                # Próximo a 1.0 para discos rápidos
effective_io_concurrency = 200
```

## 2. TimescaleDB: Hypertables e Compressão

Para Zabbix com extensão TimescaleDB:
- **Chunk Interval**:
  - Tabelas de histórico (`history`, `history_uint`, `history_str`): 1 dia por chunk.
  - Tabelas de tendências (`trends`, `trends_uint`): 7 dias por chunk.
- **Compressão de Chunks Antigos**:
  ```sql
  -- Habilita compressão após 7 dias
  ALTER TABLE history_uint SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'itemid',
    timescaledb.compress_orderby = 'clock DESC'
  );

  SELECT add_compression_policy('history_uint', INTERVAL '7 days');
  ```
  A compressão nativa do TimescaleDB reduz o consumo em disco em 85% a 92% e acelera leituras históricas do Grafana.

## 3. Governança com PgBouncer

No `pgbouncer.ini`:
```ini
[databases]
zabbix = host=127.0.0.1 port=5432 dbname=zabbix

[pgbouncer]
listen_port = 6432
pool_mode = transaction               # Máxima eficiência para o Zabbix Server
max_client_conn = 1000
default_pool_size = 50
reserve_pool_size = 10
```
