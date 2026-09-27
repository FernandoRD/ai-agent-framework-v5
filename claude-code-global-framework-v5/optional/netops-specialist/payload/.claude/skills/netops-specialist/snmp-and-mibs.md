# SNMP e MIBs: Arquitetura e Engenharia de Coleta

## 1. OIDs Fundamentais para Interfaces de Rede

| Métrica | OID 32-bit (Legado) | OID 64-bit (Obrigatório >= 1G) |
|---|---|---|
| Tráfego de Entrada | `1.3.6.1.2.1.2.2.1.10.X` (`ifInOctets`) | `1.3.6.1.2.1.31.1.1.1.6.X` (`ifHCInOctets`) |
| Tráfego de Saída | `1.3.6.1.2.1.2.2.1.16.X` (`ifOutOctets`) | `1.3.6.1.2.1.31.1.1.1.10.X` (`ifHCOutOctets`) |
| Pacotes com Erro (In) | `1.3.6.1.2.1.2.2.1.14.X` (`ifInErrors`) | Idem |
| Descarte de Pacotes (In)| `1.3.6.1.2.1.2.2.1.13.X` (`ifInDiscards`) | Idem |
| Velocidade da Porta | `1.3.6.1.2.1.2.2.1.5.X` (`ifSpeed`, max 4.2Gbps) | `1.3.6.1.2.1.31.1.1.1.15.X` (`ifHighSpeed`, em Mbps) |
| Status Operacional | `1.3.6.1.2.1.2.2.1.8.X` (`ifOperStatus`: 1=up, 2=down) | Idem |

> [!WARNING]
> Contadores de 32 bits em uma interface de 10 Gbps sofrem **wrap-around** (estouro e reinicialização a zero) em menos de 35 segundos sob tráfego intenso. Sempre use contadores de 64 bits (`ifHC*`).

## 2. SNMPv3 Seguro (authPriv)

Comando de teste e validação:
```bash
snmpwalk -v3 -l authPriv   -u zabbix_user   -a SHA-256 -A "ChaveAutenticacaoForte123"   -x AES -X "ChavePrivacidadeForte456"   10.0.0.1 1.3.6.1.2.1.31.1.1.1.1
```

## 3. Descoberta Automática de Portas (LLD no Zabbix)

SNMP OID no Zabbix:
```text
discovery[{#IFNAME},1.3.6.1.2.1.31.1.1.1.1,{#IFALIAS},1.3.6.1.2.1.31.1.1.1.18,{#IFOPERSTATUS},1.3.6.1.2.1.2.2.1.8]
```
Filtro regex recomendado:
- `{#IFOPERSTATUS} matches 1` (somente portas ativas)
- `{#IFNAME} not_matches ^(lo|null|vlan.*)` (ignora interfaces virtuais irrelevantes).
