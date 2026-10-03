# Base de Conhecimento Local: Shell Script e Python

Este diretório armazena convenções de programação, padrões de scripts e decisões de ferramentas adotadas no projeto para Shell Script e Python.

---

## 1. Convenção Recomendada de Layout

| Caminho | Finalidade |
|---|---|
| `scripts/` | Scripts Shell executáveis (`*.sh`), um por tarefa |
| `scripts/lib/` | Funções Shell compartilhadas (`source`), sem efeitos colaterais ao carregar |
| `src/<pacote>/` | Código Python do projeto (layout `src`) |
| `tests/` | Testes `pytest` e `bats` |
| `pyproject.toml` | Metadados, dependências e configuração de `ruff`, `mypy` e `pytest` |

---

## 2. Padrões Mínimos

- **Shell**: `#!/usr/bin/env bash` + `set -euo pipefail`; `--help` em todo script; simulação por padrão e escrita somente com `--apply`.
- **Python**: `requires-python = ">=3.10"`; `argparse` + `logging`; `main()` retornando código de saída; sem `shell=True`.
- **Saída**: dados em `stdout`, diagnósticos em `stderr`; códigos de saída `0` sucesso, `1` falha de execução, `2` uso ou configuração inválidos.
- **Segredos**: somente via variáveis de ambiente ou arquivos `0600` fora do repositório.

---

## 3. Verificação Antes de Publicar

```bash
bash -n scripts/*.sh && shellcheck -x scripts/*.sh
ruff check . && ruff format --check .
pytest -q
```

Registre aqui as versões mínimas de Bash e Python dos servidores de destino e qualquer exceção aprovada a estes padrões.
