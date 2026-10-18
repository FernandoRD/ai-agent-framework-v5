# Alertmanager e Armazenamento com VictoriaMetrics

## 1. Regras de Alerta Resilientes

```yaml
groups:
  - name: host_alerts
    rules:
      - alert: HostDiskFillingFast
        expr: (node_filesystem_free_bytes / node_filesystem_size_bytes < 0.15) and (predict_linear(node_filesystem_free_bytes[4h], 8 * 3600) < 0)
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Disco {{ $labels.mountpoint }} no host {{ $labels.instance }} encherá em menos de 8 horas."
```

## 2. Inibição e Agrupamento no Alertmanager

No `alertmanager.yml`:
```yaml
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'telegram-noc'

inhibit_rules:
  # Se o nó está indisponível (NodeDown), silencia alarmes de serviço do nó
  - source_match:
      alertname: 'NodeDown'
    target_match_re:
      alertname: '^(HostDiskFillingFast|HighCpuUsage)$'
    equal: ['instance']
```

## 3. Integração de Longo Prazo com VictoriaMetrics

No `prometheus.yml`:
```yaml
remote_write:
  - url: "http://victoriametrics:8428/api/v1/write"
    queue_config:
      max_samples_per_send: 10000
      capacity: 50000
      max_shards: 10
```
