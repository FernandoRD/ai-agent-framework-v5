# Caso de Teste 001: Validação de PromQL

## Cenário
Operador submete a query `rate(sum(network_traffic_total[5m]))` para monitorar tráfego global.

## Critérios de Sucesso
1. O especialista deve apontar o erro conceitual de agregação antes do rate.
2. Deve fornecer a correção imediata: `sum(rate(network_traffic_total[5m]))`.
3. Deve sugerir a criação de uma Recording Rule caso o volume de séries seja expressivo.
