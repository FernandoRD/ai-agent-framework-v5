# Troubleshooting de UX/UI e Frontend

## 1. Layout Quebrado ou Rolagem Horizontal no Celular

```js
// No console do DevTools: lista elementos mais largos que a janela
[...document.querySelectorAll('*')].filter(e => e.scrollWidth > document.documentElement.clientWidth).map(e => e.outerHTML.slice(0, 120));
```

- Causas comuns: largura fixa em `px`, `100vw` (inclui a barra de rolagem), imagem ou tabela sem `max-width: 100%`, palavra/URL longa sem `overflow-wrap: anywhere`, `min-width` implícito de itens flex (use `min-width: 0`).
- `meta viewport` ausente: `<meta name="viewport" content="width=device-width, initial-scale=1">`; não use `user-scalable=no`, que bloqueia zoom.

## 2. Conteúdo "Pulando" ao Carregar (CLS Alto)

- Mídia sem `width`/`height` ou `aspect-ratio`.
- Fonte web trocando métricas: use `font-display: swap` com `size-adjust`/fallback de métricas próximas, ou fonte do sistema.
- Banner, cookie bar ou resultado assíncrono inserido acima do conteúdo: reserve o espaço ou insira abaixo.
- Diagnóstico: aba Performance do DevTools (Layout Shifts) ou `web-vitals` com atribuição (`onCLS(console.log, { reportAllChanges: true })`).

## 3. Interface Lenta ao Clicar ou Digitar (INP Alto)

- Grave a interação na aba Performance com CPU limitada (4×–6×) e procure tarefas longas (> 50 ms).
- React: re-renderizações em cascata (React DevTools Profiler), estado global alterado a cada tecla, listas sem virtualização, cálculos sem memoização.
- Use `startTransition`/`useDeferredValue` para atualizações não urgentes, debounce em busca e mova processamento pesado para Web Worker.

## 4. Estilo Não Aplica ou Aplica Errado

- Inspecione o elemento: regra riscada indica especificidade ou ordem; confira `@layer`, CSS Modules com nome de classe gerado e purge do Tailwind removendo classe montada dinamicamente (use nomes completos de classe, não concatenação).
- Variável CSS sem valor: o fallback `var(--x, valor)` só vale quando a variável não está definida, não quando o valor é inválido.
- `z-index` sem efeito: o elemento precisa criar contexto de empilhamento (`position` não estático, `isolation: isolate`); `transform`/`filter` de um ancestral cria um novo contexto e prende o filho.

## 5. Tema Escuro com Problemas

- Flash de tema claro ao carregar: aplique `data-theme` com script inline no `<head>` antes do CSS ou use `color-scheme: light dark`.
- Imagens e ícones com fundo branco embutido: prefira SVG com `currentColor`.
- Reavalie contraste de todos os estados (hover, desabilitado, foco) no tema escuro.

## 6. Problemas de Acessibilidade Recorrentes

| Sintoma | Causa provável | Correção |
|---|---|---|
| Leitor de tela diz "botão" sem nome | Botão só com ícone | `aria-label` ou texto visualmente oculto |
| Foco some após fechar modal | Foco não devolvido | Guardar e restaurar o elemento que abriu |
| `div` clicável inacessível por teclado | Falta elemento nativo | Trocar por `<button>` ou `<a href>` |
| Mensagem de erro não é lida | Inserida sem região viva | `role="alert"` ou `aria-describedby` no campo |
| Leitor anuncia conteúdo oculto | `display` visual sem `hidden`/`inert` | `hidden`, `inert` ou `aria-hidden` no conteúdo fora de tela |

## 7. Hidratação e Renderização no Servidor

- Erro de hidratação (Next.js, Nuxt, SvelteKit): HTML do servidor difere do cliente. Causas: `Date.now()`, `Math.random()`, `window`/`localStorage` na renderização, locale/fuso diferentes, HTML inválido (`<div>` dentro de `<p>`).
- Mova código dependente do navegador para efeito pós-montagem ou componente apenas cliente e formate datas com fuso explícito.

## 8. Aplicativos Móveis

- **Teclado cobrindo campo**: `KeyboardAvoidingView` com `behavior` diferente por plataforma (RN), `imePadding()` (Compose), `resizeToAvoidBottomInset` (Flutter).
- **Conteúdo sob o notch ou a barra de gestos**: áreas seguras ausentes ou aplicadas duas vezes.
- **Texto cortado com fonte grande do sistema**: alturas fixas em contêineres de texto; use altura mínima e permita quebra.
- **Lista travando**: componente de lista não virtualizado, imagens em resolução original, `keyExtractor`/chaves instáveis.
- **Funciona no emulador e falha no aparelho**: permissões, rede (HTTP sem TLS bloqueado por ATS/Network Security Config), arquitetura do binário ou build de release com minificação removendo código usado por reflexão.

## 9. Coleta de Evidência

Antes de propor correção, registre: navegador ou dispositivo e versão, sistema operacional, largura da janela, tema, zoom ou escala de fonte, passos para reproduzir, captura de tela ou gravação e erros do console. Correção sem reprodução é hipótese e deve ser apresentada como tal.
