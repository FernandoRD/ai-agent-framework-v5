# Referência técnica — AI Agent Framework v5

## Objetivo e escopo

A versão 5 (v5) padroniza o comportamento, a governança e a tomada de decisão do agente principal em tarefas de engenharia de software e infraestrutura. Ela não substitui o julgamento técnico do desenvolvedor ou operador: transforma esse julgamento em critérios sistemáticos e explícitos para **classificação de complexidade**, **roteamento orçamentário por faixas de modelo**, **despacho paralelo de subagentes (fan-out / fan-in)**, **revisão independente** e **extensões modulares de domínio**.

A fonte canônica da política é [`codex-global-framework-v5/.codex/AGENTS.md`](codex-global-framework-v5/.codex/AGENTS.md); as variantes para Claude Code, Gemini CLI / Google Antigravity e Cursor adaptam a política nativamente aos mecanismos e capacidades de cada ecossistema, mantendo paridade funcional e de segurança.

---

## Fluxo de decisão

```text
pedido → classificação trivial/não trivial → score e pisos de risco
       → execução direta ou delegação delimitada (individual ou paralela)
       → validação e revisão independente → relatório final
```

### 1. Classificação: Trivial vs. Não Trivial

Uma tarefa é classificada como **trivial** exclusivamente quando **todas** as condições a seguir forem verdadeiras:
- Possui um único objetivo estreito e claramente declarado;
- Afeta no máximo um arquivo ou ponto isolado do sistema;
- A causa raiz, a alteração necessária e o resultado esperado já são previamente conhecidos;
- Não envolve decisões de design arquitetural ou investigações incertas;
- Não altera contratos consumidos externamente (APIs públicas, schemas, protocolos);
- Não aciona nenhum gatilho não trivial obrigatório;
- Falhas têm apenas impacto local e facilmente reversível;
- É imediatamente reversível com uma alteração mínima;
- Uma única verificação determinística e focada comprova o resultado.

Qualquer incerteza ou dúvida eleva a classificação para **não trivial**. Tarefas triviais são tratadas diretamente pelo agente principal, sem cálculo de score, sem subagentes e sem sobrecarga operacional.

### 2. Gatilhos Não Triviais Obrigatórios

Uma tarefa é compulsoriamente classificada como não trivial se envolver:
- Causa raiz desconhecida ou incerta;
- Mais de um componente, subsistema, serviço ou repositório;
- Alterações coordenadas em múltiplos arquivos;
- Mudanças em arquitetura, fluxo de dados, estado compartilhado ou concorrência;
- APIs públicas, formatos de arquivos, schemas de bancos de dados ou persistência;
- Autenticação, autorização, segredos, privacidade ou limites de segurança;
- Migrações, escritas em banco de dados ou alterações de modelo de dados;
- Concorrência, travamentos (locks), condições de corrida ou comportamento distribuído;
- Infraestrutura de produção, redes, contêineres, CI/CD ou configurações operacionais;
- Adição, atualização ou remoção de dependências externas;
- Compatibilidade retroativa ou matriz de runtime suportada;
- Ações destrutivas, de difícil reversão ou com potencial de parada de serviço;
- Dificuldade na criação ou execução de testes de validação.

### 3. Matriz de Pontuação e Faixas de Capacidade

Para trabalhos não triviais, o agente principal estima a complexidade de 0 a 100 somando as notas de 0 a 4 (onde 0 = nenhum e 4 = muito alto) multiplicadas pelo peso do fator dividido por 4:

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

#### Mapeamento de Faixas por Plataforma

- **Plataformas de 3 faixas (Codex, Claude Code, Cursor):**
  - **Score 0–34 (Tier Baixo / Rápido):** Luna (`gpt-5.6-luna`), Haiku (`claude-3-5-haiku`), Composer. Focado em descoberta direcionada, tarefas mecânicas ou alterações locais de baixo risco.
  - **Score 35–69 (Tier Médio / Padrão):** Terra (`gpt-5.6-terra`), Sonnet (`claude-3-7-sonnet`). Focado em implementação usual, depuração, testes e alterações multi-arquivo.
  - **Score 70–100 (Tier Alto / Raciocínio):** Sol (`gpt-5.6-sol`), Opus (`claude-3-opus`). Focado em raciocínio complexo, problemas ambíguos, refatores de alto impacto ou análises críticas.

