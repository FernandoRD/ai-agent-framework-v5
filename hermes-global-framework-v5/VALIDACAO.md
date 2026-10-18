# Validação da distribuição (Hermes)

Resultados observados nesta máquina (Linux, bash, pwsh e fish disponíveis; Hermes Agent v0.21.5):

| Comando | Resultado |
| --- | --- |
| `python3 hermes-global-framework-v5/scripts/test_install.py` | `Ran 20 tests ... OK` |
| `pwsh` (`Parser::ParseFile` em `install.ps1`) | 0 erros de parse |
| `pwsh install.ps1 -Help` | exibe a ajuda ("Uso: .\install.ps1 [opções]") |
| `pwsh install.ps1 -Target '~/' -Global` (HOME temporário, sem `-Apply`) | `CRIAR .../.hermes/HERMES.md`, `Auditoria: 8 arquivo(s) novo(s); nenhuma alteração.`; nada criado em `.hermes` |
| `pwsh install.ps1 -Target <tmp> -WithAllSpecialists -Apply`, depois `install.sh` e `install.fish` no mesmo alvo | 93 arquivos; em seguida, `Instalados 0` e `Auditoria: 0` (idempotente entre os três instaladores) |
| `build_context_files_prompt` do Hermes no projeto instalado (repositório Git temporário) | `HERMES.md` carregado inteiro (abaixo do mínimo de 20.000 caracteres; sem truncamento) |
| `hermes chat -Q --oneshot` no projeto instalado | o modelo informou o H1 "Hermes Framework v5"; sem `trust`, nenhuma skill de projeto foi listada |
| Mesmo teste após `hermes skills trust` (revogado depois com `untrust`) | as sete skills de papel foram listadas como skills de projeto |
| Scanner de skills de projeto (`is_quarantined_project_skill`) com `--with-all-specialists` | 7 papéis e 9 especialistas aceitos; `zabbix-specialist` e `docker-kubernetes-specialist` em quarentena (`dangerous`, falsos positivos documentados no README) |
| `install.sh --global --with-zabbix-specialist --with-docker-kubernetes-specialist --apply` em HOME temporário, depois `skills_list`/`skill_view` do Hermes com esse `HERMES_HOME` | os dois especialistas e `luna-worker` listados e carregados (sem quarentena fora de skills de projeto) |

Os testes offline são os mesmos das variantes Gemini CLI e Cursor (o arquivo é idêntico). A pasta da ferramenta é detectada no payload, e os testes cobrem:

- auditoria sem escrita, instalação e idempotência;
- conflito sem instalação parcial e conflito de especialista;
- recusa de link simbólico (projeto, `--global` e `link/..`);
- barra final e `--target` sem valor;
- `.`, `..`, `~` e `~/` a partir do HOME tratados como instalação global, e `~foo` tratado como nome literal;
- criação exclusiva com shim de `mkdir`;
- ramificação "Link no pacote";
- instalação padrão sem nenhum especialista.

Modo de arquivo: apenas `scripts/install.fish` é executável. O instalador não preserva o bit de execução.

Não verificado:

- delegação real a um filho no `delegation.model` e execução Terra/Sol via `hermes chat -m` ou kanban;
- se o modelo respeita os papéis e os pisos de risco;
- Windows nativo;
- criação exclusiva sob corrida concorrente real (só simulada com shim).

## Cenários manuais de publicação

- Configure `delegation.model` com um modelo de faixa Luna. Peça uma publicação rotineira autorizada e confirme que o fluxo completo (status/diff, staging explícito, commit, push e hash de cada remote) vai para um filho do `delegate_task` instruído a carregar `luna-worker`.
- Deixe alterações não relacionadas no working tree e confirme que elas continuam fora do staging e fora do commit.
- Simule conflito ou escopo incerto e confirme que só essa unidade sobe para Terra ou Sol, por `hermes chat -m` ou kanban. Confirme também que o relatório não alega uma faixa sem evidência do modelo efetivo.

## Cenários manuais de roteamento

- **Trivial:** peça a correção de um erro de digitação em 2 arquivos de um componente e confirme a edição direta. Peça a mesma correção em 4 arquivos e confirme que a tarefa é delegada.
- **Sempre não trivial:** peça a criação de um host no Zabbix, uma alteração de segredo ou uma unit systemd e confirme a delegação.
- **Leitura pontual:** faça uma pergunta respondível com 2 arquivos já identificados e confirme a leitura direta, sem edição. Aponte um `.env` e confirme que o principal não o lê.
