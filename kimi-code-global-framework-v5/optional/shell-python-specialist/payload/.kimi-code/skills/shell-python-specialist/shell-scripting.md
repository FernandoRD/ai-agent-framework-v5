# Shell Script Robusto (Bash 4+, POSIX sh e fish)

## 1. Esqueleto Recomendado em Bash

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="${0##*/}"
APPLY=false
TARGET=""

log()  { printf '%s [%s] %s\n' "$(date '+%F %T')" "$SCRIPT_NAME" "$*" >&2; }
die()  { log "ERRO: $*"; exit 1; }

usage() {
    cat <<USAGE
Uso: $SCRIPT_NAME --target <caminho> [--apply]
  --target <caminho>  Diretório a processar
  --apply             Aplica as alterações (padrão: simulação)
USAGE
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --target) [ $# -ge 2 ] || die "--target exige um valor"; TARGET="$2"; shift 2 ;;
        --apply)  APPLY=true; shift ;;
        -h|--help) usage 0 ;;
        *) log "Opção desconhecida: $1"; usage 1 ;;
    esac
done
[ -n "$TARGET" ] || usage 1

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT

main() {
    if [ "$APPLY" = true ]; then
        log "Aplicando em $TARGET"
    else
        log "Simulação: nada será alterado em $TARGET"
    fi
}

main "$@"
```

Notas:
- `set -e` não cobre tudo: comandos em condições (`if`, `&&`, `||`), subshells em substituição de comando dentro de atribuições locais (`local x="$(cmd)"`) e funções chamadas em contexto condicional mascaram falhas. Separe `local x` de `x="$(cmd)"` quando o código de saída importar.
- `pipefail` faz o pipeline falhar se qualquer estágio falhar; cuidado com `grep` sem correspondência (saída 1) e com `head` fechando o pipe (SIGPIPE no produtor).
- Prefira `printf` a `echo` para dados arbitrários.

## 2. Aspas, Arrays e Expansões

```bash
# Errado: quebra em espaços e expande glob
rm $arquivo
# Certo
rm -- "$arquivo"

# Lista de argumentos segura
args=(--timeout 5 --retries 3)
[ "$verbose" = true ] && args+=(--verbose)
cmd "${args[@]}"

# Valores padrão e obrigatórios
: "${ZBX_SERVER:?defina ZBX_SERVER}"
porta="${PORTA:-10051}"
```

- Use `--` antes de caminhos vindos de entrada externa.
- Leia linhas com `while IFS= read -r linha; do ...; done < arquivo`; nunca `for linha in $(cat arquivo)`.
- Nunca use `eval` com dados externos; para mapear opções, use `case`.

## 3. Portabilidade: POSIX sh vs. Bash vs. fish

| Recurso | POSIX sh | Bash 4+ | fish |
|---|---|---|---|
| Arrays | não | `arr=(a b)` / `"${arr[@]}"` | listas nativas `set arr a b` |
| Teste | `[ ]` | `[[ ]]` | `test` / `[ ]` |
| `pipefail` | não garantido | `set -o pipefail` | `$pipestatus` |
| Arrays associativos | não | `declare -A` | não |
| Substituição de comando | `$(cmd)` | `$(cmd)` | `(cmd)` ou `$(cmd)` (fish 3.4+) |

- Scripts com `#!/bin/sh` precisam rodar em `dash`/`busybox ash`: valide com `shellcheck -s sh` e teste com `dash -n`.
- macOS traz Bash 3.2 em `/bin/bash`; se precisar de Bash 4+, documente a dependência ou mantenha compatibilidade.
- Em fish, prefira delegar a lógica para um script Bash/POSIX e manter o `.fish` como wrapper fino (`bash "$script_dir/script.sh" $argv`), para manter paridade de comportamento.

## 4. Concorrência, Lock e Timeouts

```bash
exec 9>"/run/lock/${SCRIPT_NAME}.lock"
flock -n 9 || die "outra instância já está em execução"

# Limite o tempo de comandos externos
timeout 10 curl -fsS --max-time 8 "https://api.exemplo.local/health"
```

- Em rotinas agendadas, sempre use lock e timeout: execuções sobrepostas são causa frequente de carga e de dados duplicados.
- Escrita atômica: gere em arquivo temporário no mesmo filesystem e use `mv` para substituir.

## 5. Validação Antes de Publicar

```bash
bash -n script.sh
shellcheck -x script.sh
shfmt -d -i 4 script.sh
bats tests/
```

- Corrija avisos do `shellcheck` em vez de suprimi-los; quando a supressão for necessária, use `# shellcheck disable=SCxxxx` na linha, com justificativa.
