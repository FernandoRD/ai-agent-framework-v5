# AI Agent Framework v5

Framework de roteamento de tarefas de engenharia entre agentes de IA. A v5 faz o agente principal classificar cada solicitação, avaliar complexidade e risco e escolher a menor capacidade que possa executá-la com segurança. A prioridade é decompor o trabalho e encaminhar cada unidade ao menor agente capaz de executá-la e validá-la com segurança. O principal coordena e integra; sua capacidade maior não justifica reter unidades de menor complexidade. A política também define delegação e revisão obrigatórias quando houver benefício concreto, exceções delimitadas e validação proporcional.

O repositório distribui uma implementação nativa para Codex e adaptações por projeto para Claude Code, Gemini CLI (Google Antigravity), Cursor e Hermes Agent. As adaptações preservam a política de decisão; os nomes e a disponibilidade dos modelos dependem de cada plataforma.

Em todas as variantes, a publicação é roteada separadamente: commits e pushes rotineiros, autorizados e com mudanças validadas são delegados ao worker de menor capacidade suficiente (Luna no Codex, Haiku no Claude Code, Flash no Gemini CLI / Antigravity, Composer no Cursor e o `delegation.model` no Hermes), mesmo quando a implementação usou um agente maior. O fluxo reaproveita as validações disponíveis, preserva alterações alheias e confere o hash em cada remote. Conflitos e riscos adicionais elevam apenas a etapa afetada; falta de acesso não justifica trocar por um modelo mais caro.

## Pacotes

Versões atuais (arquivo `VERSION`): Codex 5.0.0, Claude Code 5.2.0-claude-code, Gemini CLI 5.0.0-gemini-cli, Cursor 5.0.0-cursor, Hermes 5.0.0-hermes. As variantes não têm paridade funcional; veja [VARIANTES-V5.md](VARIANTES-V5.md).

| Pacote | Destino | Instalação | Modelos mapeados |
| --- | --- | --- | --- |
| [codex-global-framework-v5](codex-global-framework-v5/) | Codex | Global (padrão) ou Por projeto | Luna, Terra e Sol |
| [claude-code-global-framework-v5](claude-code-global-framework-v5/) | Claude Code | Por projeto (padrão) ou Global | Haiku, Sonnet e Opus |
| [gemini-cli-global-framework-v5](gemini-cli-global-framework-v5/) | Gemini CLI / Antigravity | Por projeto (padrão) ou Global | Flash (0-34) e Pro (35-100) |
| [cursor-global-framework-v5](cursor-global-framework-v5/) | Cursor | Por projeto (padrão) ou Global | Composer, Sonnet e Opus |
| [hermes-global-framework-v5](hermes-global-framework-v5/) | Hermes Agent | Por projeto (padrão) ou Global | Luna, Terra e Sol (sem modelo fixo; escolhidos pelo usuário) |

Os arquivos `.zip` na raiz contêm as mesmas distribuições prontas para transporte. Cada ZIP inclui uma pasta principal com o nome da distribuição; após extrair, entre nessa pasta para executar o instalador. Isso mantém os arquivos do pacote separados das configurações instaladas, mesmo ao extrair no diretório pessoal. Veja as diferenças de cada variante em [VARIANTES-V5.md](VARIANTES-V5.md) e a arquitetura em [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md).

## Extensões opcionais

Os 11 especialistas de domínio são distribuídos em todos os cinco pacotes como skills opcionais, não fazendo parte da instalação padrão nem alterando os papéis centrais do framework:

