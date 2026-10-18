# Workloads e Rede no Kubernetes

## 1. Deployment de Referência para Produção

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: app
  labels: { app.kubernetes.io/name: app }
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxUnavailable: 0, maxSurge: 1 }
  selector:
    matchLabels: { app.kubernetes.io/name: app }
  template:
    metadata:
      labels: { app.kubernetes.io/name: app }
    spec:
      serviceAccountName: app
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        seccompProfile: { type: RuntimeDefault }
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels: { app.kubernetes.io/name: app }
      containers:
        - name: app
          image: registry.exemplo.local/app:1.4.2
          ports: [{ name: http, containerPort: 8080 }]
          resources:
            requests: { cpu: 100m, memory: 128Mi }
            limits: { memory: 256Mi }
          readinessProbe:
            httpGet: { path: /ready, port: http }
            periodSeconds: 5
          livenessProbe:
            httpGet: { path: /health, port: http }
            initialDelaySeconds: 10
            periodSeconds: 10
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities: { drop: ["ALL"] }
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app
  namespace: app
spec:
  minAvailable: 2
  selector:
    matchLabels: { app.kubernetes.io/name: app }
```

- `livenessProbe` não deve depender de serviços externos (banco, API): falha de dependência reinicia pods sadios em cascata; isso é papel da `readinessProbe`.
- Limite de memória sempre definido; limite de CPU é decisão consciente (throttling vs. vizinhança ruidosa) e deve ser documentado.
- `HorizontalPodAutoscaler` exige `requests` definidos e metrics-server instalado.

## 2. Rede: Services, Ingress/Gateway e NetworkPolicy

- `ClusterIP` para tráfego interno; exposição externa via Ingress controller ou Gateway API, com TLS gerenciado (por exemplo cert-manager).
- Negação padrão por namespace e liberações explícitas:
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata: { name: default-deny, namespace: app }
  spec:
    podSelector: {}
    policyTypes: [Ingress, Egress]
  ```
  Lembre de liberar egress para DNS (porta 53 UDP/TCP do CoreDNS) ao aplicar negação de egress. `NetworkPolicy` só tem efeito se o CNI a implementar (por exemplo Calico ou Cilium).

## 3. Configuração, Segredos e Storage

- `ConfigMap` para configuração não sensível; `Secret` para credenciais, com criptografia em repouso no etcd habilitada e acesso restrito por RBAC.
- `PersistentVolumeClaim` com `StorageClass` explícita; verifique `reclaimPolicy` (`Retain` para dados críticos) e `volumeBindingMode`.
- Backups de volumes e recursos (por exemplo Velero) testados com restauração.

## 4. Empacotamento: Helm e Kustomize

```bash
helm lint ./chart
helm template app ./chart -f values-prod.yaml | kubectl apply --dry-run=server -f -
helm diff upgrade app ./chart -f values-prod.yaml   # requer o plugin helm-diff
kustomize build overlays/prod | kubectl diff -f -
```

- Fixe a versão do chart (`--version`) e versione os `values` por ambiente.
- `helm upgrade --install --atomic --timeout 10m` reverte automaticamente em falha; registre `helm history` para rollback (`helm rollback app <revisão>`).
