# Troubleshooting de Shell Script e Python

## 1. Script Funciona no Terminal mas Falha no cron, systemd ou Zabbix Agent

- **Causa típica**: ambiente diferente (`PATH`, `HOME`, `LANG`, usuário, diretório de trabalho).
- Diagnóstico:
  ```bash
  sudo -u zabbix env -i PATH=/usr/bin:/bin /usr/local/lib/zabbix/app_queue.sh pedidos
  systemctl show app-report.service -p Environment -p User -p WorkingDirectory
  ```
- Use caminhos absolutos, defina `PATH` no script ou na unit e não dependa de arquivos de perfil do shell.

## 2. Item do Zabbix `Not supported` ou Timeout

- Execute a chave no próprio agente: `zabbix_agent2 -t 'app.queue.size[pedidos]'` (ou `zabbix_agentd -t`).
- A partir do servidor ou proxy: `zabbix_get -s <host> -k 'app.queue.size[pedidos]'`.
- Confira: saída contendo apenas o valor, tipo de informação do item compatível, tempo de execução abaixo do timeout e permissões do usuário `zabbix`.

## 3. Depuração de Bash

```bash
bash -x script.sh --target /tmp/teste          # rastreia cada comando
PS4='+ ${BASH_SOURCE}:${LINENO}: ' bash -x script.sh
shellcheck -x script.sh                        # erros de aspas, expansões e portabilidade
```

- Saída inesperada com `set -e`: procure falhas mascaradas em `local x="$(cmd)"`, pipelines e condicionais.
- Caracteres invisíveis: `cat -A script.sh` revela `\r` (arquivo salvo com CRLF), que causa `$'\r': command not found`; converta com `dos2unix` ou `sed -i 's/\r$//'`.

## 4. Depuração de Python

- Traceback completo com `python3 -X dev -m pacote.cli --verbose`; `python3 -m pdb` ou `breakpoint()` para inspeção interativa.
- `ModuleNotFoundError` em produção: confirme o interpretador (`which python3`, `python3 -c 'import sys; print(sys.executable)'`) e se o shebang aponta para o `venv` correto.
- Encoding: abra arquivos com `encoding="utf-8"` explícito e defina `LANG`/`LC_ALL` em serviços.
- Travamentos em rede: confirme que toda chamada tem `timeout`; use `py-spy dump --pid <pid>` para ver onde o processo está parado.

## 5. Desempenho

- Shell: evite laços que chamam processos externos por linha (`while read; do grep ...`); prefira um único `awk`, `jq` ou migre para Python.
- Python: meça antes de otimizar (`python3 -m cProfile -s cumtime script.py`, `time`); para I/O de rede, paralelize com limite de concorrência.
