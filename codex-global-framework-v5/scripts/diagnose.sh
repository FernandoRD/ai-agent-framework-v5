#!/usr/bin/env bash
set -euo pipefail

# Pure Bash diagnostic tool for Codex Global Framework v5
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
LEGACY=("task-router" "complexity-score" "deep-analysis" "implementation" "testing" "refactor" "final-review" "model-usage-report")
SKILLS=("security-review" "code-review" "dependency-review" "documentation")

ERRORS=0
WARNINGS=0

ok()   { echo "OK    $1"; }
warn() { WARNINGS=$((WARNINGS + 1)); echo "WARN  $1"; }
fail() { ERRORS=$((ERRORS + 1)); echo "FAIL  $1"; }

echo "Codex home: $CODEX_HOME"
echo -e "Skills home: $SKILLS_HOME\n"

agents_md="$CODEX_HOME/AGENTS.md"
if [ -f "$agents_md" ] && grep -q "CODEX-GLOBAL-FRAMEWORK:BEGIN v5" "$agents_md"; then
    ok "v5 block found in AGENTS.md"
else
    fail "v5 block missing from AGENTS.md"
fi

override="$CODEX_HOME/AGENTS.override.md"
if [ -f "$override" ] && [ -s "$override" ]; then
    fail "non-empty AGENTS.override.md shadows AGENTS.md"
else
    ok "no global AGENTS.override.md shadow"
fi

config_file="$CODEX_HOME/config.toml"
config=""
if [ -f "$config_file" ]; then
    config="$(cat "$config_file")"
fi

if echo "$config" | grep -q "# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS"; then
    ok "v5 agent registration block found"
else
    fail "v5 agent registration block missing"
fi

for role in "${ROLES[@]}"; do
    count=$(echo "$config" | grep -cE "^[[:space:]]*\[agents\.$role\][[:space:]]*$" || true)
    if [ "$count" -eq 1 ]; then
        ok "one registration for $role"
    else
        fail "registration count for $role: $count"
    fi

    layer="$CODEX_HOME/agent-configs/$role.toml"
    if [ -f "$layer" ] && ! grep -qE "^[[:space:]]*(name|description)[[:space:]]*=" "$layer"; then
        ok "agent layer $role"
    else
        fail "missing or standalone-form layer $role"
    fi
done

standalone="$CODEX_HOME/agents"
if [ -d "$standalone" ]; then
    for f in "$standalone"/*.toml; do
        [ -f "$f" ] || continue
        base="$(basename "$f" .toml)"
        for r in "${ROLES[@]}"; do
            if [ "$base" = "$r" ]; then
                fail "duplicate-prone standalone framework agent: $f"
            fi
        done
    done
fi

for name in "${SKILLS[@]}"; do
    skill="$SKILLS_HOME/$name/SKILL.md"
    if [ -f "$skill" ] && grep -qE "^name:[[:space:]]*$name" "$skill"; then
        ok "skill $name"
    else
        fail "missing or invalid skill $name"
    fi
    if [ -d "$CODEX_HOME/skills/$name" ]; then
        fail "duplicate legacy .codex/skills copy remains: $name"
    fi
done

for name in "${LEGACY[@]}"; do
    if [ -d "$SKILLS_HOME/$name" ]; then
        fail "legacy user Skill remains: $name"
    fi
    if [ -d "$CODEX_HOME/skills/$name" ]; then
        fail "legacy .codex/skills copy remains: $name"
    fi
done

hooks_file="$CODEX_HOME/hooks.json"
if [ -f "$hooks_file" ]; then
    ok "hooks.json exists"
    if grep -q "mandatory-router" "$hooks_file"; then
        ok "exactly one routing reminder hook is configured"
    else
        warn "routing hook absent; AGENTS.md still works"
    fi
else
    warn "hooks.json absent; AGENTS.md still works"
fi

hook="$CODEX_HOME/hooks/mandatory-router.sh"
if [ -f "$hook" ]; then
    hook_out="$(sh "$hook" 2>/dev/null || true)"
    if echo "$hook_out" | grep -q "UserPromptSubmit"; then
        ok "routing hook output is valid"
    else
        fail "routing hook output is invalid"
    fi
fi

if echo "$config" | grep -qE "^[[:space:]]*hooks[[:space:]]*=[[:space:]]*false[[:space:]]*$"; then
    warn "hooks disabled in config.toml"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "Result: FAIL ($ERRORS error(s), $WARNINGS warning(s))"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo "Result: WARN ($WARNINGS warning(s))"
else
    echo "Result: OK"
fi
echo "Restart Codex after installation. Use /hooks to verify UserPromptSubmit is Active."
