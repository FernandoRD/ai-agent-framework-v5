# Troubleshooting

## Routing is ignored

Run the platform diagnostic. The most important check is a non-empty
`$CODEX_HOME/AGENTS.override.md`: Codex reads it instead of `AGENTS.md`.

Also confirm that Codex was fully restarted. Global instructions are assembled
when a run/session starts.

## Hook is not running

Open `/hooks`. New or modified unmanaged hooks remain disabled until their exact
definition is reviewed and trusted. Also check that `[features] hooks = false`
is not set in `config.toml`.

The hook is optional. If unavailable, v5 still routes through the global
`AGENTS.md`.

## Duplicate agent role name

Run the v5 installer. It finds framework TOMLs by their internal `name`, moves
them out of the auto-discovery directory, removes old exact registrations, and
creates one explicit registration per role. Then run the diagnostic; any
remaining matching TOML in `.codex/agents` is reported as a failure.

## Skills do not appear

Confirm they are in `$HOME/.agents/skills`, not `$CODEX_HOME/skills`. Restart
Codex and try explicit invocation such as `$code-review`. Automatic matching is
heuristic and is not used for mandatory routing.

## Wrong home on WSL

Run `echo "$HOME"` and `echo "${CODEX_HOME:-$HOME/.codex}"` in the same WSL
shell that launches Codex. Windows and WSL homes are separate unless you
explicitly share `CODEX_HOME`.
