# Claude Code Global Framework v5

Pacote v5 com roteamento obrigatório, econômico e orientado a risco para uso por projeto no Claude Code. Ele adapta integralmente a política da versão Codex para subagentes nativos do Claude Code, sem alterar a configuração pessoal do usuário.

## Modelo principal sugerido

Use **Sonnet com effort `high`** como agente principal para a maior parte dos projetos: ele equilibra classificação, decomposição, integração e custo. Use **Opus com effort `high`** como principal quando arquitetura ambígua e trabalho crítico forem frequentes. O principal classifica cada pedido e pode executá-lo diretamente quando já tiver capacidade suficiente; subagentes são usados apenas quando adicionam capacidade, isolamento, paralelismo, revisão independente ou economia de contexto.

## Mapeamento v5

| Nível v5 | Subagente Claude Code | Modelo | Finalidade |
| --- | --- | --- | --- |
| Luna | `haiku-explorer` | Haiku | Descoberta focada, somente leitura |
| Luna | `haiku-worker` | Haiku | Trabalho estreito, claro e de baixo risco |
| Terra | `sonnet-worker` | Sonnet | Implementação e depuração normais |
| Terra | `sonnet-reviewer` | Sonnet | Revisão independente |
| Sol | `opus-specialist` | Opus | Parte difícil ou ambígua da implementação |
| Sol | `opus-reviewer` | Opus | Revisão de alto risco |
| Sol | `opus-critical` | Opus | Análise crítica antes de mutações |

Os sete agentes usam frontmatter nativo com `name`, `description`, `tools`, `model`, `permissionMode` e `effort` quando configurado. Os nomes usam letras minúsculas e hífens, conforme a regra do Claude Code. Agentes de descoberta e revisão recebem somente ferramentas de leitura; os workers podem editar. Todos usam `permissionMode: default`; este pacote não usa `bypassPermissions`, `dontAsk` ou outro bypass de permissões.

## Publicação autorizada

Publicação rotineira é uma unidade separada da implementação. Com mudanças
validadas, branch e remotes conhecidos e autorização explícita, o principal
delega ao `haiku-worker` o fluxo completo: status e diff no escopo, staging de
caminhos explícitos, commit pedido, push aos remotes autorizados e conferência
do hash de cada remote. O repasse contém evidência compacta (repositório,
branch, arquivos permitidos, destinos, autorização, verificações e limites),
reutilizada até surgir mudança, falha ou dúvida nova.

Conflito, escopo incerto, compatibilidade, release, deploy ou outro risco
material elevam somente a unidade afetada para Sonnet ou Opus. Ausência de
credencial, rede ou permissão exige o fluxo normal de acesso, nunca modelo mais
forte ou contorno de aprovação. A política não concede autoridade para novos
destinos, mudança de privacidade, release, deploy, force push ou reescrita de
histórico; a delegação indisponível deve ser reportada com o bloqueio concreto.

## Instalação por projeto

O pacote é um payload para instalação em um repositório-alvo. O instalador está incluído em `scripts/`; requer Python 3.10+:

```bash
python scripts/install.py --target /caminho/projeto
python scripts/install.py --target /caminho/projeto --apply
```

Sem `--apply`, o instalador apenas audita. Com `--apply`, copia `payload/CLAUDE.md` e `payload/.claude/agents/*.md` para o projeto-alvo após mostrar o plano. Ele não deve escrever em `~/.claude/`, nem sobrescrever `CLAUDE.md` ou agentes existentes sem uma estratégia explícita de mesclagem/backup. O Claude Code procura subagentes de projeto em `.claude/agents/`; arquivos nesse local podem ser versionados para que a equipe compartilhe as definições.

## Estrutura

```text
claude-code-global-framework-v5/
├── README.md
└── payload/
    ├── CLAUDE.md
    └── .claude/
        └── agents/
            ├── haiku-explorer.md
            ├── haiku-worker.md
            ├── sonnet-worker.md
            ├── sonnet-reviewer.md
            ├── opus-specialist.md
            ├── opus-reviewer.md
            └── opus-critical.md
```

## Limitações conhecidas

- Isto é configuração declarativa: o Claude Code decide a delegação a partir de `description`, portanto a política orienta o comportamento e não é um roteador externo que garanta a pontuação ou a chamada de cada modelo.
- `effort` depende de versão, plano e disponibilidade do modelo no ambiente. Se um valor não for suportado, ajuste-o à lista aceita pela instalação local.
- O pacote inclui testes offline do instalador (`python scripts/test_install.py`), mas não foi executado em sessão autenticada no Claude Code. Confirme a descoberta invocando um agente de leitura e confira o modelo efetivo em `/tasks`.
- Apesar do nome histórico “global framework”, a distribuição desta variante é somente por projeto. Ela não migra configuração global, não instala hooks e não transporta Skills do Codex; esses recursos precisam de uma adaptação própria se forem desejados.
- O escopo do projeto tem prioridade sobre agentes pessoais quando os nomes colidem; evite duplicar os nomes deste pacote dentro da mesma árvore `.claude/agents/`.

## Fontes

- [Claude Code: Create custom subagents](https://code.claude.com/docs/en/sub-agents) — local de agentes por projeto, frontmatter, modelos, ferramentas, permissões e limites de `effort` quando configurado.
- [Política fonte Codex v5](../codex-global-framework-v5/.codex/AGENTS.md) — classificação, fatores de risco, pisos, estratégia de delegação e validação preservados nesta adaptação.

Haiku não recebe effort explícito nesta distribuição; Sonnet worker usa medium, reviewer high e os agentes Opus usam high. Não há equivalência automática com os esforços do Codex. Os aliases seguem os modelos disponíveis na instalação. Revisores sem Bash recebem diff e evidências do principal; verificações executáveis ficam a cargo do principal. O instalador recusa conflitos e links simbólicos; não faz mesclagem automática.
