# Base de Conhecimento Local: Docker e Kubernetes

Este diretório armazena convenções de contêineres, padrões de manifests e decisões de plataforma adotadas no projeto para Docker e Kubernetes.

---

## 1. Convenção Recomendada de Labels

| Label | Finalidade | Exemplo |
|---|---|---|
| `app.kubernetes.io/name` | Nome da aplicação | `api-pedidos` |
| `app.kubernetes.io/instance` | Instância/release | `api-pedidos-prod` |
| `app.kubernetes.io/version` | Versão implantada | `1.4.2` |
| `app.kubernetes.io/component` | Papel no sistema | `backend`, `worker` |
| `app.kubernetes.io/part-of` | Sistema maior | `faturamento` |
| `app.kubernetes.io/managed-by` | Ferramenta de deploy | `Helm`, `kustomize` |

---

## 2. Convenção Recomendada de Namespaces

| Padrão | Finalidade |
|---|---|
| `<sistema>-<ambiente>` | Workloads de aplicação (`faturamento-prod`, `faturamento-hml`) |
| `monitoring` | Prometheus, Alertmanager, Zabbix proxy/agentes, Alloy |
| `logging` | Loki e coletores |
| `ingress` | Ingress controller / Gateway |

Todo namespace de aplicação recebe `NetworkPolicy` de negação padrão, `ResourceQuota`, `LimitRange` e o label de Pod Security Admission (`pod-security.kubernetes.io/enforce`).

---

## 3. Padrões Mínimos de Imagem

- Tag imutável com versão e commit (`1.4.2-<sha curto>`); nunca `latest` em produção.
- Usuário não-root (UID ≥ 10000), sem shell ou ferramentas de build na imagem final quando possível.
- Varredura de vulnerabilidades no pipeline antes do push para o registry.

Registre aqui as versões de Kubernetes, CNI, CSI, Ingress controller e registry em uso, e qualquer exceção aprovada a estes padrões.
