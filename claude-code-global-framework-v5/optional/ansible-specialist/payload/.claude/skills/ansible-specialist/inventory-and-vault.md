# Inventários e Ansible Vault

## 1. Inventários Estáticos e Estrutura de Grupos

Organize inventários em formato YAML por função e ambiente:

```yaml
all:
  children:
    datacenter_sp:
      children:
        db_servers:
          hosts:
            db01.empresa.local:
              ansible_host: 10.0.10.11
            db02.empresa.local:
              ansible_host: 10.0.10.12
        mon_servers:
          hosts:
            zbx-server.empresa.local:
              ansible_host: 10.0.10.20
              zabbix_role: server
```

## 2. Inventários Dinâmicos (Integração Zabbix API)

Integre a API do Zabbix como fonte de inventário dinâmico utilizando o plugin `community.zabbix.zabbix_inventory`:

```yaml
# inventory_zabbix.yaml
plugin: community.zabbix.zabbix_inventory
server_url: https://zabbix.empresa.local
login_user: ansible_svc
login_password: "{{ vault_zabbix_token }}"
validate_certs: true
group_by_host_groups: true
host_format: "{host}"
```

## 3. Segurança com Ansible Vault

- **Regra de Ouro**: Nunca versione senhas em texto puro no Git.
- **Encriptar arquivo completo**:
  ```bash
  ansible-vault encrypt group_vars/all/vault.yml
  ```
- **Encriptar variável isolada (Vault Inline)**:
  ```bash
  ansible-vault encrypt_string 'SenhaComplexa123!' --name 'vault_db_password'
  ```
- No playbook, referencie a variável segura:
  ```yaml
  db_password: "{{ vault_db_password }}"
  ```
