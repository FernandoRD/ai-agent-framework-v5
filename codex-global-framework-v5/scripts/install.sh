#!/usr/bin/env bash
set -euo pipefail

# Pure Bash installer for Codex Global Framework v5.
# Two phases: (1) compute the complete plan and abort on any conflict without
# touching the disk; (2) apply. --audit-only stops after phase 1.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
HOME_DIR="$(cd "$HOME" && pwd -P)"

TARGET=""
IS_GLOBAL=false
CODEX_HOME="${CODEX_HOME:-$HOME_DIR/.codex}"
SKILLS_HOME="${SKILLS_HOME:-$HOME_DIR/.agents/skills}"
NO_HOOK=false
AUDIT_ONLY=false
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
    "proxmox-specialist"
    "shell-python-specialist"
    "docker-kubernetes-specialist"
)

add_specialist() {
    local spec="$1" s
    if [ "${#OPTIONAL_SPECS[@]}" -gt 0 ]; then
        for s in "${OPTIONAL_SPECS[@]}"; do
            if [ "$s" = "$spec" ]; then return 0; fi
        done
    fi
    OPTIONAL_SPECS+=("$spec")
}

usage_text() {
    cat <<'EOF'
Uso: install.sh [opções]

Sem --audit-only, o instalador APLICA as alterações (com backup). O plano
completo é calculado antes; qualquer conflito aborta sem alterar arquivos.

Opções gerais:
  --target <dir>      Diretório de destino (instalação por projeto)
  --global, -g        Instalação no ambiente global do usuário (~/.codex)
  --audit-only        Apenas audita: lista ações e conflitos, sem escrever
  --apply             Aceito por compatibilidade; é o comportamento padrão (no-op)
  --no-hook           Não instala o hook de roteamento obrigatório
  --codex-home <dir>  Sobrescreve o diretório ~/.codex
  --skills-home <dir> Sobrescreve o diretório ~/.agents/skills
  -h, --help          Exibe esta mensagem de ajuda

Especialistas de domínio opcionais:
  --with-zabbix-specialist          Instala o especialista Zabbix
  --with-grafana-specialist         Instala o especialista Grafana (Grafana 12 / HTML Graphics)
  --with-ansible-specialist         Instala o especialista Ansible (playbooks/roles/vault)
  --with-loki-specialist            Instala o especialista Loki (LogQL/Promtail/Alloy)
  --with-prometheus-specialist      Instala o especialista Prometheus (PromQL/exporters/alerting)
  --with-netops-specialist          Instala o especialista NetOps (SNMP/BGP/OSPF/VLANs)
  --with-sre-incident-specialist    Instala o especialista SRE Incident (Incident Command/SLOs)
                                    (alias: --with-sre-specialist)
  --with-database-tuning-specialist Instala o especialista Database Tuning (PostgreSQL/queries/locks)
                                    (alias: --with-db-tuning-specialist)
  --with-proxmox-specialist         Instala o especialista Proxmox VE (8.x/9.x, PBS, Ceph, ZFS, SDN)
  --with-shell-python-specialist    Instala o especialista Shell & Python (Bash/POSIX sh/Python 3.10+)
  --with-docker-kubernetes-specialist
                                    Instala o especialista Docker & Kubernetes (Compose/K8s/Helm)
  --with-all-specialists            Instala todos os 11 especialistas de domínio acima
EOF
}

usage() {
    if [ "${1:-0}" -eq 0 ]; then usage_text; else usage_text >&2; fi
    exit "${1:-0}"
}

