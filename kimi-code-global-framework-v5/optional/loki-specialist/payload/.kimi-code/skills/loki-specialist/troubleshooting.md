# Troubleshooting de Grafana Loki

## 1. Erro `entry too far behind` ou `out of order`

- **Causa**: O coletor (Alloy/Promtail) enviou logs com timestamp anterior ao chunk já compactado ou além do `reject_old_samples_max_age`.
- **Solução**:
  - No Promtail/Alloy, garantir que a pipeline de parsing de data não use ano fixo errado;
  - Se timestamps desordenados forem inevitáveis, habilitar no Loki 3.x:
    ```yaml
    limits_config:
      creation_grace_period: 10m
    ```

## 2. Erro `rate limit exceeded` (429 Too Many Requests)

- **Causa**: O volume de logs ultrapassou `ingestion_rate_mb`.
- **Diagnóstico**: Verificar logs do Promtail com `server returned status 429`.
- **Solução**:
  - No `loki.yaml`, ajustar `ingestion_rate_mb` e `ingestion_burst_size_mb`;
  - Filtrar logs ruidosos (debug/trace) diretamente na origem no Alloy/Promtail antes do envio.

## 3. Query Timeout em Períodos Longos

- **Solução**:
  - Exigir filtros de stream mais específicos (`{app="x", env="prod"}` em vez de `{env="prod"}`);
  - Habilitar e configurar o **Loki Query Frontend** para particionar queries por sub-intervalos em paralelo.
