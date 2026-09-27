# Base de Conhecimento: Prometheus

## Convenções de Métricas

1. **Unidades de Medida**:
   - Tempos em segundos (`_seconds`);
   - Bytes em bytes (`_bytes`);
   - Ratios e porcentagens entre 0 e 1 (`_ratio`).
2. **Nomenclatura**:
   - Formato snake_case: `<namespace>_<subsystem>_<name>_<unit>`.
