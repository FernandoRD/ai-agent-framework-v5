# AGENTS.md — Codex Multi-Agent Smart Routing

## 0. Objetivo

Este projeto usa um modelo de execução multi-agent orientado por custo, risco e complexidade.

O agente principal deve atuar prioritariamente como **orquestrador**, não como executor universal.

Objetivos:
1. analisar silenciosamente cada novo pedido;
2. decompor o trabalho em subtarefas quando isso reduzir custo, risco ou tempo;
3. calcular a complexidade de cada subtarefa;
4. aplicar ajustes, bônus e overrides;
5. delegar cada subtarefa ao modelo mais barato que consiga executá-la com alta probabilidade de sucesso;
6. executar subtarefas independentes em paralelo quando seguro;
7. preservar contexto por handoffs curtos e objetivos;
8. escalar apenas quando houver justificativa técnica;
9. integrar e validar os resultados antes de declarar conclusão.

Prioridade de custo/capacidade:

**Luna → Terra → Sol**

Política padrão:
- **Terra** = orquestrador principal e executor de tarefas moderadas.
- **Luna** = worker preferencial para tarefas simples, mecânicas, exploratórias ou de alto volume.
- **Sol** = especialista para tarefas realmente complexas, críticas ou de alto risco.

Nunca use um modelo mais caro apenas porque ele é mais capaz.

---

# 1. Regra principal

Antes de executar CADA novo pedido do usuário:

1. compreenda o objetivo;
2. avalie se deve decompor o pedido;
3. calcule o score de cada subtarefa;
4. aplique ajustes críticos;
5. aplique bônus de simplificação;
6. aplique overrides;
7. escolha o modelo mínimo suficiente;
8. defina dependências entre subtarefas;
9. identifique o que pode rodar em paralelo;
10. execute/delegue;
11. integre;
12. teste e valide;
13. somente então responda ao usuário.

A análise de roteamento deve ser feita **a cada novo turno**, e não apenas no primeiro pedido da sessão.

---

# 2. Princípio de economia

A decisão deve obedecer a esta ordem:

1. reduzir o escopo;
2. melhorar o contexto;
3. decompor a tarefa;
4. usar Luna;
5. usar Terra;
6. usar Sol somente quando necessário.

> O objetivo não é escolher o modelo mais poderoso. O objetivo é escolher o modelo mais barato com capacidade e margem de segurança suficientes para executar corretamente cada subtarefa.

Quando dois modelos forem plausíveis, escolha o mais barato.

---

# 3. Papel do agente principal

O agente principal deve funcionar principalmente como **orquestrador**.

Responsabilidades:
- entender o pedido;
- decompor;
- calcular scores;
- decidir dependências;
- decidir paralelismo;
- escolher o modelo por subtarefa;
- delegar;
- acompanhar resultados;
- revisar handoffs;
- integrar alterações;
- executar validação final;
- comunicar resultados ao usuário.

Se o agente principal for Terra:
- não execute trabalho de Luna apenas por conveniência;
- não faça trabalho de Sol se houver motivo técnico para escalonamento;
- reserve seu próprio trabalho para coordenação, integração e tarefas moderadas.

---

# 4. Política de subagentes

Quando a capacidade multi-agent estiver disponível, prefira `spawn_agent` para trabalho concreto, limitado e delegável.

Subagentes devem receber tarefas:
- bem delimitadas;
- independentes sempre que possível;
- com arquivos ou áreas claramente definidos;
- com critérios de conclusão;
- com instruções explícitas para testar;
- sem necessidade de reler o repositório inteiro.

Não delegue uma tarefa vaga como:

> Analise todo o projeto e veja o que acha.

Prefira:

> Analise `src/auth/` e identifique onde o refresh token é validado. Não altere arquivos. Retorne arquivos, funções e riscos encontrados.

---

# 5. Seleção de modelo do subagente

Quando `spawn_agent` expuser override de modelo, use-o conforme este documento.

Prioridade:
1. Luna
2. Terra
3. Sol

Se o modelo recomendado não estiver disponível como override naquela versão/superfície do Codex:
- escolha o modelo disponível imediatamente acima;
- registre internamente o fallback;
- não interrompa a tarefa apenas por indisponibilidade do modelo barato.

Exemplo:
- tarefa classificada para Luna;
- Luna indisponível no `spawn_agent`;
- usar Terra;
- não escalar para Sol.

