# Claude Code Global Framework v5

Pacote v5 com roteamento obrigatório, econômico e orientado a risco para uso por projeto no Claude Code. Ele adapta integralmente a política da versão Codex para subagentes nativos do Claude Code, sem alterar a configuração pessoal do usuário.

## Modelo principal sugerido

Use **Sonnet com effort `high`** como agente principal para a maior parte dos projetos: ele equilibra classificação, decomposição, integração e custo. Use **Opus com effort `high`** como principal quando arquitetura ambígua e trabalho crítico forem frequentes. O principal classifica, decompõe, delega, coordena e integra. **O uso de subagentes é mandatório**: toda unidade delegável não trivial vai para o subagente do nível exigido, e a execução direta só é aceita diante de uma das exceções listadas em `CLAUDE.md` (subagentes indisponíveis, pedido explícito do usuário, recurso exclusivo do principal, pergunta sem ação, tarefa trivial conforme a definição (até 3 arquivos do mesmo componente, nunca escrita em sistema vivo, produção, segredos ou deploy) ou leitura pontual (exceção (f): no máximo 3 arquivos e 2 buscas por pergunta, ferramentas nativas sem shell, como Read, Glob e Grep), que o principal pode executar sem declarar bloqueio; arquivos de segredos nunca são lidos pelo principal). Na dúvida, a tarefa é não trivial e é delegada; a publicação continua delegada ao `haiku-worker`.

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

## Instalação por projeto e global

O pacote é um payload para instalação tanto em um repositório de projeto quanto globalmente no `$HOME` do usuário. Os instaladores estão incluídos em `scripts/` (Bash, Fish e PowerShell; Python 3.10+ é usado apenas por `scripts/test_install.py`):
- **No projeto (`--target /caminho/projeto`)**: `CLAUDE.md` é copiado para a raiz do repositório e os subagentes para `.claude/agents/`.
- **Global no `$HOME` (`--global` ou `--target ~`)**: `CLAUDE.md` e os subagentes ficam **dentro** de `~/.claude/` (`~/.claude/CLAUDE.md` e `~/.claude/agents/`), mantendo o `$HOME` limpo.

No Linux/macOS (Bash ou Fish):

```bash
# No projeto:
./scripts/install.sh --target /caminho/projeto
./scripts/install.sh --target /caminho/projeto --apply

# Global ($HOME):
./scripts/install.sh --global
./scripts/install.sh --global --apply
# ou no Fish:
./scripts/install.fish --global --apply
```

No Windows (PowerShell):

```powershell
# No projeto:
.\scripts\install.ps1 -Target "C:\caminho\projeto"
.\scripts\install.ps1 -Target "C:\caminho\projeto" -Apply

# Global:
.\scripts\install.ps1 -Global
.\scripts\install.ps1 -Global -Apply
```

Sem `--apply`, o instalador apenas audita. Com `--apply`, cria arquivos novos e preserva idênticos sem sobrescrever arquivos com conflito.

Resolução do alvo: `~` e `~/...` são expandidos (`~foo` é um nome relativo literal); `.`, `..` e `//` são normalizados lexicalmente, sem seguir links, antes da comparação com o `$HOME`; um alvo que resolve ao `$HOME` é tratado como global (instala em `~/.claude/`). A raiz (`/`, ou a raiz de unidade no PowerShell) é recusada.

**Alvo cujo caminho passa por link simbólico é recusado por desenho**, inclusive o `$HOME` global quando algum componente é link (por exemplo `/home` apontando para `/var/home` em sistemas atômicos). Para contornar, passe o caminho físico já resolvido (`--target "$(cd "$HOME" && pwd -P)"`, ou `-Target` com o caminho real no PowerShell). Não foi observado em macOS (por exemplo `/var` -> `/private/var`); nesse sistema, use o caminho físico do mesmo modo.

Divergências conhecidas entre `install.sh` e `install.ps1`: `install.sh` oferece `--uninstall` e aceita `--target=valor`; `install.ps1` só instala/audita. O `install.ps1` só foi exercitado em `pwsh` no Linux. Os arquivos instalados recebem o modo padrão do sistema (o pacote não contém executáveis).

### Especialistas opcionais

Os 11 especialistas (`zabbix-specialist`, `grafana-specialist`, `ansible-specialist`,
`loki-specialist`, `prometheus-specialist`, `netops-specialist`, `sre-incident-specialist`,
`database-tuning-specialist`, `proxmox-specialist`, `shell-python-specialist`
e `docker-kubernetes-specialist`) não são instalados por padrão. Cada
opção instala:

- o **agente nativo** `.claude/agents/<nome>.md`, que aparece em `/agents` e pode receber
  delegação do principal. Ele pré-carrega a skill homônima pelo campo `skills` do
  frontmatter, usa `model: sonnet` e `effort: high` por padrão e segue o roteamento v5:
  para unidade de nível Haiku ou Opus, o principal invoca o especialista com o modelo
  correspondente na própria chamada;
- a **skill** `.claude/skills/<nome>/` com o procedimento e as referências do domínio;
- `knowledge/<domínio>/` e `evals/<domínio>/` (no modo global, dentro de `~/.claude/`).

