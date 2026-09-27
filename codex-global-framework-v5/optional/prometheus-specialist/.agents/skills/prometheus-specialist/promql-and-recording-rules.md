# PromQL Avançado e Recording Rules

## 1. Princípios Fundamentais do PromQL

- **Regra de Ouro do Rate**: Nunca faça `sum(rate(...))` invertido como `rate(sum(...))`. O `rate()` deve calcular o incremento de cada série individualmente para tratar reinicializações de contadores (resets).
  - **Correto**: `sum by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))`
  - **Incorreto**: `rate(sum by (instance) (node_cpu_seconds_total{mode="idle"}[5m]))`

## 2. Álgebra Vetorial e Matching

- **One-to-One matching**:
  ```promql
  node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100
  ```
- **Many-to-One / One-to-Many matching (`group_left` / `group_right`)**:
  ```promql
  # Associa metadados de host a métricas de tráfego de interface
  rate(node_network_receive_bytes_total[5m])
    * on (instance) group_left (datacenter, rack)
    node_inventory_info
  ```

## 3. Histogramas e Cálculo de Latência

- **P99 de Latência HTTP**:
  ```promql
  histogram_quantile(0.99,
    sum by (le, handler) (rate(http_request_duration_seconds_bucket[5m]))
  )
  ```

## 4. Recording Rules para Telas de NOC

Pré-computar valores para renderização instantânea no Grafana:

```yaml
groups:
  - name: noc_infrastructure_rules
    interval: 30s
    rules:
      - record: job:node_cpu_utilization:percent
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)

      - record: job:node_memory_utilization:percent
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```
