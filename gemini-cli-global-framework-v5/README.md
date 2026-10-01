# Gemini CLI Global Framework v5

Variante da política v5 para projetos usados com o Gemini CLI. O pacote é um
payload de instalação: contém apenas os arquivos que devem chegar ao projeto.
Inclui instaladores Shell/PowerShell e testes offline. O exemplo de settings fica separado para mesclagem manual.

Esta distribuição suporta tanto instalação por projeto (`--target <projeto>`) quanto instalação global no `$HOME` do usuário (`--global` ou `--target ~`). Ela não altera configurações pessoais alheias, hooks ou Skills existentes de outros assistentes.

## Modelo de roteamento

A política mantém a classificação, a tabela de risco 0-100, os gatilhos
obrigatórios, os pisos de risco, as regras de delegação, validação e relatório
da v5 original. Ela suporta o ecossistema completo de modelos:

| Faixa v5 | Tier Google | Modelos Google | Agentes |
| --- | --- | --- | --- |
| 0-34 | Flash | `gemini-2.5-flash` | `flash-explorer`, `flash-worker` |
| 35-69 | Pro | `gemini-2.5-pro` | `pro-worker`, `pro-reviewer` |
| 70-100 | Pro (alto risco) | `gemini-2.5-pro` | `pro-specialist`, `pro-risk-reviewer`, `pro-critical` |

O pacote fixa o mesmo modelo Pro nas duas faixas superiores; a faixa escolhe o papel do agente, não outro modelo.

### Modelos de outros provedores (não verificado)

Este pacote fixa apenas modelos Gemini (`gemini-2.5-pro` e `gemini-2.5-flash`) nos
agentes. O uso de outros provedores no Google Antigravity, a herança de modelo
(`inherit`) por subagentes e a delegação programática entre modelos não foram
verificados nem são sustentados pela documentação do Gemini CLI consultada;
não dependa deles.
- **Regra obrigatória para o agente Flash**: Quando a sessão principal estiver operando em Flash, o agente **não pode reter diretamente** tarefas não triviais com piso de risco Pro (implementações multi-componentes, refatorações amplas, segurança). Ele deve obrigatoriamente despachar subagentes com modelo **Pro** (ou modelo de alto raciocínio ativo).

### Relatório de utilização de modelos

O relatório final registra as execuções dos agentes do pacote: **Flash** (`gemini-2.5-flash`) e **Pro** (`gemini-2.5-pro`). Outros provedores (Claude, ChatGPT) não são verificados por este pacote; só inclua linha para eles se o usuário os configurar e eles realmente executarem.

## Conteúdo e destino

O instalador suporta dois destinos:

### 1. No projeto (`--target /caminho/do/projeto`):
O arquivo `GEMINI.md` é copiado para a raiz do projeto e os subagentes para a pasta oculta `.gemini/agents/`:

```text
<pasta-do-projeto>/
├── GEMINI.md
└── .gemini/
    └── agents/
        ├── flash-explorer.md
        ├── flash-worker.md
        ├── pro-worker.md
        ├── pro-reviewer.md
        ├── pro-specialist.md
        ├── pro-risk-reviewer.md
        └── pro-critical.md
```

### 2. Global no `$HOME` (`--global` ou `--target ~`):
Tudo fica guardado **dentro** de `~/.gemini/`, evitando arquivos soltos no diretório pessoal:

```text
~/.gemini/
├── GEMINI.md
└── agents/
    ├── flash-explorer.md
    ├── flash-worker.md
    ├── ...
```

O arquivo `settings.example.json` permanece fora de `payload/`. Ele é um
modelo para mesclar manualmente em `.gemini/settings.json` ou
`~/.gemini/settings.json`; não deve substituir um arquivo existente. Ele
mantém confirmações de ferramentas em `default` e habilita
`experimental.enableAgents`. A documentação atual informa que esse recurso
vem habilitado por padrão, mas declarar o valor torna a dependência explícita.

## Ativação

1. Copie ou mescle o exemplo de configurações sem apagar preferências atuais.
2. Reinicie o Gemini CLI: alterações em `agents.overrides` e
   `experimental.enableAgents` exigem reinício.
