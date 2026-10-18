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
case "$CODEX_HOME" in /*) ;; *) CODEX_HOME="$PWD/$CODEX_HOME" ;; esac
case "$SKILLS_HOME" in /*) ;; *) SKILLS_HOME="$PWD/$SKILLS_HOME" ;; esac

ROLES=(
    "luna_explorer" "luna_worker" "terra_worker"
    "terra_reviewer" "sol_specialist" "sol_reviewer" "sol_critical"
)

SKILLS=("security-review" "code-review" "dependency-review" "documentation")

agents_file="$CODEX_HOME/AGENTS.md"
config_file="$CODEX_HOME/config.toml"
hooks_file="$CODEX_HOME/hooks.json"

# Reports unbalanced/nested/orphan markers: awk would otherwise drop the rest of the file.
markers_balanced() {
    awk -v b="$2" -v e="$3" '
        $0 ~ b { if (inb) bad=1; inb=1; next }
        $0 ~ e { if (!inb) bad=1; inb=0; next }
        END { exit (bad || inb) ? 1 : 0 }
    ' "$1"
}
check_markers() {
    if [ -f "$1" ] && ! markers_balanced "$1" "$2" "$3"; then
        echo "Unbalanced framework markers in $1; fix manually. No changes made." >&2
        exit 1
    fi
}
check_markers "$agents_file" '<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5' '<!-- CODEX-GLOBAL-FRAMEWORK:END v5'
check_markers "$config_file" '# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS' '# END CODEX GLOBAL FRAMEWORK V5 AGENTS'

# Plan hooks.json first: an invalid file or missing tooling aborts before any change.
HOOK_PY='
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8-sig") as f:
        data = json.load(f)
except ValueError as exc:
    raise SystemExit("invalid JSON: %s" % exc)
if not isinstance(data, dict):
    raise SystemExit("hooks.json root must be an object")
hooks = data.get("hooks")
if isinstance(hooks, dict) and isinstance(hooks.get("UserPromptSubmit"), list):
    hooks["UserPromptSubmit"] = [g for g in hooks["UserPromptSubmit"] if "mandatory-router" not in json.dumps(g)]
print(json.dumps(data, indent=2, ensure_ascii=False))
'
NEW_HOOKS=""
if [ -f "$hooks_file" ]; then
    if command -v python3 >/dev/null 2>&1; then
        NEW_HOOKS="$(python3 -c "$HOOK_PY" "$hooks_file")" \
            || { echo "Existing hooks.json is invalid; no changes made: $hooks_file" >&2; exit 1; }
    elif command -v jq >/dev/null 2>&1; then
        NEW_HOOKS="$(jq 'if (.hooks | type) == "object" and (.hooks.UserPromptSubmit | type) == "array" then
              .hooks.UserPromptSubmit |= [.[] | select(tostring | contains("mandatory-router") | not)]
            else . end' "$hooks_file")" \
            || { echo "Existing hooks.json is invalid; no changes made: $hooks_file" >&2; exit 1; }
    else
        echo "python3 or jq is required to edit $hooks_file; no changes made." >&2
        exit 1
    fi
fi

timestamp="$(date +%Y%m%d-%H%M%S-%N | cut -b1-21)"
backup_dir="$CODEX_HOME/backups/framework-v5-uninstall-$timestamp"
mkdir -p "$backup_dir"

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
    printf '%s\n' "$NEW_HOOKS" > "$hooks_file"
fi

for h in "$CODEX_HOME/hooks/mandatory-router.sh" "$CODEX_HOME/hooks/mandatory-router.ps1"; do
    if [ -f "$h" ]; then
        rm -f "$h"
    fi
done

echo "Framework v5 removed. Backup: $backup_dir"
