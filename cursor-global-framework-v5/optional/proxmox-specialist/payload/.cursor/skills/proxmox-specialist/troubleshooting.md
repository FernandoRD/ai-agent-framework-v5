# Guia de Troubleshooting: Diagnósticos e Resolução no Proxmox VE

## 1. Problemas de Cluster e Perda de Quorum

### Sintoma: Cluster em modo Read-Only / Não é possível criar ou iniciar VMs
Quando o Corosync perde o quorum (menos da metade dos nós + 1 comunicando), o filesystem de configuração `/etc/pve` torna-se somente leitura para prevenir split-brain.

**Diagnóstico**:
```bash
pvecm status
systemctl status corosync
journalctl -u corosync -n 50 --no-pager
```

**Resolução de Emergência (Quorum Temporário)**:
Se nós físicos estiverem permanentemente desligados e você precisar operar os nós sobreviventes:
```bash
# Reduz o quorum esperado para a quantidade de nós ativos sobreviventes (ex.: 1)
pvecm expected 1
```
*Atenção*: Utilize este comando apenas em emergências e após garantir que os outros nós estão desligados da rede.

---

## 2. Resolução de Locks e Tarefas Travadas

### Sintoma: "VM is locked (backup)" ou "CT is locked (mounted)"
Ocorre quando um processo de backup, snapshot ou migração é interrompido abruptamente ou sofre timeout.

**Remoção de Lock**:
```bash
# Para Máquinas Virtuais (QEMU):
qm unlock <vmid>

# Para Containers LXC:
pct unlock <vmid>
```

### Sintoma: Tarefa de cluster travada em execução infinita
```bash
# Listar tarefas ativas:
pvesh get /nodes/<node>/tasks --source active

# Abortar tarefa específica:
pvesh delete /nodes/<node>/tasks/<UPID>
```

---

## 3. Diagnóstico e Resolução de Storage

### Ceph Degradado ou PGs Incompletos
```bash
# Verificar estado global:
ceph status
ceph health detail

# Listar OSDs com falha:
ceph osd tree | grep -E "down|out"

# Reiniciar OSD problemático:
systemctl restart ceph-osd@<osd-id>
```

### ZFS Pool Degradado ou Lentidão Extrema
```bash
# Inspecionar erros de leitura/escrita/checksum:
zpool status -v

# Limpar contadores de erro transitórios:
zpool clear <pool>

# Substituir disco falho:
zpool replace <pool> <disco-antigo> <novo-disco>
```
*Armadilha comum*: Pools ZFS com mais de 80% de ocupação sofrem fragmentação severa e queda drástica de IOPS. Mantenha a utilização abaixo de 80%.

---

## 4. Problemas de Rede e SDN

### Sintoma: Conectividade intermitente em túneis VXLAN / EVPN
- **Causa mais comum**: Mismatch de MTU. O cabeçalho VXLAN adiciona 50 bytes ao pacote IP. Se a interface física subjacente estiver configurada com MTU 1500, pacotes com payload padrão sofrerão fragmentação ou descarte.
- **Solução**: Configurar MTU de no mínimo 1550 (recomendado 9000 - Jumbo Frames) nas interfaces físicas subjacentes e manter MTU 1500 dentro das Vnets SDN.

---

## 5. Arquivos de Log e Comandos Essenciais

| Componente | Localização do Log / Comando |
|---|---|
| Cluster Engine | `journalctl -u pve-cluster -f` |
| Corosync Quorum | `journalctl -u corosync -f` |
| Daemon da API | `journalctl -u pvedaemon -f` |
| Proxy Web HTTPS | `journalctl -u pveproxy -f` |
| Tarefas de Nós | `/var/log/pve/tasks/` |
| Kernel / Hardware | `dmesg -T \| grep -E "kvm\|qemu\|zfs\|ceph"` |