need_value() {
    if [ "$2" -lt 2 ]; then
        echo "A opção $1 requer um valor." >&2
        usage 1
    fi
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage 0 ;;
        --target)
            need_value "$1" $#
            TARGET="$2"
            shift 2
            ;;
        --target=*)
            TARGET="${1#--target=}"
            shift
            ;;
        --global|-g) IS_GLOBAL=true; shift ;;
        --codex-home)
            need_value "$1" $#
            CODEX_HOME="$2"
            shift 2
            ;;
        --skills-home)
            need_value "$1" $#
            SKILLS_HOME="$2"
            shift 2
            ;;
        --no-hook) NO_HOOK=true; shift ;;
        --audit-only) AUDIT_ONLY=true; shift ;;
        --apply) APPLY=true; shift ;;
        --with-zabbix-specialist) add_specialist "zabbix-specialist"; shift ;;
        --with-grafana-specialist) add_specialist "grafana-specialist"; shift ;;
        --with-ansible-specialist) add_specialist "ansible-specialist"; shift ;;
        --with-loki-specialist) add_specialist "loki-specialist"; shift ;;
        --with-prometheus-specialist) add_specialist "prometheus-specialist"; shift ;;
        --with-netops-specialist) add_specialist "netops-specialist"; shift ;;
        --with-sre-specialist|--with-sre-incident-specialist) add_specialist "sre-incident-specialist"; shift ;;
        --with-db-tuning-specialist|--with-database-tuning-specialist) add_specialist "database-tuning-specialist"; shift ;;
        --with-proxmox-specialist) add_specialist "proxmox-specialist"; shift ;;
        --with-shell-python-specialist) add_specialist "shell-python-specialist"; shift ;;
        --with-docker-kubernetes-specialist) add_specialist "docker-kubernetes-specialist"; shift ;;
        --with-all-specialists)
            for s in "${ALL_KNOWN_SPECS[@]}"; do add_specialist "$s"; done
            shift
            ;;
        -*)
            echo "Opção desconhecida: $1" >&2
            usage 1
            ;;
        *)
            if [ -z "$TARGET" ] && [ "$IS_GLOBAL" = false ]; then
                TARGET="$1"
                shift
            else
                echo "Argumento inesperado: $1" >&2
                usage 1
            fi
            ;;
    esac
done

if [ "$APPLY" = true ] && [ "$AUDIT_ONLY" = true ]; then
    echo "--apply e --audit-only são mutuamente exclusivos." >&2
    exit 1
fi

# Expand ~, make absolute, drop trailing slashes (no symlink resolution).
norm_path() {
    local p="$1"
    case "$p" in
        "~") p="$HOME_DIR" ;;
        "~/"*) p="$HOME_DIR/${p#"~/"}" ;;
    esac
    case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
    if command -v realpath >/dev/null 2>&1; then
        p="$(realpath -sm -- "$p" 2>/dev/null || printf '%s' "$p")"
    fi
    while [ "${#p}" -gt 1 ] && [ "${p%/}" != "$p" ]; do p="${p%/}"; done
    printf '%s' "$p"
}

ROLES=(
    "luna_explorer"
    "luna_worker"
    "terra_worker"
    "terra_reviewer"
    "sol_specialist"
    "sol_reviewer"
    "sol_critical"
)

declare -A ROLE_DESCRIPTIONS=(
    ["luna_explorer"]="Low-cost read-only explorer for targeted codebase mapping and compact context capsules."
    ["luna_worker"]="Efficient worker for narrow, well-specified, low-risk implementation and mechanical tasks."
    ["terra_worker"]="Balanced implementation worker for normal engineering changes across related files."
    ["terra_reviewer"]="Independent read-only reviewer for correctness, regressions, and missing tests."
    ["sol_specialist"]="High-capability specialist for difficult implementation and ambiguous multi-step reasoning."
    ["sol_reviewer"]="Independent read-only reviewer for complex or high-risk engineering changes."
    ["sol_critical"]="Read-only critical analyst for security boundaries, data loss, concurrency, and production incidents."
)

LEGACY_SKILLS=(
    "task-router" "complexity-score" "deep-analysis" "implementation"
    "testing" "refactor" "final-review" "model-usage-report"
    "security-review" "code-review" "dependency-review" "documentation"
)
CURRENT_SKILLS=("security-review" "code-review" "dependency-review" "documentation")

# A legacy Skill is moved only when SKILL.md proves it belongs to the framework.
FRAMEWORK_SKILL_RE='(luna|terra|sol)_(explorer|worker|reviewer|specialist|critical)|CODEX-GLOBAL-FRAMEWORK|Codex Global Framework|task-router'

FINDINGS=()
CONFLICTS=()
NOTICES=()

PLAN_OPT_SRC=()
PLAN_OPT_DEST=()
OPT_REUSED=0

check_chain_for_symlinks() {
    local cur="$1" parent
    while [ -n "$cur" ] && [ "$cur" != "/" ] && [ "$cur" != "." ]; do
        if [ -L "$cur" ]; then return 0; fi
        parent="$(dirname "$cur")"
        [ "$parent" = "$cur" ] && break
        cur="$parent"
    done
    return 1
}

