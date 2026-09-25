#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    echo "Erro: Python 3 não foi encontrado no PATH." >&2
    exit 1
fi

has_target=false
has_global=false
for arg in "$@"; do
    if [[ "$arg" == "--target" ]] || [[ "$arg" == --target=* ]]; then
        has_target=true
    elif [[ "$arg" == "--global" ]] || [[ "$arg" == "-g" ]]; then
        has_global=true
    fi
done

if [ "$has_target" = false ] && [ "$has_global" = false ] && [ "$#" -ge 1 ] && [[ "$1" != -* ]]; then
    target="$1"
    shift
    exec "$PYTHON_BIN" "$script_dir/install_core.py" --target "$target" "$@"
else
    exec "$PYTHON_BIN" "$script_dir/install_core.py" "$@"
fi
