# Validação da distribuição

Somente resultados observados na última execução (Linux, Python 3, `pwsh` no Linux):

- `python3 scripts/test_install.py` -> `Ran 19 tests ... OK`. Cobre: auditoria sem escrita (inclusive global e `--uninstall`), instalação, idempotência, recusa de conflito sem instalação parcial, recusa de link simbólico, alvo `~`/`~/`/barra final global, normalização léxica (`.` dentro do HOME, `..`, `sub/..`, `.//`; `.` em subdiretório continua projeto; `~foo` literal), recusa de raiz, `--target` sem valor (com conferência da mensagem), poda de diretórios vazios no `--uninstall` e destino criado após o preflight não sobrescrito (o shim de `cat` cria todos os demais destinos, sem depender da ordem).
- `bash -n scripts/install.sh` sem erros; `install.ps1` sem erros de sintaxe no parser do `pwsh`.
- `pwsh install.ps1 -Help` imprime o uso. Com `HOME` temporário, `-Target '~'`, `-Target '~/'` e `-Target '<home>/'` (sem `-Apply`) resolveram todos para global: primeira linha `CRIAR <home>/.claude/agents/haiku-explorer.md`, última `Auditoria: 8 arquivo(s) novo(s); nenhuma alteração.`. Também observado: `-Global -Target ''` sai com código 1 e `Erro: -Target exige um caminho.`; `-Target /` e `-Global -Target /` recusam a raiz (código 1); `-Target .` no HOME e `-Target ..` a partir de um subdiretório são globais; `~foo` vira subdiretório literal.
- Executáveis: `find -type f -perm -u+x` listou 14 arquivos, mas o git registra todo `payload/` e `optional/` como `100644`; o bit +x é acidental da árvore de trabalho e não há executáveis no pacote. Por isso o instalador (`cat`/`CreateNew`) não preserva modo e os arquivos instalados usam o umask.
- Não observado: execução no Windows, macOS ou sessão autenticada no Claude Code; carregamento e modelos efetivos dependem de teste na plataforma. Checksums e ZIP não foram regenerados nesta etapa.

## Cenários manuais de publicação

- Com publicação rotineira explicitamente autorizada, destinos conhecidos e
  mudanças validadas, confirme a delegação do fluxo inteiro ao `haiku-worker`:
  status/diff no escopo, staging explícito, commit, push e hash de cada remote.
- Inclua mudanças não relacionadas na árvore de trabalho; confirme que permanecem
  fora do staging e do commit depois da publicação delimitada.
- Forneça a cápsula com repositório, branch, arquivos, destinos, autorização,
  verificações e limitações; confirme o reúso da evidência até haver mudança,
  falha ou dúvida nova.
- Simule conflito, escopo incerto, compatibilidade, release ou deploy; confirme
  escalonamento somente da unidade afetada para Sonnet/Opus. Sem credencial,
  rede ou aprovação, confirme solicitação normal de acesso, sem elevação.
- Indisponibilize ou proíba a delegação; confirme que o principal declara o
  bloqueio concreto e executa apenas o fallback já autorizado, sem atribuir a
  publicação ao Haiku.
- Em dois remotes autorizados, confira cada hash e reporte publicação parcial
  se um push falhar. Confirme que a política não permite force push, reescrita,
  novo destino, mudança de privacidade, release ou deploy sem autorização.

Os pacotes Claude e Gemini foram produzidos por dois subagentes Terra; um terceiro subagente Terra realizou revisão independente do Cursor e da correção Gemini. A integração e os ajustes finais foram feitos pelo principal.
