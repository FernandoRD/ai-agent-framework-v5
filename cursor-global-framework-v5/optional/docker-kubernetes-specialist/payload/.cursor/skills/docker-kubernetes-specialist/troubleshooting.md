# Troubleshooting de Docker e Kubernetes

## 1. Pod em `Pending`

```bash
kubectl describe pod <pod> -n <ns>        # seção Events
kubectl get events -n <ns> --sort-by=.lastTimestamp
kubectl describe node <node> | grep -A5 -E 'Allocated resources|Taints'
```

- Causas comuns: `requests` acima da capacidade livre, taints sem tolerations, afinidade impossível, PVC sem `StorageClass` ou volume preso a outra zona.

## 2. `CrashLoopBackOff`, `Error` ou `OOMKilled`

```bash
kubectl logs <pod> -n <ns> -c <container> --previous
kubectl get pod <pod> -n <ns> -o jsonpath='{.status.containerStatuses[*].lastState}'
```

- `OOMKilled` (exit code 137): limite de memória baixo ou vazamento; compare com o uso real antes de só aumentar o limite.
- Exit code 1/2 no início: configuração, variáveis ausentes ou `Secret`/`ConfigMap` inexistente.
- `livenessProbe` agressiva reiniciando uma aplicação lenta para subir: use `startupProbe`.

## 3. `ImagePullBackOff` / `ErrImagePull`

- Confirme nome, tag e arquitetura da imagem (`docker manifest inspect <imagem>`), o `imagePullSecrets` do pod/ServiceAccount e a resolução DNS/proxy do nó até o registry.

## 4. Serviço Sem Resposta

```bash
kubectl get endpointslices -n <ns> -l kubernetes.io/service-name=<svc>
kubectl run -it --rm debug --image=busybox:1.36 --restart=Never -n <ns> -- \
  wget -qO- -T 3 http://<svc>:<porta>/health
kubectl debug -it <pod> -n <ns> --image=busybox:1.36 --target=<container>
```

- Sem endpoints: o `selector` do Service não bate com os labels dos pods ou os pods não estão prontos.
- Com endpoints mas sem resposta: `NetworkPolicy` bloqueando, porta errada (`port` vs. `targetPort`) ou aplicação ouvindo só em `127.0.0.1`.
- DNS: `nslookup <svc>.<ns>.svc.cluster.local` a partir de um pod de depuração e logs do CoreDNS.

## 5. Nó `NotReady`

- No nó: `systemctl status kubelet containerd`, `journalctl -u kubelet --since '30 min ago'`, espaço em disco (`df -h`, `crictl images`) e pressão de memória.
- Use `crictl ps -a` e `crictl logs` (runtime containerd/CRI-O) em vez de `docker` em nós Kubernetes atuais.

## 6. Docker Engine e Compose

```bash
docker compose ps
docker compose logs --tail=100 <serviço>
docker inspect --format '{{json .State}}' <contêiner>
docker events --since 30m
docker system df
```

- Contêiner reiniciando: verifique `State.ExitCode`, `State.OOMKilled` e o `healthcheck`.
- Disco cheio: logs sem rotação, imagens antigas e volumes órfãos; limpe somente após confirmar o que será removido.
