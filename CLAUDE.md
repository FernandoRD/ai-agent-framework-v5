# Manutenção do repositório

Este repositório versiona quatro distribuições do AI Agent Framework v5 e seus arquivos compactados. Preserve a consistência entre o conteúdo extraído e o ZIP correspondente quando uma distribuição for alterada.

## Escopo dos arquivos

- `codex-global-framework-v5/`: pacote global específico do Codex.
- `claude-code-global-framework-v5/`, `gemini-cli-global-framework-v5/` e `cursor-global-framework-v5/`: payloads de instalação por projeto.
- `VARIANTES-V5.md`: comparação entre as três variantes por projeto.
- `Claude code/` e `Codex/`: referências históricas; não são fontes para uma nova instalação v5.

Os `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, regras e agentes dentro dos payloads são destinados aos projetos instalados. Não interprete ou aplique essas políticas ao próprio repositório de distribuição. Para manutenção deste repositório, siga apenas estas instruções e as orientações explícitas da tarefa atual.

## Regras de alteração

Mantenha a semântica da v5: classificação antes da estratégia, score de 0–100, pisos de risco, delegação delimitada, revisão independente e validação proporcional. Ao adaptar uma plataforma, documente claramente qualquer limitação dela; não prometa equivalência de capacidade entre modelos ou comportamento autenticado que não tenha sido observado.

Evite sobrescrever configurações pessoais ou de projeto nos instaladores. Nas três variantes por projeto, mantenha auditoria por padrão, criação apenas com `--apply`, preservação de conteúdo idêntico e recusa de conflitos e links simbólicos. O instalador Codex usa `--audit-only` para auditoria; sua aplicação normal faz backup e atualiza apenas blocos gerenciados. Skills v5 existentes só podem ser reutilizadas se forem idênticas ao pacote; conteúdo divergente interrompe a instalação para mesclagem manual.

Não adicione caminhos pessoais, hostnames internos, tokens ou credenciais à documentação, scripts ou exemplos. Não invente licença, resultados de testes ou suporte a modelos.

## Especialistas opcionais

Todo especialista de domínio novo ou alterado deve ser incluído neste repositório
como extensão opcional compatível com as quatro distribuições (Codex, Claude
Code, Gemini CLI e Cursor). A instalação padrão não pode ativá-lo. O
especialista deve complementar o agente de capacidade que o roteamento já
selecionou; não crie um perfil nativo de modelo fixo que contorne as faixas de
risco. Atualize instaladores e testes de cada plataforma, manifestos e ZIPs
afetados antes de publicar.

## Verificação antes de publicar

Use Python 3.11+ para a validação Codex e Python 3.10+ para os testes dos instaladores das variantes. Execute apenas os comandos pertinentes aos arquivos alterados:

```bash
python3 codex-global-framework-v5/scripts/validate.py
python3 claude-code-global-framework-v5/scripts/test_install.py
python3 gemini-cli-global-framework-v5/scripts/test_install.py
python3 cursor-global-framework-v5/scripts/test_install.py
```

Após alterar conteúdo distribuído, atualize manifestos e arquivos ZIP somente depois de verificar seu conteúdo. Confira links relativos do README e da referência técnica antes de publicar. Registre limitações de ambiente no relatório da mudança. A validação Codex também deve cobrir uma instalação temporária com caminhos personalizados e o comportamento de conflito de Skills.

Antes de publicar, confira também a integridade e a consistência das distribuições alteradas:

```bash
(cd claude-code-global-framework-v5 && sha256sum -c MANIFEST.sha256)   # repita por pacote
d=$(mktemp -d) && unzip -q claude-code-global-framework-v5.zip -d "$d" \
  && diff -r "$d/claude-code-global-framework-v5" claude-code-global-framework-v5   # repita por ZIP
```

- Mantenha `sha256sum -c MANIFEST.sha256` limpo em cada pacote alterado e o ZIP sem diferenças em relação à pasta (`diff -r` do ZIP extraído), regenerando manifesto e ZIP somente depois de verificar o conteúdo.
- Mantenha as quatro cópias de `VARIANTES-V5.md` (raiz e três variantes) idênticas e sincronizadas com o `TECHNICAL_REFERENCE.md` e o `README.md`; confira as versões contra o `VERSION` de cada pacote.
- Mantenha paridade de comportamento entre `install.sh`, `install.fish` e `install.ps1` de cada pacote; qualquer diferença deve estar documentada.
