# Validação da distribuição (Cursor)

Resultados observados nesta máquina (Linux, bash, pwsh disponíveis; fish só é exercitado se instalado):

| Comando | Resultado |
| --- | --- |
| `python3 cursor-global-framework-v5/scripts/test_install.py` | `Ran 20 tests ... OK` |
| `pwsh` (`Parser::ParseFile` em `install.ps1`) | 0 erros de parse |
| `pwsh install.ps1 -Help` | exibe a ajuda ("Uso: .\install.ps1 [opções]") |
| `pwsh install.ps1 -Target '~/' -Global` (HOME temporário, sem `-Apply`) | `CRIAR .../<pasta da ferramenta>/...`, `Auditoria: 8 arquivo(s) novo(s); nenhuma alteração.`, nada criado no HOME |
| `pwsh install.ps1 -Global -Target ''` | `Erro: -Target exige um caminho.` + ajuda, código 1 (como o `install.sh`) |

Os testes offline cobrem: auditoria sem escrita, instalação, idempotência, conflito sem instalação parcial, conflito de especialista, recusa de link simbólico (projeto, `--global` e `link/..`), barra final, `--target` sem valor (mensagem e sem diretório `--apply`), `.`/`..`/`~`/`~/` a partir do HOME tratados como global, `~foo` literal, criação exclusiva quando o destino surge após o preflight (shim de `mkdir` no PATH), ramificação "Link no pacote" (link em cópia temporária do payload) e instalação padrão sem nenhum dos 11 especialistas (nem pastas `sre-incident`/`database-tuning`).

Modo de arquivo: `find cursor-global-framework-v5 -type f -perm -u+x` lista apenas arquivos do payload/documentação e scripts do próprio pacote (nenhum script dos especialistas opcionais, como `rag_ingest.py`, é executável). O instalador cria arquivos com o modo padrão do umask e não preserva o bit de execução; não há executável instalável a preservar.

Falha parcial de escrita (disco cheio, permissão) pode deixar um arquivo truncado no destino; na próxima execução ele aparece como Conflito e deve ser removido ou mesclado manualmente.

Divergências conhecidas sh/ps1: link de diretório no payload (PowerShell 5.1 vs 7) e link pendente no destino; `install.ps1` não foi exercitado em Windows nativo.

Não verificado: execução autenticada em provedores ou no Cursor (carregamento e modelos efetivos dependem de teste na plataforma), Windows nativo e criação exclusiva sob corrida concorrente real (só simulada por shim). ZIP e MANIFEST.sha256 não foram regenerados nesta etapa.

## Manual publication smoke scenarios

- When native Task is available, use explicitly authorized routine publication
  with known destinations and validated changes. Confirm the full scoped flow
  delegates to `luna-worker` (Composer): status/diff, explicit staging, commit,
  push, and every remote hash.
- Include unrelated working-tree changes and confirm they remain unstaged and
  uncommitted after the bounded publication.
- Pass repository, branch, allowed files, destinations, authorization, checks,
  and limits; confirm evidence is reused until a new change, failure, or doubt.
- If Task is unavailable, confirm the main agent states that concrete blocker
  and uses only the authorized fallback. Simulate conflict, uncertain scope,
  compatibility, release, or deployment; confirm only that unit rises to Terra
  or Sol. Missing access must use normal approval.
- With two authorized remotes, verify each hash and report partial publication
  if one push fails. Confirm no implicit force push, rewrite, destination,
  privacy, release, or deployment authority.
