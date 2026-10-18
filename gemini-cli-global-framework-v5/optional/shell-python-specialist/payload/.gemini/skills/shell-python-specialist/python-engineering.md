# Engenharia Python 3.10+ para Infraestrutura

## 1. Estrutura de CLI Recomendada

```python
#!/usr/bin/env python3
"""Coleta o estado de um serviço e imprime JSON."""
from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path

log = logging.getLogger(__name__)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--apply", action="store_true", help="aplica alterações (padrão: simulação)")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        stream=sys.stderr,
    )
    try:
        config = json.loads(args.config.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        log.error("configuração inválida: %s", exc)
        return 2
    json.dump({"items": len(config)}, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- Logs e diagnósticos em `stderr`; dados em `stdout`.
- `main()` retorna o código de saída e aceita `argv`, o que facilita testes.

## 2. Subprocessos e Rede

```python
import subprocess

result = subprocess.run(
    ["systemctl", "is-active", "zabbix-agent2"],
    capture_output=True, text=True, timeout=10, check=False,
)
ativo = result.returncode == 0
```

- Nunca `shell=True` com entrada externa; passe lista de argumentos.
- Toda chamada HTTP com timeout explícito (`requests.get(url, timeout=(3, 10))` ou `httpx.Client(timeout=10)`), verificação TLS ativa e tratamento de status (`raise_for_status()`).
- Retentativas com backoff exponencial e limite, apenas para operações idempotentes.

## 3. Ambientes, Dependências e Empacotamento

- Ambiente isolado por projeto: `python3 -m venv .venv` ou `uv venv`; nunca instale dependências no Python do sistema com `sudo pip`.
- Declare metadados e dependências em `pyproject.toml` (`requires-python = ">=3.10"`); fixe versões para produção (`uv lock`, `pip-tools` ou `requirements.txt` com hashes).
- Scripts distribuídos para servidores sem acesso à internet: prefira a biblioteca padrão ou empacote as dependências (wheelhouse) e documente o procedimento.

## 4. Qualidade e Testes

```bash
ruff check . && ruff format --check .
mypy --strict pacote/
pytest -q
```

- Use type hints nas interfaces públicas; `dataclasses` ou `TypedDict` para estruturas de dados.
- Testes com `pytest`, `tmp_path` para arquivos e `monkeypatch`/`unittest.mock` para rede e subprocessos; nenhum teste deve depender de produção.
- Tratamento de datas com `datetime` timezone-aware (`datetime.now(timezone.utc)`).

## 5. Concorrência

- I/O de rede em lote (ex.: consultar centenas de hosts): `concurrent.futures.ThreadPoolExecutor` com `max_workers` limitado ou `asyncio` com semáforo.
- CPU-bound: `ProcessPoolExecutor`.
- Sempre limite a concorrência para não sobrecarregar a API ou o alvo monitorado.
