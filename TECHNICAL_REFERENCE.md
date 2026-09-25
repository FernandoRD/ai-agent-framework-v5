# Referência técnica — AI Agent Framework v5

## Objetivo e escopo

A v5 padroniza a decisão do agente principal em tarefas de engenharia. Ela não substitui julgamento técnico: transforma esse julgamento em critérios explícitos para classificação, delegação, revisão e relato. A fonte da política é [codex-global-framework-v5/.codex/AGENTS.md](codex-global-framework-v5/.codex/AGENTS.md); as outras variantes a adaptam às capacidades de suas plataformas.

## Fluxo de decisão

```text
pedido → classificação trivial/não trivial → score e pisos de risco
       → execução direta ou delegação delimitada → validação → relatório
```

Uma tarefa é trivial somente se todos os critérios forem atendidos: objetivo estreito, um arquivo ou ponto isolado, causa e resultado conhecidos, baixo impacto, reversibilidade imediata e uma verificação determinística. Dúvida torna a tarefa não trivial. Tarefas triviais são executadas diretamente, sem score nem subagente.

Para trabalho não trivial, o principal estima cada fator de 0 a 4, multiplica pelo respectivo peso e divide por 4. A soma forma um score de 0 a 100.

| Fator | Peso máximo |
| --- | ---: |
| Escopo e tamanho da mudança | 10 |
| Componentes afetados | 8 |
| Incerteza e investigação | 10 |
| Impacto arquitetural | 10 |
| Segurança e autorização | 12 |
| Dados, estado ou persistência | 10 |
| Concorrência ou distribuição | 8 |
| Impacto operacional ou em produção | 10 |
| Irreversibilidade | 6 |
| Dificuldade de testes | 6 |
| Compatibilidade ou dependências | 5 |
| Integrações externas | 5 |

| Score | Faixa v5 | Uso |
| --- | --- | --- |
| 0–34 | Luna | Descoberta e trabalho pequeno, claro e reversível |
| 35–69 | Terra | Implementação, depuração e revisão usuais |
| 70–100 | Sol | Análise ou implementação difícil, ambígua e de alto impacto |

Os pisos de risco substituem o score: autenticação, APIs públicas, persistência, migrações, infraestrutura de produção, refatoração estrutural, compatibilidade e múltiplos componentes exigem ao menos Terra. Vulnerabilidades críticas, criptografia, autorização, risco de perda/corrupção, corridas difíceis e falhas de produção de alto impacto exigem Sol para a parte crítica.

## Delegação e responsabilidades

O principal atribui cada unidade delimitada ao menor agente nomeado que possa concluí-la e validá-la com segurança. Quando o principal tem capacidade maior, ele delega as unidades de nível inferior; a capacidade do principal não é motivo para retê-las. A delegação não é uma meta de quantidade: trabalho trivial segue direto, e uma operação minúscula e totalmente especificada pode seguir direta quando o repasse e a verificação excederiam o próprio trabalho. Para outro trabalho não trivial sem checkpoint obrigatório, execução direta só é permitida se o principal já estiver no menor nível suficiente e a delegação não trouxer benefício independente. Uma exceção a checkpoint obrigatório deve registrar bloqueio concreto, como restrição superior, ferramenta indisponível, pedido explícito de trabalho individual ou ausência de unidade independente que possa avançar em paralelo.

Para repositório grande ou desconhecido, o principal delega descoberta somente leitura ao `luna_explorer` antes de exploração ampla. Para causa incerta, múltiplos componentes, mudança coordenada em vários arquivos ou compatibilidade, delega ao menos uma unidade concreta de análise, implementação ou validação. Antes de concluir mudança com múltiplos componentes, compatibilidade, contrato público ou risco elevado, obtém revisão independente no menor nível que atenda ao piso de risco. A revisão deve ocorrer enquanto ainda há integração ou validação útil; um agente que descobriu ou implementou a mudança não a revisa de forma independente.

Cada subagente recebe objetivo, escopo autorizado, contexto relevante, critérios de aceitação, validação esperada e condição de parada. O principal espera, verifica e integra a entrega; a responsabilidade final não é transferida. Revisores são independentes e somente leitura. Paralelismo só é apropriado para trabalhos independentes, com escopos de escrita sem sobreposição.

| Papel | Responsabilidade |
| --- | --- |
| Explorer | Descoberta focada e cápsula de contexto somente leitura |
| Worker | Implementação delimitada no nível apropriado |
| Reviewer | Revisão independente de correção, regressão e testes |
| Specialist | Parte difícil ou ambígua da implementação |
| Critical | Análise somente leitura antes de mutação em risco elevado |

Para repositórios grandes ou desconhecidos, o explorer produz uma cápsula com arquivos e símbolos relevantes, caminho de execução, restrições, testes prováveis e dúvidas abertas. Os demais agentes reutilizam essa cápsula em vez de repetir uma varredura ampla.

## Publicação com o menor agente adequado

Commit, push e sincronização de repositório são unidades separadas da implementação. Para mudanças já validadas, destinos conhecidos e autorização existente, o worker de menor nível executa o fluxo delimitado inteiro: conferir status e diff, preservar alterações alheias, selecionar arquivos explicitamente, criar o commit solicitado, enviar a branch autorizada e confirmar o hash em cada remote.

O repasse contém repositório, branch, arquivos permitidos, destinos, autorização, verificações concluídas e limitações. Resultados válidos são reaproveitados; novos testes dependem de mudanças, falhas ou dúvidas remanescentes. Conflitos e riscos de release ou implantação elevam apenas a etapa afetada. Ausência de credenciais, rede, permissão ou delegação disponível é um bloqueio a tratar, não motivo para trocar por um modelo mais caro nem contornar controles.

