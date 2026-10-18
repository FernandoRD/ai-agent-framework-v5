# LogQL Mastery: Consultas, Filtragem e Métricas de Logs

## 1. Estrutura de uma Consulta LogQL

Uma consulta completa no LogQL possui 4 fases lógicas:
`{seletor_de_stream} | filtros_de_linha | parsers_e_extracao | filtros_de_labels | formatacao`

Exemplo prático:
```logql
{app="zabbix-server", env="prod"}
  |= "database error"
  | json
  | error_code > 500
  | line_format "{{.timestamp}} [ERR-{{.error_code}}] {{.message}}"
```

## 2. Filtros de Linha (Executados no Ingester/Querier)

- `|= "texto"` : Linha contém a string literal (muito rápido).
  `!= "texto"` : Linha não contém a string.
  `|~ "regex"` : Linha casa com expressão regular (RE2).
  `!~ "regex"` : Linha não casa com regex.

> [!TIP]
> Sempre posicione `|=` antes de `|~` ou de parsers `| json`. Isso descarta 90%+ dos chunks antes de carregar o analisador de JSON.

## 3. Parsers em Tempo de Execução

- **JSON**: `| json query_duration="duration_ms"` (extrai campos JSON automaticamente).
- **Logfmt**: `| logfmt` (extrai formato `chave=valor`).
- **Pattern**: `| pattern "<ip> - <user> [<time>] "<method> <uri>" <status>"` (alta velocidade para logs tabulares).
- **Regex**: `| regexp "^(?P<ts>\S+) \[(?P<level>\w+)\] (?P<msg>.*)$"`.

## 4. Agregações Métricas a partir de Logs

- **Taxa de linhas de erro por segundo**:
  ```logql
  sum by (service) (rate({env="prod"} |= "ERROR" [5m]))
  ```
- **Total de bytes trafegados em logs de acesso**:
  ```logql
  sum by (host) (bytes_over_time({job="nginx"} [1h]))
  ```
- **P95 de latência extraída do log**:
  ```logql
  quantile_over_time(0.95,
    {job="api-gateway"}
      | json
      | unwrap response_time [5m]
  ) by (path)
  ```
