# Troubleshooting de Ansible

## 1. Problemas de Conectividade e Autenticação

- **Erro `UNREACHABLE!`**:
  - Teste manual: `ssh -i ~/.ssh/id_rsa usuario@host`
  - Validar host key: `ANSIBLE_HOST_KEY_CHECKING=False` (apenas em testes)
  - Diagnóstico com módulo ping: `ansible -i hosts all -m ping -vvv`

## 2. Erros de Sintaxe e Jinja2

- **Erro `TemplateSyntaxError` ou `UndefinedError`**:
  - Validar sintaxe sem executar: `ansible-playbook --syntax-check playbook.yml`
  - Checar variáveis não definidas: usar o filtro `default`: `{{ minha_var | default('valor_padrao') }}`
  - Proteger blocos JSON/YAML brutos no Jinja2 com `{% raw %} ... {% endraw %}`.

## 3. Falha de Idempotência e Modo Check

- **Comportamento inesperado em `--check`**:
  - Módulos `command` ou `shell` falham em `--check` se tentarem ler arquivos gerados por passos anteriores. Use `check_mode: false` apenas onde for indispensável para inspeção somente-leitura.
  - Inspecione as diferenças exatas com:
    ```bash
    ansible-playbook -i inventario playbook.yml --check --diff
    ```
