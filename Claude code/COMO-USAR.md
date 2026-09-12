# Como usar estes arquivos

## 1. Instalação

Na raiz do projeto:

```
seu-projeto/
├── AGENTS.md              ← já existia, agora com a seção 41 (compat Claude Code)
├── CLAUDE.md               ← novo, só importa o AGENTS.md
└── .claude/
    └── agents/
        ├── luna.md          ← worker haiku
        ├── terra.md         ← executor sonnet
        └── sol.md           ← especialista opus
```

Copie:
- `AGENTS.md` e `CLAUDE.md` para a raiz do projeto (substituindo o `AGENTS.md` atual).
- `luna.md`, `terra.md`, `sol.md` para dentro de `.claude/agents/` (crie a pasta se não existir).

Se quiser esses três subagentes disponíveis em **todos** os projetos, em vez de um só, copie-os para `~/.claude/agents/` ao invés de `.claude/agents/`.

## 2. Por que o `CLAUDE.md` existe

Claude Code só lê `CLAUDE.md` automaticamente — nunca `AGENTS.md` sozinho. O `CLAUDE.md` que te passei tem uma linha (`@AGENTS.md`) que importa o arquivo inteiro. Sem isso, todo o roteamento seria ignorado por mim. Não delete essa linha nem o `CLAUDE.md`.

## 3. Uso no dia a dia

Não precisa fazer nada manualmente — o roteamento é automático:

1. Você pede algo normalmente.
2. O agente principal (a sessão que você abriu) aplica o score da seção 7–13 do AGENTS.md e decide se delega.
3. Se delegar, ele aciona `luna`, `terra` ou `sol` conforme a faixa de score — a `description` de cada subagente foi escrita para casar com os critérios do AGENTS.md.
4. No fim, você recebe o relatório da seção 40 (tabela de utilização por modelo).

Para forçar um subagente específico, basta pedir explicitamente: *"use o subagente sol para investigar essa race condition"*.

## 4. Pontos de atenção

- **Modelo da sessão principal:** se você abrir o Claude Code em Sonnet, a sessão principal já cumpre o papel de "Terra" (seção 3 do AGENTS.md) — o subagente `terra.md` só entra em cena se a sessão principal estiver em Opus e precisar rebaixar uma subtarefa.
- **Reasoning effort:** o AGENTS.md menciona `low/medium/high/max` (seção 6) — isso é conceito do Codex. Claude Code não tem esse dial por subagente; trate como orientação qualitativa, não como configuração real.
- **Se `haiku`/`opus` não estiverem disponíveis** na sua conta/superfície, o subagente cai para `inherit` (modelo da sessão principal) — comportamento já documentado na seção 41.3 do AGENTS.md, não é bug.
- **Escopo de arquivos:** cada subagente foi instruído a não sair do escopo combinado e a não fazer mudanças oportunistas — isso segue a seção 31 (Escopo e Git) do AGENTS.md.
