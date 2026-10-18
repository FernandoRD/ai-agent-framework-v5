# RCA e Post-Mortems Blameless (Sem Culpa)

## 1. Princípios do Post-Mortem Sem Culpa

- O erro humano é um sintoma de falhas mais profundas nos sistemas, ferramentas e processos, nunca a causa raiz.
- Se alguém cometeu um erro de comando, o sistema deveria ter impedido a execução ou tornado o impacto reversível.
- Foco em: "Como tornamos o sistema imune a essa categoria de falha no futuro?".

## 2. Metodologia dos 5 Porquês (Exemplo Real)

- **Incidente**: O dashboard do NOC parou de atualizar por 40 minutos.
  1. *Por que parou?* O Grafana perdeu a conexão com o datasource do Zabbix.
  2. *Por que perdeu a conexão?* O Zabbix Server rejeitou as chamadas de API por excesso de conexões.
  3. *Por que havia excesso de conexões?* O banco de dados PostgreSQL entrou em deadlock, retendo transações abertas.
  4. *Por que houve deadlock?* O housekeeper executou um `DELETE` massivo em `history_uint` simultaneamente a uma consulta agregada pesada.
  5. *Por que o housekeeper executou um delete massivo?* Porque a tabela não estava particionada e o volume diário superou 50GB.
  - **Ação Corretiva Definitiva**: Implementar particionamento nativo de tabelas e desabilitar o housekeeping de histórico no Zabbix.
