#!/usr/bin/env bash
set -euo pipefail

# Pure Bash installer for framework files (project or global home)
# Default: audit-only, never overwrites conflicts. Zero Python required.

TARGET=""
IS_GLOBAL=false
APPLY=false
OPTIONAL_SPECS=()
ALL_KNOWN_SPECS=(
    "zabbix-specialist"
    "grafana-specialist"
    "ansible-specialist"
    "loki-specialist"
    "prometheus-specialist"
    "netops-specialist"
    "sre-incident-specialist"
    "database-tuning-specialist"
)

add_specialist() {
    local spec="$1"
    if [ "${#OPTIONAL_SPECS[@]}" -gt 0 ]; then
        for s in "${OPTIONAL_SPECS[@]}"; do
            if [ "$s" = "$spec" ]; then return 0; fi
        done
    fi
    OPTIONAL_SPECS+=("$spec")
}

usage() {
    echo "Uso: $0 --target <caminho> [--apply] [--with-<especialista>] [--with-all-specialists]" >&2
    echo "     $0 --global [--apply] [--with-<especialista>] [--with-all-specialists]" >&2
    echo "     $0 <caminho> [--apply] [--with-<especialista>] [--with-all-specialists]" >&2
    echo "Especialistas disponíveis: ${ALL_KNOWN_SPECS[*]}" >&2
    exit 1
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            [ $# -ge 2 ] || usage
            TARGET="$2"
            shift 2
            ;;
        --target=*)
            TARGET="${1#--target=}"
            shift
            ;;
        --global|-g)
            IS_GLOBAL=true
            shift
            ;;
        --apply)
            APPLY=true
            shift
            ;;
        --with-zabbix-specialist)
            add_specialist "zabbix-specialist"
            shift
            ;;
        --with-grafana-specialist)
            add_specialist "grafana-specialist"
            shift
            ;;
        --with-ansible-specialist)
            add_specialist "ansible-specialist"
            shift
            ;;
        --with-loki-specialist)
            add_specialist "loki-specialist"
            shift
            ;;
        --with-prometheus-specialist)
            add_specialist "prometheus-specialist"
            shift
            ;;
        --with-netops-specialist)
            add_specialist "netops-specialist"
            shift
            ;;
        --with-sre-specialist|--with-sre-incident-specialist)
            add_specialist "sre-incident-specialist"
            shift
            ;;
        --with-db-tuning-specialist|--with-database-tuning-specialist)
            add_specialist "database-tuning-specialist"
            shift
            ;;
        --with-all-specialists)
            for s in "${ALL_KNOWN_SPECS[@]}"; do
                add_specialist "$s"
            done
            shift
            ;;
        -*)
            echo "Erro: Opção desconhecida: $1" >&2
            usage
            ;;
        *)
            if [ -z "$TARGET" ] && [ "$IS_GLOBAL" = false ]; then
                TARGET="$1"
                shift
            else
                echo "Erro: Argumento inesperado: $1" >&2
                usage
            fi
            ;;
    esac
done

if [ -z "$TARGET" ] && [ "$IS_GLOBAL" = false ]; then
    usage
fi

HOME_DIR="$(cd "$HOME" && pwd -P)"

# Resolve TARGET path
if [ "$IS_GLOBAL" = true ]; then
    if [ -n "$TARGET" ]; then
        TARGET="${TARGET/#\~/$HOME_DIR}"
        mkdir -p "$TARGET" 2>/dev/null || true
        TARGET="$(cd "$TARGET" 2>/dev/null && pwd -P || echo "$TARGET")"
    else
        TARGET="$HOME_DIR"
    fi
