# AI Agent Framework v5

Framework de roteamento de tarefas de engenharia entre agentes de IA. A v5 faz o agente principal classificar cada solicitação, avaliar complexidade e risco e escolher a menor capacidade que possa executá-la com segurança. A prioridade é decompor o trabalho e encaminhar cada unidade ao menor agente capaz de executá-la e validá-la com segurança. O principal coordena e integra; sua capacidade maior não justifica reter unidades de menor complexidade. A política também define delegação e revisão obrigatórias quando houver benefício concreto, exceções delimitadas e validação proporcional.

O repositório distribui uma implementação nativa para Codex e adaptações por projeto para Claude Code, Gemini CLI (Google Antigravity) e Cursor. As adaptações preservam a política de decisão; os nomes e a disponibilidade dos modelos dependem de cada plataforma.

Em todas as variantes, a publicação é roteada separadamente: commits e pushes rotineiros, autorizados e com mudanças validadas são delegados ao worker de menor capacidade suficiente (Luna no Codex, Haiku no Claude Code, Flash no Gemini CLI / Antigravity e Composer no Cursor), mesmo quando a implementação usou um agente maior. O fluxo reaproveita as validações disponíveis, preserva alterações alheias e confere o hash em cada remote. Conflitos e riscos adicionais elevam apenas a etapa afetada; falta de acesso não justifica trocar por um modelo mais caro.

## Pacotes

| Pacote | Destino | Instalação | Modelos mapeados |
| --- | --- | --- | --- |
| [codex-global-framework-v5](codex-global-framework-v5/) | Codex | Global, via instaladores da plataforma | Luna, Terra e Sol |
| [claude-code-global-framework-v5](claude-code-global-framework-v5/) | Claude Code | Por projeto | Haiku, Sonnet e Opus |
| [gemini-cli-global-framework-v5](gemini-cli-global-framework-v5/) | Gemini CLI / Antigravity | Por projeto | Flash e Pro |
| [cursor-global-framework-v5](cursor-global-framework-v5/) | Cursor | Por projeto | Composer, Sonnet e Opus |

Os arquivos `.zip` na raiz contêm as mesmas distribuições prontas para transporte. Cada ZIP inclui uma pasta principal com o nome da distribuição; após extrair, entre nessa pasta para executar o instalador. Isso mantém os arquivos do pacote separados das configurações instaladas, mesmo ao extrair no diretório pessoal. Veja as diferenças de cada variante em [VARIANTES-V5.md](VARIANTES-V5.md) e a arquitetura em [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md).

## Como usar

### Codex

O pacote Codex instala a política global em `~/.codex/` e as skills em `~/.agents/skills/`. Requer Python 3.11 ou superior: o validador usa `tomllib` da biblioteca padrão.

No Linux:

```bash
cd codex-global-framework-v5
./scripts/install.sh --audit-only
./scripts/install.sh
./scripts/diagnose.sh
python3 scripts/validate.py
```

Há instaladores equivalentes para PowerShell, Fish e WSL dentro de `scripts/`. Leia o [README do pacote Codex](codex-global-framework-v5/README.md) antes de instalar: ele faz backup e trata resíduos das versões v3/v4.

### Claude Code, Gemini CLI (Antigravity) e Cursor

As três variantes usam instalador conservador com suporte a escopo por projeto ou global (`$HOME`), com scripts equivalentes em Shell Script (`.sh` para Bash e `.fish` para Fish), PowerShell (`.ps1` para Windows) e Python (`.py`). A auditoria não escreve; `--apply` / `-Apply` cria somente arquivos inexistentes e interrompe se encontrar conflito ou link simbólico:
- **No projeto (`--target "/caminho/do/projeto"`)**: o arquivo de instruções (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`) é gerado na raiz do repositório, e os subagentes na pasta oculta (`.claude/agents/`, `.gemini/agents/`, `.cursor/`).
- **No Home / Global (`--global` ou `--target ~`)**: o arquivo de instruções fica **dentro** da pasta oculta (`~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.cursor/`), evitando poluir a raiz do diretório pessoal.

No Linux/macOS (Bash ou Fish):

```bash
cd claude-code-global-framework-v5  # ou gemini-cli-global-framework-v5, cursor-global-framework-v5

# Para instalar em um projeto:
./scripts/install.sh --target "/caminho/do/projeto"
./scripts/install.sh --target "/caminho/do/projeto" --apply

# Para instalar globalmente no seu $HOME:
./scripts/install.sh --global
./scripts/install.sh --global --apply

# ou no Fish: ./scripts/install.fish --global --apply
python3 scripts/test_install.py
```

No Windows (PowerShell):

```powershell
cd claude-code-global-framework-v5  # ou gemini-cli-global-framework-v5, cursor-global-framework-v5

# Para instalar em um projeto:
.\scripts\install.ps1 -Target "C:\caminho\do\projeto"
.\scripts\install.ps1 -Target "C:\caminho\do\projeto" -Apply

# Para instalar globalmente:
.\scripts\install.ps1 -Global
.\scripts\install.ps1 -Global -Apply
```

Ou diretamente via Python (`python3` no Linux ou `py -3` no Windows): `python3 scripts/install.py --target "/caminho/do/projeto" --apply` ou `python3 scripts/install.py --global --apply`. Siga o README da variante para ativar agentes e, no Gemini, mesclar `settings.example.json` manualmente.

## Limites

A política orienta o agente principal; ela não é um despachante externo que imponha a pontuação ou a seleção de modelos. Planos, versões, políticas administrativas e autenticação podem alterar quais modelos, esforços e subagentes estão disponíveis. Os pacotes foram verificados por seus validadores e testes offline quando fornecidos, mas não há garantia de execução em uma sessão autenticada de cada plataforma.

As pastas [Claude code](Claude%20code/) e [Codex](Codex/) são material histórico/de referência. Não as use para instalar a v5; escolha um dos quatro pacotes acima.

## Manutenção

As regras de contribuição e manutenção deste repositório estão em [CLAUDE.md](CLAUDE.md). Antes de modificar payloads, instaladores ou a política, consulte a [referência técnica](TECHNICAL_REFERENCE.md) e execute as verificações pertinentes.
