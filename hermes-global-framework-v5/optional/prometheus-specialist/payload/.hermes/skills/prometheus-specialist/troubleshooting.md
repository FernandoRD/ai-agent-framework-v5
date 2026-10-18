# Troubleshooting de Prometheus e VictoriaMetrics

## 1. Identificando Explosão de Cardinalidade

Execute via terminal ou API administrativa:
```bash
# Identifica os nomes de métricas com mais séries ativas
curl -s http://localhost:9090/api/v1/status/tsdb | jq '.data.seriesCountByMetricName[:10]'

# Identifica as labels com maior quantidade de valores únicos
curl -s http://localhost:9090/api/v1/status/tsdb | jq '.data.labelValueCountByLabelName[:10]'
```

## 2. Scrape Timeout (`context deadline exceeded`)

- **Causa**: O exporter demora mais para coletar os dados do que o `scrape_timeout` configurado.
- **Diagnóstico**: Teste de tempo de resposta: `time curl -s http://alvo:9100/metrics > /dev/null`.
- **Solução**: Desabilitar coletores lentos no exporter ou aumentar temporariamente o timeout no job.

## 3. Recuperação de WAL e Memória

- Se o Prometheus reiniciar em loop por falta de memória na recuperação do WAL:
  - Aumentar temporariamente o swap;
  - Utilizar VictoriaMetrics (`vmstorage`) que gerencia memória e flush de forma assíncrona e não sofre com reconstruções custosas de WAL.
