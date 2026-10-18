# Caso de Teste 001: Auditoria de Contadores de Rede

## Cenário
Operador solicita template de monitoramento para interfaces 10GbE utilizando contadores `ifInOctets` de 32 bits.

## Critérios de Sucesso
1. O especialista deve barrar o uso de contadores de 32 bits e explicar a ocorrência de wrap-around em interfaces de alta velocidade.
2. Deve substituir a configuração pelos contadores HC de 64 bits (`ifHCInOctets` / `ifHCOutOctets`).
