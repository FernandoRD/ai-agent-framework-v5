# Cursor Framework v5

Adaptação por projeto da política v5: classificação, score, pisos de risco, sete papéis, contexto compacto e validação proporcional. O pacote não altera a instalação Codex nem o modelo principal.

## Modelos

| Papel | Modelo configurado |
| --- | --- |
| Luna explorer / worker | `composer-2.5[fast=false]` |
| Terra worker / reviewer | `claude-sonnet-5` |
| Sol specialist / reviewer / critical | `claude-opus-5[effort=high]` |

Principal sugerido: Sonnet 5 selecionado no Cursor. Esta escolha e o mapeamento são recomendações da adaptação, não equivalências comprovadas entre fornecedores. Composer padrão reduz uma fonte de variação; não representa promessa de menor custo em toda tarefa. Effort foi configurado somente onde o formato está explicitamente documentado; não copiamos os níveis do Codex automaticamente.

## Instalar

Extraia o pacote e execute dentro dele usando o instalador de sua preferência (Bash, Fish, PowerShell ou Python 3.10+):

No Linux/macOS (Bash ou Fish):

```sh
./scripts/install.sh --target /caminho/do/projeto
./scripts/install.sh --target /caminho/do/projeto --apply
# ou no Fish:
./scripts/install.fish /caminho/do/projeto --apply
```

No Windows (PowerShell):

```powershell
.\scripts\install.ps1 -Target "C:\caminho\do\projeto"
.\scripts\install.ps1 -Target "C:\caminho\do\projeto" -Apply
```

Ou diretamente via Python:

```sh
python scripts/install.py --target /caminho/do/projeto --apply
```

O primeiro comando apenas audita. O instalador recusa arquivos existentes diferentes e links simbólicos, sem sobrescrever configurações. Arquivos idênticos são preservados. Para atualizar uma instalação conflitante, compare e mescle manualmente antes de repetir.

A regra `.cursor/rules/framework-v5.mdc` usa `alwaysApply: true`. Os sete agentes ficam em `.cursor/agents`. Abra uma nova conversa no projeto e confira a regra e os agentes. Não instale as variantes Claude e Cursor juntas sem conferir duplicidades: Cursor também descobre agentes de `.claude/agents`.

## Publicação autorizada

Publicação rotineira é uma unidade separada da implementação. Quando a
ferramenta nativa Task estiver disponível e houver mudanças validadas, branch e
remotes conhecidos com autorização explícita, o principal delega ao
`luna-worker` (Composer) o fluxo completo: status e diff no escopo, staging de
caminhos explícitos, commit pedido, push aos remotes autorizados e conferência
do hash de cada remote. O repasse contém evidência compacta (repositório,
branch, arquivos permitidos, destinos, autorização, verificações e limites),
reutilizada até surgir mudança, falha ou dúvida nova.

Se a Task não estiver disponível ou a delegação for proibida, o principal
registra o bloqueio concreto e usa somente o fallback autorizado necessário,
sem alegar execução pelo Composer. Conflito, escopo incerto, compatibilidade,
release, deploy ou outro risco material elevam apenas a unidade afetada para
Terra ou Sol. Credencial, rede ou aprovação ausente exigem o fluxo normal de
acesso. A política não concede autoridade para novos destinos, mudança de
privacidade, release, deploy, force push ou reescrita de histórico.

## Verificação e limites

Peça uma correção trivial: deve ser direta. Depois peça explicitamente ao `luna-explorer` que localize um símbolo, sem editar; confira modelo efetivo e retorno. Um reviewer deve permanecer somente leitura. Para testar piso de risco, peça apenas um plano de mudança de autorização: deve encaminhar a análise crítica ao Sol antes de mutação.

A plataforma pode substituir modelos por restrições de plano/admin; confira o modelo efetivo. O roteamento é instrução ao principal, não um despachante determinístico. Não há garantia de economia ou de disponibilidade de modelos. O pacote não inclui hooks, migração automática de v3/v4, skills nem instalação global: esses recursos do instalador Codex são específicos daquela plataforma. Não houve execução autenticada no Cursor durante a geração.

## Fontes oficiais consultadas em 2026-09-12

- https://cursor.com/docs/subagents
- https://cursor.com/docs/rules
- https://cursor.com/docs/models-and-pricing
