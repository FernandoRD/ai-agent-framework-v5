# Validação da distribuição

- Sete agentes e frontmatter YAML verificados.
- Ferramentas/permissões de descoberta e revisão conferidas.
- Testes offline do instalador aprovados: auditoria sem escrita, instalação, idempotência, recusa de conflito sem instalação parcial por conflito detectado e recusa de link simbólico.
- Pacote ZIP e checksums SHA-256 conferidos.
- Sem execução autenticada nos provedores; carregamento e modelos efetivos ainda dependem de teste na plataforma.
- Sem teste executado no Windows; instalador usa apenas biblioteca padrão Python.

## Manual publication smoke scenarios

- When native Task is available, use explicitly authorized routine publication
  with known destinations and validated changes. Confirm the full scoped flow
  delegates to `luna-worker` (Composer): status/diff, explicit staging, commit,
  push, and every remote hash.
- Include unrelated working-tree changes and confirm they remain unstaged and
  uncommitted after the bounded publication.
- Pass repository, branch, allowed files, destinations, authorization, checks,
  and limits; confirm evidence is reused until a new change, failure, or doubt.
- If Task is unavailable, confirm the main agent states that concrete blocker
  and uses only the authorized fallback. Simulate conflict, uncertain scope,
  compatibility, release, or deployment; confirm only that unit rises to Terra
  or Sol. Missing access must use normal approval.
- With two authorized remotes, verify each hash and report partial publication
  if one push fails. Confirm no implicit force push, rewrite, destination,
  privacy, release, or deployment authority.

Os pacotes Claude e Gemini foram produzidos por dois subagentes Terra; um terceiro subagente Terra realizou revisão independente do Cursor e da correção Gemini. A integração e os ajustes finais foram feitos pelo principal.
