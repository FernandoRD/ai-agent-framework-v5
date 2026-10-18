# Hermes Framework v5

Adaptação por projeto da política v5 para o [Hermes Agent](https://hermes-agent.nousresearch.com/docs/) (Nous Research). Ela mantém a classificação, o score, os pisos de risco, os sete papéis, o contexto compacto e a validação proporcional. A política é a mesma da variante Cursor. As diferenças estão em três pontos: a seção de publicação (sem a ferramenta Task), a seção de skills (que informa que as skills de revisão não vêm no pacote) e a seção final "Hermes adaptation". Essa seção final reúne as salvaguardas da adaptação Cursor: faixas não são equivalência de benchmark, é preciso verificar o modelo efetivo, nunca rebaixar um piso de risco, nunca simular delegação e nunca contar papéis como execuções. O pacote não altera a instalação Codex, o `config.yaml` nem o modelo principal.

> **Importante: a política do Hermes precisa estar na pasta do projeto.** O Hermes só lê `HERMES.md` a partir da pasta onde a sessão começa, subindo até a raiz do repositório Git. Ele não tem arquivo de regras global, ao contrário de `~/.claude/CLAUDE.md` ou `~/.codex/AGENTS.md`. Por isso, a classificação, o score, os pisos de risco e as regras de delegação só valem em projetos onde o pacote foi instalado com `--target <projeto>`. A instalação global (`--global`) disponibiliza apenas as skills de papel e de especialistas; ela **não ativa a política**.

## Modelos

O Hermes é independente de provedor, e o pacote não fixa nenhum modelo. Os nomes Luna, Terra e Sol identificam faixas de capacidade. Quem escolhe o modelo de cada faixa é o usuário.

| Faixa v5 | Papéis (skills) | Como a faixa é executada no Hermes |
| --- | --- | --- |
| 0-34 Luna | `luna-explorer`, `luna-worker` | Filhos do `delegate_task`, que usam `delegation.model` / `delegation.provider` do `config.yaml` |
| 35-69 Terra | `terra-worker`, `terra-reviewer` | `hermes chat -Q --oneshot -m <modelo> -s <papel> -q "<repasse>"`, tarefa kanban com modelo por tarefa, ou filhos herdando um principal desta faixa |
| 70-100 Sol | `sol-specialist`, `sol-reviewer`, `sol-critical` | Os mesmos mecanismos da faixa Terra, com um modelo de faixa Sol |

O `delegate_task` não aceita modelo por tarefa. O `delegation.model` vale para todos os filhos de uma sessão, então Terra e Sol precisam de um dos mecanismos listados na tabela. Uma execução só conta como Terra ou Sol quando o modelo efetivo era daquela faixa. Configure o Luna com `hermes config set delegation.model <modelo>` (e `delegation.provider`, se for diferente do principal). Não edite o `config.yaml` à mão.

## Conteúdo e destino

### 1. No projeto (`--target /caminho/do/projeto`)

```text
<projeto>/
├── HERMES.md
└── .hermes/
    └── skills/
        ├── luna-explorer/SKILL.md
        ├── luna-worker/SKILL.md
        ├── terra-worker/SKILL.md
        ├── terra-reviewer/SKILL.md
        ├── sol-specialist/SKILL.md
        ├── sol-reviewer/SKILL.md
        └── sol-critical/SKILL.md
```

O `HERMES.md` é o arquivo de contexto de maior prioridade do Hermes. Ele é procurado do diretório atual até a raiz do Git. **Só um tipo de contexto de projeto é carregado por sessão**: `.hermes.md`/`HERMES.md` → `AGENTS.override.md` → `AGENTS.md` → `CLAUDE.md` → `.cursorrules`. Com este pacote instalado, o Hermes deixa de ler o `AGENTS.md` ou o `CLAUDE.md` do projeto. Se eles contiverem fatos, restrições ou comandos do projeto, mescle esse conteúdo manualmente no `HERMES.md`. Codex, Claude Code e os outros assistentes continuam lendo os próprios arquivos.

No Hermes, o limite de cada arquivo de contexto é de no mínimo 20.000 caracteres. Ele cresce com a janela de contexto do modelo, até 500.000, a menos que `context_file_max_chars` esteja definido. Acima do limite, o arquivo é truncado no meio. O `HERMES.md` do pacote fica abaixo do mínimo. Se você acrescentar conteúdo, mantenha-o abaixo de 20.000 caracteres ou configure `context_file_max_chars`.

As skills de projeto (`.hermes/skills/`) **não são carregadas até o repositório ser marcado como confiável**. Execute `hermes skills trust` dentro do projeto. Isso exige um repositório Git, porque a raiz do projeto é o diretório que contém `.git`. Antes de indexar uma skill de projeto, o Hermes a submete ao scanner de segurança.

### 2. Global no `$HOME` (`--global` ou `--target ~`): só skills, sem política

```text
~/.hermes/
├── HERMES.md          # cópia de referência; o Hermes NÃO a carrega automaticamente
└── skills/
    ├── luna-explorer/SKILL.md
    └── ...
```

Na instalação global, as skills ficam em `~/.hermes/skills/` e valem para todas as sessões, sem `trust`. **A política não é aplicada:** o Hermes nunca lê `~/.hermes/HERMES.md`, que fica apenas como cópia de referência. O pacote também não usa nem altera o `SOUL.md`. Esse arquivo define a identidade do agente, entra em toda conversa, inclusive as que não são de engenharia, e não é repassado aos subagentes.

Para aplicar a política, instale o pacote **em cada projeto** (`--target <projeto>`). Para combinar os dois modos, use `--global` para as skills e `--target` em cada projeto para o `HERMES.md`. As skills idênticas no projeto e no `~/.hermes/skills/` não entram em conflito: a cópia do projeto tem precedência.

## Instalar

O instalador é o mesmo das variantes Gemini CLI e Cursor (os arquivos são idênticos byte a byte). A pasta da ferramenta (`.hermes`) é detectada pelo payload.

No Linux/macOS (Bash ou Fish):

```sh
# No projeto:
./scripts/install.sh --target /caminho/do/projeto
./scripts/install.sh --target /caminho/do/projeto --apply
cd /caminho/do/projeto && hermes skills trust

# Global ($HOME) — só skills; a política exige --target no projeto:
./scripts/install.sh --global
./scripts/install.sh --global --apply
# ou no Fish:
./scripts/install.fish --global --apply
python3 scripts/test_install.py  # testes do instalador (Python 3.10+; não é um instalador)
```

No Windows (PowerShell):

```powershell
.\scripts\install.ps1 -Target "C:\caminho\do\projeto"
.\scripts\install.ps1 -Target "C:\caminho\do\projeto" -Apply
.\scripts\install.ps1 -Global -Apply
```

Sem `--apply`, o instalador apenas audita. Com `--apply`, ele recusa arquivos existentes diferentes e links simbólicos, sem sobrescrever configurações, e preserva arquivos idênticos. Se a instalação encontrar conflito, compare e mescle manualmente antes de repetir.

O destino passa por normalização lexical (`.`, `..`, `//`); apenas `~` e `~/...` são expandidos para o HOME. Depois disso, um alvo que resolva para o próprio HOME é tratado como instalação global. Por desenho, o instalador recusa qualquer alvo cujo caminho atravesse um link simbólico. Divergências conhecidas entre `install.sh` e `install.ps1`:

- um link de diretório dentro do payload é detectado de forma diferente no Windows PowerShell 5.1 e no PowerShell 7;
- um link pendente no destino só é tratado de forma garantida pelo `install.sh`.

### Especialistas opcionais

Os 11 especialistas não são instalados por padrão e não alteram os sete papéis nem o roteamento Luna/Terra/Sol:

- `zabbix-specialist`
- `grafana-specialist`
- `ansible-specialist`
- `loki-specialist`
- `prometheus-specialist`
- `netops-specialist`
- `sre-incident-specialist`
- `database-tuning-specialist`
- `proxmox-specialist`
- `shell-python-specialist`
- `docker-kubernetes-specialist`

O conteúdo é idêntico ao das outras variantes; só a pasta muda, para `.hermes/skills/`. Para instalar, use as opções explícitas junto com `--apply`:

```bash
./scripts/install.sh --target /caminho/do/projeto --with-ansible-specialist --apply
./scripts/install.sh --target /caminho/do/projeto --with-all-specialists --apply
```

No PowerShell, use `-WithZabbixSpecialist`, `-WithGrafanaSpecialist`, …, `-WithDockerKubernetesSpecialist` ou `-WithAllSpecialists`, sempre com `-Apply`. Cada especialista complementa o papel escolhido pelo roteamento e não muda a faixa. O filho carrega a skill do papel e, em seguida, a do especialista.

**Quarentena de skills de projeto.** O scanner de segurança do Hermes marca `zabbix-specialist` e `docker-kubernetes-specialist` como `dangerous` quando instalados como skills de projeto, e eles ficam fora do índice. Os motivos são:

- `zabbix-specialist`: fixtures de teste do coletor RAG com tokens e chaves fictícios, além de um `subprocess.run(["git", ...])`;
- `docker-kubernetes-specialist`: exemplos de Dockerfile com `rm -rf` e endpoints locais.

São falsos positivos, mas o pacote não altera o conteúdo compartilhado com as outras variantes. Os outros nove especialistas passaram no scanner.

A quarentena só vale para skills de projeto, cujo conteúdo chega com qualquer repositório clonado. As skills em `~/.hermes/skills/` são tratadas como do próprio usuário e não passam por essa verificação. O instalador apenas copia arquivos e não aciona o scanner do hub (`hermes skills install`) nem o de skills criadas pelo agente. Por isso, instale esses dois especialistas globalmente e mantenha a política no projeto:

| Onde ficam `zabbix-specialist` e `docker-kubernetes-specialist` | Resultado |
| --- | --- |
| Projeto (`--target`, em `.hermes/skills/`) | Em quarentena: não aparecem na lista de skills e não carregam |
| Global (`--global`, em `~/.hermes/skills/`) | Listados e carregados normalmente |

```sh
./scripts/install.sh --global --with-zabbix-specialist --with-docker-kubernetes-specialist --apply
./scripts/install.sh --target /caminho/do/projeto --apply   # política + papéis no projeto
```

Uma skill global vale para todas as sessões do perfil, não só para aquele projeto.

## Publicação autorizada

A publicação rotineira é uma unidade separada da implementação. Quando há mudanças validadas, branch e remotes conhecidos e autorização explícita, o principal delega ao `luna-worker` o fluxo completo:

1. status e diff no escopo;
2. staging de caminhos explícitos;
3. o commit pedido;
4. push para os remotes autorizados;
5. conferência do hash em cada remote.

O `luna-worker` roda como filho do `delegate_task` no `delegation.model`. Se esse filho não puder ser criado, o principal registra o bloqueio concreto e usa apenas o fallback autorizado necessário, sem alegar execução Luna. Conflito, escopo incerto, compatibilidade, release, deploy ou outro risco material elevam apenas a unidade afetada para Terra ou Sol. A política não concede autoridade para novos destinos, mudança de privacidade, release, deploy, force push ou reescrita de histórico.

## Trabalho trivial e leitura pontual

As regras são as mesmas da variante Cursor.

**Trabalho trivial:**
- afeta até 3 arquivos do mesmo componente;
- escritas em sistemas vivos, mensageria ou persistência de produção, credenciais e segredos, e deploy/systemd nunca são triviais.

**Leitura pontual:**
- no máximo 3 arquivos e 2 buscas por pergunta, e no máximo 2 perguntas seguidas sem delegar;
- sem shell e sem editar nada;
- arquivos de segredo nunca são lidos pelo principal.

A publicação continua sempre delegada.

## Limites do Hermes

- **Sem perfil nativo de agente.** Os papéis são skills, não subagentes com modelo e ferramentas próprios. Por isso, o repasse precisa citar a skill do papel, e o filho deve carregá-la com `skill_view` antes de qualquer outra coisa.
- **O papel não escolhe o modelo.** A skill define o comportamento, não a faixa. A faixa vem de `delegation.model`, de `-m` ou do modelo da tarefa kanban. Sem `delegation.model`, os filhos herdam o modelo do principal.
- **Somente leitura por instrução.** Os filhos herdam os toolsets do principal, e o `delegate_task` não permite reduzi-los por chamada. Nos papéis `luna-explorer`, `terra-reviewer`, `sol-reviewer` e `sol-critical`, o "somente leitura" é uma instrução, não uma imposição técnica.
- **Execuções Terra e Sol são agentes completos.** As execuções via `hermes chat --oneshot` não são filhos folha: elas releem o `HERMES.md`, podem delegar e podem perguntar ao usuário. O repasse precisa proibir isso explicitamente. No kanban, as skills de papel precisam estar instaladas ou marcadas como confiáveis no perfil do worker.
- **Filhos folha têm restrições.** Por padrão, um filho não pode delegar, perguntar ao usuário nem gravar memória. O principal mantém a orquestração, a espera, a integração e a validação final.
- **Skills de revisão não incluídas.** As skills `security-review`, `code-review`, `dependency-review` e `documentation`, citadas na política, não vêm neste pacote.
- **Sem garantia de roteamento.** O roteamento é uma instrução ao principal, não um despachante determinístico. Não há garantia de economia nem de disponibilidade de modelos.

## Fontes consultadas em 2026-10-03

- https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files
- https://hermes-agent.nousresearch.com/docs/user-guide/features/skills (seção Project-Local Skills)
- https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation (seções Model Override e Toolsets)
- https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban (seção Per-task model override)
