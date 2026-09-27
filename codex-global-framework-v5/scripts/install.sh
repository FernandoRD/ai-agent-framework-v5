#!/usr/bin/env bash
set -euo pipefail

# Pure Bash installer for Codex Global Framework v5
# Zero Python required.

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
    cat <<'EOF'
Uso: install.sh [opções]

Opções gerais:
  --target <dir>      Diretório de destino (instalação por projeto)
  --global, -g        Instalação no ambiente global do usuário (~/.codex)
  --apply             Aplica as alterações no disco (padrão é auditoria)
  --audit-only        Modo estrito de auditoria (não altera arquivos)
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
  --with-all-specialists            Instala todos os 8 especialistas de domínio acima
EOF
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage 0
            ;;
        --target)
            [ $# -ge 2 ] || usage 1
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
        --codex-home)
            [ $# -ge 2 ] || usage
            CODEX_HOME="$2"
            shift 2
            ;;
        --skills-home)
            [ $# -ge 2 ] || usage
            SKILLS_HOME="$2"
            shift 2
            ;;
        --no-hook)
            NO_HOOK=true
            shift
            ;;
        --audit-only)
            AUDIT_ONLY=true
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

check_chain_for_symlinks() {
    local check_path="$1"
    local cur="$check_path"
    while [ -n "$cur" ] && [ "$cur" != "/" ] && [ "$cur" != "." ]; do
        if [ -L "$cur" ]; then return 0; fi
        local parent
        parent="$(dirname "$cur")"
        [ "$parent" = "$cur" ] && break
        cur="$parent"
    done
    return 1
}

install_optional_files() {
    local src_root="$1"
    local dest_root="$2"
    local count=0
    local opt_errors=()
    local opt_pending_src=()
    local opt_pending_dest=()

    [ -d "$src_root" ] || return 0

    while IFS= read -r -d '' src_file; do
        if [ -L "$src_file" ]; then
            opt_errors+=("Optional package link: $src_file")
            continue
        fi
        [ -f "$src_file" ] || continue
        rel="${src_file#$src_root/}"
        dest="$dest_root/$rel"

        if check_chain_for_symlinks "$dest"; then
            opt_errors+=("Optional destination link: $dest")
            continue
        fi

        if [ -e "$dest" ]; then
            if [ ! -f "$dest" ] || ! cmp -s "$src_file" "$dest"; then
                opt_errors+=("Optional package conflict: $dest")
            fi
        else
            opt_pending_src+=("$src_file")
            opt_pending_dest+=("$dest")
        fi
    done < <(find "$src_root" -type f -print0 | sort -z)

    if [ "${#opt_errors[@]}" -gt 0 ]; then
        for err in "${opt_errors[@]}"; do echo "$err" >&2; done
        exit 1
    fi

    for i in "${!opt_pending_src[@]}"; do
        s="${opt_pending_src[$i]}"
        d="${opt_pending_dest[$i]}"
        mkdir -p "$(dirname "$d")"
        if ( set -C; cp "$s" "$d" ) 2>/dev/null; then
            count=$((count + 1))
        else
            echo "Falha ao instalar arquivo opcional: $d" >&2
            exit 1
        fi
    done
    echo "$count"
}

