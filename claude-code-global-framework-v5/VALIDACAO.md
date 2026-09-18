# Validação da distribuição

- Sete agentes e frontmatter YAML verificados.
- Ferramentas/permissões de descoberta e revisão conferidas.
- Testes offline do instalador aprovados: auditoria sem escrita, instalação, idempotência, recusa de conflito sem instalação parcial por conflito detectado e recusa de link simbólico.
- Pacote ZIP e checksums SHA-256 conferidos.
- Sem execução autenticada nos provedores; carregamento e modelos efetivos ainda dependem de teste na plataforma.
- Sem teste executado no Windows; instalador usa apenas biblioteca padrão Python.

## Cenários manuais de publicação

- Com publicação rotineira explicitamente autorizada, destinos conhecidos e
  mudanças validadas, confirme a delegação do fluxo inteiro ao `haiku-worker`:
  status/diff no escopo, staging explícito, commit, push e hash de cada remote.
- Inclua mudanças não relacionadas na árvore de trabalho; confirme que permanecem
  fora do staging e do commit depois da publicação delimitada.
- Forneça a cápsula com repositório, branch, arquivos, destinos, autorização,
  verificações e limitações; confirme o reúso da evidência até haver mudança,
  falha ou dúvida nova.
- Simule conflito, escopo incerto, compatibilidade, release ou deploy; confirme
  escalonamento somente da unidade afetada para Sonnet/Opus. Sem credencial,
  rede ou aprovação, confirme solicitação normal de acesso, sem elevação.
- Indisponibilize ou proíba a delegação; confirme que o principal declara o
  bloqueio concreto e executa apenas o fallback já autorizado, sem atribuir a
  publicação ao Haiku.
- Em dois remotes autorizados, confira cada hash e reporte publicação parcial
  se um push falhar. Confirme que a política não permite force push, reescrita,
  novo destino, mudança de privacidade, release ou deploy sem autorização.

Os pacotes Claude e Gemini foram produzidos por dois subagentes Terra; um terceiro subagente Terra realizou revisão independente do Cursor e da correção Gemini. A integração e os ajustes finais foram feitos pelo principal.
