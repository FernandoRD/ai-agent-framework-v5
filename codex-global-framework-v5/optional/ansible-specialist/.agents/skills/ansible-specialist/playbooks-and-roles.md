# Playbooks e Roles: Arquitetura e Melhores Práticas

## 1. Estrutura Canônica de Role

```text
roles/nome_da_role/
├── README.md
├── defaults/main.yml       # Variáveis padrão de menor precedência (sobrescrevíveis)
├── vars/main.yml           # Variáveis internas constantes da role
├── tasks/
│   ├── main.yml            # Ponto de entrada de tarefas
│   ├── install_linux.yml   # Tarefas específicas para SO
│   └── install_windows.yml
├── handlers/main.yml       # Handlers disparados por 'notify'
├── templates/*.j2          # Arquivos de configuração Jinja2
├── files/*                 # Arquivos estáticos
└── meta/main.yml           # Metadados e dependências da role
```

## 2. Idempotência e Tratamento de Mudanças

- **Uso de `creates` e `removes`**:
  ```yaml
  - name: Descompacta pacote de telemetria
    ansible.builtin.unarchive:
      src: /tmp/telemetry.tar.gz
      dest: /opt/telemetry
      remote_src: true
      creates: /opt/telemetry/bin/collector
  ```
- **Controle explícito de `changed_when`**:
  ```yaml
  - name: Testa configuração antes de reiniciar serviço
    ansible.builtin.command: zabbix_agent2 -t agent.ping
    register: zabbix_test
    changed_when: false
    failed_when: zabbix_test.rc != 0
  ```

## 3. Resiliência com Block / Rescue / Always

```yaml
- name: Executa mutação com rollback automático
  block:
    - name: Atualiza arquivo de configuração
      ansible.builtin.template:
        src: agent.conf.j2
        dest: /etc/zabbix/zabbix_agent2.conf
        validate: '/usr/sbin/zabbix_agent2 -t agent.ping'
      notify: Reinicia zabbix-agent2
  rescue:
    - name: Restaura backup em caso de falha de validação
      ansible.builtin.copy:
        src: /etc/zabbix/zabbix_agent2.conf.bak
        dest: /etc/zabbix/zabbix_agent2.conf
        remote_src: true
      notify: Reinicia zabbix-agent2
  always:
    - name: Registra conclusão do playbook
      ansible.builtin.debug:
        msg: "Concluído bloco de configuração em {{ inventory_hostname }}"
```
