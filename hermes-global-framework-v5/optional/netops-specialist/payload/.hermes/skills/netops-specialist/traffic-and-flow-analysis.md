# Análise de Tráfego e Telemetria de Fluxo (Flow)

## 1. NetFlow / IPFIX / sFlow

- **NetFlow v9 / IPFIX**: Baseado em fluxo orientado a conexão (agregação com templates dinâmicos).
- **sFlow**: Amostragem de pacotes em hardware (ideal para switches core de altíssima densidade de portas 40G/100G).

## 2. Integração com Coletores e Visualização

1. O appliance exporta fluxos para um coletor (ex: `pmacct`, `nfdump`, `Vector` ou `GoFlow2`).
2. O coletor agrega os fluxos por:
   - `src_ip`, `dst_ip` (Top Talkers);
   - `protocol`, `dst_port` (Aplicações consumindo banda);
   - `as_src`, `as_dst` (Tráfego por provedor/trânsito IP).
3. Os dados agregados são inseridos no VictoriaMetrics ou Elastic/Loki e exibidos em dashboards do Grafana.

## 3. Métricas de Qualidade de Enlace (SLA de Rede)

- **Loss**: Porcentagem de perda de pacotes em rajadas ICMP (`icmppingloss`).
- **RTT (Round Trip Time)**: Média, desvio padrão e P95 de tempo de ida e volta (`icmppingsec`).
- **Jitter**: Variação estatística da latência entre pacotes sucessivos (crítico para VoIP, videoconferência e streaming).
