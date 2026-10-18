# SDN, Backup e Alta Disponibilidade (HA)

## 1. Software Defined Network (SDN) no Proxmox VE 8.x e 9.x

O Proxmox VE 8 e 9 integra o módulo de SDN diretamente ao core da distribuição, permitindo criar overlays de rede e isolamentos multitenant sem dependência de switches físicos gerenciados.

### Tipos de Zonas SDN
- **VLAN Zone**: Mapeamento simples de tags 802.1Q sobre bridges Linux físicas (`vmbrX`).
- **QinQ Zone**: Suporte a encapsulamento de duas camadas de tags VLAN para provedores ou ambientes isolados.
- **VXLAN Zone**: Túnel de encapsulamento L2 sobre rede IP L3 sem necessidade de protocolo de roteamento complexo. Exige MTU físico adequado ($\ge 1550$ bytes).
- **EVPN Zone (BGP EVPN)**:
  - Solução enterprise para grandes data centers ou clusters multi-site.
  - Utiliza BGP com Frr (Free Range Routing) integrado no Proxmox para anunciar MACs e IPs dinamicamente, permitindo mobilidade de VMs entre nós sem quebra de sessão TCP.

### Vnets, Subnets e IPAM
- **Vnets**: Bridges virtuais criadas dentro de uma zona SDN que são atribuídas diretamente às placas de rede das VMs/LXC (`net0: vnet10`).
- **IPAM (IP Address Management)**:
  - O PVE integra nativamente provedores de IPAM (PVE IPAM local, NetBox ou phpIPAM).
  - Configuração de subnets com alocação automática de IPs e integração opcional com servidor DHCP embutido (dnsmasq).

---

## 2. Alta Disponibilidade (HA) e Fencing

### Componentes de HA
- **`pve-ha-crm` (Cluster Resource Manager)**: Roda em um nó eleito mestre e gerencia o estado global dos recursos protegidos.
- **`pve-ha-lrm` (Local Resource Manager)**: Roda em cada nó individual e executa ações de start/stop/migrate delegadas pelo CRM.

### Fencing Confiável (Anti-Split-Brain)
- **Watchdog Fencing**: Fencing nativo via módulo de watchdog do kernel Linux (`softdog` ou watchdog de hardware via IPMI/iLO/iDRAC). Se o Corosync perder o quórum por mais de 60 segundos, o nó isolado reinicia automaticamente via hardware watchdog para proteger storages compartilhados.
- **HA Groups**:
  - Definir grupos de nós prioritários para cargas específicas.
  - Utilizar a flag `nofailback` para evitar que uma VM retorne ao nó de origem assim que ele reaparecer, prevenindo churn de migrações desnecessárias.

---

## 3. Políticas de Backup e Disaster Recovery (DR)

### Modos de Backup
1. **Snapshot**: Modo recomendado. A VM continua executando sem interrupção; os dados são lidos via QEMU dirty-bitmaps e transmitidos de forma assíncrona.
2. **Suspend**: Congela a execução da VM durante a cópia da memória/estado.
3. **Stop**: Desliga a VM para consistência estrita (raramente necessário com QEMU Guest Agent ativo).

### Esquema de Retenção Recomendado (GFS)
```text
keep-last=7
keep-daily=7
keep-weekly=4
keep-monthly=12
keep-yearly=2
```

---

## 4. Telemetria e Observabilidade do Proxmox

### Metric Server Nativo
O Proxmox VE suporta envio de métricas em tempo real para InfluxDB (v1/v2) ou Graphite:
- Configuração em **Datacenter → Metric Server**.
- Envio a cada 10 segundos de métricas de CPU, memória, IOPS, latência de disco e tráfego de rede de todos os nós e VMs.

### Zabbix Integration
- Monitoramento via **Zabbix Agent 2** instalado no host Proxmox ou monitoramento agentless via API REST HTTPS utilizando token RBAC dedicado.
- Monitoramento de pools Ceph (`ceph status`), saúde ZFS (`zpool status`), estado do Corosync (`pvecm status`) e status de backups PBS.

### Prometheus Integration
- Implantação do `proxmox-pve-exporter` em contêiner ou VM dedicada.
- Coleta de métricas padronizadas em `/metrics` para scraping pelo Prometheus e visualização em dashboards corporativos no Grafana 12.