| Variante | Worker de publicação rotineira | Particularidade |
| --- | --- | --- |
| Codex | `luna_worker` / Luna | Registro das camadas na configuração global |
| Claude Code | `haiku-worker` / Haiku | Respeitar as permissões efetivas do subagente |
| Gemini CLI | `flash-worker` / Flash | Orquestração fica com o principal; faixas superiores usam Pro |
| Cursor | `luna-worker` / Composer | Confirmar modelo e delegação disponíveis no ambiente |

Se a delegação estiver indisponível, o agente registra o bloqueio e usa somente a alternativa autorizada necessária, sem alegar execução pelo modelo menor. A política não concede autorização nova para publicar, implantar, criar releases ou alterar visibilidade. Equivalência da política não significa igualdade de recursos nativos ou de capacidade medida entre modelos.

## Pacotes e instalação

O pacote Codex é global e específico do Codex. Os scripts de instalação fazem auditoria, backup do estado afetado e atualização controlada dos blocos marcados da v5; também tratam resíduos de v3/v4. A validação estática usa Python 3.11+ por importar `tomllib`.

```bash
cd codex-global-framework-v5
./scripts/install.sh --audit-only
./scripts/install.sh
python3 scripts/validate.py
```

Claude Code, Gemini CLI e Cursor são payloads por projeto. Cada um possui instaladores em Shell Script (`scripts/install.sh`, `scripts/install.fish`), PowerShell (`scripts/install.ps1`) e Python (`scripts/install.py`): sem `--apply` / `-Apply`, apenas listam arquivos pendentes; com `--apply` / `-Apply`, criam arquivos novos com criação exclusiva, preservam arquivos idênticos e recusam conflitos, links simbólicos e pais inválidos. Requerem Python 3.10+ no Linux/macOS ou PowerShell nativo no Windows.

```bash
cd cursor-global-framework-v5  # substitua pela variante desejada
./scripts/install.sh --target "/caminho/do/projeto"
./scripts/install.sh --target "/caminho/do/projeto" --apply
python3 scripts/test_install.py
```

O instalador por projeto não é uma transação de múltiplos arquivos: uma falha de I/O pode deixar parte dos novos arquivos criada. Como não sobrescreve arquivos existentes, uma nova execução após resolver a falha completa apenas os faltantes. Atualizações com conflito devem ser comparadas e mescladas manualmente.

## Mapeamento por plataforma

| Plataforma | Agentes/configuração | Observações |
| --- | --- | --- |
| Codex | Sete camadas registradas em `.codex/agent-configs` | Luna, Terra e Sol; hook opcional; instalação global |
| Claude Code | Sete arquivos em `.claude/agents` | Haiku, Sonnet e Opus; instalação por projeto |
| Gemini CLI / Antigravity | Sete arquivos em `.gemini/agents` e exemplo de settings | Flash e Pro; o principal mantém a orquestração |
| Cursor | Sete arquivos em `.cursor/agents` e regra `.cursor/rules` | Composer, Sonnet e Opus; instalação por projeto |

Gemini CLI / Google Antigravity não expõe uma terceira classe equivalente a Terra/Sol: os papéis acima de Flash usam Pro. Relatórios de utilização de IA nessa plataforma devem listar estritamente os modelos Google (Flash e Pro), nunca modelos OpenAI (Luna/Terra/Sol). Em todas as adaptações, os modelos são mapeamentos operacionais, não equivalências mensuradas entre fornecedores.

## Validação e limitações

A validação acompanha o risco: uma verificação focada para mudanças pequenas; testes, lint, build ou integração relevantes para mudanças usuais; revisão independente e testes de falhas para mudanças de alto risco. Resultados não observados não devem ser declarados como concluídos. O relatório final deve registrar verificações, limitações, riscos e, quando houve subagentes, contagens reais por modelo e percentual de execuções.

Os validadores do pacote Codex conferem marcadores, pesos, sete camadas, skills, hook, sintaxe e manifesto. As variantes possuem testes offline do instalador. Isso não comprova seleção de modelo, descoberta de agentes, permissões ou comportamento em um runtime autenticado. Confirme esses pontos em uma sessão de teste antes de usar a política em trabalho crítico.

As pastas `Claude code/` e `Codex/` ficam somente como referência histórica. Não fazem parte do caminho recomendado de instalação da v5.

## Módulos e interfaces de manutenção

| Módulo | Responsabilidade |
| --- | --- |
| Codex `scripts/install_core.py` | Descoberta de configuração e aplicação do framework com backups |
| Codex `scripts/diagnose_core.py` | Diagnóstico da instalação |
| Codex `scripts/uninstall_core.py` | Remoção dos componentes gerenciados |
| Codex `scripts/validate.py` | Validação estática da distribuição e manifesto |
| Variantes `scripts/install.{sh,fish,ps1,py}` | Scripts de instalação conservadora com `--target` e `--apply` |
| Variantes `scripts/test_install.py` | Testes offline em diretórios temporários |
| `MANIFEST.sha256` | Digest SHA-256 e caminho relativo por arquivo distribuído |

Não há API HTTP, banco de dados nem serviço residente. As interfaces distribuídas são CLIs, Markdown com frontmatter, TOML e JSON de configuração. O hook Codex emite um lembrete JSON no evento `UserPromptSubmit`; não calcula score nem executa roteamento. Os ZIPs das variantes incluem a pasta do pacote; o ZIP Codex contém os arquivos diretamente na raiz e deve ser extraído em uma pasta própria.