# Reports unbalanced/nested/orphan markers: awk would otherwise drop the rest of the file.
markers_balanced() {
    awk -v b="$2" -v e="$3" '
        $0 ~ b { if (inb) bad=1; inb=1; next }
        $0 ~ e { if (!inb) bad=1; inb=0; next }
        END { exit (bad || inb) ? 1 : 0 }
    ' "$1"
}

same_tree() {
    [ -z "$(find "$1" "$2" -type l -print -quit)" ] && diff -rq "$1" "$2" >/dev/null 2>&1
}

# Same directory even through symlinks (string comparison is not enough).
same_dir() {
    [ "$1" = "$2" ] || [ "$1" -ef "$2" ]
}

is_framework_skill() {
    [ -f "$1/SKILL.md" ] && grep -qE "$FRAMEWORK_SKILL_RE" "$1/SKILL.md"
}

# plan_optional <src_root> <dest_root>: fills PLAN_OPT_* and CONFLICTS; writes nothing.
plan_optional() {
    local src_root="$1" dest_root="$2" src_file rel dest
    if [ ! -d "$src_root" ] || [ -L "$src_root" ]; then
        CONFLICTS+=("Optional package missing or link: $src_root")
        return 0
    fi
    while IFS= read -r -d '' src_file; do
        if [ -L "$src_file" ]; then
            CONFLICTS+=("Optional package link: $src_file")
            continue
        fi
        rel="${src_file#"$src_root"/}"
        dest="$dest_root/$rel"
        if check_chain_for_symlinks "$dest"; then
            CONFLICTS+=("Optional destination link: $dest")
        elif [ -e "$dest" ]; then
            if [ -f "$dest" ] && cmp -s "$src_file" "$dest"; then
                OPT_REUSED=$((OPT_REUSED + 1))
            else
                CONFLICTS+=("Optional package conflict: $dest")
            fi
        else
            PLAN_OPT_SRC+=("$src_file")
            PLAN_OPT_DEST+=("$dest")
        fi
    done < <(find "$src_root" \( -type f -o -type l \) -print0 | sort -z)
}

# Exclusive create: noclobber makes the redirection fail if dest appeared meanwhile.
apply_optional() {
    local i s d count=0
    for i in "${!PLAN_OPT_SRC[@]}"; do
        s="${PLAN_OPT_SRC[$i]}"
        d="${PLAN_OPT_DEST[$i]}"
        mkdir -p "$(dirname "$d")"
        if ! ( set -C; cat "$s" > "$d" ); then
            echo "Falha ao instalar arquivo opcional: $d" >&2
            exit 1
        fi
        [ -x "$s" ] && chmod 0755 "$d"
        count=$((count + 1))
    done
    echo "Optional specialists installed: $count file(s), $OPT_REUSED identical reused."
}

finish_plan() {
    local c
    if [ "${#CONFLICTS[@]}" -gt 0 ]; then
        echo "" >&2
        echo "Conflicts detected; no files were changed:" >&2
        for c in "${CONFLICTS[@]}"; do echo "- $c" >&2; done
        exit 1
    fi
    if [ "${#NOTICES[@]}" -gt 0 ]; then
        for c in "${NOTICES[@]}"; do echo "NOTE: $c"; done
    fi
    if [ "$AUDIT_ONLY" = true ]; then
        echo "Audit-only mode: no files changed."
        exit 0
    fi
}

build_agents() {
    local existing="" block
    if [ -f "$1" ]; then
        existing="$(awk '
            /<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN/ { in_block=1; next }
            /<!-- CODEX-GLOBAL-FRAMEWORK:END/ { in_block=0; next }
            !in_block { print }
        ' "$1")"
    fi
    block="$(cat "$PACKAGE_DIR/.codex/AGENTS.md")"
    if [ -n "$existing" ]; then
        printf '%s\n\n%s\n' "$existing" "$block"
    else
        printf '%s\n' "$block"
    fi
}

# -----------------
# PROJECT INSTALL
# -----------------
IS_PROJECT=false
if [ -n "$TARGET" ]; then
    TARGET="$(norm_path "$TARGET")"
    if [ "$IS_GLOBAL" = false ] && [ "$TARGET" != "$HOME_DIR" ]; then
        IS_PROJECT=true
    fi
fi

