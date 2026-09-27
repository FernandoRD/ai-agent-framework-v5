# Base de Conhecimento Local: Proxmox VE e Nuvem Privada

Este diretório armazena diretrizes arquiteturais, convenções de infraestrutura e snippets padronizados para o ecossistema Proxmox VE (8.x e 9.x) do projeto.

---

## 1. Convenção Recomendada de VMIDs

Para evitar colisões e manter a governança clara em múltiplos clusters ou datacenters:

| Faixa de VMID | Finalidade | Exemplos |
|---|---|---|
| `100 - 199` | Infraestrutura de Core (Roteadores, Firewalls, DNS, DHCP) | OPNsense, pfSense, Pi-hole, BIND9 |
| `200 - 299` | Serviços de Observabilidade e Monitoramento | Zabbix Server, Grafana, Prometheus, Loki |
| `300 - 399` | Bancos de Dados e Armazenamento Central | PostgreSQL, TimescaleDB, MySQL, Redis |
| `400 - 499` | Aplicações e Microsserviços Internos | APIs, Web Apps, Portais corporativos |
| `500 - 599` | Contêineres de Desenvolvimento e CI/CD | Runners Gitea/GitHub, staging |
| `9000 - 9999` | Templates Imutáveis de Cloud-Init | `template-debian-12`, `template-ubuntu-2404` |

---

## 2. Snippet Canônico de Cloud-Init (Debian / Ubuntu)

Template base recomendado para injeção via Cloud-Init:

```yaml
#cloud-config
users:
  - name: deployer
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... chave-de-automacao
package_upgrade: true
packages:
  - qemu-guest-agent
  - curl
  - htop
runcmd:
  - systemctl enable --now qemu-guest-agent
```

---

## 3. Matriz de Dimensionamento de Overcommit de Recursos

- **CPU Overcommit (vCPU : pCore)**:
  - Cargas Críticas / Bancos de Dados: máx `1:1` a `1.5:1`
  - Cargas Gerais de Produção: máx `2:1` a `3:1`
  - Ambientes de Teste / Dev: máx `4:1` a `5:1`
- **Memória RAM**:
  - Proibido overcommit com KSM (Kernel Samepage Merging) em servidores de produção com alta transação para evitar latência imprevisível.