Nunca escolha Sol apenas porque Luna não está disponível.

Subagentes herdam o modelo do pai por padrão. Portanto, **sempre use override explícito quando o roteamento exigir um modelo diferente e a ferramenta permitir**.

---

# 6. Reasoning effort

Use esforço proporcional à tarefa.

## Luna
- `low` para exploração, busca, alterações mecânicas e documentação;
- `medium` para tarefas simples com alguma lógica;
- evite `high/max` salvo necessidade concreta.

## Terra
- `medium` para implementação normal;
- `high` para debugging, refactoring complexo ou integração;
- `max` somente quando realmente necessário.

## Sol
- `high` para tarefas complexas;
- `max` apenas para problemas excepcionalmente difíceis, críticos ou de causa raiz obscura.

Não aumente reasoning effort automaticamente só porque o modelo é mais poderoso.

---

# 7. Score de complexidade

Avalie cada fator de **0 a 5**.

Escala:
- 0 = inexistente ou irrelevante
- 1 = muito baixo
- 2 = baixo
- 3 = moderado
- 4 = alto
- 5 = crítico

## Peso 1
- Escopo de arquivos ×1
- Quantidade de contexto necessário ×1
- Ambiguidade do requisito ×1

## Peso 2
- Complexidade lógica ×2
- Conhecimento arquitetural necessário ×2
- Acoplamento e dependências ×2
- Dificuldade de debugging ×2
- Risco de regressão ×2
- Impacto operacional ×2

## Peso 3
- Segurança ×3
- Dados e persistência ×3
- Concorrência e paralelismo ×3

---

# 8. Critérios dos fatores

## Escopo de arquivos ×1
- 0 = nenhum arquivo ou alteração trivial
- 1 = 1 arquivo
- 2 = poucos arquivos próximos
- 3 = vários arquivos no mesmo módulo
- 4 = múltiplos módulos
- 5 = grande parte do repositório

Volume sozinho não implica alta complexidade.

## Quantidade de contexto ×1
- 0 = contexto já conhecido
- 1 = função/classe isolada
- 2 = pequeno módulo
- 3 = vários módulos relacionados
- 4 = arquitetura ampla
- 5 = grande parte do projeto ou sistemas externos

## Ambiguidade ×1
- 0 = resultado totalmente definido
- 1 = detalhe menor aberto
- 2 = pequenas decisões necessárias
- 3 = múltiplas interpretações plausíveis
- 4 = requisitos incompletos relevantes
- 5 = comportamento esperado pouco definido

## Complexidade lógica ×2
- 0 = alteração mecânica
- 1 = lógica trivial
- 2 = fluxo simples
- 3 = várias condições/estados
- 4 = algoritmo ou domínio complexo
- 5 = lógica altamente complexa

## Conhecimento arquitetural ×2
- 0 = isolado
- 1 = padrão local claro
- 2 = um componente
- 3 = vários componentes
- 4 = arquitetura global relevante
- 5 = decisão arquitetural profunda

## Acoplamento e dependências ×2
- 0 = independente
- 1 = poucas dependências
- 2 = dependências locais
- 3 = múltiplos módulos
- 4 = vários serviços/componentes
- 5 = sistema altamente acoplado/distribuído

## Dificuldade de debugging ×2
- 0 = sem debugging
- 1 = erro evidente
- 2 = causa provável
- 3 = investigação moderada
- 4 = causa incerta
- 5 = intermitente, não determinístico ou sem causa raiz conhecida

## Risco de regressão ×2
- 0 = praticamente nenhum
- 1 = impacto muito localizado
- 2 = baixo
- 3 = moderado
- 4 = alto
- 5 = crítico

## Impacto operacional ×2
- 0 = local
- 1 = desenvolvimento
- 2 = ambiente não crítico
- 3 = serviço compartilhado
- 4 = produção relevante
- 5 = produção crítica/alta disponibilidade

## Segurança ×3
- 0 = nenhuma implicação
- 1 = mínima
- 2 = validações comuns
- 3 = autenticação/autorização conhecida
- 4 = exposição de dados ou controle de acesso sensível
- 5 = vulnerabilidade, exploitabilidade, isolamento ou criptografia crítica

## Dados e persistência ×3
- 0 = nenhum dado persistente
- 1 = leitura simples
- 2 = escrita comum
- 3 = schema/migração controlada
- 4 = integridade relevante
- 5 = risco de corrupção/perda irreversível

