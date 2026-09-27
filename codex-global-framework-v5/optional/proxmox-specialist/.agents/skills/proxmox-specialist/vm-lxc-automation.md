# Máquinas Virtuais, Containers LXC e Automação IaC

## 1. Otimização de Máquinas Virtuais QEMU/KVM

### Tipo de Processador e Recursos
- **CPU Type**:
  - `host`: máxima performance, expondo todas as instruções do hardware físico (AES-NI, AVX, SSE4.2). Recomendado para clusters homogêneos.
  - `x86-64-v3` ou `x86-64-v2-AES`: recomendado para clusters heterogêneos de diferentes gerações de CPUs Intel/AMD, permitindo migração ao vivo sem travamento de instruções.
- **Controladora de Disco**:
  - Controladora SCSI: `VirtIO SCSI single`.
  - Discos: ativar flags `iothread=1` (threads dedicadas de I/O por disco) e `discard=on` (repasse de comandos TRIM para liberar espaço em thin pools ZFS/LVM-Thin/Ceph).
  - Cache: `none` (garante gravação direta em disco e suporta migração ao vivo).

### Memória e Arquitetura NUMA
- Para VMs grandes (mais de 8 vCPUs ou mais de 32GB RAM), ativar a flag `numa=1` para que o kernel convidado mapeie corretamente a topologia de memória dos sockets físicos.
- Evitar Ballooning em máquinas de alta carga (bancos de dados, Elasticsearch, Kafka); fixar a memória alocada sem variação dinâmica.

### BIOS e Segurança Convidada
- Utilizar UEFI (`OVMF`) com particionamento GPT para sistemas operacionais modernos.
- Adicionar chip `vTPM 2.0` emulado para suporte a Secure Boot e Windows 11 / Windows Server 2022/2025.
- Instalar compulsoriamente o **QEMU Guest Agent** (`qemu-guest-agent`) em todas as VMs convidadas para permitir:
  - Congelamento atômico de filesystem (`fsfreeze`) durante backups;
  - Desligamento ordenado seguro;
  - Exibição de endereços IP de rede na interface do PVE e API.

---

## 2. Containers de Sistema LXC

- **Privilégios e Segurança**:
  - Utilizar sempre contêineres **Unprivileged** (sem privilégios). O root dentro do container é mapeado para um UID não privilegiado (ex.: UID 100000) no host via `subuid`/`subgid`.
  - Habilitar virtualização aninhada (*nesting*) e `keyctl=1` caso o container vá executar Docker ou Podman interno.
- **Armazenamento e Bind Mounts**:
  - Mapear volumes de storage locais ou NFS compartilhados diretamente no container via bind mount em `/etc/pve/lxc/<vmid>.conf`:
    ```ini
    mp0: /dados/compartilhados,mp=/mnt/dados,ro=1
    ```
- **Limites de cgroups v2**:
  - O Proxmox VE 8 e 9 operam sob cgroups v2 unificado: limites de memória, swap e peso de CPU (`cpu.weight`) são aplicados dinamicamente sem reinicialização.

---

## 3. Automação e Infraestrutura como Código (IaC)

### Autenticação Segura via API Token
Nunca armazenar usuário e senha em scripts ou repositórios Git:
1. Criar usuário e grupo dedicado de automação (ex.: `terraform@pve` ou `ansible@pve`).
2. Criar API Token com segredo gerado:
   ```bash
   pveum user add terraform@pve --comment "Automacao Terraform"
   pveum user token add terraform@pve terraform-token --privsep 0
   pveum acl modify /vms -user terraform@pve -role PVEVMAdmin
   pveum acl modify /storage -user terraform@pve -role PVEStorageAdmin
   ```

### Proxmox Provider com Terraform / OpenTofu
Utilizar o provider moderno mantido pela comunidade (`bpg/proxmox`):
```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.60.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://pve1.empresa.local:8006/"
  api_token = "terraform@pve!terraform-token=SEU-TOKEN-AQUI"
  insecure  = false
}
```

### Templates e Cloud-Init
- Criar templates imutáveis de VMs base com Cloud-Init instalado e zerado (`machine-id` limpo).
- Clonagem rápida com linked clones (`qm clone <template-vmid> <new-vmid> --full 0`) e injeção de rede, chaves SSH públicas e scripts de bootstrap via Cloud-Init.