- **Plataformas de 2 faixas (Gemini CLI / Google Antigravity):**
  - **Score 0–34:** **Flash** (`gemini-2.5-flash`, `gemini-3-flash`, suportando `flash_lite` para descoberta somente leitura).
  - **Score 35–100:** **Pro** (`gemini-2.5-pro`, `gemini-3-pro`). Raciocínio avançado, arquitetura e implementação pesada.

### 4. Pisos de Risco (Risk Floors)

Os pisos de risco sobrepõem a pontuação numérica:
- **Piso Intermediário (ao menos Terra / Pro):** autenticação, APIs públicas, alterações em persistência, migrações de esquemas, infraestrutura de produção, refatorações estruturais, matriz de compatibilidade e mudanças multi-componente.
- **Piso Crítico (ao menos Sol / Pro com análise prévia somente leitura):** vulnerabilidades críticas, criptografia, fronteiras de autorização, risco de perda/corrupção de dados, condições de corrida difíceis e falhas de produção de grande impacto.

O piso de risco aplica-se à fração afetada, não a toda a solicitação. Tarefas posteriores de apoio mecânico ou publicação retornam ao menor tier seguro.

---

## Arquitetura de execução e despacho concorrente

### 1. Princípio do Menor Agente Capaz (*Smallest Capable Agent*)

O trabalho é decomposto em unidades delimitadas e cada unidade é atribuída ao menor modelo capaz de executá-la com segurança e validação completa. A capacidade maior do agente principal não justifica reter trabalho simples. Reduzir execuções desnecessárias em tiers elevados é um princípio central de economia de tokens e latência.

O papel do agente principal concentra-se em:
- Decomposição inicial e delimitação de escopos;
- Coordenação e despacho de subagentes;
- Integração contínua e validação dos resultados entregues;
- Aceite e reporte final ao usuário.

### 2. Despacho Paralelo Ativo (Fan-Out / Fan-In)

Para evitar gargalos de despacho sequencial defensivo ("1 agente por vez"), o Framework v5 estabelece diretrizes ativas de concorrência:
- **Despacho em Lote:** Quando existirem duas ou mais unidades independentes (ex.: implementar submódulos isolados, pesquisar subsistemas diferentes ou auditar áreas distintas), o principal despacha os subagentes em lote de 2 a 4 agentes em paralelo.
- **Particionamento Estrito de Escopos de Escrita (*Disjoint Write Scopes*):** Agentes operando em paralelo nunca devem ter sobreposição de escrita no mesmo arquivo ou recurso compartilhado.
- **Pipelining de Revisão Independente:** Enquanto o revisor independente inspeciona os artefatos gerados, o agente principal prossegue executando testes, compilações ou validações complementares.
- **Custódia Exclusiva de Recursos Críticos:** Sessões compartilhadas de navegadores, mutações ao vivo em banco de dados ou deploys em staging permanecem sob a guarda de um único agente executor.

### 3. Agentes Pais em Modelo Flash (Gemini CLI / Antigravity)

Quando o agente principal estiver operando em um modelo Flash (por restrição de quota, configuração de IDE ou escolha do usuário), **ele não deve reter a implementação nem a revisão de tarefas com score $\ge 35$ ou que atinjam o piso de risco**. O agente pai Flash deve atuar como coordenador, delegando a implementação ao `pro-worker` e a verificação ao `pro-reviewer`.

### 4. Suporte Multi-Provedor no Google Antigravity

No ecossistema Google Antigravity, o runtime suporta a seleção e alternância de múltiplos provedores (modelos Google Gemini, Anthropic Claude e OpenAI ChatGPT). As diretivas do framework reconhecem essas capacidades: subagentes invocados com modo de herança (`inherit`) adaptam-se perfeitamente ao modelo ativo, mantendo o controle de escopo e os critérios de validação.

---

## Publicação com o menor agente adequado

O fluxo de publicação (inspeção de git status/diff, staging explícito, commit semântico, push e confirmação de hashes nos remotes) é uma **unidade de trabalho desacoplada da implementação**. 

- Após a validação das alterações por testes e revisão, o principal delega o fluxo completo de publicação ao worker de menor tier disponível:
  - **Codex:** `luna_worker`
  - **Claude Code:** `haiku-worker`
  - **Gemini CLI / Antigravity:** `flash-worker`
  - **Cursor:** `luna-worker` (Composer)
- **Repasse Compacto:** O subagente de publicação recebe apenas o contexto necessário: repositório, branch, arquivos permitidos, remotes autorizados e confirmação de testes concluídos.
- **Verificação Obrigatória de Hashes:** A publicação só é dada como concluída após a verificação de paridade de hash do commit entre a branch local e todos os remotes configurados (`git rev-parse HEAD`, `git ls-remote <remote> <branch>`).