# -----------------
# PROJECT INSTALL
# -----------------
IS_PROJECT=false
if [ -n "$TARGET" ]; then
    TARGET="${TARGET/#\~/$HOME_DIR}"
    case "$TARGET" in
        /*) ;;
        *) TARGET="$(pwd)/$TARGET" ;;
    esac
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
        else
            echo "- existing AGENTS: append framework block preserving personal text"
        fi
    else
        echo "- new AGENTS: create AGENTS.md with framework block"
    fi

    if [ "$AUDIT_ONLY" = true ]; then
        echo "Audit-only mode: no files changed."
        exit 0
    fi

    existing_personal=""
    if [ -f "$agents_file" ]; then
        # Remove marked framework block using awk
        existing_personal="$(awk '
            /<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN/ { in_block=1; next }
            /<!-- CODEX-GLOBAL-FRAMEWORK:END/ { in_block=0; next }
            !in_block { print }
        ' "$agents_file" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"
    fi

    package_block="$(cat "$PACKAGE_DIR/.codex/AGENTS.md")"
    if [ -n "$existing_personal" ]; then
        printf "%s\n\n%s\n" "$existing_personal" "$package_block" > "$agents_file"
    else
        printf "%s\n" "$package_block" > "$agents_file"
    fi

    if [ "${#OPTIONAL_SPECS[@]}" -gt 0 ]; then
        for spec in "${OPTIONAL_SPECS[@]}"; do
            spec_src="$PACKAGE_DIR/optional/$spec"
            if [ -d "$spec_src" ]; then
                scount="$(install_optional_files "$spec_src" "$TARGET")"
                echo "Optional $spec installed: $scount file(s)."
            fi
        done
    fi
    echo -e "\nCodex Framework v5 installed for project: $TARGET"
    exit 0
fi

# -----------------
# GLOBAL INSTALL
# -----------------
CODEX_HOME="${CODEX_HOME/#\~/$HOME_DIR}"
SKILLS_HOME="${SKILLS_HOME/#\~/$HOME_DIR}"
case "$CODEX_HOME" in /*) ;; *) CODEX_HOME="$(pwd)/$CODEX_HOME" ;; esac
case "$SKILLS_HOME" in /*) ;; *) SKILLS_HOME="$(pwd)/$SKILLS_HOME" ;; esac

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

# Preflight audit
FINDINGS=()
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
for root in "$legacy_codex_skills" "$SKILLS_HOME"; do
    if [ -d "$root" ]; then
        for name in "${LEGACY_SKILLS[@]}"; do
            path="$root/$name"
            if [ -d "$path" ]; then
                is_curr=false
                for c in "${CURRENT_SKILLS[@]}"; do [ "$c" = "$name" ] && is_curr=true && break; done
                if [ "$root" = "$SKILLS_HOME" ] && [ "$is_curr" = true ]; then
                    FINDINGS+=("legacy Skill: backup and replace with v5: $path")
                else
                    FINDINGS+=("legacy Skill: move legacy Skill to backup: $path")
                fi
            fi
        done
    fi
done
if [ -f "$config_file" ]; then
    for r in "${ROLES[@]}"; do
        if grep -qE "^[[:space:]]*\[agents\.$r\][[:space:]]*$" "$config_file"; then
            FINDINGS+=("agent registration: normalize to one v5 block: $config_file [$r]")
        fi
    done
fi
if [ -f "$hooks_file" ] && grep -q "mandatory-router" "$hooks_file"; then
    FINDINGS+=("routing hook: replace framework hook: $hooks_file")
fi

echo "Codex Global Framework v5 preflight"
echo "Codex home: $CODEX_HOME"
echo "Skills home: $SKILLS_HOME"
if [ "${#FINDINGS[@]}" -gt 0 ]; then
    for f in "${FINDINGS[@]}"; do
        echo "- $f"
    done
else
    echo "No v3/v4 residue detected."
fi

if [ "$AUDIT_ONLY" = true ]; then
    echo "Audit-only mode: no files changed."
    exit 0
fi

# Apply phase
timestamp="$(date +%Y%m%d-%H%M%S-%N | cut -b1-21)"
backup_dir="$CODEX_HOME/backups/framework-v5-$timestamp"
mkdir -p "$backup_dir/codex" "$SKILLS_HOME" "$standalone_dir" "$layer_dir" "$CODEX_HOME/hooks"

backup_file() {
    local src="$1"
    local dest="$2"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
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
    src_toml="$PACKAGE_DIR/.codex/agent-configs/$r.toml"
    if [ -f "$target_toml" ]; then
        mkdir -p "$backup_dir/codex/agent-configs"
        cp "$target_toml" "$backup_dir/codex/agent-configs/$r.toml"
    fi
    cp "$src_toml" "$target_toml"
done

# Update config.toml
existing_config=""
if [ -f "$config_file" ]; then
    existing_config="$(cat "$config_file")"
    # Remove existing v3/v4/v5 block
    existing_config="$(awk '
        /# BEGIN CODEX GLOBAL FRAMEWORK V[345] AGENTS/ { in_block=1; next }
        /# END CODEX GLOBAL FRAMEWORK V[345] AGENTS/ { in_block=0; next }
        !in_block { print }
    ' "$config_file")"
    # Remove individual agent role tables
    for r in "${ROLES[@]}"; do
        existing_config="$(echo "$existing_config" | awk -v role="$r" '
            $0 ~ "^[[:space:]]*\\[agents\\." role "\\]" { in_agent=1; next }
            in_agent && /^[[:space:]]*\[/ { in_agent=0 }
            !in_agent { print }
        ')"
    done
    existing_config="$(echo "$existing_config" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"
fi

{
    if [ -n "$existing_config" ]; then
        printf "%s\n\n" "$existing_config"
    fi
    printf "# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS\n"
    for r in "${ROLES[@]}"; do
        printf "\n[agents.%s]\ndescription = \"%s\"\nconfig_file = \"agent-configs/%s.toml\"\n" \
            "$r" "${ROLE_DESCRIPTIONS[$r]}" "$r"
    done
    printf "\n# END CODEX GLOBAL FRAMEWORK V5 AGENTS\n"
} > "$config_file"

# Move legacy skills to backup
for root in "$legacy_codex_skills" "$SKILLS_HOME"; do
    if [ -d "$root" ]; then
        label="legacy-codex-skills"
        [ "$root" = "$SKILLS_HOME" ] && label="user-skills"
        for name in "${LEGACY_SKILLS[@]}"; do
            path="$root/$name"
            if [ -d "$path" ]; then
                mkdir -p "$backup_dir/$label"
                mv "$path" "$backup_dir/$label/$name"
            fi
        done
        # Remove legacy root if empty
        if [ "$root" = "$legacy_codex_skills" ] && [ -d "$root" ] && [ -z "$(ls -A "$root" 2>/dev/null)" ]; then
            rmdir "$root"
        fi
    fi
done

# Copy current Skills
mkdir -p "$SKILLS_HOME"
for name in "${CURRENT_SKILLS[@]}"; do
    src_skill="$PACKAGE_DIR/.agents/skills/$name"
    dest_skill="$SKILLS_HOME/$name"
    rm -rf "$dest_skill"
    cp -r "$src_skill" "$dest_skill"
done

# Install optional specialists
if [ "${#OPTIONAL_SPECS[@]}" -gt 0 ]; then
    for spec in "${OPTIONAL_SPECS[@]}"; do
        spec_src="$PACKAGE_DIR/optional/$spec/.agents/skills/$spec"
        if [ -d "$spec_src" ]; then
            scount="$(install_optional_files "$spec_src" "$SKILLS_HOME/$spec")"
            echo "Optional $spec installed: $scount file(s)."
        fi
    done
fi

# Update AGENTS.md
existing_agents=""
if [ -f "$agents_file" ]; then
    existing_agents="$(awk '
        /<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN/ { in_block=1; next }
        /<!-- CODEX-GLOBAL-FRAMEWORK:END/ { in_block=0; next }
        !in_block { print }
    ' "$agents_file" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"
fi
package_agents="$(cat "$PACKAGE_DIR/.codex/AGENTS.md")"
if [ -n "$existing_agents" ]; then
    printf "%s\n\n%s\n" "$existing_agents" "$package_agents" > "$agents_file"
else
    printf "%s\n" "$package_agents" > "$agents_file"
fi

# Install hooks
if [ "$NO_HOOK" = false ]; then
    hook_dir="$CODEX_HOME/hooks"
    cp "$PACKAGE_DIR/.codex/hooks/mandatory-router.sh" "$hook_dir/mandatory-router.sh"
    cp "$PACKAGE_DIR/.codex/hooks/mandatory-router.ps1" "$hook_dir/mandatory-router.ps1"
    chmod 0755 "$hook_dir/mandatory-router.sh"

    # Update hooks.json safely
    hook_cmd='sh "${CODEX_HOME:-$HOME/.codex}/hooks/mandatory-router.sh"'
    hook_win='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\\.codex\\hooks\\mandatory-router.ps1"'
    
    if [ ! -f "$hooks_file" ]; then
        cat <<EOF > "$hooks_file"
{
  "description": "User hooks.",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh \"\${CODEX_HOME:-\$HOME/.codex}/hooks/mandatory-router.sh\"",
            "commandWindows": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\\\.codex\\\\hooks\\\\mandatory-router.ps1\"",
            "timeout": 5,
            "statusMessage": "Applying global routing policy"
          }
        ]
      }
    ]
  }
}
EOF
    else
        # If python3 or jq is available, use it for clean json manipulation, otherwise append hook
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import json
with open('$hooks_file', 'r', encoding='utf-8-sig') as f:
    try: data = json.load(f)
    except Exception: data = {'description': 'User hooks.', 'hooks': {}}
hooks = data.setdefault('hooks', {})
ups = hooks.setdefault('UserPromptSubmit', [])
ups[:] = [g for g in ups if 'mandatory-router' not in json.dumps(g)]
ups.append({'hooks': [{'type': 'command', 'command': 'sh \"\${CODEX_HOME:-\$HOME/.codex}/hooks/mandatory-router.sh\"', 'commandWindows': 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\\\.codex\\\\hooks\\\\mandatory-router.ps1\"', 'timeout': 5, 'statusMessage': 'Applying global routing policy'}]})
with open('$hooks_file', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
        elif command -v jq >/dev/null 2>&1; then
            jq '
              .hooks //= {} |
              .hooks.UserPromptSubmit //= [] |
              .hooks.UserPromptSubmit = ([.hooks.UserPromptSubmit[] | select(tostring | contains("mandatory-router") | not)] + [{
                "hooks": [{
                  "type": "command",
                  "command": "sh \"${CODEX_HOME:-$HOME/.codex}/hooks/mandatory-router.sh\"",
                  "commandWindows": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.codex\\hooks\\mandatory-router.ps1\"",
                  "timeout": 5,
                  "statusMessage": "Applying global routing policy"
                }]
              }])
            ' "$hooks_file" > "$hooks_file.tmp" && mv "$hooks_file.tmp" "$hooks_file"
        fi
    fi
fi

echo -e "\nCodex Global Framework v5 installed."
echo "Backup: $backup_dir"
if [ -f "$override_file" ] && [ -s "$override_file" ]; then
    echo "WARNING: AGENTS.override.md shadows the global AGENTS.md."
fi
echo "Run: $PACKAGE_DIR/scripts/diagnose.sh"