Zabbix e Grafana incluem ainda o guia `infra-rag.md`, para consultar, de forma opcional, não bloqueante e somente leitura, um índice local do projeto separado `infra-rag` via `rag-query`. O guia `infra-rag.md` é opcional e não bloqueante: sem ele, o especialista segue normalmente. Suas regras são instruções ao modelo, não imposição técnica; os controles de implantação estão na documentação do próprio `infra-rag`. Não foi testado com um agente real.

Os sete agentes de roteamento não mudam. Revisão independente continua com
`sonnet-reviewer` ou `opus-reviewer`. Para instalar:

```bash
./scripts/install.sh --target /caminho/projeto --with-ansible-specialist --apply
./scripts/install.sh --target /caminho/projeto --with-all-specialists --apply
```

No PowerShell, use `-With<Nome>Specialist -Apply` ou `-WithAllSpecialists -Apply` (SRE e Database Tuning: `-WithSreSpecialist` e `-WithDbTuningSpecialist`, ou os aliases kebab-case `-with-sre-incident-specialist` e `-with-database-tuning-specialist`).
Sem as opções, nenhum arquivo de especialista é criado; auditoria e recusa de conflitos permanecem iguais.

### Desinstalação e atualização

`--uninstall` remove somente arquivos intactos: os idênticos ao pacote atual e os que
batem com o hash de uma versão anterior registrada em `scripts/legacy-hashes.sha256`.
Arquivos modificados e arquivos que não pertencem ao pacote são preservados e listados.
Diretórios que ficarem vazios são removidos. Sem `--apply`, apenas audita e nada é escrito em disco.

```bash
# Auditar e depois remover uma instalação global com todos os especialistas:
./scripts/install.sh --global --with-all-specialists --uninstall
./scripts/install.sh --global --with-all-specialists --uninstall --apply

# Atualizar de uma versão anterior: desinstale com o pacote novo e instale de novo.
./scripts/install.sh --global --with-all-specialists --apply
```

Use as mesmas opções de destino e de especialistas da instalação. O modo
`--uninstall` existe apenas no instalador Bash/Fish; no Windows, remova manualmente.

## Estrutura

```text
claude-code-global-framework-v5/
├── README.md
├── payload/
│   ├── CLAUDE.md
│   └── .claude/
│       └── agents/
│           ├── haiku-explorer.md
│           ├── haiku-worker.md
│           ├── sonnet-worker.md
│           ├── sonnet-reviewer.md
│           ├── opus-specialist.md
│           ├── opus-reviewer.md
│           └── opus-critical.md
├── optional/<nome>-specialist/payload/
│   ├── .claude/agents/<nome>-specialist.md
│   ├── .claude/skills/<nome>-specialist/
│   ├── knowledge/<domínio>/
│   └── evals/<domínio>/
└── scripts/
    ├── install.sh / install.fish / install.ps1
    ├── legacy-hashes.sha256
    └── test_install.py
```

## Limitações conhecidas

- Isto é configuração declarativa: o Claude Code decide a delegação a partir de `description`, portanto a política orienta o comportamento e não é um roteador externo que garanta a pontuação ou a chamada de cada modelo.
- `effort` depende de versão, plano e disponibilidade do modelo no ambiente. Se um valor não for suportado, ajuste-o à lista aceita pela instalação local.
- O pacote inclui testes offline do instalador (`python3 scripts/test_install.py`), mas não foi executado em sessão autenticada no Claude Code. Confirme a descoberta invocando um agente de leitura e confira o modelo efetivo em `/tasks`.
- A instalação pode ser por projeto ou global. O pacote não migra configuração existente, não instala hooks e não transporta Skills do Codex; as skills incluídas são as dos especialistas opcionais.
- O campo `skills` dos agentes especialistas depende de uma versão do Claude Code que suporte pré-carregamento de skills em subagentes. Se a skill não carregar, o agente ainda pode invocá-la pela ferramenta `Skill`.
- O escopo do projeto tem prioridade sobre agentes pessoais quando os nomes colidem; evite duplicar os nomes deste pacote dentro da mesma árvore `.claude/agents/`.
- Divergência intencional: a regra "delegar sempre que possível" (delegação mandatória, 5.2.0) para o trabalho não trivial existe apenas no `payload/CLAUDE.md` desta variante Claude Code; não se afirma sincronização com as demais distribuições, incluindo a Codex.

## Fontes

- [Claude Code: Create custom subagents](https://code.claude.com/docs/en/sub-agents) — local de agentes por projeto, frontmatter, modelos, ferramentas, permissões e limites de `effort` quando configurado.
- Política fonte Codex v5 (`codex-global-framework-v5/.codex/AGENTS.md` no repositório de distribuição) — classificação, fatores de risco, pisos, estratégia de delegação e validação preservados nesta adaptação.

Haiku não recebe effort explícito nesta distribuição; Sonnet worker usa medium, reviewer high e os agentes Opus usam high. Não há equivalência automática com os esforços do Codex. Os aliases seguem os modelos disponíveis na instalação. Revisores sem Bash recebem diff e evidências do principal; verificações executáveis ficam a cargo do principal. O instalador recusa conflitos e links simbólicos; não faz mesclagem automática.
