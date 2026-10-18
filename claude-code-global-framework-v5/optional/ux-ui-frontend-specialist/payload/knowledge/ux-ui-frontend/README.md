# Base de Conhecimento Local: UX/UI e Frontend

Este diretório armazena decisões de interface, convenções de design system e padrões de frontend adotados no projeto, para que o especialista reutilize o que já existe em vez de criar estilos paralelos.

---

## 1. Ficha da Interface (preencha)

| Item | Valor no projeto |
|---|---|
| Plataformas | Web / iOS / Android / PWA |
| Stack e versões | Ex.: React 19 + Vite 6 + TypeScript 5, Flutter 3.x |
| Biblioteca de componentes | Ex.: Radix UI + CSS Modules, Material 3 |
| Fonte dos tokens | Ex.: `src/styles/tokens.css`, `tokens.json` |
| Storybook / catálogo | URL interna ou caminho |
| Navegadores e dispositivos suportados | Ex.: duas últimas versões estáveis; iOS 17+, Android 10+ |
| Meta de acessibilidade | WCAG 2.2 AA |
| Idiomas | pt-BR, en |

---

## 2. Convenção Recomendada de Nomes de Tokens

| Categoria | Padrão | Exemplo |
|---|---|---|
| Cor semântica | `--color-<papel>[-<estado>]` | `--color-accent`, `--color-danger-hover` |
| Superfície | `--color-surface-<nível>` | `--color-surface-1` |
| Espaçamento | `--space-<passo>` | `--space-4` (1rem) |
| Tipografia | `--text-<tamanho>`, `--font-<família>` | `--text-lg`, `--font-mono` |
| Raio e sombra | `--radius-<tamanho>`, `--shadow-<nível>` | `--radius-md`, `--shadow-2` |
| Movimento | `--duration-<velocidade>`, `--ease-<curva>` | `--duration-fast`, `--ease-out` |

Componentes usam apenas tokens semânticos; primitivos (`--blue-600`) ficam restritos ao arquivo de tokens.

---

## 3. Cores de Status para Monitoramento

Se a interface exibe estado de serviços ou alertas, mantenha mapeamento único e sempre acompanhado de ícone ou texto:

| Estado | Token | Uso |
|---|---|---|
| OK | `--color-status-ok` | Serviço saudável |
| Aviso | `--color-status-warning` | Degradação, limiar de atenção |
| Crítico | `--color-status-critical` | Indisponível, ação imediata |
| Desconhecido | `--color-status-unknown` | Sem dados, coleta falhou |
| Manutenção | `--color-status-maintenance` | Janela planejada |

Alinhe com as severidades do Zabbix ou do Alertmanager usadas no projeto e registre aqui a correspondência.

---

## 4. Definição de Pronto para Telas

- Estados vazio, carregando, erro e sem permissão implementados.
- Funciona a 320 px de largura e em desktop; temas claro e escuro conferidos.
- Navegação completa por teclado e sem violações no axe.
- Textos em arquivo de mensagens; nenhum valor de cor ou espaçamento solto no componente.

Registre aqui exceções aprovadas a estes padrões, com data e responsável.
