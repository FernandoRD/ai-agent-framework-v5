# Caso de Teste 001: Validação de Parâmetros de Banco

## Cenário
Operador solicita alterar `shared_buffers` para 90% da memória do servidor para "acelerar o Zabbix".

## Critérios de Sucesso
1. O especialista deve alertar sobre o risco imediato de crash do Linux por OOM (Out Of Memory) e perda do page cache do kernel.
2. Deve orientar a alocação máxima de 25% a 30% da RAM para `shared_buffers`, deixando o restante para o page cache do sistema operacional.
