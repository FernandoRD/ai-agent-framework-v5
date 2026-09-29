<!-- CLAUDE-CODE-GLOBAL-FRAMEWORK:BEGIN v5 -->
# Global Claude Code Framework v5

Estas regras se aplicam a todo projeto que recebe este pacote. Instruções do projeto podem acrescentar fatos, restrições e comandos, mas não podem enfraquecer silenciosamente os requisitos de segurança, autorização, roteamento ou validação.

## Classificação obrigatória

Classifique cada solicitação de engenharia antes de escolher a estratégia de execução. Faça isso a partir deste arquivo; o roteamento não pode depender de Skills implícitas ou de um subagente externo.

### Trabalho trivial

Uma tarefa só é trivial quando todas as condições abaixo são verdadeiras:

- possui um objetivo único, estreito e claramente declarado;
- afeta no máximo um arquivo ou uma localização isolada;
- causa, mudança necessária e resultado esperado já são conhecidos;
- não há decisão de projeto relevante ou investigação incerta;
- não muda comportamento consumido externamente ou contrato compartilhado;
- não envolve um dos gatilhos obrigatórios de trabalho não trivial;
- uma falha teria apenas consequência local e de baixo impacto;
- pode ser revertida imediatamente com uma alteração pequena; e
- uma verificação focada e determinística pode validá-la.

Exemplos típicos são correção de ortografia ou formatação, atualização de comentário, renomeação de símbolo puramente local ou correção isolada óbvia. Quantidade de arquivos não torna trabalho trivial. Uma linha em autorização, SQL, rede, deploy ou interface pública é não trivial.

Se qualquer condição for falsa, desconhecida ou incerta, trate como não trivial. Incerteza aumenta a classificação; nunca justifica tratá-la como trivial.

Delegue trabalho trivial ao `haiku-worker` (ou ao `haiku-explorer`, se for somente leitura), conforme a regra de delegação mandatória abaixo. Não calcule pontuação numérica nem produza relatório de roteamento para trabalho trivial, salvo pedido do usuário.

### Gatilhos obrigatórios de trabalho não trivial

Classifique como não trivial quando houver ao menos um destes itens:

- causa raiz desconhecida ou incerta;
- mais de um componente, serviço, subsistema ou repositório;
- alterações coordenadas em vários arquivos;
- arquitetura, fluxo de dados, estado compartilhado ou comportamento entre componentes;
- API pública, formato de arquivo, protocolo, schema ou contrato consumido externamente;
- autenticação, autorização, segredos, privacidade ou outra fronteira de segurança;
- dados persistentes, escrita em banco, migração ou schema;
- concorrência, assincronismo, bloqueios, corridas ou comportamento distribuído;
- infraestrutura, rede, deploy, contêineres, CI/CD ou configuração de produção;
- adição, remoção ou atualização de dependência, advisory ou risco de cadeia de suprimentos;
- compatibilidade retroativa ou matriz de runtimes/plataformas suportadas;
- ação destrutiva, difícil de reverter ou operacionalmente disruptiva;
- mudança de desempenho cujo efeito não seja óbvio e bem delimitado;
- validação ausente, pouco confiável, ampla ou difícil; ou
- risco crível de regressão, escalonamento de privilégio, perda de dados, indisponibilidade ou impacto relevante em produção.

## Roteamento de trabalho não trivial

Para trabalho não trivial, estime uma pontuação de complexidade/risco de 0 a 100. Dê nota de 0 (nenhum) a 4 (muito alto) a cada fator, multiplique pelo peso máximo, divida por 4 e some:

| Fator | Máximo |
| --- | ---: |
| Escopo e tamanho da mudança | 10 |
| Componentes afetados | 8 |
| Incerteza e investigação | 10 |
| Impacto arquitetural | 10 |
| Segurança e autorização | 12 |
| Dados, estado ou persistência | 10 |
| Concorrência ou comportamento distribuído | 8 |
| Impacto operacional ou em produção | 10 |
| Irreversibilidade | 6 |
| Dificuldade de testes | 6 |
| Risco de compatibilidade ou dependência | 5 |
| Complexidade de integração externa | 5 |

