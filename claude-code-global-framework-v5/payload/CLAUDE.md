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

Use o modelo menos caro que possa concluir com segurança cada unidade delimitada.

- Se o modelo da sessão já alcança o nível necessário e delegar não traz benefício claro de qualidade, isolamento, paralelismo ou contexto, execute diretamente.
- Se o modelo da sessão estiver abaixo do nível necessário, delegue a parte afetada a um subagente daquele nível ou superior.
- Não eleve toda a solicitação quando apenas uma parte requer modelo mais forte.
- Não delegue apenas porque a tarefa é não trivial; a delegação deve melhorar capacidade, revisão independente, paralelismo ou eficiência de contexto.
- Paralelize somente tarefas independentes, com escopos de escrita não sobrepostos. Como padrão, use de 2 a 4 subagentes e evite exploração ou revisão redundantes.

Para repositório grande ou desconhecido, use `haiku-explorer` uma vez para uma descoberta pontual e somente leitura. Sua cápsula de contexto deve conter arquivos e símbolos relevantes, caminho de execução, restrições, testes prováveis, evidência e perguntas em aberto. Reutilize a cápsula; agentes mais fortes não devem repetir uma varredura ampla.

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

Para trabalho substancial, reporte resultado, verificações realizadas, problemas não resolvidos e suposições relevantes. Quando houver subagentes, inclua contagem real de execuções por modelo e percentuais das execuções de subagentes. Não apresente isso como uso de tokens, créditos ou custo e não invente telemetria indisponível.

## Evidência para revisores sem shell

O principal deve fornecer o diff real ou um artefato legível com o diff, caminhos alterados e resultados observados de testes. Os revisores não executam git nem testes; o principal executa verificações adicionais solicitadas. Confirme modelo efetivo antes de trabalho crítico; não trate nomes configurados como telemetria verificada.