1. **Zabbix Specialist**: automação Zabbix, templates, LLD, proxies, API, HA e coletor RAG opcional.
2. **Grafana Specialist**: foco em Grafana 12, desenvolvimento avançado em HTML Graphics (`gapit-htmlgraphics-panel`), UI/UX de NOC/dashboards e automação via API.
3. **Ansible Specialist**: automação de infraestrutura, playbooks modulares, roles, dynamic inventory, idempotência e Ansible Vault.
4. **Loki Specialist**: agregação e consulta de logs em escala, LogQL, Promtail/Alloy, otimização de labels e retenção em chunks.
5. **Prometheus Specialist**: monitoramento e observabilidade métrica, PromQL avançado, exporters, Alertmanager e controle de cardinalidade.
6. **NetOps Specialist**: engenharia de redes, topologia, BGP/OSPF, VLANs, firewalling, VPNs e análise de tráfego/pacotes.
7. **SRE Incident Specialist**: resposta e gestão de incidentes, runbooks de crise, post-mortems estruturados (RCA), SLOs/SLIs e error budgets.
8. **Database Tuning Specialist**: otimização de bancos relacionais e analíticos, tuning de queries/índices, pool de conexões e mitigação de locks/deadlocks.
9. **Proxmox Specialist**: virtualização e clustering empresarial com foco em Proxmox VE 8.x e 9.x, Corosync v3, Ceph (Reef/Squid), Proxmox SDN (VLAN/VXLAN/EVPN), Proxmox Backup Server (PBS), automação via QEMU/LXC, Terraform (`bpg/proxmox`), cloud-init e alta disponibilidade (HA CRM/LRM).
10. **Shell & Python Specialist**: programação Shell Script (Bash 4+, POSIX sh, fish) e Python 3.10+ para automação de infraestrutura, com scripts robustos (`set -euo pipefail`, `shellcheck`, `ruff`, `pytest`), UserParameters, LLD e `zabbix_sender` do Zabbix, clientes de API e agendamento com cron/timers do systemd.
11. **Docker & Kubernetes Specialist**: contêineres com Docker Engine e Compose v2 (imagens multi-stage, hardening) e orquestração com Kubernetes (workloads, probes, PDB, RBAC, NetworkPolicy, Helm/Kustomize, upgrades, backup do etcd) e observabilidade com Prometheus, Loki e Zabbix.

Instale-os somente quando o projeto precisar:

```bash
# Codex (global ou por projeto)
./scripts/install.sh --with-grafana-specialist
./scripts/install.sh --with-all-specialists

# Claude Code, Gemini CLI, Cursor ou Hermes (inclua --apply para escrever)
./scripts/install.sh --target "/caminho/do/projeto" --with-ansible-specialist --apply
./scripts/install.sh --target "/caminho/do/projeto" --with-all-specialists --apply
```

No PowerShell, use os parâmetros correspondentes (`-WithAnsibleSpecialist`, `-WithGrafanaSpecialist`, etc.) ou `-WithAllSpecialists`. Nas variantes por projeto, combine com `-Apply`. Sem essas opções, o conteúdo dos especialistas não é instalado.

No Hermes, `zabbix-specialist` e `docker-kubernetes-specialist` ficam em quarentena quando instalados como skills de projeto (falsos positivos do scanner de segurança); instale-os com `--global`, onde funcionam normalmente. Detalhes em [hermes-global-framework-v5/README.md](hermes-global-framework-v5/README.md).

No Claude Code (v5.2.0-claude-code), cada opção instala também o **agente nativo** `.claude/agents/<nome>-specialist.md`, que pré-carrega a skill homônima, usa `model: sonnet` por padrão e segue o roteamento v5 (para unidade de nível Haiku ou Opus, o principal o invoca com o modelo correspondente). O instalador Bash/Fish dessa variante (e só ele; Gemini CLI, Cursor e Hermes não têm) ganhou `--uninstall`, que remove apenas arquivos intactos (inclusive de versões anteriores listadas em `scripts/legacy-hashes.sha256`). Detalhes em [claude-code-global-framework-v5/README.md](claude-code-global-framework-v5/README.md).

O Zabbix Specialist inclui um coletor RAG opcional para fontes Git e Jira. Ele fica
dentro da skill, recebe configuração JSON criada pelo usuário e grava dados
somente no diretório de dados informado pelo usuário. Veja `rag-ingestion.md`
na skill instalada antes de configurar uma fonte ou um agendador externo.

## Como usar

### Codex

O pacote Codex instala a política global em `~/.codex/` e as skills em `~/.agents/skills/`. Requer Python 3.11 ou superior apenas para o validador (`tomllib`). Por padrão o instalador aplica; `--audit-only` só audita e `--apply` é um no-op documentado. O plano é calculado antes de mutar, Skills divergentes abortam e o hook usa caminho absoluto; `validate.py` instala em diretório temporário.

No Linux:

