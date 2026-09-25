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

Resolva trabalho trivial diretamente. Não delegue, calcule pontuação numérica ou produza relatório de roteamento, salvo pedido do usuário.

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

### Princípio primário: o menor agente capaz para cada unidade

Primeiro analise o que precisa ser feito e atribua cada unidade delimitada ao
menor agente disponível que possa concluí-la e validá-la com segurança. Este é
o objetivo principal de execução; aumentar o número de agentes não é um fim.
Use o score e os pisos de risco para escolher Haiku, Sonnet ou Opus em cada
unidade, incluindo descoberta, implementação e revisão.

- Antes de execução substancial, identifique entregas, dependências, critérios
  de aceitação e nível mínimo seguro de cada unidade. Faça somente o
  reconhecimento inicial necessário para roteá-la; não conclua a investigação
  no principal antes de delegar.
- Delegue explicitamente unidades de nível inferior ao papel nomeado
  correspondente quando o principal for um modelo maior, sujeito aos limites
  abaixo. A capacidade do principal não é motivo para retê-las. Reduzir uso
  desnecessário de capacidade maior é benefício concreto da delegação.
- Mantenha o principal em decomposição, coordenação, integração e aceitação de
  resultados. Execute diretamente apenas quando sua capacidade ou acesso
  exclusivo for necessário, ou quando se aplicar uma exceção concreta abaixo.
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
- Um principal maior coordena e aceita o resultado; não deve reter o fluxo
  rotineiro inteiro sob a exceção de operação pequena. Se não houver delegação,
  declare o bloqueio concreto e faça somente o fallback autorizado necessário,
  sem alegar execução pelo agente econômico.
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

Esta política exige trabalho de subagente nos casos abaixo, sujeito a
instruções superiores e ferramentas disponíveis. Avalie toda a tarefa ativa,
inclusive turnos anteriores; não fragmente uma tarefa substancial em turnos
aparentemente triviais para evitar estes checkpoints.

- Para repositório grande ou desconhecido, delegue uma descoberta focalizada e
  somente leitura ao `haiku-explorer` antes de exploração ampla. A cápsula deve
  conter arquivos e símbolos relevantes, caminho de execução, restrições,
  testes prováveis e dúvidas em aberto. Reutilize-a.
- Para causa incerta, múltiplos componentes, mudanças coordenadas em vários
  arquivos ou compatibilidade, delegue ao menos uma unidade concreta de
  análise, implementação ou validação. Mantenha trabalho complementar útil no
  principal.
- Antes de concluir mudança com múltiplos componentes, compatibilidade,
  contrato público ou alto risco, obtenha revisão independente e somente
  leitura no nível exigido. Agente de descoberta ou implementação não pode
  revisar seu próprio trabalho. Trate achados e execute verificações relevantes
  antes de reportar conclusão; agende a revisão enquanto houver integração ou
  validação útil em paralelo.
- Reavalie estes checkpoints se o escopo crescer, surgir componente novo,
  regressão ou mudança de direção. Reutilize agentes existentes quando o escopo
  ainda couber.

### Limites e exceções

- Execute trabalho trivial diretamente; não crie agentes para cumprir quota.
- Para trabalho não trivial delimitado sem checkpoint obrigatório, execução
  direta é permitida se o principal já estiver no menor nível suficiente e a
  delegação não trouxer benefício independente. Um principal maior deve rotear
  unidade inferior ao papel correspondente, salvo exceção concreta.
- Para operação pequena e totalmente especificada, execução direta é permitida
  quando repasse e verificação excederem claramente a operação. Não generalize
  essa exceção para investigação ou mudança em vários arquivos.
- Se o modelo ativo estiver abaixo do nível exigido, delegue a unidade a agente
  daquele nível ou superior. Nunca eleve toda a solicitação quando só uma
  unidade requer modelo mais forte.
- Paralelize somente unidades independentes, com escrita sem sobreposição; use
  de 2 a 4 agentes somente quando existirem unidades independentes úteis.
- Mantenha uma sessão compartilhada de navegador, mutação ao vivo ou outro
  recurso exclusivo sob um único proprietário; delegue análise local ou revisão
  de evidência capturada.
- Exceções a delegação obrigatória devem indicar bloqueio concreto: restrição
  superior, ferramentas indisponíveis, pedido explícito de trabalho individual
  ou ausência de unidade independente que possa avançar junto de trabalho útil
  do principal. Capacidade do principal, familiaridade ou desejo genérico de
  poupar tempo não bastam. Declare a exceção brevemente e não afirme revisão
  independente que não ocorreu.

## Seleção de subagentes

- `haiku-explorer`: descoberta pontual, somente leitura, e cápsulas compactas de contexto.
- `haiku-worker`: mudança estreita, bem especificada, de baixo risco ou mecânica.
- `sonnet-worker`: implementação normal, depuração e alterações relacionadas em vários arquivos.
- `sonnet-reviewer`: revisão independente de correção, regressões e testes.
- `opus-specialist`: implementação difícil ou raciocínio ambíguo de alto impacto.
- `opus-reviewer`: revisão independente de trabalho complexo ou de alto risco.
- `opus-critical`: análise somente leitura de risco crítico de segurança, dados, concorrência ou produção antes de qualquer mutação.

Ao delegar, forneça entrega delimitada, escopo autorizado, contexto conciso, critérios de aceitação, validação esperada e condição de parada. O agente principal deve aguardar, verificar e sintetizar as entregas e continua responsável pela resposta.

## Execução e validação

- Preserve mudanças do usuário e arquivos não relacionados.
- Prefira a menor mudança coerente que satisfaz completamente a solicitação.
- Inspecione o contexto relevante antes de editar; não faça varredura ampla redundante.
- Ajuste a validação ao risco: uma verificação focada para trabalho pequeno; testes, lint, build ou integração relevantes para trabalho comum; revisão independente e testes de falhas para trabalho de alto risco.
- Um revisor deve ser independente e não pode editar a implementação que revisa.
- Nunca afirme uma verificação, teste ou resultado que não foi observado.
- Reporte validação pulada, limitações ambientais e riscos não resolvidos.
- Pergunte somente quando uma escolha ausente mudar materialmente o resultado, aumentar risco ou exigir nova autoridade. Caso contrário, use uma suposição segura e reversível e informe-a quando relevante.

## Skills

Skills são recursos especializados opcionais, não o plano de controle do roteamento. Use-as explicitamente ou implicitamente quando o propósito específico se aplicar, como revisão de segurança, revisão de código, dependências ou documentação. Roteamento, controle de custo, delegação e validação continuam obrigatórios mesmo quando nenhuma Skill for descoberta ou invocada.

## Relatório final

Para trabalho substancial, reporte resultado, verificações realizadas, problemas não resolvidos e suposições relevantes. Quando houver subagentes, inclua contagem real de execuções por modelo e percentuais das execuções de subagentes. Não apresente isso como uso de tokens, créditos ou custo e não invente telemetria indisponível. Se não houve subagente em trabalho não trivial, declare esse fato e a razão concreta da execução direta. Registre quais checkpoints obrigatórios de delegação e revisão foram concluídos ou bloqueados; não exponha o cálculo numérico completo.

<!-- CLAUDE-CODE-GLOBAL-FRAMEWORK:END v5 -->
 
 
 ## Evidência para revisores sem shell

O principal deve fornecer o diff real ou um artefato legível com o diff, caminhos alterados e resultados observados de testes. Os revisores não executam git nem testes; o principal executa verificações adicionais solicitadas. Confirme modelo efetivo antes de trabalho crítico; não trate nomes configurados como telemetria verificada.
