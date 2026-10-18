# Validação da distribuição (Gemini CLI)

Resultados observados nesta máquina (Linux, bash, pwsh disponíveis; fish só é exercitado se instalado):

| Comando | Resultado |
| --- | --- |
| `python3 gemini-cli-global-framework-v5/scripts/test_install.py` | `Ran 20 tests ... OK` |
| `pwsh` (`Parser::ParseFile` em `install.ps1`) | 0 erros de parse |
| `pwsh install.ps1 -Help` | exibe a ajuda ("Uso: .\install.ps1 [opções]") |
| `pwsh install.ps1 -Target '~/' -Global` (HOME temporário, sem `-Apply`) | `CRIAR .../<pasta da ferramenta>/...`, `Auditoria: 8 arquivo(s) novo(s); nenhuma alteração.`, nada criado no HOME |
| `pwsh install.ps1 -Global -Target ''` | `Erro: -Target exige um caminho.` + ajuda, código 1 (como o `install.sh`) |

Os testes offline cobrem: auditoria sem escrita, instalação, idempotência, conflito sem instalação parcial, conflito de especialista, recusa de link simbólico (projeto, `--global` e `link/..`), barra final, `--target` sem valor (mensagem e sem diretório `--apply`), `.`/`..`/`~`/`~/` a partir do HOME tratados como global, `~foo` literal, criação exclusiva quando o destino surge após o preflight (shim de `mkdir` no PATH), ramificação "Link no pacote" (link em cópia temporária do payload) e instalação padrão sem nenhum dos 11 especialistas (nem pastas `sre-incident`/`database-tuning`).

Modo de arquivo: `find gemini-cli-global-framework-v5 -type f -perm -u+x` lista apenas arquivos do payload/documentação e scripts do próprio pacote (nenhum script dos especialistas opcionais, como `rag_ingest.py`, é executável). O instalador cria arquivos com o modo padrão do umask e não preserva o bit de execução; não há executável instalável a preservar.

Falha parcial de escrita (disco cheio, permissão) pode deixar um arquivo truncado no destino; na próxima execução ele aparece como Conflito e deve ser removido ou mesclado manualmente.

Divergências conhecidas sh/ps1: link de diretório no payload (PowerShell 5.1 vs 7) e link pendente no destino; `install.ps1` não foi exercitado em Windows nativo.

Não verificado: execução autenticada em provedores ou no Gemini CLI (carregamento e modelos efetivos dependem de teste na plataforma), Windows nativo e criação exclusiva sob corrida concorrente real (só simulada por shim). ZIP e MANIFEST.sha256 não foram regenerados nesta etapa.

## Manual direct-execution smoke scenarios

- Trivial work: a typo fix touching 2 files of the same component is handled
  directly with no declared blocker; the same fix across 4 files, or across two
  components, is routed as non-trivial.
- Always non-trivial: creating or deleting a host in Zabbix, editing a
  credential or secret, or touching deploy/systemd in one line is delegated.
- Pinpoint reading: ask a question answerable from 2 already-identified files;
  confirm the main agent reads them directly, edits nothing, and declares no
  blocker. Broad discovery or an unfamiliar repository goes to `flash-explorer`.
  A `.env` or key file goes to a worker that reports only path and type, never
  values.

## Manual publication smoke scenarios

- With explicitly authorized routine publication, known destinations, and
  validated changes, confirm the main agent delegates the full scoped workflow
  to `flash-worker`: scoped status/diff, explicit staging, commit, push, and
  every remote hash. Confirm the worker does not delegate further.
- Include unrelated working-tree changes and confirm they remain unstaged and
  uncommitted after the bounded publication.
- Pass repository, branch, allowed files, destinations, authorization, checks,
  and limits; confirm evidence is reused until a new change, failure, or doubt.
- Simulate conflict, uncertain scope, compatibility, release, or deployment;
  confirm only that unit rises to Pro. Without credentials, network, or
  approval, confirm normal access handling rather than escalation.
- Make delegation unavailable or prohibited; confirm the main agent states the
  concrete blocker and uses only the authorized fallback without claiming Flash
  execution.
- With multiple authorized remotes, verify each hash and report partial publication
  if one push fails. Confirm no implicit force push, rewrite, destination,
  privacy, release, or deployment authority.