else
    TARGET="${TARGET/#\~/$HOME_DIR}"
    case "$TARGET" in
        /*) ;;
        *) TARGET="$(pwd)/$TARGET" ;;
    esac
    if [ "$TARGET" = "$HOME_DIR" ]; then
        IS_GLOBAL=true
    fi
fi

# Safety check: refuse root
if [ "$TARGET" = "/" ]; then
    echo "Erro: Recusando instalar no caminho raiz '/'." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"

PAYLOAD_DIRS=("$PACKAGE_DIR/payload")
if [ "${#OPTIONAL_SPECS[@]}" -gt 0 ]; then
    for spec in "${OPTIONAL_SPECS[@]}"; do
        opt_payload="$PACKAGE_DIR/optional/$spec/payload"
        [ -d "$opt_payload" ] || { echo "Pacote opcional não encontrado: $opt_payload" >&2; exit 1; }
        PAYLOAD_DIRS+=("$opt_payload")
    done
fi

# Discover tool dot-directory in primary payload (e.g. .gemini, .claude, .cursor)
TOOL_DOT_DIR=""
for item in "${PAYLOAD_DIRS[0]}"/.*; do
    if [ -d "$item" ]; then
        base="$(basename "$item")"
        if [ "$base" != "." ] && [ "$base" != ".." ]; then
            TOOL_DOT_DIR="$base"
            break
        fi
    fi
done

check_chain_for_symlinks() {
    local check_path="$1"
    local cur="$check_path"
    while [ -n "$cur" ] && [ "$cur" != "/" ] && [ "$cur" != "." ]; do
        if [ -L "$cur" ]; then
            return 0
        fi
        local parent
        parent="$(dirname "$cur")"
        [ "$parent" = "$cur" ] && break
        cur="$parent"
    done
    return 1
}

check_parent_invalid() {
    local check_path="$1"
    local cur
    cur="$(dirname "$check_path")"
    while [ -n "$cur" ] && [ "$cur" != "/" ] && [ "$cur" != "." ]; do
        if [ -e "$cur" ] && [ ! -d "$cur" ]; then
            return 0
        fi
        local parent
        parent="$(dirname "$cur")"
        [ "$parent" = "$cur" ] && break
        cur="$parent"
    done
    return 1
}

ERRORS=()
PENDING_SOURCES=()
PENDING_DESTS=()

for payload in "${PAYLOAD_DIRS[@]}"; do
    [ -d "$payload" ] || { echo "Pacote opcional não encontrado: $payload" >&2; exit 1; }

    # Find all files recursively in deterministic sorted order
    while IFS= read -r -d '' source_file; do
        if [ -L "$source_file" ]; then
            ERRORS+=("Link no pacote: $source_file")
            continue
        fi
        if [ ! -f "$source_file" ]; then
            continue
        fi

        source_rel="${source_file#$payload/}"
        first_part="${source_rel%%/*}"

        if [ "$IS_GLOBAL" = true ] && [ -n "$TOOL_DOT_DIR" ] && [[ "$first_part" != .* ]]; then
            dest="$TARGET/$TOOL_DOT_DIR/$source_rel"
        else
            dest="$TARGET/$source_rel"
        fi

        if check_chain_for_symlinks "$dest"; then
            ERRORS+=("Link no destino: $dest")
            continue
        fi

        if check_parent_invalid "$dest"; then
            ERRORS+=("Pai não é diretório: $dest")
            continue
        fi

        if [ -e "$dest" ]; then
            if [ ! -f "$dest" ] || ! cmp -s "$source_file" "$dest"; then
                ERRORS+=("Conflito, preservar e mesclar manualmente: $dest")
            else
                echo "IDÊNTICO $dest"
            fi
        else
            PENDING_SOURCES+=("$source_file")
            PENDING_DESTS+=("$dest")
            echo "CRIAR $dest"
        fi
    done < <(find "$payload" -type f -print0 | sort -z)
done

if [ "${#ERRORS[@]}" -gt 0 ]; then
    for err in "${ERRORS[@]}"; do
        echo "$err"
    done
    exit 1
fi

if [ "$APPLY" = false ]; then
    echo "Auditoria: ${#PENDING_SOURCES[@]} arquivo(s) novo(s); nenhuma alteração."
    exit 0
fi

# Apply changes with verification
for i in "${!PENDING_SOURCES[@]}"; do
    src="${PENDING_SOURCES[$i]}"
    dest="${PENDING_DESTS[$i]}"

    if check_chain_for_symlinks "$dest"; then
        echo "Destino tornou-se link; instalação interrompida: $dest" >&2
        exit 1
    fi

    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    # Non-destructive copy (fails if destination already exists)
    if ( set -C; cp "$src" "$dest" ) 2>/dev/null; then
        :
    else
        echo "Falha ao criar arquivo: $dest" >&2
        exit 1
    fi
done

echo "Instalados ${#PENDING_SOURCES[@]} arquivo(s). Configurações existentes preservadas."