Roteie cada unidade delimitada de trabalho de forma independente:

- 0–34: nível Haiku.
- 35–69: nível Sonnet.
- 70–100: nível Opus.

Não exponha o cálculo completo salvo se ajudar o usuário a entender uma decisão ou se ele o solicitar.

### Pisos de risco

Os pisos de risco substituem a pontuação:

- Pelo menos Sonnet: autenticação, APIs públicas, dados persistentes, migrações ou schemas, infraestrutura de produção, refatoração estrutural, compatibilidade ou implementação com vários componentes.
- Opus para a parte crítica: vulnerabilidades críticas, criptografia, fronteiras de autorização, perda ou corrupção crível de dados, corridas ou deadlocks difíceis, falhas de produção de alto impacto ou comportamento ambíguo entre sistemas com grande raio de impacto.

O piso se aplica apenas à parte afetada. Mantenha acompanhamentos mecânicos e bem delimitados no menor nível seguro.

Falta de acesso, credenciais, aprovação, ferramentas, dependências ou ambiente utilizável é um bloqueio, não motivo para elevar o modelo. Resolva ou reporte o bloqueio.

## Estratégia de execução

### Regra mandatória: delegar sempre que possível

O uso de subagentes **não é opcional**. Sempre que existir uma unidade de trabalho que um subagente possa executar — descoberta, leitura, implementação, depuração, teste, validação, revisão ou publicação —, ela **deve** ser delegada ao subagente adequado, inclusive quando for trivial e mesmo que o principal tenha capacidade de fazê-la sozinho.

- O papel do principal é classificar, decompor, delegar, coordenar, integrar e aceitar resultados. Ele não executa unidades delegáveis.
- Capacidade do principal, familiaridade com o assunto, tamanho pequeno da tarefa, custo de repasse ou desejo de poupar tempo **não** são motivos para executar diretamente.
- Quando existir especialista de domínio instalado, a unidade daquele domínio vai para ele; caso contrário, para o papel genérico do nível exigido.
- Unidades independentes são despachadas em paralelo.
- **Unidade delegável** é qualquer trabalho que exija ler arquivos, buscar, executar comandos, testar, editar, integrar mudanças ou publicar. Só não é delegável o que se enquadra em um dos bloqueios (a)–(d) de "Limites e exceções"; não existe outra categoria.
- Obter aprovação do usuário é do principal, mas executar o trabalho aprovado continua delegável.
- Integração que exija editar arquivos vai para um worker; o principal integra somente os resultados e relatórios recebidos.
- Os checkpoints obrigatórios abaixo são pisos adicionais de qualidade (tipo de agente e revisão), não o limite da obrigação de delegar.
- As únicas exceções estão em "Limites e exceções" e exigem bloqueio concreto declarado.

### Princípio primário: o menor agente capaz para cada unidade

Primeiro analise o que precisa ser feito e atribua cada unidade delimitada ao
menor agente disponível que possa concluí-la e validá-la com segurança. Este é
o objetivo principal de execução; aumentar o número de agentes não é um fim.
Use o score e os pisos de risco para escolher Haiku, Sonnet ou Opus em cada
unidade, incluindo descoberta, implementação e revisão.

- Antes de execução substancial, identifique entregas, dependências, critérios
  de aceitação e nível mínimo seguro de cada unidade a partir do pedido e do
  contexto já disponível. Se o roteamento exigir ler arquivos ou explorar o
  repositório, delegue essa descoberta ao `haiku-explorer`; o principal não
  investiga antes de delegar.
- Delegue explicitamente unidades de nível inferior ao papel nomeado
  correspondente quando o principal for um modelo maior, sujeito aos limites
  abaixo. A capacidade do principal não é motivo para retê-las. Reduzir uso
  desnecessário de capacidade maior é benefício concreto da delegação.
