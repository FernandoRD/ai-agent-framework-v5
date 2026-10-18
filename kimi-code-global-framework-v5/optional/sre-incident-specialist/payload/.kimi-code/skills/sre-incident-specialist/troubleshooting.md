# Troubleshooting de Confiabilidade e Crises

## 1. Mitigação de Tempestades de Falhas em Cascata

Quando uma falha secundária sobrecarrega os nós saudáveis restantes:
1. **Ativar Shedding de Carga**: Cortar tráfego de métricas de baixa prioridade ou queries de dashboards não essenciais.
2. **Degradação Graciosa**: Congelar atualizações automáticas de telas secundárias para priorizar a persistência de alarmes.
3. **Circuit Breaking**: Interromper temporariamente chamadas à API que estejam com timeout para permitir a recuperação dos backends.

## 2. Prevenção de Flapping de Alarmes

- Use **histerese** em triggers de recuperação:
  - Disparar alarme: CPU > 90% por 5 minutos;
  - Limpar alarme: CPU < 75% por 10 minutos.
