# Validação da distribuição

- Sete agentes e frontmatter YAML verificados.
- Ferramentas/permissões de descoberta e revisão conferidas.
- Testes offline do instalador aprovados: auditoria sem escrita, instalação, idempotência, recusa de conflito sem instalação parcial por conflito detectado e recusa de link simbólico.
- Pacote ZIP e checksums SHA-256 conferidos.
- Sem execução autenticada nos provedores; carregamento e modelos efetivos ainda dependem de teste na plataforma.
- Sem teste executado no Windows; instalador usa apenas biblioteca padrão Python.

## Manual publication smoke scenarios

- With explicitly authorized routine publication, known destinations, and
  validated changes, confirm the main agent delegates the full scoped workflow
  to `flash-worker`: scoped status/diff, explicit staging, commit, push, and
  every remote hash. Confirm the worker does not delegate further.
- Include unrelated working-tree changes and confirm they remain unstaged and
  uncommitted after the bounded publication.
- Pass repository, branch, allowed files, destinations, authorization, checks,
  and limits; confirm evidence is reused until a new change, failure, or doubt.
- Simulate conflict, uncertain scope, compatibility, release, or deployment;
  confirm only that unit rises to Pro. Without credentials, network, or
  approval, confirm normal access handling rather than escalation.
- Make delegation unavailable or prohibited; confirm the main agent states the
  concrete blocker and uses only the authorized fallback without claiming Flash
  execution.
- With two authorized remotes, verify each hash and report partial publication
  if one push fails. Confirm no implicit force push, rewrite, destination,
  privacy, release, or deployment authority.

Os pacotes Claude e Gemini foram produzidos por dois subagentes Terra; um terceiro subagente Terra realizou revisão independente do Cursor e da correção Gemini. A integração e os ajustes finais foram feitos pelo principal.