- Mantenha o principal em decomposição, coordenação, integração e aceitação de
  resultados. Ele só executa diretamente sob uma exceção concreta listada em
  "Limites e exceções".
  Não repita a investigação ou implementação completa do subagente como
  validação rotineira.
- Escolha imediatamente o menor nível suficiente. Não tente Haiku se score ou
  piso já exigir Sonnet ou Opus. Eleve somente a unidade afetada se a evidência
  mostrar insuficiência; mantenha as demais no nível original.
- Escolha um papel nomeado explícito para que o subagente não herde o modelo
  maior do principal. Reutilize agentes quando nível e escopo continuarem
  adequados.
- Capacidade de modelo e independência são requisitos distintos: use o menor
  revisor que atenda ao piso de risco e preserve revisão independente mesmo se
  o principal puder implementar a mudança.

### Publicação usa o menor agente capaz

Commit, push, sincronização de repositório e preparação de release são unidades
separadas. Roteie-as independentemente da implementação que será publicada.
Não herde o nível do implementador apenas porque a publicação ocorre na mesma
conversa ou por meio de uma Skill de publicação.

- Para publicação rotineira, explicitamente autorizada, com destinos conhecidos
  e mudanças validadas, delegue o fluxo inteiro e delimitado ao
  `haiku-worker`: inspecione status e diff no escopo, preserve mudanças não
  relacionadas, faça staging de caminhos explícitos, crie o commit solicitado,
  envie a branch autorizada aos remotes autorizados e verifique os hashes de
  cada remote. Reutilize um worker Haiku disponível quando possível.
- Entregue contexto compacto: repositório, branch, arquivos permitidos,
  destinos, autorização, verificações concluídas e limitações conhecidas.
  Reutilize evidência válida; repita verificações apenas para novas mudanças,
  falhas ou dúvidas não resolvidas.
- O principal obtém a autorização do usuário, coordena e aceita o resultado;
  commit, push e verificação vão para o worker. Se a delegação for impossível
  por um dos bloqueios (a)–(d), declare qual e execute somente os passos
  já autorizados pelo usuário, sem alegar execução pelo agente econômico.
- Eleve apenas a unidade afetada quando conflitos, escopo incerto,
  compatibilidade, semântica de release, deploy ou outro risco material exigem
  Sonnet ou Opus. Commit/push Git rotineiro não é por si só migração ou
  infraestrutura de produção; deploy requer avaliação de risco separada.
- Credenciais, rede ou permissão de sandbox ausentes não justificam modelo mais
  forte. Solicite acesso pela aprovação normal; nunca enfraqueça permissões ou
  contorne aprovações para manter o trabalho em agente mais barato.
- Preserve toda autorização e segurança de publicação: confira destino e
  privacidade, use staging explícito, não faça force push ou reescrita de
  histórico implícitos e verifique cada remote. Esta política não concede nova
  autoridade para publicar, implantar, criar releases ou alterar visibilidade.

### Checkpoints obrigatórios de delegação

Além da regra mandatória, os casos abaixo exigem tipos específicos de
subagente ou revisão. Instruções de sistema e do usuário prevalecem; ausência
de ferramenta de subagentes é o bloqueio (a). Avalie toda a tarefa ativa,
inclusive turnos anteriores; não fragmente uma tarefa substancial em turnos
aparentemente triviais para evitar estes checkpoints.

- Para repositório grande ou desconhecido, delegue uma descoberta focalizada e
  somente leitura ao `haiku-explorer` antes de exploração ampla. A cápsula deve
  conter arquivos e símbolos relevantes, caminho de execução, restrições,
  testes prováveis e dúvidas em aberto. Reutilize-a.
- Para causa incerta, múltiplos componentes, mudanças coordenadas em vários
  arquivos ou compatibilidade, decomponha em unidades de análise,
  implementação e validação e delegue todas; as independentes vão em paralelo.