## Concorrência e paralelismo ×3
- 0 = inexistente
- 1 = async simples
- 2 = paralelismo conhecido
- 3 = sincronização moderada
- 4 = concorrência difícil
- 5 = race condition, deadlock ou comportamento não determinístico

---

# 9. Cálculo

Máximo bruto:
- peso 1 = 15
- peso 2 = 60
- peso 3 = 45

**Total = 120**

`score_base = round((score_bruto / 120) * 100)`

---

# 10. Ajustes críticos

Depois do score base:
- Segurança = 4 ou 5 → **+8**
- Dados/persistência = 4 ou 5 → **+8**
- Concorrência = 4 ou 5 → **+10**
- Debugging = 5 → **+8**
- Risco de regressão = 5 → **+6**
- Impacto operacional = 5 → **+6**

Score máximo: **100**

---

# 11. Bônus de simplificação

Quando aplicável:
- alteração puramente mecânica → **−15**
- testes existentes cobrindo completamente → **−5**
- implementação seguindo padrão já existente → **−8**
- tarefa totalmente localizada → **−5**
- documentação/configuração sem lógica → **−15**

Score mínimo: **0**

Não aplique bônus que esconda risco real.
Não aplique bônus para reduzir tarefa que acionou `FORCE_SOL`.

`score_final = clamp(score_base + ajustes - bonus, 0, 100)`

---

# 12. Faixas

## 0–34 → Luna

Use para:
- exploração;
- busca de arquivos/referências;
- leitura localizada;
- alterações mecânicas;
- renomes;
- imports;
- boilerplate;
- documentação;
- configuração simples;
- código repetitivo;
- testes simples;
- pequenas correções;
- alto volume com baixa complexidade.

Reasoning: `low`, ocasionalmente `medium`.

## 35–69 → Terra

Use para:
- implementação normal de features;
- integrações;
- APIs;
- refactoring não trivial;
- debugging comum;
- vários arquivos;
- testes de integração;
- lógica moderada;
- coordenação.

Reasoning: `medium`, escalando para `high` quando necessário.

## 70–100 → Sol

Use para:
- debugging difícil;
- arquitetura crítica;
- concorrência;
- não determinismo;
- segurança profunda;
- integridade crítica de dados;
- causa raiz obscura;
- grande risco de regressão.

Antes de selecionar Sol:
1. tente decompor;
2. identifique se só uma subtarefa precisa dele;
3. mantenha o resto em Luna/Terra.

Reasoning: `high`; `max` apenas quando justificado.

---

# 13. Overrides

Overrides vencem o score.

## MIN_TERRA

Use no mínimo Terra quando houver:
- alteração de API pública;
- migração de banco;
- alteração relevante de schema;
- autenticação/autorização relevante;
- múltiplos serviços;
- infraestrutura de produção;
- refactoring estrutural;
- CI/CD relevante;
- contrato entre componentes;
- possibilidade de indisponibilidade perceptível.

Aplica-se somente à subtarefa afetada.

## FORCE_SOL

Use Sol quando houver:
- vulnerabilidade crítica/potencialmente explorável;
- análise de exploitabilidade;
- código criptográfico;
- race condition difícil;
- deadlock;
- corrupção de dados;
- risco de perda irreversível;
- incidente crítico sem causa raiz;
- decisão arquitetural de grande impacto;
- debugging não determinístico multissistema;
- falha intermitente sem causa após investigação razoável;
- autorização crítica;
- isolamento de tenants;
- controle de acesso crítico;
- alto impacto combinado com baixa reversibilidade.

Aplica-se somente à subtarefa afetada.

---

# 14. Overrides de economia

## Volume não força modelo caro
Muitos arquivos, por si só, não justificam Terra/Sol.

## Repositório grande não força Sol
Use Luna para explorar, reduzir contexto e produzir handoff antes de escalar.

## Segurança moderada não força Sol
OAuth seguindo padrão existente, RBAC simples, validação conhecida, headers de segurança e correções já compreendidas podem ficar em Terra.

---

# 15. Decomposição

Antes de um modelo mais caro, pergunte:

> Esta tarefa pode ser dividida para que partes sejam executadas por um modelo mais barato?

Exemplo OAuth:
1. localizar autenticação atual → Luna
2. mapear dependências → Luna
3. entender arquitetura → Terra
4. implementar → Terra
5. configuração → Luna
6. testes simples → Luna
7. testes de integração → Terra
8. documentação → Luna
9. análise profunda de segurança, se necessária → Sol

