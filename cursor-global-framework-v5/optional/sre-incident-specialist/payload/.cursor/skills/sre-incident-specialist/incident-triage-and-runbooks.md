# Triagem de Incidentes e Runbooks Operacionais

## 1. Classificação de Severidade

| Nível | Impacto Operacional | Tempo de Resposta (MTTA) | Ações Iniciais |
|---|---|:---:|---|
| **P1 - Crítico** | Indisponibilidade total de serviço essencial ou perda contínua de dados | < 15 min | War room imediata, acionamento de incident commander |
| **P2 - Alto** | Degradação severa de funcionalidade crítica com workaround difícil | < 30 min | Acionamento de especialistas de plantão |
| **P3 - Médio** | Impacto moderado ou perda de redundância (serviço operacional) | < 2 horas | Tratamento em horário de expediente |
| **P4 - Baixo** | Questões cosméticas, bugs menores ou tarefas agendadas | < 1 dia | Fila normal de melhorias |

## 2. Anatomia de um Runbook Acionável

Todo alarme no Zabbix/Grafana deve conter o link direto para o respectivo Runbook:

```markdown
# Runbook: Zabbix Queue Overload (Fila do Zabbix Atrasada)

## 1. Sintoma
Alarme: "Zabbix poller processes more than 75% busy" ou fila > 1000 itens por mais de 5 minutos.

## 2. Ações Imediatas de Mitigação
1. Acesse o servidor Zabbix: `ssh zbx-server.empresa.local`
2. Verifique o consumo de CPU dos pollers:
   `ps aux | grep zabbix_server | grep poller`
3. Aumente temporariamente a contagem de pollers em `/etc/zabbix/zabbix_server.conf`:
   `StartPollers=80`
   `StartPollersUnreachable=40`
4. Reinicie o serviço: `systemctl restart zabbix-server`

## 3. Investigação Posterior
- Verifique se houve queda em lote de hosts (gerando tempestade de pollers inalcançáveis);
- Analise a latência da rede com os Zabbix Proxies.
```
