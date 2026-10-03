# SLI, SLO e Gestão de Error Budgets

## 1. Definições Fundamentais

- **SLI (Service Level Indicator)**: Medição quantitativa de conformidade do serviço.
  $$\text{SLI} = \frac{\text{Requisições com Sucesso}}{\text{Total de Requisições}} \times 100$$
- **SLO (Service Level Objective)**: Meta de confiabilidade estabelecida internamente pela equipe (ex: 99.9% no mês).
- **SLA (Service Level Agreement)**: Compromisso contratual com clientes, com penalidades financeiras ou jurídicas (tipicamente inferior ao SLO).
- **Error Budget**: A margem de falha tolerada pelo SLO.
  $$\text{Error Budget} = 100\% - \text{SLO} = 0.1\% \text{ (para 99.9%)}$$

## 2. Modelagem com os 4 Sinais Dourados (Golden Signals)

1. **Latência**: Tempo que leva para atender a uma requisição (separando sucesso de falha).
2. **Tráfego**: Demanda imposta ao sistema (operações por segundo, throughput).
3. **Erros**: Taxa de requisições que falharam explicitamente (código HTTP 5xx, timeouts).
4. **Saturação**: Medida de fração utilizada do recurso mais restrito (memória, CPU, I/O, conexões de banco).

## 3. Alertas por Queima de Error Budget (Burn Rate)

Em vez de alertar sobre limiares estáticos simples, alerte sobre a velocidade com que o orçamento de erros está se esgotando:

- **Burn Rate 1x**: O orçamento consumirá 100% exatamente no final do período de 30 dias.
- **Burn Rate 14.4x**: Consumirá 2% do orçamento mensal em 1 hora (Alerta Crítico / Pager).
- **Burn Rate 6x**: Consumirá 5% do orçamento mensal em 6 horas (Alerta de Atenção).