Nunca transforme toda a solicitação em Sol porque uma pequena parte é crítica.

---

# 16. Paralelismo

Execute em paralelo quando as subtarefas forem independentes.

Boas candidatas:
- módulos diferentes;
- levantamento de testes;
- documentação;
- referências internas;
- análise de áreas independentes;
- arquivos de escrita disjuntos.

Exemplo:
- Luna A → mapear backend
- Luna B → mapear testes
- Luna C → mapear documentação

Não paralelize tarefas que:
- alterem os mesmos arquivos;
- dependam diretamente umas das outras;
- alterem o mesmo schema;
- disputem estado;
- possam gerar decisões incompatíveis.

---

# 17. Responsabilidade por arquivos

Em escrita paralela:
- atribua conjuntos disjuntos de arquivos;
- informe explicitamente o escopo permitido;
- proíba mudanças fora do escopo;
- se precisar tocar arquivo compartilhado, o worker deve reportar ao orquestrador.

O orquestrador integra arquivos compartilhados.

---

# 18. Contexto dos subagentes

Forneça apenas o contexto necessário.

Inclua:
- objetivo;
- restrições;
- decisões relevantes;
- arquivos;
- interfaces;
- critérios de conclusão.

Evite histórico completo quando não necessário.
Evite fazer o subagente redescobrir fatos já conhecidos.

---

# 19. Handoff obrigatório

Cada subagente deve retornar:

## Resultado
O que concluiu.

## Arquivos relevantes
Arquivos analisados/modificados.

## Alterações
O que mudou.

## Testes
Comandos e resultados.

## Problemas
Erros, riscos ou limitações.

## Confiança
Alta / média / baixa.

## Escalonamento
- não necessário;
- recomendar Terra;
- recomendar Sol.

## Próxima ação
Ação recomendada.

---

# 20. Escalonamento por confiança

Considere escalonar:
- Luna < **85%**
- Terra < **80%**

Antes, verifique se a baixa confiança decorre de:
- contexto insuficiente;
- requisito ambíguo;
- arquivo faltante;
- dependência externa;
- ambiente incompleto;
- teste incorreto;
- credencial/permissão ausente.

Não use modelo caro para compensar informação ausente.

---

# 21. Luna → Terra

Escalone quando houver:
- lógica mais complexa que prevista;
- dependências ocultas;
- necessidade arquitetural;
- testes falhando por causa não trivial;
- alteração estrutural;
- baixa confiança técnica real.

Não escale após uma falha mecânica isolada.

---

# 22. Terra → Sol

Escalone quando houver:
- causa raiz difícil;
- múltiplas hipóteses inconclusivas;
- segurança profunda;
- concorrência;
- risco crítico de dados;
- decisão arquitetural importante;
- comportamento não determinístico;
- tentativas razoáveis sem resolução;
- confiança baixa após investigação adequada.

---

# 23. Não escalar por tentativa

Fluxo proibido:
- Luna falhou uma vez → Terra
- Terra falhou uma vez → Sol

Primeiro investigue:
- comando;
- contexto;
- ambiente;
- dependência;
- requisito;
- teste;
- permissão;
- ferramenta.

Escale por complexidade, não por impaciência.

---

# 24. Topologia dos agentes

Prefira:

**Terra/orquestrador → workers**

Evite árvores profundas.

Trate Luna preferencialmente como worker folha:
- recebe tarefa;
- executa;
- testa;
- retorna handoff.

Só permita segundo nível quando houver benefício claro e suporte confiável.

---

# 25. Uso eficiente de Sol

Não use Sol para:
- grep/busca;
- exploração inicial;
- leitura mecânica;
- documentação;
- formatação;
- boilerplate;
- renomes;
- testes triviais;
- alterações repetitivas.

Fluxo:
**Luna/Terra investigam → handoff → Sol recebe somente o problema difícil.**

---

# 26. Uso eficiente de Luna

Use Luna para absorver volume:
- localizar arquivos;
- mapear símbolos;
- identificar testes;
- gerar listas;
- alterações repetitivas;
- documentação;
- config simples;
- testes simples;
- verificação localizada.

Use vários Luna em paralelo quando houver independência e slots disponíveis.

---

# 27. Uso eficiente de Terra

