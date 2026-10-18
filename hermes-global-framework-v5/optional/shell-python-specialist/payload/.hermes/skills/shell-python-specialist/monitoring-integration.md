# Integração com Monitoramento e Agendamento

## 1. UserParameters do Zabbix Agent / Agent 2

```ini
# /etc/zabbix/zabbix_agent2.d/app.conf
UserParameter=app.queue.size[*],/usr/local/lib/zabbix/app_queue.sh "$1"
```

Regras para o script chamado:
- Imprimir **apenas o valor** em `stdout`, sem texto adicional; mensagens de diagnóstico vão para `stderr`.
- Terminar dentro do `Timeout` configurado no agente (ou do timeout do item nas versões que o suportam); scripts lentos devem virar coleta assíncrona (arquivo de cache ou `zabbix_sender`).
- Rodar sem privilégios; se precisar de acesso elevado, conceder via regra `sudo` mínima e específica, nunca `ALL`.
- Validar os parâmetros recebidos (`$1`), pois vêm do servidor; nunca repassá-los a `eval` ou a um shell sem aspas.

## 2. Saída de Low-Level Discovery (LLD)

```python
import json
import sys

discovered = [{"{#QUEUE}": nome} for nome in ("pedidos", "faturas")]
json.dump(discovered, sys.stdout)
```

- Emita um array JSON de objetos com macros LLD (`{#MACRO}`); gere o JSON com a biblioteca (`json.dump`, `jq -n`), nunca concatenando strings.
- Em Bash, use `jq` para montar JSON com segurança:
  ```bash
  jq -n '[$ARGS.positional[] | {"{#QUEUE}": .}]' --args pedidos faturas
  ```

## 3. Envio Ativo com zabbix_sender

```bash
zabbix_sender -z "$ZBX_SERVER" -s "$HOSTNAME_ZBX" -k app.backup.status -o 0
# Em lote (host chave valor por linha):
zabbix_sender -z "$ZBX_SERVER" -i /var/tmp/app_metrics.txt
```

- Útil para rotinas longas (backup, ETL) que reportam o resultado ao terminar; o item correspondente é do tipo *Zabbix trapper*.
- Verifique o resumo de retorno (`processed`/`failed`) e trate falhas no código de saída.

## 4. API do Zabbix em Python

- Use a biblioteca oficial `zabbix_utils` ou chamadas JSON-RPC diretas com `requests`/`httpx`.
- Autentique com **API token** de usuário dedicado e papel com permissões mínimas; nunca com `Admin`.
- Operações de escrita (`*.create`, `*.update`, `*.delete`) seguem o fluxo: consulta prévia, simulação com o diff pretendido, aprovação e aplicação em lote delimitado.
- Para mudanças estruturais em templates e hosts, coordene com o `zabbix-specialist` quando instalado.

## 5. Agendamento: cron e timers do systemd

```ini
# /etc/systemd/system/app-report.service
[Service]
Type=oneshot
User=app-report
ExecStart=/usr/local/bin/app_report.py --config /etc/app-report/config.json
TimeoutStartSec=300

# /etc/systemd/system/app-report.timer
[Timer]
OnCalendar=*-*-* 02:30:00
RandomizedDelaySec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

- Timers do systemd oferecem logs no journal (`journalctl -u app-report`), controle de sobreposição e timeouts nativos.
- No cron, defina `PATH` e `SHELL` explicitamente, redirecione a saída para log e use `flock` para evitar sobreposição.
- Monitore a própria rotina: reporte sucesso/falha e duração ao Zabbix (trapper ou item de verificação do último sucesso).
