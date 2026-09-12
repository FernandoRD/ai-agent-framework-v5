# Validação da distribuição

- Sete agentes e frontmatter YAML verificados.
- Ferramentas/permissões de descoberta e revisão conferidas.
- Testes offline do instalador aprovados: auditoria sem escrita, instalação, idempotência, recusa de conflito sem instalação parcial por conflito detectado e recusa de link simbólico.
- Pacote ZIP e checksums SHA-256 conferidos.
- Sem execução autenticada nos provedores; carregamento e modelos efetivos ainda dependem de teste na plataforma.
- Sem teste executado no Windows; instalador usa apenas biblioteca padrão Python.

Os pacotes Claude e Gemini foram produzidos por dois subagentes Terra; um terceiro subagente Terra realizou revisão independente do Cursor e da correção Gemini. A integração e os ajustes finais foram feitos pelo principal.
