# Particionamento por Tempo e Fim do Housekeeper

## 1. Por que o Housekeeper Padrão Degrada a Performance?

O housekeeper padrão executa periodicamente:
```sql
DELETE FROM history_uint WHERE clock < 1700000000 LIMIT 5000;
```
Esse comando:
- Realiza scans contínuos no disco;
- Gera milhares de transações de escrita de WAL;
- Gera inchaço massivo (*table bloat*) no PostgreSQL;
- Compete por I/O diretamente com os processos de escrita de novas métricas.

## 2. A Solução: Particionamento Nativo (Drop Partition)

Ao particionar a tabela por range de tempo:
```sql
-- Criando a partição de um dia específico
CREATE TABLE history_uint_y2026m09d26 PARTITION OF history_uint
    FOR VALUES FROM (1758844800) TO (1758931200);
```

Para descartar os dados com mais de 30 dias:
```sql
-- Operação atômica em milissegundos sem I/O nem bloat!
DROP TABLE history_uint_y2026m08d26;
```
No Zabbix, acesse **Administração** > **Geral** > **Housekeeping** e **desabilite** o housekeeper para tabelas de histórico e tendências que estiverem particionadas.
