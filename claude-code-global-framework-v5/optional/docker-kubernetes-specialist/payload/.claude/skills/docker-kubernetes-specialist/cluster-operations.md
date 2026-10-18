# Operação de Cluster e Observabilidade

## 1. Contexto Antes de Qualquer Comando

```bash
kubectl config current-context
kubectl version
kubectl get nodes -o wide
kubectl auth can-i --list -n <namespace>
```

- Confirme o contexto e o namespace antes de toda operação; um `kubectl` apontado para o cluster errado é causa clássica de incidente.
- Prefira kubeconfigs separados por ambiente e contextos com nomes explícitos (`prod-...`, `hml-...`).

## 2. Manutenção de Nós

```bash
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --timeout=10m
# manutenção...
kubectl uncordon <node>
```

- `drain` respeita `PodDisruptionBudget`; se travar, investigue o PDB em vez de forçar (`--disable-eviction` contorna os PDBs e só deve ser usado com aprovação).
- `--delete-emptydir-data` apaga dados de `emptyDir`: confirme que não há estado relevante.

## 3. Upgrades de Cluster

- Kubernetes suporta upgrade de **uma versão minor por vez** no control plane; os kubelets podem ficar algumas versões atrás do API server, dentro da política de *version skew* oficial da versão em uso.
- Antes do upgrade: leia as notas de release e as APIs removidas, verifique manifests e charts com ferramentas como `pluto` ou `kubent`, faça backup do etcd e dos recursos, e confirme compatibilidade de CNI, CSI, Ingress controller e operadores.
- kubeadm: `kubeadm upgrade plan` → `kubeadm upgrade apply v1.X.Y` no primeiro control plane → `kubeadm upgrade node` nos demais → kubelet/kubectl nó a nó com `drain`/`uncordon`.
- Clusters gerenciados e distribuições (k3s, RKE2) seguem o procedimento do fornecedor.

## 4. Backup do etcd (clusters kubeadm)

```bash
ETCDCTL_API=3 etcdctl snapshot save /var/backups/etcd-$(date +%F).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
etcdutl snapshot status /var/backups/etcd-$(date +%F).db
```

- O snapshot contém todos os `Secret`s do cluster: armazene cifrado e com acesso restrito.
- Um backup só é válido depois de uma restauração testada em ambiente isolado.

## 5. Observabilidade

- **Prometheus**: kube-prometheus-stack (Prometheus Operator, kube-state-metrics, node-exporter, Alertmanager); alertas essenciais para `CrashLoopBackOff`, pods não prontos, nós `NotReady`, PVC quase cheio, certificados expirando e `OOMKilled`.
- **Logs**: coleta de `stdout`/`stderr` dos contêineres com Grafana Alloy ou Promtail para Loki, com labels de baixa cardinalidade (`namespace`, `app`, `container`).
- **Zabbix**: Helm chart oficial do Zabbix para Kubernetes (Zabbix proxy e agentes no cluster) com os templates oficiais "Kubernetes ... by HTTP" (nós, estado do cluster, API server, kubelet, controller manager e scheduler); use um `ServiceAccount` com permissões somente leitura e token dedicado.
- **Docker standalone**: plugin Docker do Zabbix Agent 2 (template "Docker by Zabbix agent 2") ou cAdvisor exposto ao Prometheus.