3. Use `/agents` para confirmar que os sete agentes foram encontrados.
4. A delegação automática depende da descrição do agente e da decisão do
   principal. Para tornar uma chamada explícita, inicie a solicitação com
   `@flash-explorer`, `@pro-reviewer` ou outro nome definido.

O Gemini CLI atual permite que o principal chame subagentes locais, mas um
subagente não pode chamar outro subagente. Por isso o principal deve manter a
orquestração, a espera, a integração e a validação final.

## Publicação autorizada

Publicação rotineira é uma unidade separada da implementação. Com mudanças
validadas, branch e remotes conhecidos e autorização explícita, o principal
delega ao `flash-worker` o fluxo completo: status e diff no escopo, staging de
caminhos explícitos, commit pedido, push aos remotes autorizados e conferência
do hash de cada remote. O repasse contém evidência compacta (repositório,
branch, arquivos permitidos, destinos, autorização, verificações e limites),
reutilizada até surgir mudança, falha ou dúvida nova. O `flash-worker` não
delegará esse trabalho: a orquestração continua exclusivamente no principal.

Conflito, escopo incerto, compatibilidade, release, deploy ou outro risco
material elevam somente a unidade afetada para Pro. Ausência de credencial,
rede ou permissão exige o fluxo normal de acesso, nunca modelo mais forte ou
contorno de aprovação. A política não concede autoridade para novos destinos,
mudança de privacidade, release, deploy, force push ou reescrita de histórico;
a delegação indisponível deve ser reportada com o bloqueio concreto.

## Exceções de execução direta

Duas exceções dispensam subagente e a declaração de bloqueio. (1) Trabalho
trivial: até 3 arquivos do mesmo componente (mais que isso, ou componentes
diferentes, não é trivial); escritas em sistemas vivos (ex.: criar ou remover
hosts no Zabbix), mensageria ou persistência de produção, credenciais e
segredos, e deploy/systemd são sempre não triviais, qualquer que seja o
tamanho. (2) Leitura pontual: o principal pode ler diretamente no máximo 3 arquivos e 2 buscas por pergunta, e 2 perguntas consecutivas sem delegar (somente ferramentas nativas de leitura, listagem e busca, sem shell; buscas só em modo de listagem de caminhos ou contagem), para
responder a uma pergunta ou preparar um repasse, sem editar nada. Descoberta
ampla, repositórios desconhecidos e investigação continuam com o explorer.
Arquivos de segredo (.env, chaves, tokens, credenciais) nunca são lidos pelo
principal: vão a um worker, que reporta apenas caminho e tipo, nunca valores.
Publicação continua sempre delegada e nunca é trivial nem leitura pontual.

## Limites de permissão

`flash-explorer`, `pro-reviewer`, `pro-risk-reviewer` e
`pro-critical` recebem apenas `read_file`, `grep_search`, `glob` e `list_directory`. Eles não
herdam shell, ferramentas de escrita ou MCP. Os demais agentes recebem uma lista explícita de ferramentas locais de leitura, busca, edição e shell, sem herdar MCPs; a política exige que o
principal envie escopo, autoridade e condição de parada.

O exemplo mantém `general.defaultApprovalMode: "default"`, que solicita
aprovação de ferramentas. Não use `--yolo` para contornar esse fluxo. Esse
arquivo não é uma garantia de que um administrador, uma configuração global ou
um modo de sessão já permissivo não autoaprove operações mutáveis de
subagentes. Antes de delegar edição, shell, rede, Git ou efeitos externos,
verifique as configurações efetivas com `/settings` e as políticas carregadas;
mantenha confirmação obrigatória para essas ferramentas onde a instalação
permitir. O framework também não ativa worktrees, AgentSession/ADK, roteador
Gemma, browser agent, ou outras opções experimentais. A execução paralela só
deve ocorrer quando houver isolamento de escrita real; o gerenciamento
automatizado de worktrees continua experimental e desabilitado por padrão.

## Fontes consultadas