---

## Pacotes e instaladores nativos (Zero Python em Runtime)

Todas as quatro distribuições do framework contam com instaladores e ferramentas de manutenção **100% nativos em Shell Script (`.sh`, `.fish`) e PowerShell (`.ps1`)**, sem qualquer necessidade de interpretadores Python para instalação ou diagnóstico:

| Plataforma | Instaladores e Utilitários | Suporte de Instalação |
|---|---|---|
| **Codex** | `scripts/install.sh`, `install.fish`, `install.ps1`, `install-wsl.ps1`, `diagnose.*`, `uninstall.*`, `validate.py` | Global padrão (`~/.codex`) ou Por Projeto (`--target`) |
| **Claude Code** | `scripts/install.sh`, `install.fish`, `install.ps1`, `test_install.py` | Por Projeto padrão (`--target`) ou Global (`--global`) |
| **Gemini CLI** | `scripts/install.sh`, `install.fish`, `install.ps1`, `test_install.py` | Por Projeto padrão (`--target`) ou Global (`--global`) |
| **Cursor** | `scripts/install.sh`, `install.fish`, `install.ps1`, `test_install.py` | Por Projeto padrão (`--target`) ou Global (`--global`) |

### Mecanismos de Proteção dos Instaladores

- **Auditoria Prévia Conservadora:** Por padrão, a execução sem `--apply` / `-Apply` apenas audita e reporta as ações planejadas sem gravar nenhum byte em disco (no Codex global, use `--audit-only`).
- **Prevenção de Sobrescrita e Conflitos:** Com `--apply`, o instalador cria apenas arquivos novos (`set -C` no Bash / `CreateNew` no PowerShell). Arquivos idênticos são preservados (`IDÊNTICO`); arquivos existentes com conteúdo divergente geram erro de conflito explícito, exigindo comparação manual.
- **Inspeção de Links Simbólicos:** Varre toda a cadeia de diretórios do destino e do payload recusando instalação em caminhos que contenham links simbólicos (*symlinks* ou *reparse points*).
- **Instalação Global Limpa:** Na instalação global (`--global`), os arquivos de instruções gerais são gerados **dentro** da respectiva pasta oculta de cada ferramenta (`~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.cursor/`), garantindo que o diretório `$HOME` permaneça limpo.
- **Help Completo Integrado:** Todos os scripts aceitam `-h` e `--help` (Bash/Fish) e `-Help`, `-h`, `-?` (PowerShell), exibindo ajuda contextual com todas as opções gerais e catálogo de especialistas.

---

## Catálogo modular dos 9 especialistas de domínio

Os quatro pacotes disponibilizam um catálogo modular de **9 especialistas técnicos de engenharia**. Os especialistas são distribuídos como extensões **opt-in**, não alteram os papéis centrais do framework e não forçam modelos fixos (são sempre operados sob a faixa de capacidade decidida pelo roteamento da v5).

### 1. `zabbix-specialist`
- **Domínio:** Arquitetura corporativa de monitoramento com Zabbix 7.0 LTS / 6.0 LTS.
- **Cobertura técnica:** Zabbix Server, Proxies ativos/passivos, Zabbix Agent 2 em Go, templates modulares, LLD (Low-Level Discovery) com filtros regex, regras de pré-processamento (JSONPath, JavaScript, throttling), triggers com histerese, automação via API HTTP JSON-RPC, particionamento de tabelas de histórico/trends e configurações de Alta Disponibilidade (HA).
- **Alimentação RAG opcional:** Inclui CLI local de ingestão (`rag_ingest.py`) para fontes Git e Jira em diretório isolado com quarentena, sanitização e promoção explícita via `--approve`.

### 2. `grafana-specialist`
- **Domínio:** Visualização avançada de dados, focado em **Grafana 12** (com suporte retrocompatível para 11.x e 10.x).
- **Cobertura técnica:** Desenvolvimento de alto desempenho no plugin **HTML Graphics** (`gapit-htmlgraphics-panel`), ciclo de vida segregado (`onInit` para estruturação do DOM/SVG e estado em `htmlGraphics.state`; `onRender` para mutações cirúrgicas de atributos sem recriar nós DOM), manipulação eficiente de DataFrames (`data.series`), gráficos SVG dinâmicos e responsivos com `viewBox`, escopo rigoroso de CSS para não contaminar a interface do Grafana, conformidade com a Content Security Policy (CSP) do Grafana 12, princípios de UI/UX para telas de NOC (regra dos 5 segundos, layout hierárquico vertical, grid de 24 colunas, paletas semânticas anti-fadiga) e governança por API via Service Accounts, tokens RBAC e provisionamento declarativo YAML.

