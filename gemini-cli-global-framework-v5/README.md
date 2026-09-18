# Gemini CLI Global Framework v5

Variante da política v5 para projetos usados com o Gemini CLI. O pacote é um
payload de instalação: contém apenas os arquivos que devem chegar ao projeto.
Inclui instalador Python por projeto e testes offline. O exemplo de settings fica separado para mesclagem manual.

Apesar do nome de origem, esta distribuição é somente por projeto. Ela não
migra nem altera `~/.gemini/GEMINI.md`, `~/.gemini/settings.json`, políticas
globais, hooks ou Skills existentes. Também não instala hooks e não tenta
converter configurações de outros assistentes.

## Modelo de roteamento

A política mantém a classificação, a tabela de risco 0-100, os gatilhos
obrigatórios, os pisos de risco, as regras de delegação, validação e relatório
da v5 original. A mudança é honesta com a capacidade exposta pelo Gemini CLI:

| Faixa v5 | Gemini CLI | Agentes |
| --- | --- | --- |
| 0-34 | Flash | `flash-explorer`, `flash-worker` |
| 35-100 | Pro | `pro-worker`, `pro-reviewer`, `pro-specialist`, `pro-risk-reviewer`, `pro-critical` |

Não há uma terceira classe de capacidade equivalente a Terra/Sol. Pisos de
risco e análise crítica usam Pro. Os sete papéis são especializações de escopo,
permissão e prompt; não prometem níveis de inteligência distintos.

Os agentes usam os IDs estáveis `gemini-2.5-flash` e `gemini-2.5-pro`.
Se a conta tiver acesso aos modelos Gemini 3, altere os campos `model` dos
arquivos de agentes para um ID realmente disponível, como
`gemini-3-flash-preview` ou `gemini-3-pro-preview`. Não altere o
roteamento para depender de modelos em preview.

## Conteúdo e destino

O instalador comum deve copiar, em modo de aplicação, o conteúdo de
`payload/` para a raiz do projeto alvo:

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
- [Gemini 3 no Gemini CLI](https://geminicli.com/docs/get-started/gemini-3/)

## Validação

A estrutura foi validada estaticamente: todos os sete arquivos iniciam com
frontmatter YAML e usam apenas campos documentados (`name`, `description`,
`kind`, `tools`, `model`, `temperature`, `max_turns` e
`timeout_mins`); o exemplo é JSON válido. Não houve execução do Gemini CLI,
porque este pacote não instala nem inicia o runtime.

## Instalação por projeto

Requer Python 3.10+. Dentro do pacote extraído:

```sh
python scripts/install.py --target "/caminho/do/projeto"
python scripts/install.py --target "/caminho/do/projeto" --apply
python scripts/test_install.py
```

Use `python3` no Linux ou `py -3` no Windows, se necessário. A auditoria não escreve; a aplicação cria somente arquivos novos e recusa conflitos e links simbólicos. Depois faça a ativação descrita acima. Principal sugerido: Pro selecionado explicitamente com `/model`; o pacote não altera a seleção da sessão.

Reviewers recebem do principal o diff real ou um arquivo legível com o diff, caminhos modificados e resultados dos testes. Sem esses dados devem reportar revisão incompleta. Eles não executam git nem testes; o principal executa verificações adicionais solicitadas.
