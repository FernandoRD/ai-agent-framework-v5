# Variantes v5 para outras plataformas

Geradas em 12/09/2026; política de execução e publicação alinhada em redação, em 01/10/2026, com `codex-global-framework-v5/.codex/AGENTS.md`, exceto pelas divergências intencionais descritas abaixo.

| Pacote | Versão | Plataforma | Faixas de execução |
| --- | --- | --- | --- |
| `claude-code-global-framework-v5.zip` | 5.2.0-claude-code | Claude Code | Haiku / Sonnet / Opus |
| `gemini-cli-global-framework-v5.zip` | 5.0.0-gemini-cli | Gemini CLI / Antigravity | 0-34 Flash; 35-69 e 70-100 Pro (mesmo modelo Pro nas duas faixas superiores; a faixa escolhe o papel do agente) |
| `cursor-global-framework-v5.zip` | 5.0.0-cursor | Cursor | Composer / Sonnet / Opus |

As versões vêm do arquivo `VERSION` de cada pacote e divergem porque as variantes evoluem separadamente. As quatro variantes permitem execução direta de tarefa trivial (até 3 arquivos do mesmo componente) e leitura pontual, mantendo a delegação obrigatória para o trabalho não trivial e a publicação sempre delegada; a diferença do Claude Code é a regra textual "delegar sempre que possível" (delegação mandatória, 5.2.0) para o trabalho não trivial, que nas demais variantes decorre dos checkpoints e do princípio do menor agente. A variante Claude Code ainda traz agentes nativos de especialistas e `--uninstall`. Não há paridade funcional completa entre as variantes; compare o `CLAUDE.md`, o `AGENTS.md`, o `GEMINI.md` e a regra do Cursor antes de assumir o mesmo comportamento.

Cada pacote tem sete agentes, política v5 adaptada, README próprio e instalador unificado com suporte a instalação por projeto (`--target <pasta>`) ou global no `$HOME` (`--global` ou `--target ~`). Na instalação no projeto, o arquivo de instruções fica na raiz do projeto; na instalação global, ele fica guardado dentro da respectiva pasta oculta (`~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`; no Cursor, a regra em `~/.cursor/rules/`), mantendo o `$HOME` limpo.

## Usar

Extraia o ZIP da plataforma. Dentro da pasta extraída, execute com o instalador de sua preferência (Bash, Fish ou PowerShell):

No Linux/macOS (Bash ou Fish):

```sh
# Instalação por projeto:
./scripts/install.sh --target "/caminho/do/projeto"
./scripts/install.sh --target "/caminho/do/projeto" --apply

# Instalação com todos os 11 especialistas:
./scripts/install.sh --target "/caminho/do/projeto" --with-all-specialists --apply

# Instalação global ($HOME):
./scripts/install.sh --global
./scripts/install.sh --global --apply
# ou no Fish:
./scripts/install.fish --global --apply
```

No Windows (PowerShell):

```powershell
# Instalação por projeto:
.\scripts\install.ps1 -Target "C:\caminho\do\projeto"
.\scripts\install.ps1 -Target "C:\caminho\do\projeto" -Apply

# Instalação com todos os 11 especialistas:
.\scripts\install.ps1 -Target "C:\caminho\do\projeto" -WithAllSpecialists -Apply

# Instalação global:
.\scripts\install.ps1 -Global
.\scripts\install.ps1 -Global -Apply
```