### 3. `ansible-specialist`
- **Domínio:** Automação de infraestrutura como código (IaC) e orquestração com Ansible 2.15+.
- **Cobertura técnica:** Playbooks modulares e estritamente idempotentes, estrutura de Roles com `meta/main.yml`, inventários dinâmicos (*dynamic inventory plugins*) para ambientes em nuvem e redes, uso avançado de handlers, tags e variáveis com precedência controlada, criptografia de segredos via Ansible Vault e automação de rollout de agentes de telemetria (Zabbix Agent 2, Grafana Alloy, Promtail, Node Exporter).

### 4. `loki-specialist`
- **Domínio:** Agregação, processamento e consulta de logs em larga escala com Grafana Loki 3.x.
- **Cobertura técnica:** Consultas complexas em LogQL (filtros de linha, expressões regulares, parsers de JSON/Logfmt, transformações de formato e agregações de métricas com `unwrap`), agentes coletores modernos (Grafana Alloy e Promtail) com pipelines de extração de labels, mitigação rigorosa de explosão de cardinalidade de streams, estruturação eficiente de metadados, retenção por compactor e gerenciamento de armazenamento em chunks compatível com S3/MinIO.

### 5. `prometheus-specialist`
- **Domínio:** Observabilidade e métricas de séries temporais com Prometheus e VictoriaMetrics.
- **Cobertura técnica:** Consultas avançadas em PromQL (`rate`, `irate`, `histogram_quantile`, `predict_linear`, junções de vetores com `group_left`/`group_right`), recording rules para otimização prévia de dashboards pesados, arquitetura de alertas via Alertmanager (rotas, inibições, agrupamentos e silenciamento), deployment e scraping de exporters corporativos e controle preventivo de cardinalidade (*metric cardinality explosion*).

### 6. `netops-specialist`
- **Domínio:** Engenharia de conectividade, redes corporativas e telemetria de switches e roteadores.
- **Cobertura técnica:** Monitoramento SNMPv2c e SNMPv3 seguro com USM (autenticação SHA/AES e privacidade), compilação de MIBs e mapeamento de OIDs enterprise (Cisco, Juniper, Mikrotik, Dell, Huawei), telemetria de tráfego via NetFlow v5/v9 e IPFIX, topologias e enlaces L2/L3 (VLANs, agregação LACP, STP), roteamento dinâmico BGP e OSPF, túneis VPN (IPsec e WireGuard) e diagnóstico aprofundado de tráfego e pacotes com `tcpdump` e Wireshark.

### 7. `sre-incident-specialist`
- **Domínio:** Resposta a incidentes em produção e práticas de Site Reliability Engineering (SRE).
- **Cobertura técnica:** Framework de comando de incidentes (*Incident Command System* com papéis de Incident Commander, Scribe e Communications Lead), triagem de crise, runbooks operacionais de contingência e mitigação de *alert fatigue*, definição e mensuração de indicadores de confiabilidade (SLI, SLO, SLA, Error Budgets), condução de investigações de causa raiz (RCA) com Post-Mortems blameless e acompanhamento de métricas de resiliência (MTTD, MTTR).

### 8. `database-tuning-specialist`
- **Domínio:** Otimização e sustentação de bancos de dados relacionais e de séries temporais sob alto throughput.
- **Cobertura técnica:** Tuning de bancos de telemetria e produção (PostgreSQL 14+, TimescaleDB com hypertables/chunks e MySQL 8+), análise minuciosa de planos de execução (`EXPLAIN (ANALYZE, BUFFERS)`), estratégias de indexação avançada (B-Tree, BRIN para dados temporais sequenciais, GIN/GiST para JSONB), particionamento de tabelas de histórico/tendências, dimensionamento e pool de conexões (PgBouncer), mitigação de contenção de locks/deadlocks e parametrização de I/O, memória (`work_mem`, `shared_buffers`) e checkpoints.