if [ "$IS_PROJECT" = true ]; then
    [ -d "$TARGET" ] || { echo "Target directory does not exist or is not a directory: $TARGET" >&2; exit 1; }
    agents_file="$TARGET/AGENTS.md"
    echo "Codex Framework v5 project preflight"
    echo "Project target: $TARGET"
    echo "Agents file: $agents_file"
    if [ -f "$agents_file" ]; then
        if grep -q "CODEX-GLOBAL-FRAMEWORK:BEGIN" "$agents_file"; then
            echo "- legacy/existing AGENTS: replace marked framework block"
            markers_balanced "$agents_file" '<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN' '<!-- CODEX-GLOBAL-FRAMEWORK:END' \
                || CONFLICTS+=("Unbalanced framework markers in $agents_file; fix manually")
        else
            echo "- existing AGENTS: append framework block preserving personal text"
        fi
    else
        echo "- new AGENTS: create AGENTS.md with framework block"
    fi

    if [ "${#OPTIONAL_SPECS[@]}" -gt 0 ]; then
        for spec in "${OPTIONAL_SPECS[@]}"; do
            plan_optional "$PACKAGE_DIR/optional/$spec" "$TARGET"
        done
        echo "- optional specialists: ${#PLAN_OPT_SRC[@]} file(s) to create, $OPT_REUSED identical"
    fi

    finish_plan

    if [ -f "$agents_file" ]; then
        new_agents="$(build_agents "$agents_file")"
    else
        new_agents="$(build_agents /dev/null)"
    fi
    printf '%s\n' "$new_agents" > "$agents_file"
    [ "${#OPTIONAL_SPECS[@]}" -gt 0 ] && apply_optional
    printf '\nCodex Framework v5 installed for project: %s\n' "$TARGET"
    exit 0
fi

# -----------------
# GLOBAL INSTALL
# -----------------
CODEX_HOME="$(norm_path "$CODEX_HOME")"
SKILLS_HOME="$(norm_path "$SKILLS_HOME")"

if [ "$CODEX_HOME" = "/" ] || [ "$SKILLS_HOME" = "/" ]; then
    echo "Refusing unsafe target path." >&2
    exit 1
fi

hooks_file="$CODEX_HOME/hooks.json"
agents_file="$CODEX_HOME/AGENTS.md"
override_file="$CODEX_HOME/AGENTS.override.md"
config_file="$CODEX_HOME/config.toml"
standalone_dir="$CODEX_HOME/agents"
layer_dir="$CODEX_HOME/agent-configs"
legacy_codex_skills="$CODEX_HOME/skills"

# ---- Plan: findings ----
case "$CODEX_HOME" in
    *[[:cntrl:]]*) CONFLICTS+=("CODEX_HOME contains control characters (refusing): cannot be written safely to hooks.json") ;;
esac
if [ -f "$override_file" ] && [ -s "$override_file" ]; then
    FINDINGS+=("shadow: manual review required: $override_file")
fi
if [ -f "$agents_file" ]; then
    if grep -qE "CODEX-GLOBAL-FRAMEWORK:BEGIN v[1-4]" "$agents_file"; then
        FINDINGS+=("legacy AGENTS: replace marked framework block: $agents_file")
    fi
    if grep -iq "task-router" "$agents_file" && ! grep -q "CODEX-GLOBAL-FRAMEWORK:BEGIN" "$agents_file"; then
        FINDINGS+=("unmarked AGENTS: preserve and warn for manual review: $agents_file")
    fi
    markers_balanced "$agents_file" '<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN' '<!-- CODEX-GLOBAL-FRAMEWORK:END' \
        || CONFLICTS+=("Unbalanced framework markers in $agents_file; fix manually")
fi
if [ -f "$config_file" ]; then
    markers_balanced "$config_file" '# BEGIN CODEX GLOBAL FRAMEWORK V[345] AGENTS' '# END CODEX GLOBAL FRAMEWORK V[345] AGENTS' \
        || CONFLICTS+=("Unbalanced framework markers in $config_file; fix manually")
    for r in "${ROLES[@]}"; do
        if grep -qE "^[[:space:]]*\[agents\.$r\][[:space:]]*$" "$config_file"; then
            FINDINGS+=("agent registration: normalize to one v5 block: $config_file [$r]")
        fi
    done
