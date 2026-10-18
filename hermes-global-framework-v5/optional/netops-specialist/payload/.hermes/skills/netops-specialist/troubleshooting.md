# Troubleshooting de Redes e SNMP

## 1. Timeout de Coleta SNMP

- **Sintoma**: Host fica piscando vermelho no Zabbix (`Timeout while connecting to...`).
- **Diagnóstico**:
  - Teste de latência: `ping -c 20 <ip>` (verificar se há perda de pacotes);
  - Teste de MTU: `ping -s 1472 -M do <ip>` (evitar fragmentação de pacotes SNMP);
  - Verificar se a porta UDP 161 está sendo limitada por rate-limiting de controle de plano (CoPP) no switch.

## 2. Erros de CRC e Pacotes Descartados (Discards)

- **Erros de CRC (`ifInErrors`)**: Tipicamente causados por cabo defeituoso, conector óptico sujo, GBIC/SFP incompatível ou duplex mismatch (Half/Full).
- **Descartes (`ifInDiscards` / `ifOutDiscards`)**: Tipicamente causados por estouro de buffer de porta (microbursts) quando o tráfego tenta passar de uma interface rápida (ex: 10G) para uma mais lenta (ex: 1G).