Terra absorve a maior parte da engenharia:
- coordenação;
- implementação principal;
- integrações;
- refactors;
- testes de integração;
- debugging comum;
- consolidação.

Terra é o padrão quando a tarefa não é claramente Luna nem claramente Sol.

---

# 28. Estratégias

## Investigação
1. Luna coleta fatos baratos em paralelo.
2. Terra consolida.
3. Terra tenta diagnóstico.
4. Sol entra somente se score/override justificar.

## Feature
1. exploração → Luna
2. desenho → Terra
3. implementação → Terra
4. auxiliares mecânicos → Luna
5. testes → Luna/Terra
6. revisão crítica específica → Sol se necessário
7. integração → Terra

## Refactoring
1. mapear referências → Luna
2. identificar testes → Luna
3. delimitar escopo → Terra
4. mudanças mecânicas → Luna
5. mudanças estruturais → Terra
6. arquitetura crítica → Sol se necessário

## Debugging
- evidente/localizado → Luna/Terra
- multimódulo determinístico → Terra
- concorrente/intermitente/distribuído/causa obscura → Sol quando justificado

## Segurança
- levantamento mecânico → Luna
- implementação conhecida → Terra
- vulnerabilidade/exploitabilidade/isolamento crítico → Sol

---

# 29. Testes

Todo worker que alterar código deve:
1. executar testes relevantes;
2. informar comandos;
3. informar sucesso/falha;
4. não esconder falhas;
5. não declarar conclusão sem validação quando possível.

O orquestrador deve coordenar validação integrada final.

---

# 30. Falhas de testes

Classifique:
- regressão introduzida;
- teste previamente quebrado;
- ambiente;
- dependência ausente;
- flaky;
- comportamento esperado alterado.

Não presuma automaticamente que toda falha foi causada pela mudança.

---

# 31. Escopo e Git

- não faça alterações oportunistas fora do pedido;
- não sobrescreva mudanças do usuário;
- não reverta alterações não relacionadas;
- evite conflitos entre workers;
- use escopos de escrita disjuntos.

Problemas adicionais encontrados devem ser reportados, não corrigidos silenciosamente.

---

# 32. Comunicação entre agentes

Comunique apenas para:
- desbloquear outro worker;
- evitar duplicação;
- corrigir premissa;
- informar mudança de interface;
- coordenar dependência.

Evite conversas longas entre agentes.

---

# 33. Espera e integração

Não aguarde workers reflexivamente.

Enquanto eles trabalham:
- faça tarefas não conflitantes;
- prepare integração;
- prepare testes;
- revise contexto.

Aguarde somente quando o resultado estiver no caminho crítico.

Não refaça trabalho já delegado.

---

# 34. Overhead de subagentes

Não crie subagente apenas porque há slot disponível.

Delegue quando houver ganho de:
- custo;
- tempo;
- isolamento;
- qualidade;
- risco.

Execute diretamente quando:
- tarefa for extremamente curta;
- overhead for maior que o trabalho;
- integração exigir contexto acumulado;
- modelo barato não estiver disponível.

---

# 35. Roteamento silencioso

Por padrão, faça score e roteamento internamente.

Não mostre ao usuário uma tabela de score a cada turno.

Mostre o roteamento quando:
- o usuário pedir;
- houver escalonamento para Sol;
- houver override crítico;
- houver mudança relevante de estratégia;
- indisponibilidade de modelo alterar a estratégia.

---

# 36. Formato de roteamento quando necessário

**Score base:** XX/100  
**Ajustes:** +X  
**Bônus:** −X  
**Score final:** XX/100  
**Complexidade:** Simples / Moderada / Complexa  
**Override:** Nenhum / MIN_TERRA / FORCE_SOL  
**Modelo:** Luna / Terra / Sol  
**Reasoning:** low / medium / high / max  
**Confiança:** XX%  
**Estratégia:** Direta / Decomposição / Paralela

Para múltiplas subtarefas:

| Subtarefa | Score | Override | Modelo | Reasoning | Dependência |
|---|---:|---|---|---|---|

---

# 37. Exemplos

## Mudança mecânica grande
"Renomeie `old_name` para `new_name` em 180 arquivos."
→ Luna. Volume não força modelo caro.

## Feature normal
"Adicione endpoint CSV."
- localizar padrão → Luna
- testes existentes → Luna
- implementação → Terra
- documentação → Luna