A auditoria (sem `--apply`) nunca escreve em disco, inclusive com `--global`, e só mostra o que seria criado. Com `--apply`, o instalador cria arquivos novos (no Bash, criação exclusiva via `cat > destino` sob `noclobber`), preserva idênticos, recusa conflitos e links simbólicos (inclusive alvo global que seja link simbólico) e não modifica configurações pessoais. No PowerShell, caminhos relativos e `~` são resolvidos antes da verificação. Os scripts são nativos em Shell Script (`.sh`, `.fish`) e PowerShell (`.ps1`); Python não é necessário para instalar. Só o Claude Code (`install.sh` e `install.fish`) tem `--uninstall` (auditoria por padrão, remoção com `--apply`, preservando arquivos modificados); `install.ps1`, Gemini CLI e Cursor não têm. Os especialistas aceitam aliases (`--with-sre-specialist`, `--with-db-tuning-specialist`; no PowerShell, `-with-sre-specialist`, `-with-sre-incident-specialist`, `-with-db-tuning-specialist`, `-with-database-tuning-specialist`). Para consultar as opções e o catálogo completo dos 11 especialistas, execute `./scripts/install.sh --help` ou `.\scripts\install.ps1 -Help`. Leia o README da plataforma antes da ativação, especialmente o exemplo de settings do Gemini.

Nos instaladores `install.sh` das variantes por projeto, o alvo é normalizado lexicalmente (`.`, `..`, `//`) e é recusado se o caminho atravessar um link simbólico, inclusive no modo global.

Divergência intencional: a regra "delegar sempre que possível" (delegação mandatória, 5.2.0) para o trabalho não trivial existe apenas no `payload/CLAUDE.md` da variante Claude Code (as demais exigem delegação por checkpoints e pelo princípio do menor agente), e somente o Claude Code não tem a cláusula de tier equivalente (Codex, Gemini CLI e Cursor a têm).

Para conferir o instalador sem acessar nenhum provedor (Python 3.10+; 19 testes no Claude Code, 20 no Gemini CLI e no Cursor):

```sh
python3 scripts/test_install.py
```

O pacote preserva classificação trivial/não trivial, pesos e faixas do score, pisos de risco, delegação delimitada, revisão independente e relatório de execuções. Os nomes dos modelos não representam equivalência de capacidade entre fornecedores. A prioridade é analisar e decompor o trabalho, atribuir cada unidade ao menor agente suficiente dentro do mapeamento da plataforma e reservar ao principal a coordenação e integração. Isso não significa tentar sempre o modelo menor: os pisos de risco continuam obrigatórios. Delegação útil e revisão independente têm gatilhos explícitos; exceções devem ser justificadas. A política orienta o agente; não existe despachante externo que imponha cada decisão.

## Publicação

As três variantes seguem o mesmo contrato do Codex para publicação: delegação do fluxo rotineiro autorizado ao menor worker suficiente, repasse compacto, reaproveitamento de validações, staging explícito, preservação de alterações e confirmação de hashes por remote. Os mapeamentos são Haiku no Claude Code, Flash no Gemini CLI e Composer no Cursor. O modelo efetivo e suas permissões dependem do ambiente; indisponibilidade deve ser declarada, sem simular delegação nem enfraquecer controles. Somente etapas com riscos adicionais são escaladas. Nenhuma variante recebe nova autorização para publicar ou implantar por causa dessa regra.

## Diferenças do pacote Codex

Estas variantes não migram instalações v3/v4, não limpam configurações legadas, não instalam hooks nem copiam skills do Codex. Isso evita transportar mecanismos específicos para ambientes incompatíveis. Não instale várias variantes no mesmo projeto sem conferir regras e agentes duplicados.

A geração não instala os pacotes nos seus aplicativos. Validação de arquivos e instalação temporária não comprova disponibilidade de modelos ou comportamento autenticado no provedor. Confira descoberta dos sete agentes, modelo efetivo e respeito aos pisos de risco em uma sessão de teste antes de usar em trabalho crítico.

O instalador é para uso local sem modificações concorrentes no destino; não é uma transação de múltiplos arquivos. Uma falha de I/O pode deixar apenas parte dos arquivos novos criada. Nenhum arquivo pessoal é sobrescrito; após resolver a falha, repetir a instalação completa os faltantes. Para remover, apague somente os arquivos instalados listados na auditoria, preservando alterações feitas posteriormente.
