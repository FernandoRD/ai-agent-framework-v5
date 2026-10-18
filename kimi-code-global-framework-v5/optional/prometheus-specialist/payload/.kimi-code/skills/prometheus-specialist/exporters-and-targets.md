# Configuração de Exporters e Alvos de Coleta

## 1. Node Exporter (Métricas de Sistema Operacional)

Flags recomendadas para produção em servidores de infraestrutura:
```bash
/usr/local/bin/node_exporter   --collector.systemd   --collector.processes   --collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc)($|/)"   --collector.netclass.ignored-devices="^(veth.*|docker.*|cali.*)$"   --web.listen-address="127.0.0.1:9100"
```

## 2. Blackbox Exporter (Testes Sintéticos de Conectividade)

Módulos no `blackbox.yml`:
```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200, 204]
      method: GET
      fail_if_ssl: false

  icmp_ping:
    prober: icmp
    timeout: 3s
    icmp:
      preferred_ip_protocol: "ip4"
```

Job de scrape no `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'blackbox-icmp'
    metrics_path: /probe
    params:
      module: [icmp_ping]
    static_configs:
      - targets:
        - 8.8.8.8
        - 1.1.1.1
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115
```
