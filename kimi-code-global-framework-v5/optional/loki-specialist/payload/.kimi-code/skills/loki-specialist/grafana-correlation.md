# Correlação de Logs e Métricas no Grafana

## 1. Derived Fields (Extração de Links Clicáveis)

Configure Derived Fields no datasource do Loki para converter identificadores de log em links diretos:

- **Nome**: `Host Dashboard Link`
- **Regex**: `host=([a-zA-Z0-9._-]+)`
- **URL**: `/d/zabbix-host-detail/host-overview?var-hostname=${__value.raw}`

Ao visualizar o log no Grafana Explore, o valor do `host` se torna um botão interativo levando ao dashboard do host.

## 2. Data Links: Do Alarme Zabbix ao Loki

Em qualquer painel do Grafana (incluindo tabelas de alarmes ou painel HTML Graphics):
1. Acesse **Field Options** > **Data Links**.
2. **Title**: `Ver logs do incidente no Loki`.
3. **URL**:
   ```text
   /explore?left={"datasource":"Loki","queries":[{"expr":"{hostname=\"${__data.fields.host}\"} |= \"error\""}],"range":{"from":"${__from}","to":"${__to}"}}
   ```
4. O operador clica no alarme e é transportado para os logs exatamente no intervalo de 15 minutos ao redor do alarme.
