# Variantes v5 para outras plataformas

Geradas em 12/09/2026; política de execução e publicação sincronizada em 17/09/2026 com `codex-global-framework-v5/.codex/AGENTS.md`.

| Pacote | Plataforma | Faixas de execução |
| --- | --- | --- |
| `claude-code-global-framework-v5.zip` | Claude Code | Haiku / Sonnet / Opus |
| `gemini-cli-global-framework-v5.zip` | Gemini CLI | Flash / Pro; consultar limites na adaptação |
| `cursor-global-framework-v5.zip` | Cursor | Composer / Sonnet / Opus |

Cada pacote tem sete agentes, política v5 adaptada, README próprio e instalador Python por projeto. O nome “global-framework” identifica a origem; estas distribuições instalam no projeto explicitamente indicado. Não são instaladores globais em equivalência com o pacote Codex.

## Usar

Extraia o ZIP da plataforma. Dentro da pasta extraída, execute com o instalador de sua preferência (Bash, Fish, PowerShell ou Python):

No Linux/macOS (Bash ou Fish):

```sh
./scripts/install.sh --target "/caminho/do/projeto"
./scripts/install.sh --target "/caminho/do/projeto" --apply
# ou no Fish:
./scripts/install.fish "/caminho/do/projeto" --apply
```

No Windows (PowerShell):

```powershell
.\scripts\install.ps1 -Target "C:\caminho\do\projeto"
.\scripts\install.ps1 -Target "C:\caminho\do\projeto" -Apply
```

Ou diretamente via Python:

```sh
python scripts/install.py --target "/caminho/do/projeto" --apply
```

O primeiro comando somente mostra o que seria criado. O segundo cria arquivos novos, preserva idênticos e recusa conflitos; não modifica configurações pessoais. Requer Python 3.10+ no Linux/macOS ou PowerShell no Windows. Leia o README da plataforma antes da ativação, especialmente o exemplo de settings do Gemini.

Para conferir o instalador sem acessar nenhum provedor:

```sh
python scripts/test_install.py
```

O pacote preserva classificação trivial/não trivial, pesos e faixas do score, pisos de risco, delegação delimitada, revisão independente e relatório de execuções. Os nomes dos modelos não representam equivalência de capacidade entre fornecedores. A prioridade é analisar e decompor o trabalho, atribuir cada unidade ao menor agente suficiente dentro do mapeamento da plataforma e reservar ao principal a coordenação e integração. Isso não significa tentar sempre o modelo menor: os pisos de risco continuam obrigatórios. Delegação útil e revisão independente têm gatilhos explícitos; exceções devem ser justificadas. A política orienta o agente; não existe despachante externo que imponha cada decisão.

## Publicação

As três variantes seguem o mesmo contrato do Codex para publicação: delegação do fluxo rotineiro autorizado ao menor worker suficiente, repasse compacto, reaproveitamento de validações, staging explícito, preservação de alterações e confirmação de hashes por remote. Os mapeamentos são Haiku no Claude Code, Flash no Gemini CLI e Composer no Cursor. O modelo efetivo e suas permissões dependem do ambiente; indisponibilidade deve ser declarada, sem simular delegação nem enfraquecer controles. Somente etapas com riscos adicionais são escaladas. Nenhuma variante recebe nova autorização para publicar ou implantar por causa dessa regra.

## Diferenças do pacote Codex

Estas variantes não migram instalações v3/v4, não limpam configurações legadas, não instalam hooks nem copiam skills do Codex. Isso evita transportar mecanismos específicos para ambientes incompatíveis. Não instale várias variantes no mesmo projeto sem conferir regras e agentes duplicados.

A geração não instala os pacotes nos seus aplicativos. Validação de arquivos e instalação temporária não comprova disponibilidade de modelos ou comportamento autenticado no provedor. Confira descoberta dos sete agentes, modelo efetivo e respeito aos pisos de risco em uma sessão de teste antes de usar em trabalho crítico.

O instalador é para uso local sem modificações concorrentes no destino; não é uma transação de múltiplos arquivos. Uma falha de I/O pode deixar apenas parte dos arquivos novos criada. Nenhum arquivo pessoal é sobrescrito; após resolver a falha, repetir a instalação completa os faltantes. Para remover, apague somente os arquivos instalados listados na auditoria, preservando alterações feitas posteriormente.
