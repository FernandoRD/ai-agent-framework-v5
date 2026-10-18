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

# Same normalization as install.sh: expands ~, absolute, no symlink resolution, no trailing or doubled slashes.
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
CODEX_HOME="$(norm_path "$CODEX_HOME")"
SKILLS_HOME="$(norm_path "$SKILLS_HOME")"

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
    legacy_copy="$CODEX_HOME/skills/$name"
    if [ -d "$legacy_copy" ] && ! [ "$legacy_copy" -ef "$SKILLS_HOME/$name" ]; then
        # Same rule as the installer: identical or framework-owned copies are moved; a divergent one is kept.
        if diff -rq "$PACKAGE_DIR/.agents/skills/$name" "$legacy_copy" >/dev/null 2>&1 \
            || { [ -f "$legacy_copy/SKILL.md" ] && grep -qE '(luna|terra|sol)_(explorer|worker|reviewer|specialist|critical)|CODEX-GLOBAL-FRAMEWORK|Codex Global Framework|task-router' "$legacy_copy/SKILL.md"; }; then
            fail "duplicate legacy .codex/skills copy remains: $name"
        else
            warn "divergent .codex/skills/$name kept by the installer (merge or remove manually)"
        fi
    fi
done

for name in "${LEGACY[@]}"; do
    if [ -d "$SKILLS_HOME/$name" ]; then
        warn "legacy-named user Skill present (left intact by the installer unless proven framework-owned): $name"
    fi
    if [ -d "$CODEX_HOME/skills/$name" ]; then
        warn "legacy-named .codex/skills copy present (left intact unless proven framework-owned): $name"
    fi
done

hooks_file="$CODEX_HOME/hooks.json"
if [ -f "$hooks_file" ]; then
    ok "hooks.json exists"
    hook_count=""
    if command -v python3 >/dev/null 2>&1; then
        hook_count="$(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8-sig") as f:
    d = json.load(f)
g = d.get("hooks", {}).get("UserPromptSubmit", [])
print(sum(1 for x in g if "mandatory-router" in json.dumps(x)))
' "$hooks_file" 2>/dev/null)" || hook_count="invalid"
    elif command -v jq >/dev/null 2>&1; then
        hook_count="$(jq '[(.hooks.UserPromptSubmit // [])[] | select(tostring | contains("mandatory-router"))] | length' "$hooks_file" 2>/dev/null)" || hook_count="invalid"
    fi
    if [ "$hook_count" = "invalid" ]; then
        fail "hooks.json is invalid JSON or has an unexpected structure"
    elif [ -z "$hook_count" ]; then
        warn "python3/jq unavailable; cannot validate hooks.json"
    else
        ok "hooks.json is valid JSON"
        if [ "$hook_count" -eq 1 ]; then
            ok "exactly one routing reminder hook is configured"
        elif [ "$hook_count" -eq 0 ]; then
            warn "routing hook absent; AGENTS.md still works"
        else
            fail "duplicate routing hooks: $hook_count"
        fi
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
