# Base de Conhecimento: Database Tuning

## Arquitetura de Armazenamento Recomendada

1. **Separação de Discos**:
   - `pg_wal`: NVMe dedicado para escrita rápida e sem concorrência;
   - Dados (`base/`): Array NVMe/SSD com RAID 10 para alta vazão de leitura e escrita.