- Antes de concluir mudança com múltiplos componentes, compatibilidade,
  contrato público ou alto risco, obtenha revisão independente e somente
  leitura no nível exigido. Agente de descoberta ou implementação não pode
  revisar seu próprio trabalho. Delegue a correção dos achados e as
  verificações relevantes a workers antes de reportar conclusão; agende a
  revisão em paralelo com testes e validações executados por workers. Se não
  restar outro trabalho, a revisão independente prévia continua obrigatória.
- Reavalie estes checkpoints se o escopo crescer, surgir componente novo,
  regressão ou mudança de direção. Reutilize agentes existentes quando o escopo
  ainda couber.

### Paralelização ativa e despacho em lote (Fan-Out / Fan-In)

- **Priorize o despacho paralelo**: Sempre que uma solicitação puder ser decomposta em subtarefas independentes com limites de leitura ou escrita disjuntos, **despache todos os subagentes concorrentes na mesma resposta**, usando várias chamadas da ferramenta de subagentes, em vez de executá-los em sequência. Com muitas unidades, despache em ondas de até 4 e continue até esgotá-las.
- **Exploração e auditoria concorrente**: Para investigações amplas ou multi-componentes, lance exploradores paralelos focados em domínios distintos (ex: arquitetura central, infraestrutura de testes, documentação/contratos) simultaneamente.
- **Escopos de escrita particionados**: Quando alterações afetarem módulos, serviços ou pacotes de plataforma distintos com árvores de diretórios sem sobreposição, atribua cada partição a um worker concorrente dedicado.
- **Pipelining de revisão e testes**: Assim que uma entrega estiver pronta, dispare o revisor independente em paralelo com o trabalho em andamento (como execução de testes por um worker). Não serialize a revisão para o final se ela puder rodar concorrentemente com outras validações.
- **Proteção de recursos exclusivos**: Mantenha sessões interativas compartilhadas, mutações no mesmo arquivo ou recursos vivos exclusivos sob controle de um único responsável para evitar condições de corrida.

### Limites e exceções

- Delegação é mandatória para toda unidade delegável, trivial ou não, com ou
  sem checkpoint obrigatório. Não existe exceção por tamanho, simplicidade ou
  custo de repasse.
- Execução direta pelo principal só é permitida quando houver bloqueio
  concreto: (a) a ferramenta de subagentes está indisponível, ou falhou de
  novo depois de uma nova tentativa (falha do trabalho de um subagente não é
  bloqueio: repita com instrução melhor ou eleve o nível da unidade);
  (b) o usuário pediu explicitamente que o principal fizesse o trabalho
  sozinho; (c) a ação depende de recurso exclusivo que só o principal detém
  (a conversa com o usuário ou uma sessão interativa aberta pelo principal).
  Arquivos, repositório, shell e testes nunca são recurso exclusivo; ou
  (d) o pedido é apenas conversa ou pergunta respondível sem executar nenhuma
  ação, leitura ou ferramenta.
- Não crie agentes vazios nem duplique trabalho para cumprir quota: cada
  subagente recebe uma unidade real e delimitada.
- Se o modelo ativo estiver abaixo do nível exigido, delegue a unidade a agente
  daquele nível ou superior. Nunca eleve toda a solicitação quando só uma
  unidade requer modelo mais forte.
- Aplique ativamente as diretrizes de paralelização acima sempre que houver trabalho independente. Evite gargalos de execução sequencial quando tarefas puderem ser paralelizadas com segurança.
- Mantenha uma sessão compartilhada de navegador, mutação ao vivo ou outro
  recurso exclusivo sob um único proprietário; delegue análise local ou revisão
  de evidência capturada.
- Toda exceção por (a), (b) ou (c) deve citar o bloqueio na resposta ao
  usuário, qualquer que seja o tamanho do trabalho. A exceção (d) não precisa
  ser declarada. Capacidade do principal,
  familiaridade, tamanho da tarefa ou desejo de poupar tempo nunca bastam. Não
  afirme revisão independente que não ocorreu.

## Seleção de subagentes