fi
if [ -d "$standalone_dir" ]; then
    for f in "$standalone_dir"/*.toml; do
        [ -f "$f" ] || continue
        base="$(basename "$f" .toml)"
        for r in "${ROLES[@]}"; do
            if [ "$base" = "$r" ]; then
                FINDINGS+=("standalone agent: backup; register explicitly: $f")
                break
            fi
        done
    done
fi

# ---- Plan: Skills ----
SKILL_INSTALL=()
LEGACY_MOVE_PATH=()
LEGACY_MOVE_LABEL=()

is_current_skill() {
    local c
    for c in "${CURRENT_SKILLS[@]}"; do [ "$c" = "$1" ] && return 0; done
    return 1
}

for name in "${CURRENT_SKILLS[@]}"; do
    src_skill="$PACKAGE_DIR/.agents/skills/$name"
    dest_skill="$SKILLS_HOME/$name"
    if [ -L "$dest_skill" ]; then
        CONFLICTS+=("Skill is a link (refusing): $dest_skill")
    elif [ -e "$dest_skill" ]; then
        if [ -d "$dest_skill" ] && same_tree "$src_skill" "$dest_skill"; then
            FINDINGS+=("Skill v5 identical: reuse: $dest_skill")
        else
            CONFLICTS+=("Skill conflict (content differs from v5; merge manually): $dest_skill")
        fi
    else
        SKILL_INSTALL+=("$name")
        FINDINGS+=("Skill v5: install: $dest_skill")
    fi
done

plan_legacy_skill() {
    local root="$1" label="$2" name="$3" path
    path="$root/$name"
    [ -e "$path" ] || [ -L "$path" ] || return 0
    if [ -L "$path" ] || [ ! -d "$path" ]; then
        NOTICES+=("legacy Skill name is a link or not a directory; left intact: $path")
    elif { is_current_skill "$name" && same_tree "$PACKAGE_DIR/.agents/skills/$name" "$path"; } || is_framework_skill "$path"; then
        LEGACY_MOVE_PATH+=("$path")
        LEGACY_MOVE_LABEL+=("$label/$name")
        FINDINGS+=("legacy Skill: move framework Skill to backup: $path")
    else
        NOTICES+=("Skill '$name' does not look like a framework Skill; left intact: $path")
    fi
}

if ! same_dir "$legacy_codex_skills" "$SKILLS_HOME"; then
    for name in "${LEGACY_SKILLS[@]}"; do
        plan_legacy_skill "$legacy_codex_skills" "legacy-codex-skills" "$name"
    done
fi
for name in "${LEGACY_SKILLS[@]}"; do
    is_current_skill "$name" && continue
    plan_legacy_skill "$SKILLS_HOME" "user-skills" "$name"
done

# ---- Plan: optional specialists ----
if [ "${#OPTIONAL_SPECS[@]}" -gt 0 ]; then
    for spec in "${OPTIONAL_SPECS[@]}"; do
        plan_optional "$PACKAGE_DIR/optional/$spec/.agents/skills/$spec" "$SKILLS_HOME/$spec"
    done
    FINDINGS+=("optional specialists: ${#PLAN_OPT_SRC[@]} file(s) to create, $OPT_REUSED identical")
fi

# ---- Plan: hooks.json ----
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

# Single-quote for sh, then the caller JSON-escapes.
shell_quote() {
    local s="${1//\'/\'\\\'\'}"
    printf "'%s'" "$s"
}

HOOK_PY='
import json, sys
path, cmd, win = sys.argv[1:4]
try:
    with open(path, encoding="utf-8-sig") as f:
        data = json.load(f)
except ValueError as exc:
    raise SystemExit("invalid JSON: %s" % exc)
if not isinstance(data, dict):
    raise SystemExit("hooks.json root must be an object")
hooks = data.setdefault("hooks", {})
if not isinstance(hooks, dict):
    raise SystemExit("hooks.json: \"hooks\" must be an object")
ups = hooks.setdefault("UserPromptSubmit", [])
if not isinstance(ups, list):
    raise SystemExit("hooks.json: \"UserPromptSubmit\" must be an array")
ups[:] = [g for g in ups if "mandatory-router" not in json.dumps(g)]
entry = {"type": "command", "command": cmd, "timeout": 5, "statusMessage": "Applying global routing policy"}
if win:
    entry["commandWindows"] = win
ups.append({"hooks": [entry]})
print(json.dumps(data, indent=2, ensure_ascii=False))
'

HOOK_JQ='
if type != "object" then error("hooks.json root must be an object") else . end
| if has("hooks") then . else .hooks = {} end
| if (.hooks | type) != "object" then error("\"hooks\" must be an object") else . end
| if (.hooks | has("UserPromptSubmit")) then . else .hooks.UserPromptSubmit = [] end
| if (.hooks.UserPromptSubmit | type) != "array" then error("\"UserPromptSubmit\" must be an array") else . end
| .hooks.UserPromptSubmit = ([.hooks.UserPromptSubmit[] | select(tostring | contains("mandatory-router") | not)]
    + [{hooks: [{type: "command", command: $cmd, timeout: 5, statusMessage: "Applying global routing policy"}
    + (if $win != "" then {commandWindows: $win} else {} end)]}])
'

# commandWindows is derived only from a WSL drive mount (/mnt/<x>/...; assumes the default automount root); otherwise empty.
win_hook_command() {
    case "$1" in
        /mnt/[a-zA-Z]/*)
            local rest="${1#/mnt/?/}" drive="${1:5:1}"
            printf 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%s:\\%s\\hooks\\mandatory-router.ps1"' "${drive^^}" "${rest//\//\\}"
            ;;
    esac
}

NEW_HOOKS=""
if [ "$NO_HOOK" = false ]; then
    hook_cmd="sh $(shell_quote "$CODEX_HOME/hooks/mandatory-router.sh")"
    # commandWindows is derived only from a WSL drive mount (/mnt/<x>/...); otherwise it is omitted.
    hook_win="$(win_hook_command "$CODEX_HOME")"
    win_json=""
    if [ -n "$hook_win" ]; then
        win_json="$(printf ',\n            "commandWindows": "%s"' "$(json_escape "$hook_win")")"
    fi
    if [ ! -e "$hooks_file" ]; then
        NEW_HOOKS="$(printf '{\n  "description": "User hooks.",\n  "hooks": {\n    "UserPromptSubmit": [\n      {\n        "hooks": [\n          {\n            "type": "command",\n            "command": "%s"%s,\n            "timeout": 5,\n            "statusMessage": "Applying global routing policy"\n          }\n        ]\n      }\n    ]\n  }\n}' \
            "$(json_escape "$hook_cmd")" "$win_json")"
    elif [ ! -f "$hooks_file" ]; then
        CONFLICTS+=("hooks.json is not a regular file: $hooks_file")
    elif command -v python3 >/dev/null 2>&1; then
        NEW_HOOKS="$(python3 -c "$HOOK_PY" "$hooks_file" "$hook_cmd" "$hook_win")" \
            || CONFLICTS+=("Existing hooks.json is invalid or unexpected; no changes made: $hooks_file")
    elif command -v jq >/dev/null 2>&1; then
        NEW_HOOKS="$(jq --arg cmd "$hook_cmd" --arg win "$hook_win" "$HOOK_JQ" "$hooks_file")" \
            || CONFLICTS+=("Existing hooks.json is invalid or unexpected; no changes made: $hooks_file")
    else
        CONFLICTS+=("python3 or jq is required to merge the existing $hooks_file; install one or use --no-hook")
    fi
    if [ -f "$hooks_file" ] && grep -q "mandatory-router" "$hooks_file"; then
        FINDINGS+=("routing hook: replace framework hook: $hooks_file")
    fi
fi

echo "Codex Global Framework v5 preflight"
echo "Codex home: $CODEX_HOME"
echo "Skills home: $SKILLS_HOME"
if [ "${#FINDINGS[@]}" -gt 0 ]; then
    for f in "${FINDINGS[@]}"; do echo "- $f"; done
else
    echo "No v3/v4 residue detected."
fi

finish_plan

# ---- Compute new file contents (still no writes) ----
NEW_AGENTS="$(build_agents "$agents_file")"

new_config=""
if [ -f "$config_file" ]; then
    new_config="$(awk '
        /# BEGIN CODEX GLOBAL FRAMEWORK V[345] AGENTS/ { in_block=1; next }
        /# END CODEX GLOBAL FRAMEWORK V[345] AGENTS/ { in_block=0; next }
        !in_block { print }
    ' "$config_file")"
    for r in "${ROLES[@]}"; do
        new_config="$(printf '%s\n' "$new_config" | awk -v role="$r" '
            $0 ~ "^[[:space:]]*\\[agents\\." role "\\]" { in_agent=1; next }
            in_agent && /^[[:space:]]*\[/ { in_agent=0 }
            !in_agent { print }
        ')"
    done
fi
NEW_CONFIG="$(
    if [ -n "$new_config" ]; then
        printf '%s\n\n' "$new_config"
    fi
    printf '# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS\n'
    for r in "${ROLES[@]}"; do
        printf '\n[agents.%s]\ndescription = "%s"\nconfig_file = "agent-configs/%s.toml"\n' \
            "$r" "${ROLE_DESCRIPTIONS[$r]}" "$r"
    done
    printf '\n# END CODEX GLOBAL FRAMEWORK V5 AGENTS\n'
)"

# ---- Apply ----
timestamp="$(date +%Y%m%d-%H%M%S-%N | cut -b1-21)"
backup_dir="$CODEX_HOME/backups/framework-v5-$timestamp"
mkdir -p "$backup_dir/codex" "$SKILLS_HOME" "$standalone_dir" "$layer_dir" "$CODEX_HOME/hooks"

backup_file() {
    if [ -f "$1" ]; then
        mkdir -p "$(dirname "$2")"
        cp "$1" "$2"
    fi
}

backup_file "$agents_file" "$backup_dir/codex/AGENTS.md"
backup_file "$config_file" "$backup_dir/codex/config.toml"
backup_file "$hooks_file" "$backup_dir/codex/hooks.json"

# Move standalone framework agents to backup
if [ -d "$standalone_dir" ]; then
    for f in "$standalone_dir"/*.toml; do
        [ -f "$f" ] || continue
        base="$(basename "$f" .toml)"
        for r in "${ROLES[@]}"; do
            if [ "$base" = "$r" ]; then
                mkdir -p "$backup_dir/codex/standalone-agents"
                mv "$f" "$backup_dir/codex/standalone-agents/"
                break
            fi
        done
    done
fi

# Install agent configs
for r in "${ROLES[@]}"; do
    target_toml="$layer_dir/$r.toml"
    if [ -f "$target_toml" ]; then
        mkdir -p "$backup_dir/codex/agent-configs"
        cp "$target_toml" "$backup_dir/codex/agent-configs/$r.toml"
    fi
    cp "$PACKAGE_DIR/.codex/agent-configs/$r.toml" "$target_toml"
done

printf '%s\n' "$NEW_CONFIG" > "$config_file"

# Move proven framework legacy Skills to backup
if [ "${#LEGACY_MOVE_PATH[@]}" -gt 0 ]; then
    for i in "${!LEGACY_MOVE_PATH[@]}"; do
        mkdir -p "$backup_dir/$(dirname "${LEGACY_MOVE_LABEL[$i]}")"
        mv "${LEGACY_MOVE_PATH[$i]}" "$backup_dir/${LEGACY_MOVE_LABEL[$i]}"
    done
fi
if ! same_dir "$legacy_codex_skills" "$SKILLS_HOME" && [ -d "$legacy_codex_skills" ] && [ ! -L "$legacy_codex_skills" ] && [ -z "$(ls -A "$legacy_codex_skills" 2>/dev/null)" ]; then
    rmdir "$legacy_codex_skills"
fi

# Install v5 Skills that are absent (identical ones are reused untouched)
if [ "${#SKILL_INSTALL[@]}" -gt 0 ]; then
    for name in "${SKILL_INSTALL[@]}"; do
        cp -R "$PACKAGE_DIR/.agents/skills/$name" "$SKILLS_HOME/$name"
    done
fi

[ "${#OPTIONAL_SPECS[@]}" -gt 0 ] && apply_optional

printf '%s\n' "$NEW_AGENTS" > "$agents_file"

# Install hooks
if [ "$NO_HOOK" = false ]; then
    hook_dir="$CODEX_HOME/hooks"
    cp "$PACKAGE_DIR/.codex/hooks/mandatory-router.sh" "$hook_dir/mandatory-router.sh"
    cp "$PACKAGE_DIR/.codex/hooks/mandatory-router.ps1" "$hook_dir/mandatory-router.ps1"
    chmod 0755 "$hook_dir/mandatory-router.sh"
    printf '%s\n' "$NEW_HOOKS" > "$hooks_file"
fi

printf '\nCodex Global Framework v5 installed.\n'
echo "Backup: $backup_dir"
if [ -f "$override_file" ] && [ -s "$override_file" ]; then
    echo "WARNING: AGENTS.override.md shadows the global AGENTS.md."
fi
echo "Run: $PACKAGE_DIR/scripts/diagnose.sh"
