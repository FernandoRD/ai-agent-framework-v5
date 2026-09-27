# Cluster e Storage: Arquitetura, Hiperconvergência e Upgrades

## 1. Arquitetura de Cluster Proxmox VE 8.x e 9.x

### Corosync v3 e Quorum
O cluster Proxmox depende do Corosync v3 para troca de estado e quorum:
- **Rede Redundante de Cluster**: Configurar sempre ao menos duas redes físicas isoladas para o Corosync (`ring0_addr` e `ring1_addr`), priorizando links de baixa latência e livres de tráfego de backup ou storage massivo.
- **QDevice Externo**: Para clusters com número par de nós (especialmente 2 nós), configurar um dispositivo de quorum externo (`corosync-qnetd`) instalado em VM externa ou Raspberry Pi, garantindo voto desempate e prevenindo split-brain:
  ```bash
  pvecm qdevice setup <qdevice-ip>
  ```
- **Verificação de Saúde**:
  ```bash
  pvecm status
  pvecm nodes
  ```

### Procedimentos de Upgrade (PVE 8.x para PVE 9.x)
1. **Auditoria Prévia**:
   Executar o script oficial de auditoria antes da atualização para identificar dependências órfãs, storages legados e configurações de hardware incompatíveis:
   ```bash
   pve8to9 --full
   ```
2. **Atualização de Repositórios**:
   Substituir repositórios de Debian Bookworm para Trixie em `/etc/apt/sources.list` e `/etc/apt/sources.list.d/pve-enterprise.list` (ou `pve-no-subscription.list`).
3. **Ceph Upgrade**:
   Se o Ceph estiver integrado, atualizar primeiramente de Ceph Reef para Ceph Squid seguindo a documentação oficial da versão antes de transicionar os nós de computação.

---

## 2. Storage Hiperconvergente: Ceph e ZFS

### Ceph (Reef / Squid)
- **Monitors (MON) e Managers (MGR)**: Mínimo de 3 MONs distribuídos em nós ímpares para manter o quórum do storage.
- **OSDs (Object Storage Daemons)**:
  - Alocar discos NVMe ou SSD dedicados para OSDs com BlueStore.
  - Para discos mecânicos (HDDs), separar o DB/WAL em SSD/NVMe rápido com ratio recomendado de 1:4 ou 1:5.
- **Pools e CRUSH Maps**:
  - Pools replicados com tamanho padrão `size=3, min_size=2` para resiliência a falhas de nós inteiros.
  - Ativar `pg_autoscale_mode=on` com target size ou ratio para dimensionamento dinâmico de Placement Groups (PGs).

### ZFS (Zettabyte File System)
- **Topologia de Pools**:
  - Para máquinas virtuais com alta carga de I/O aleatório (bancos de dados), utilizar **Striped Mirrors (RAID10 equivalente)** em vez de RAIDZ. RAIDZ é indicado para dados sequenciais ou arquivamento.
  - Alinhamento de setores: fixar `ashift=12` (blocos de 4KB) para SSDs e HDDs modernos.
- **Parâmetros Críticos do Pool**:
  ```bash
  zfs set compression=zstd <pool>
  zfs set atime=off <pool>
  ```
- **Controle de Memória ARC**:
  Por padrão, o ZFS pode consumir até 50% da memória física do host para o cache ARC. Em nós de virtualização com alta densidade de VMs, limitar o ARC em `/etc/modprobe.d/zfs.conf`:
  ```ini
  # Limite máximo de ARC para 16GB
  options zfs zfs_arc_max=17179869184
  ```
- **Replicação Nativa (`pvesr`)**:
  Agendar replicação assíncrona de snapshots ZFS entre nós do cluster a cada 5 a 15 minutos para permitir migração quase instantânea de VMs com storage local.

---

## 3. Integração com Proxmox Backup Server (PBS)

- **Deduplicação e Criptografia**:
  - O PBS divide os dados de discos de VMs em blocos variáveis (chunks de ~4MB), calculando hashes SHA-256 e enviando apenas blocos inéditos (deduplicação client-side).
  - Chaves de criptografia geradas localmente no PVE garantem que os dados cheguem criptografados ao PBS (*zero-knowledge storage*).
- **Manutenção e Verificação**:
  - Configurar Verify Jobs periódicos no PBS para conferir a integridade dos blocos de backup.
  - Executar Garbage Collection (GC) e Prune Jobs agendados para expurgar blocos não referenciados e recuperar espaço em disco.
