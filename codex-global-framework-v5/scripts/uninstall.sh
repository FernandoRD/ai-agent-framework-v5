#!/usr/bin/env bash
set -euo pipefail

# Pure Bash uninstaller for Codex Global Framework v5
# Zero Python required.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
HOME_DIR="$(cd "$HOME" && pwd -P)"

CODEX_HOME="${CODEX_HOME:-$HOME_DIR/.codex}"
SKILLS_HOME="${SKILLS_HOME:-$HOME_DIR/.agents/skills}"

while [ $# -gt 0 ]; do
    case "$1" in
        --codex-home)
            [ $# -ge 2 ] || { echo "Uso: $0 [--codex-home <dir>] [--skills-home <dir>]" >&2; exit 1; }
            CODEX_HOME="$2"
            shift 2
            ;;
        --skills-home)
            [ $# -ge 2 ] || { echo "Uso: $0 [--codex-home <dir>] [--skills-home <dir>]" >&2; exit 1; }
            SKILLS_HOME="$2"
            shift 2
            ;;
        *)
            echo "Opção desconhecida: $1" >&2
            exit 1
            ;;
    esac
done

CODEX_HOME="${CODEX_HOME/#\~/$HOME_DIR}"
SKILLS_HOME="${SKILLS_HOME/#\~/$HOME_DIR}"

ROLES=(
    "luna_explorer" "luna_worker" "terra_worker"
    "terra_reviewer" "sol_specialist" "sol_reviewer" "sol_critical"
)

SKILLS=("security-review" "code-review" "dependency-review" "documentation")

timestamp="$(date +%Y%m%d-%H%M%S-%N | cut -b1-21)"
backup_dir="$CODEX_HOME/backups/framework-v5-uninstall-$timestamp"
mkdir -p "$backup_dir"

agents_file="$CODEX_HOME/AGENTS.md"
config_file="$CODEX_HOME/config.toml"
hooks_file="$CODEX_HOME/hooks.json"

for f in "$agents_file" "$config_file" "$hooks_file"; do
    if [ -f "$f" ]; then
        cp "$f" "$backup_dir/$(basename "$f")"
    fi
done

if [ -f "$agents_file" ]; then
    cleaned="$(awk '
        /<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5/ { in_block=1; next }
        /<!-- CODEX-GLOBAL-FRAMEWORK:END v5/ { in_block=0; next }
        !in_block { print }
    ' "$agents_file" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"
    if [ -n "$cleaned" ]; then
        printf "%s\n" "$cleaned" > "$agents_file"
    else
        > "$agents_file"
    fi
fi

if [ -f "$config_file" ]; then
    cleaned="$(awk '
        /# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS/ { in_block=1; next }
        /# END CODEX GLOBAL FRAMEWORK V5 AGENTS/ { in_block=0; next }
        !in_block { print }
    ' "$config_file" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"
    if [ -n "$cleaned" ]; then
        printf "%s\n" "$cleaned" > "$config_file"
    else
        > "$config_file"
    fi
fi

for r in "${ROLES[@]}"; do
    layer="$CODEX_HOME/agent-configs/$r.toml"
    if [ -f "$layer" ]; then
        mkdir -p "$backup_dir/agent-configs"
        mv "$layer" "$backup_dir/agent-configs/$r.toml"
    fi
done

for s in "${SKILLS[@]}"; do
    skill_dir="$SKILLS_HOME/$s"
    if [ -d "$skill_dir" ]; then
        mkdir -p "$backup_dir/skills"
        mv "$skill_dir" "$backup_dir/skills/$s"
    fi
done

if [ -f "$hooks_file" ]; then
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json
with open('$hooks_file', 'r', encoding='utf-8-sig') as f:
    try: data = json.load(f)
    except Exception: data = None
if data and 'hooks' in data and 'UserPromptSubmit' in data['hooks']:
    groups = data['hooks']['UserPromptSubmit']
    data['hooks']['UserPromptSubmit'] = [g for g in groups if 'mandatory-router' not in json.dumps(g)]
    with open('$hooks_file', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')
"
    elif command -v jq >/dev/null 2>&1; then
        jq '
          if .hooks.UserPromptSubmit then
            .hooks.UserPromptSubmit |= [.[] | select(tostring | contains("mandatory-router") | not)]
          else . end
        ' "$hooks_file" > "$hooks_file.tmp" && mv "$hooks_file.tmp" "$hooks_file"
    fi
fi

for h in "$CODEX_HOME/hooks/mandatory-router.sh" "$CODEX_HOME/hooks/mandatory-router.ps1"; do
    if [ -f "$h" ]; then
        rm -f "$h"
    fi
done

echo "Framework v5 removed. Backup: $backup_dir"
