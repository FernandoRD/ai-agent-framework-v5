# Kimi Code Global Framework v5

Variante da política v5 para projetos usados com o Kimi Code CLI. O pacote é um
payload de instalação: contém apenas os arquivos que devem chegar ao projeto.
Inclui instaladores Shell/PowerShell e testes offline. O Kimi Code descobre
agentes e skills automaticamente; não há arquivo de settings para mesclar.

Esta distribuição suporta tanto instalação por projeto (`--target <projeto>`) quanto instalação global no `$HOME` do usuário (`--global` ou `--target ~`). Ela não altera configurações pessoais alheias, hooks ou Skills existentes de outros assistentes.

## Modelo de roteamento

A política mantém a classificação, a tabela de risco 0-100, os gatilhos
obrigatórios, os pisos de risco, as regras de delegação, validação e relatório
da v5 original. As faixas são nomeadas pelos modelos do serviço Kimi Code:

| Faixa v5 | Tier Kimi | Modelo recomendado | Agentes |
| --- | --- | --- | --- |
| 0-34 | K2.7 | `kimi-for-coding-highspeed` (K2.7 Code HighSpeed) | `k27-explorer`, `k27-worker` |
| 35-69 | K2.8 | `kimi-for-coding` (K2.8 Preview) | `k28-worker`, `k28-reviewer` |
| 70-100 | K3 | `k3` | `k3-specialist`, `k3-reviewer`, `k3-critical` |

### Limitação de seleção de modelo (Kimi Code)

O Kimi Code não fixa modelo por subagente: arquivos de agente não têm campo
`model` e todo subagente roda o modelo ativo da sessão. As faixas acima são o
**modelo recomendado da sessão** para cada banda; a banda sempre garante o
**papel** do agente (escopo, ferramentas, revisão somente leitura, ausência de
delegação adiante). Para realizar o mapeamento de custo, inicie a sessão com o
modelo recomendado (por exemplo, `kimi -m kimi-code/kimi-for-coding-highspeed`
para um lote de trabalho de faixa baixa). Nunca apresente um modelo configurado ou
recomendado como o modelo que realmente executou sem evidência de runtime.

### Relatório de utilização de modelos

O relatório final registra as execuções dos agentes do pacote por tier: **K2.7**,
**K2.8** e **K3**, mais o modelo ativo da sessão declarado à parte. Nunca
afirme execução em um modelo que não rodou.

## Conteúdo e destino

O instalador suporta dois destinos:

### 1. No projeto (`--target /caminho/do/projeto`):
O arquivo `AGENTS.md` é copiado para a raiz do projeto e os subagentes para a pasta oculta `.kimi-code/agents/`:

```text
<pasta-do-projeto>/
├── AGENTS.md
└── .kimi-code/
    └── agents/
        ├── k27-explorer.md
        ├── k27-worker.md
        ├── k28-worker.md
        ├── k28-reviewer.md
        ├── k3-specialist.md
        ├── k3-reviewer.md
        └── k3-critical.md
```

### 2. Global no `$HOME` (`--global` ou `--target ~`):
Tudo fica guardado **dentro** de `~/.kimi-code/`, evitando arquivos soltos no diretório pessoal:

```text
~/.kimi-code/
├── AGENTS.md
└── agents/
    ├── k27-explorer.md
    ├── k27-worker.md
    ├── ...
```

Esses são exatamente os caminhos que o Kimi Code documenta para instruções
globais (`$KIMI_CODE_HOME/AGENTS.md`) e agentes de usuário
(`$KIMI_CODE_HOME/agents/`). Se você usa `KIMI_CODE_HOME` apontando para outro
diretório, instale com `--global --target "$KIMI_CODE_HOME/.."` para instalar em
`$KIMI_CODE_HOME`, ou copie o conteúdo para
dentro dele manualmente.

## Ativação

1. Não há settings para mesclar: agentes e skills são descobertos
   automaticamente pelo Kimi Code.
2. Inicie uma nova sessão do Kimi Code; a descoberta ocorre na inicialização.
3. Para confirmar, peça ao agente principal a lista de subagentes disponíveis
   ou invoque explicitamente: "use `k27-explorer` para mapear os arquivos
   relevantes antes de alterar qualquer coisa".

Os subagentes deste pacote declaram `subagents: []`: um subagente não pode
chamar outro subagente. Por isso o principal mantém a orquestração, a espera, a
integração e a validação final.

## Publicação autorizada

Publicação rotineira é uma unidade separada da implementação. Com mudanças
validadas, branch e remotes conhecidos e autorização explícita, o principal
delega ao `k27-worker` o fluxo completo: status e diff no escopo, staging de
caminhos explícitos, commit pedido, push aos remotes autorizados e conferência
do hash de cada remote. O repasse contém evidência compacta (repositório,
branch, arquivos permitidos, destinos, autorização, verificações e limites),
reutilizada até surgir mudança, falha ou dúvida nova. O `k27-worker` não
delegará esse trabalho: a orquestração continua exclusivamente no principal.

