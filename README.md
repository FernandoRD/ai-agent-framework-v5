# AI Agent Framework v5

Framework de roteamento de tarefas de engenharia entre agentes de IA. A v5 faz o agente principal classificar cada solicitação, avaliar complexidade e risco e escolher a menor capacidade que possa executá-la com segurança. Ela também define quando delegar, como limitar o escopo de subagentes e como validar o resultado.

O repositório distribui uma implementação nativa para Codex e adaptações por projeto para Claude Code, Gemini CLI e Cursor. As adaptações preservam a política de decisão; os nomes e a disponibilidade dos modelos dependem de cada plataforma.

## Pacotes

| Pacote | Destino | Instalação | Modelos mapeados |
| --- | --- | --- | --- |
| [codex-global-framework-v5](codex-global-framework-v5/) | Codex | Global, via instaladores da plataforma | Luna, Terra e Sol |
| [claude-code-global-framework-v5](claude-code-global-framework-v5/) | Claude Code | Por projeto | Haiku, Sonnet e Opus |
| [gemini-cli-global-framework-v5](gemini-cli-global-framework-v5/) | Gemini CLI | Por projeto | Flash e Pro |
| [cursor-global-framework-v5](cursor-global-framework-v5/) | Cursor | Por projeto | Composer, Sonnet e Opus |

Os arquivos `.zip` na raiz contêm as mesmas distribuições prontas para transporte. Veja as diferenças de cada variante em [VARIANTES-V5.md](VARIANTES-V5.md) e a arquitetura em [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md).

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

### Claude Code, Gemini CLI e Cursor

As três variantes usam um instalador conservador por projeto e requerem Python 3.10 ou superior. A auditoria não escreve; `--apply` cria somente arquivos inexistentes e interrompe se encontrar conflito ou link simbólico.

```bash
cd claude-code-global-framework-v5  # ou gemini-cli-global-framework-v5, cursor-global-framework-v5
python3 scripts/install.py --target "/caminho/do/projeto"
python3 scripts/install.py --target "/caminho/do/projeto" --apply
python3 scripts/test_install.py
```

No Windows, substitua `python3` por `py -3` se necessário. Siga o README da variante para ativar agentes e, no Gemini, mesclar `settings.example.json` manualmente.

## Limites

A política orienta o agente principal; ela não é um despachante externo que imponha a pontuação ou a seleção de modelos. Planos, versões, políticas administrativas e autenticação podem alterar quais modelos, esforços e subagentes estão disponíveis. Os pacotes foram verificados por seus validadores e testes offline quando fornecidos, mas não há garantia de execução em uma sessão autenticada de cada plataforma.

As pastas [Claude code](Claude%20code/) e [Codex](Codex/) são material histórico/de referência. Não as use para instalar a v5; escolha um dos quatro pacotes acima.

## Manutenção

As regras de contribuição e manutenção deste repositório estão em [CLAUDE.md](CLAUDE.md). Antes de modificar payloads, instaladores ou a política, consulte a [referência técnica](TECHNICAL_REFERENCE.md) e execute as verificações pertinentes.