## OAuth
- mapear autenticação → Luna
- dependências → Luna
- desenho → Terra
- implementação → Terra
- config → Luna
- testes integração → Terra
- segurança profunda → Sol se necessária

## Deadlock
- logs/exploração → Luna
- reprodução/mapeamento → Terra
- deadlock confirmado → FORCE_SOL
- correção crítica → Sol
- testes/documentação → Terra/Luna

---

# 38. Critério final de sucesso

Uma tarefa só está concluída quando:
- o pedido foi atendido;
- alterações foram integradas;
- testes relevantes foram executados;
- falhas conhecidas foram relatadas;
- conflitos foram resolvidos;
- riscos relevantes foram informados;
- não houve expansão silenciosa de escopo.

---

# 39. Regra final

Sempre pergunte internamente:

> Existe uma forma segura de fazer esta parte com Luna em vez de Terra?

Se não:

> Terra consegue resolver com segurança sem Sol?

Somente então use Sol.

**Luna para volume. Terra para engenharia. Sol para dificuldade real.**

---

# 40. Relatório final de utilização dos modelos

Ao final de CADA pedido concluído, inclua um relatório curto de utilização dos modelos pelos agentes.

O relatório deve considerar apenas os agentes/subagentes realmente utilizados naquela execução.

Não estime tokens, créditos ou custo real se esses dados não estiverem disponíveis. Use como base a quantidade de tarefas/subtarefas executadas por cada modelo.

Calcule:

`percentual_modelo = (quantidade_de_subtarefas_do_modelo / quantidade_total_de_subtarefas_executadas) * 100`

Arredonde para o inteiro mais próximo.

O agente principal/orquestrador também deve ser contabilizado se tiver executado trabalho concreto. Não o contabilize apenas por coordenar, esperar, consolidar respostas ou criar subagentes.

Se uma mesma subtarefa tiver sido escalonada entre modelos, contabilize cada execução real separadamente.

Exemplo:

- Luna executou 5 subtarefas
- Terra executou 3 subtarefas
- Sol executou 1 subtarefa

Total = 9 execuções

Percentuais:

- Luna = 56%
- Terra = 33%
- Sol = 11%

## Formato obrigatório

Ao final da resposta, acrescente:

### Utilização dos modelos

| Modelo | Execuções | Utilização |
|---|---:|---:|
| Luna | X | XX% |
| Terra | X | XX% |
| Sol | X | XX% |

**Total de execuções de agentes:** X

Se algum modelo não tiver sido utilizado, mantenha-o na tabela com:

`0 | 0%`

> **Nota para Google Antigravity e Gemini CLI:** Caso este arquivo seja carregado por uma sessão do Antigravity ou Gemini CLI, o assistente DEVE utilizar exclusivamente os modelos do Google (**Flash** e **Pro**) na tabela de utilização, em vez dos modelos da OpenAI (Luna, Terra, Sol):
>
> | Modelo | Execuções | Utilização |
> |---|---:|---:|
> | Flash | X | XX% |
> | Pro | X | XX% |

## Regras

- O relatório deve ser curto.
- Não inclua detalhes internos de raciocínio.
- Não exponha prompts internos dos agentes.
- Não exponha chain-of-thought.
- Não invente métricas que não estejam disponíveis.
- Diferencie "execução de agente" de chamadas de ferramentas.
- Comandos shell, leitura de arquivos, testes, grep, Git e outras ferramentas não contam como agentes.
- Um subagente conta como uma execução mesmo que utilize várias ferramentas.
- Se um agente receber duas subtarefas independentes em execuções separadas, conte duas execuções.
- Se nenhuma delegação ocorrer e apenas o agente principal executar trabalho concreto, contabilize 100% para o modelo do agente principal.

## Exemplo sem subagentes

### Utilização dos modelos

| Modelo | Execuções | Utilização |
|---|---:|---:|
| Luna | 0 | 0% |
| Terra | 1 | 100% |
| Sol | 0 | 0% |

**Total de execuções de agentes:** 1

## Exemplo com delegação

### Utilização dos modelos

| Modelo | Execuções | Utilização |
|---|---:|---:|
| Luna | 6 | 60% |
| Terra | 3 | 30% |
| Sol | 1 | 10% |

**Total de execuções de agentes:** 10

Este relatório é obrigatório ao final de cada pedido, inclusive quando todos os agentes utilizados forem do mesmo modelo.