- [Subagents do Gemini CLI](https://geminicli.com/docs/core/subagents/)
- [Configuração e schema de settings](https://geminicli.com/docs/reference/configuration/)
- [Seleção de modelos](https://geminicli.com/docs/cli/model/)

## Validação

A estrutura foi validada estaticamente: todos os sete arquivos iniciam com
frontmatter YAML e usam apenas campos documentados (`name`, `description`,
`kind`, `tools`, `model`, `temperature`, `max_turns` e
`timeout_mins`); o exemplo é JSON válido. Não houve execução do Gemini CLI,
porque este pacote não instala nem inicia o runtime.

## Instalação por projeto

Dentro do pacote extraído, execute usando o instalador de sua preferência (Bash, Fish ou PowerShell):

No Linux/macOS (Bash ou Fish):

```sh
./scripts/install.sh --target "/caminho/do/projeto"
./scripts/install.sh --target "/caminho/do/projeto" --apply
# ou no Fish:
./scripts/install.fish "/caminho/do/projeto" --apply
python3 scripts/test_install.py  # testes do instalador (requer Python 3.10+; não é um instalador)
```

No Windows (PowerShell):

```powershell
.\scripts\install.ps1 -Target "C:\caminho\do\projeto"
.\scripts\install.ps1 -Target "C:\caminho\do\projeto" -Apply
```

### Especialistas opcionais

Os 11 especialistas (`zabbix-specialist`, `grafana-specialist`, `ansible-specialist`,
`loki-specialist`, `prometheus-specialist`, `netops-specialist`, `sre-incident-specialist`,
`database-tuning-specialist`, `proxmox-specialist`, `shell-python-specialist`
e `docker-kubernetes-specialist`) não são instalados por padrão e não alteram os sete
agentes centrais ou o roteamento Flash/Pro. Para incluir skills, conhecimento e evals,
use as opções explícitas junto à aplicação:

```bash
./scripts/install.sh --target "/caminho/do/projeto" --with-ansible-specialist --apply
./scripts/install.sh --target "/caminho/do/projeto" --with-all-specialists --apply
```

No PowerShell, use `-WithZabbixSpecialist`, `-WithGrafanaSpecialist`, `-WithAnsibleSpecialist`, `-WithLokiSpecialist`, `-WithPrometheusSpecialist`, `-WithNetopsSpecialist`, `-WithSreSpecialist` (alias `-with-sre-incident-specialist`), `-WithDbTuningSpecialist` (alias `-with-database-tuning-specialist`), `-WithProxmoxSpecialist`, `-WithShellPythonSpecialist`, `-WithDockerKubernetesSpecialist` ou `-WithAllSpecialists`, sempre com `-Apply`.
Sem as opções, nenhum arquivo de especialista é criado; auditoria e recusa de conflitos permanecem iguais.

Os especialistas `zabbix-specialist` e `grafana-specialist` incluem o guia `infra-rag.md`, para consultar, de forma opcional, não bloqueante e somente leitura, um índice local do projeto separado `infra-rag` via `rag-query`. O guia `infra-rag.md` é opcional e não bloqueante: sem ele, o especialista segue normalmente. Suas regras são instruções ao modelo, não imposição técnica; os controles de implantação estão na documentação do próprio `infra-rag`. Não foi testado com um agente real.

A auditoria não escreve; a aplicação cria somente arquivos novos e recusa conflitos e links simbólicos. Depois faça a ativação descrita acima. Principal sugerido: Pro selecionado explicitamente com `/model`; o pacote não altera a seleção da sessão.

Uma vez que o destino seja normalizado lexicalmente (`.`, `..`, `//`; só `~` e `~/...` expandem para o HOME), um alvo que resolva para o próprio HOME é tratado como global. Por desenho, o instalador recusa qualquer alvo cujo caminho informado atravesse um link simbólico, inclusive um `$HOME` sob um link (por exemplo `/home -> /var/home`); informe o caminho físico. Divergências conhecidas entre `install.sh` e `install.ps1`: link de diretório dentro do payload é detectado de forma diferente no Windows PowerShell 5.1 e no PowerShell 7, e um link pendente no destino só é tratado de forma garantida pelo `install.sh`.

Reviewers recebem do principal o diff real ou um arquivo legível com o diff, caminhos modificados e resultados dos testes. Sem esses dados devem reportar revisão incompleta. Eles não executam git nem testes; o principal executa verificações adicionais solicitadas.
