# Imagens Docker e Docker Compose v2

## 1. Dockerfile Multi-Stage Recomendado (Python)

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.12-slim AS build
WORKDIR /app
COPY pyproject.toml ./
COPY src ./src
RUN pip wheel --no-cache-dir --wheel-dir /wheels .

FROM python:3.12-slim
RUN useradd --system --uid 10001 --no-create-home app
WORKDIR /app
COPY --from=build /wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels
USER 10001
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2)"]
ENTRYPOINT ["python", "-m", "app"]
```

Boas práticas:
- Ordene as instruções da menos para a mais volátil para aproveitar o cache de camadas; mantenha um `.dockerignore` (exclua `.git`, `.venv`, segredos e artefatos locais).
- Forma exec (`["cmd", "arg"]`) em `ENTRYPOINT`/`CMD` para que o processo receba sinais (`SIGTERM`) corretamente.
- Um processo principal por contêiner; logs em `stdout`/`stderr`.
- Segredos de build com `RUN --mount=type=secret,id=...` (BuildKit), nunca com `ARG` ou `ENV`.
- Imagens multi-arquitetura com `docker buildx build --platform linux/amd64,linux/arm64`.

## 2. Docker Compose v2 (`docker compose`)

```yaml
services:
  app:
    image: registry.exemplo.local/app:1.4.2
    restart: unless-stopped
    read_only: true
    user: "10001"
    cap_drop: ["ALL"]
    security_opt: ["no-new-privileges:true"]
    env_file: [.env]
    ports: ["127.0.0.1:8080:8080"]
    depends_on:
      db:
        condition: service_healthy
    deploy:
      resources:
        limits: { cpus: "1.0", memory: 512M }
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }

  db:
    image: postgres:16
    volumes: [db-data:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER}"]
      interval: 10s
      retries: 5

volumes:
  db-data:
```

- Valide antes de subir: `docker compose config` (renderiza e verifica o arquivo) e `docker compose pull`.
- Publique portas em `127.0.0.1` quando o acesso externo passar por proxy reverso; regras publicadas pelo Docker contornam políticas comuns do `ufw`/`firewalld`.
- Rotação de logs configurada (no serviço ou em `/etc/docker/daemon.json`) para evitar disco cheio.
- `.env` com segredos fica fora do versionamento; versione um `.env.example` sem valores reais.

## 3. Operação do Docker Engine

- Limpeza consciente: `docker system df` antes de `docker image prune`/`docker system prune`; nunca `prune --volumes` sem confirmar que os volumes não guardam dados.
- Atualizações: `docker compose pull && docker compose up -d` por serviço, com rollback pela tag anterior anotada.
- Acesso ao socket (`/var/run/docker.sock`) equivale a root no host: não montar em contêineres nem adicionar usuários ao grupo `docker` sem aprovação.