```bash
cd codex-global-framework-v5
./scripts/install.sh --audit-only
./scripts/install.sh
./scripts/diagnose.sh
python3 scripts/validate.py
```

Há instaladores equivalentes para PowerShell, Fish e WSL dentro de `scripts/`. Leia o [README do pacote Codex](codex-global-framework-v5/README.md) antes de instalar: ele faz backup e trata resíduos das versões v3/v4.

### Claude Code, Gemini CLI (Antigravity), Cursor e Hermes

As quatro variantes usam instalador conservador com suporte a escopo por projeto ou global (`$HOME`), com scripts equivalentes em Shell Script (`.sh` para Bash e `.fish` para Fish) e PowerShell (`.ps1` para Windows). A auditoria nunca escreve, inclusive com `--global`; não escreve; `--apply` / `-Apply` cria somente arquivos inexistentes (no Bash, criação exclusiva sob `noclobber`) e interrompe se encontrar conflito ou link simbólico, inclusive em alvo global:
- **No projeto (`--target "/caminho/do/projeto"`)**: o arquivo de instruções (`CLAUDE.md` ou `GEMINI.md`) é gerado na raiz do repositório e os subagentes na pasta oculta (`.claude/agents/`, `.gemini/agents/`). No Cursor não há `AGENTS.md`: regra e agentes ficam em `.cursor/rules/` e `.cursor/agents/`. No Hermes, `HERMES.md` fica na raiz e os papéis em `.hermes/skills/` (ative com `hermes skills trust`); o `HERMES.md` passa a ser o único contexto de projeto lido pelo Hermes.
- **No Home / Global (`--global` ou `--target ~`)**: o arquivo de instruções fica **dentro** da pasta oculta (`~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`; no Cursor, `~/.cursor/rules/`; no Hermes, `~/.hermes/`), evitando poluir a raiz do diretório pessoal. **Exceção do Hermes:** ele não lê regras globais, então a política só vale quando o `HERMES.md` está na pasta do projeto (`--target`). A instalação global do Hermes disponibiliza apenas as skills.

No Linux/macOS (Bash ou Fish):

```bash
cd claude-code-global-framework-v5  # ou gemini-cli-, cursor- ou hermes-global-framework-v5

# Para instalar em um projeto:
./scripts/install.sh --target "/caminho/do/projeto"
./scripts/install.sh --target "/caminho/do/projeto" --apply

# Para instalar globalmente no seu $HOME:
./scripts/install.sh --global
./scripts/install.sh --global --apply

# ou no Fish: ./scripts/install.fish --global --apply
python3 scripts/test_install.py  # Python 3.10+, só para testar; não é usado para instalar
```

No Windows (PowerShell):

```powershell
cd claude-code-global-framework-v5  # ou gemini-cli-, cursor- ou hermes-global-framework-v5

# Para instalar em um projeto:
.\scripts\install.ps1 -Target "C:\caminho\do\projeto"
.\scripts\install.ps1 -Target "C:\caminho\do\projeto" -Apply

# Para instalar globalmente:
.\scripts\install.ps1 -Global
.\scripts\install.ps1 -Global -Apply
```

Os scripts de instalação são nativos em Shell Script (`.sh`, `.fish`) e PowerShell (`.ps1`), sem Python na instalação. Siga o README da variante para ativar agentes e, no Gemini, mesclar `settings.example.json` manualmente.

## Limites

A política orienta o agente principal; ela não é um despachante externo que imponha a pontuação ou a seleção de modelos. Planos, versões, políticas administrativas e autenticação podem alterar quais modelos, esforços e subagentes estão disponíveis. Os pacotes foram verificados por seus validadores e testes offline quando fornecidos, mas não há garantia de execução em uma sessão autenticada de cada plataforma.

As pastas [Claude code](Claude%20code/) e [Codex](Codex/) são material histórico/de referência. Não as use para instalar a v5; escolha um dos cinco pacotes acima.

## Manutenção

As regras de contribuição e manutenção deste repositório estão em [CLAUDE.md](CLAUDE.md). Antes de modificar payloads, instaladores ou a política, consulte a [referência técnica](TECHNICAL_REFERENCE.md) e execute as verificações pertinentes.
