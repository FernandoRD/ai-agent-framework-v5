# Automação de Monitoramento com Ansible

## 1. Rollout do Zabbix Agent 2

Exemplo de task modular com suporte a Linux (Debian e RHEL):

```yaml
- name: Instala repositório oficial do Zabbix
  ansible.builtin.package:
    name: "{{ zabbix_repo_url }}"
    state: present

- name: Instala Zabbix Agent 2 e plugins
  ansible.builtin.package:
    name:
      - zabbix-agent2
      - zabbix-agent2-plugin-postgresql
    state: present

- name: Configura zabbix_agent2.conf
  ansible.builtin.template:
    src: zabbix_agent2.conf.j2
    dest: /etc/zabbix/zabbix_agent2.conf
    owner: root
    group: zabbix
    mode: '0640'
  notify: Reinicia zabbix-agent2

- name: Garante serviço ativo e habilitado no boot
  ansible.builtin.service:
    name: zabbix-agent2
    state: started
    enabled: true
```

## 2. Rollout do Grafana Alloy / Promtail

```yaml
- name: Adiciona repositório Grafana
  ansible.builtin.deb822_repository:
    name: grafana
    types: [deb]
    uris: https://apt.grafana.com
    suites: [stable]
    components: [main]
    signed_by: https://apt.grafana.com/gpg.key
    state: present

- name: Instala Grafana Alloy
  ansible.builtin.package:
    name: alloy
    state: present

- name: Configura pipeline do Alloy
  ansible.builtin.template:
    src: config.alloy.j2
    dest: /etc/alloy/config.alloy
    owner: alloy
    group: alloy
    mode: '0640'
  notify: Reinicia alloy
```

## 3. Provisionamento de Datasources no Grafana

```yaml
- name: Cria datasource Zabbix no Grafana via API
  community.grafana.grafana_datasource:
    grafana_url: "https://grafana.empresa.local"
    grafana_api_key: "{{ vault_grafana_api_key }}"
    name: "Zabbix-Production"
    ds_type: "alexanderzobnin-zabbix-datasource"
    ds_url: "https://zabbix.empresa.local/api_jsonrpc.php"
    is_default: true
    jsonData:
      username: "grafana_readonly"
      trends: true
    secureJsonData:
      password: "{{ vault_zabbix_grafana_password }}"
```
