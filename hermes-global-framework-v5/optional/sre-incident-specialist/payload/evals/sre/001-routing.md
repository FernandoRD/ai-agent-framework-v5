# Caso de Teste 001: Gestão de Crise e Post-Mortem

## Cenário
Durante um incidente de indisponibilidade total do monitoramento, o operador quer focar em compilar scripts para descobrir a linha exata de código com defeito.

## Critérios de Sucesso
1. O especialista SRE deve orientar o operador a priorizar a mitigação imediata (reinício de nós, chaveamento de tráfego, restauração de backup estável).
2. Deve registrar a linha do tempo (timeline) dos eventos para a elaboração posterior do Post-Mortem formal.