Conflito, escopo incerto, compatibilidade, release, deploy ou outro risco
material elevam somente a unidade afetada para K2.8 ou K3. Ausência de credencial,
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

`k27-explorer`, `k28-reviewer`, `k3-reviewer` e
`k3-critical` recebem apenas `Read`, `Grep` e `Glob`. Eles não
herdam shell nem ferramentas de escrita. Os demais agentes recebem uma lista explícita de ferramentas locais de leitura, busca, edição e shell; a política exige que o
principal envie escopo, autoridade e condição de parada. Regras de permissão
permanecem sob controle da sessão principal (`/permission`): verifique o modo
de aprovação efetivo antes de delegar edição, shell, rede, Git ou efeitos
externos.

## Fontes consultadas

- [Agents e sub-agents do Kimi Code](https://www.kimi.com/code/docs/en/kimi-code-cli/customization/agents.html)
- [Agent Skills do Kimi Code](https://www.kimi.com/code/docs/en/kimi-code-cli/customization/skills.html)
- [Data locations (`$KIMI_CODE_HOME`)](https://www.kimi.com/code/docs/en/kimi-code-cli/configuration/data-locations.html)
- [Visão geral e IDs de modelo do Kimi Code](https://www.kimi.com/code/docs/en/)

## Validação

A estrutura foi validada estaticamente: todos os sete arquivos de agente
iniciam com frontmatter YAML e usam apenas campos documentados (`name`,
`description`, `whenToUse`, `tools`, `subagents`). Não houve execução
autenticada do Kimi Code nesta etapa de geração, porque este pacote não
instala nem inicia o runtime; confirme a descoberta dos sete agentes e o
respeito aos pisos de risco em uma sessão de teste antes de uso crítico.

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
agentes centrais ou o roteamento K2.7/K2.8/K3. São instalados como skills em
`.kimi-code/skills/` (projeto) ou `~/.kimi-code/skills/` (global). Para incluir
skills, conhecimento e evals, use as opções explícitas junto à aplicação:

```bash
./scripts/install.sh --target "/caminho/do/projeto" --with-ansible-specialist --apply
./scripts/install.sh --target "/caminho/do/projeto" --with-all-specialists --apply
```

No PowerShell, use `-WithZabbixSpecialist`, `-WithGrafanaSpecialist`, `-WithAnsibleSpecialist`, `-WithLokiSpecialist`, `-WithPrometheusSpecialist`, `-WithNetopsSpecialist`, `-WithSreSpecialist` (alias `-with-sre-incident-specialist`), `-WithDbTuningSpecialist` (alias `-with-database-tuning-specialist`), `-WithProxmoxSpecialist`, `-WithShellPythonSpecialist`, `-WithDockerKubernetesSpecialist` ou `-WithAllSpecialists`, sempre com `-Apply`.
Sem as opções, nenhum arquivo de especialista é criado; auditoria e recusa de conflitos permanecem iguais.

Os especialistas `zabbix-specialist` e `grafana-specialist` incluem o guia `infra-rag.md`, para consultar, de forma opcional, não bloqueante e somente leitura, um índice local do projeto separado `infra-rag` via `rag-query`. O guia `infra-rag.md` é opcional e não bloqueante: sem ele, o especialista segue normalmente. Suas regras são instruções ao modelo, não imposição técnica; os controles de implantação estão na documentação do próprio `infra-rag`. Não foi testado com um agente real.

A auditoria não escreve; a aplicação cria somente arquivos novos e recusa conflitos e links simbólicos. Depois faça a ativação descrita acima. Principal sugerido: o modelo da faixa predominante do trabalho; o pacote não altera a seleção da sessão.

Uma vez que o destino seja normalizado lexicalmente (`.`, `..`, `//`; só `~` e `~/...` expandem para o HOME), um alvo que resolva para o próprio HOME é tratado como global. Por desenho, o instalador recusa qualquer alvo cujo caminho informado atravesse um link simbólico, inclusive um `$HOME` sob um link (por exemplo `/home -> /var/home`); informe o caminho físico. Divergências conhecidas entre `install.sh` e `install.ps1`: link de diretório dentro do payload é detectado de forma diferente no Windows PowerShell 5.1 e no PowerShell 7, e um link pendente no destino só é tratado de forma garantida pelo `install.sh`.

Reviewers recebem do principal o diff real ou um arquivo legível com o diff, caminhos modificados e resultados dos testes. Sem esses dados devem reportar revisão incompleta. Eles não executam git nem testes; o principal executa verificações adicionais solicitadas.