### 9. `proxmox-specialist`
- **Domínio:** Virtualização, clustering empresarial e infraestrutura hiperconvergente com Proxmox Virtual Environment (PVE) 8.x e 9.x.
- **Cobertura técnica:** Arquitetura de cluster Corosync v3, qdevice em topologias de dois nós, procedimentos de upgrade e migração segura PVE 8 para 9 (`pve8to9`), storage hiperconvergente Ceph (versões Reef e Squid com BlueStore) e pools ZFS locais/compartilhados (ashift=12, limites de ARC, compressão zstd), Proxmox SDN (Software-Defined Networking com zones VLAN, VXLAN e EVPN multi-tenancy), automação e provisionamento de VMs e contêineres unprivileged LXC via QEMU/KVM, cloud-init e Terraform (`bpg/proxmox`), ecossistema de backup com Proxmox Backup Server (PBS com deduplicação e dirty-bitmaps em tempo real), Alta Disponibilidade com HA CRM/LRM e fencing via watchdog, e integração de telemetria nativa com Zabbix Agent 2 e Prometheus.

---

### Estrutura dos Arquivos de Especialistas

Em cada uma das 4 plataformas, todo especialista implementa uma estrutura padrão composta por 7 arquivos:
1. `SKILL.md`: Manifesto com objetivos, limites operacionais, requisitos de modelo e conformidade v5;
2. Três guias de engenharia de domínio e boas práticas;
3. `troubleshooting.md`: Matriz de diagnóstico, códigos de erro e armadilhas técnicas;
4. `knowledge/<dominio>/README.md`: Repositório local de decisões de arquitetura e snippets;
5. `evals/<dominio>/001-routing.md`: Casos de teste automatizáveis para aferir respeito a gates de aprovação e pisos de risco.

### Flags de Instalação dos Especialistas

- **Instalação Individual:**
  - Bash/Fish: `--with-zabbix-specialist`, `--with-grafana-specialist`, `--with-ansible-specialist`, `--with-loki-specialist`, `--with-prometheus-specialist`, `--with-netops-specialist`, `--with-sre-incident-specialist` (alias: `--with-sre-specialist`), `--with-database-tuning-specialist` (alias: `--with-db-tuning-specialist`), `--with-proxmox-specialist`.
  - PowerShell: `-WithZabbixSpecialist`, `-WithGrafanaSpecialist`, `-WithAnsibleSpecialist`, `-WithLokiSpecialist`, `-WithPrometheusSpecialist`, `-WithNetopsSpecialist`, `-WithSreSpecialist`, `-WithDbTuningSpecialist`, `-WithProxmoxSpecialist`.
- **Instalação Agregadora (Todos os 9 especialistas):**
  - Bash/Fish: `--with-all-specialists`
  - PowerShell: `-WithAllSpecialists`

---

## Formato obrigatório do relatório de modelos

Em conformidade estrita com o Framework v5 para ecossistemas Google (Gemini CLI, Google Antigravity), todo relatório de encerramento de tarefa deve apresentar a tabela de utilização de modelos utilizando **exclusivamente a nomenclatura do Google (`Flash` e `Pro`)**:

### Utilização dos modelos

| Modelo | Execuções | Utilização |
|---|---:|---:|
| Flash | X | XX% |
| Pro | X | XX% |

**Total de execuções de subagentes:** X

- Execuções em tiers inferiores ou workers rápidos são contabilizadas em **Flash** (`gemini-2.5-flash`, `gemini-3-flash`).
- Execuções em tiers de raciocínio, especialistas ou revisores de alto risco são contabilizadas em **Pro** (`gemini-2.5-pro`, `gemini-3-pro`).
- Quando a tarefa for realizada diretamente pelo modelo principal sem acionamento de subagentes, registra-se 1 execução (100%) no modelo ativo e 0 no outro, informando a justificativa técnica para a execução direta.

---

## Distribuições e pacotes compactados

Na raiz do repositório encontram-se quatro arquivos `.zip`, gerados diretamente a partir das pastas correspondentes do projeto:
- `claude-code-global-framework-v5.zip`
- `codex-global-framework-v5.zip`
- `cursor-global-framework-v5.zip`
- `gemini-cli-global-framework-v5.zip`

**Padrão de Empacotamento:** Cada arquivo `.zip` inclui como prefixo a pasta principal da distribuição (ex.: `claude-code-global-framework-v5/scripts/...`). Ao extrair o arquivo em qualquer diretório (inclusive no `$HOME`), os arquivos não são despejados na raiz, permitindo navegar até a pasta extraída e executar os instaladores com isolamento total.

Cada pacote contém seu próprio `MANIFEST.sha256` registrando o hash SHA-256 e caminho relativo de todos os seus arquivos, garantindo integridade estática verificável.