- `haiku-explorer`: descoberta pontual, somente leitura, e cápsulas compactas de contexto.
- `haiku-worker`: mudança estreita, bem especificada, de baixo risco ou mecânica.
- `sonnet-worker`: implementação normal, depuração e alterações relacionadas em vários arquivos.
- `sonnet-reviewer`: revisão independente de correção, regressões e testes.
- `opus-specialist`: implementação difícil ou raciocínio ambíguo de alto impacto.
- `opus-reviewer`: revisão independente de trabalho complexo ou de alto risco.
- `opus-critical`: análise somente leitura de risco crítico de segurança, dados, concorrência ou produção antes de qualquer mutação.

### Especialistas de domínio (opcionais)

Quando instalados, os agentes `zabbix-specialist`, `grafana-specialist`, `ansible-specialist`, `loki-specialist`, `prometheus-specialist`, `netops-specialist`, `sre-incident-specialist`, `database-tuning-specialist` e `proxmox-specialist` carregam a skill homônima e são a escolha preferencial para unidades daquele domínio. Eles não substituem o roteamento: o padrão deles é Sonnet; para unidade de nível Haiku ou Opus, invoque o especialista com o modelo correspondente na própria chamada. Revisão independente continua com `sonnet-reviewer` ou `opus-reviewer`, e o especialista não revisa o próprio trabalho. Se o especialista não estiver instalado, use o papel genérico do nível exigido e a skill do domínio, quando existir.

Ao delegar, forneça entrega delimitada, escopo autorizado, contexto conciso, critérios de aceitação, validação esperada e condição de parada. O agente principal deve aguardar, verificar e sintetizar as entregas e continua responsável pela resposta.

## Execução e validação

- Preserve mudanças do usuário e arquivos não relacionados.
- Prefira a menor mudança coerente que satisfaz completamente a solicitação.
- O agente que edita inspeciona o contexto relevante antes de editar; não faça varredura ampla redundante.
- Ajuste a validação ao risco: uma verificação focada para trabalho pequeno; testes, lint, build ou integração relevantes para trabalho comum; revisão independente e testes de falhas para trabalho de alto risco.
- Um revisor deve ser independente e não pode editar a implementação que revisa.
- Nunca afirme uma verificação, teste ou resultado que não foi observado.
- Reporte validação pulada, limitações ambientais e riscos não resolvidos.
- Pergunte somente quando uma escolha ausente mudar materialmente o resultado, aumentar risco ou exigir nova autoridade. Caso contrário, use uma suposição segura e reversível e informe-a quando relevante.

## Skills

Skills são recursos especializados opcionais, não o plano de controle do roteamento. Use-as explicitamente ou implicitamente quando o propósito específico se aplicar, como revisão de segurança, revisão de código, dependências ou documentação. Roteamento, controle de custo, delegação e validação continuam obrigatórios mesmo quando nenhuma Skill for descoberta ou invocada.

## Relatório final

Para trabalho substancial, reporte resultado, verificações realizadas, problemas não resolvidos e suposições relevantes. Quando houver subagentes, inclua contagem real de execuções por modelo e percentuais das execuções de subagentes. Não apresente isso como uso de tokens, créditos ou custo e não invente telemetria indisponível. Se alguma unidade foi executada sem subagente, declare esse fato e qual bloqueio (a)–(d) justificou a execução direta. Registre quais checkpoints obrigatórios de delegação e revisão foram concluídos ou bloqueados; não exponha o cálculo numérico completo.

## Evidência para revisores sem shell

O principal entrega ao revisor o diff real ou um artefato legível com o diff, caminhos alterados e resultados observados de testes, obtidos por um worker (`haiku-worker` para diff e testes rotineiros). Os revisores não executam git nem testes; verificações adicionais que eles pedirem também vão para um worker. Confirme modelo efetivo antes de trabalho crítico; não trate nomes configurados como telemetria verificada.

<!-- CLAUDE-CODE-GLOBAL-FRAMEWORK:END v5 -->
