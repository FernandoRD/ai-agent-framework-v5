# Engenharia Frontend Web

## 1. Escolha de Stack

Siga a stack que o projeto já usa. Para projeto novo, decida pelo tipo de interface e registre a decisão:

| Necessidade | Opção adequada |
|---|---|
| Site de conteúdo, documentação, landing page | HTML estático ou Astro; JavaScript só onde há interação |
| Aplicação com SEO e rotas no servidor | Next.js, Nuxt, SvelteKit ou Remix/React Router |
| Painel interno autenticado (SPA) | Vite + React, Vue ou Svelte |
| Página única ou protótipo isolado | HTML + CSS + JavaScript sem build |

- TypeScript em modo `strict` para qualquer código com mais de um arquivo.
- Uma biblioteca de componentes acessível como base (Radix UI, React Aria, Headless UI, Ark UI, shadcn/ui, Vuetify, Angular Material) é preferível a reescrever menus, combobox e diálogos.
- Não misture duas soluções de estilo no mesmo projeto (por exemplo Tailwind e CSS-in-JS) sem decisão registrada.

## 2. HTML e CSS Modernos

```css
/* Reset mínimo e previsível */
*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; font-family: var(--font-sans); color: var(--color-fg); background: var(--color-bg); line-height: 1.5; }
img, svg, video { display: block; max-width: 100%; height: auto; }

/* Layout fluido sem media query */
.cards { display: grid; gap: var(--space-4); grid-template-columns: repeat(auto-fit, minmax(min(100%, 16rem), 1fr)); }

/* Tipografia fluida com limites */
h1 { font-size: clamp(1.75rem, 1.2rem + 2vw, 2.5rem); text-wrap: balance; }

/* Componente que se adapta ao contêiner, não à janela */
.panel { container-type: inline-size; }
@container (min-width: 40rem) { .panel__body { display: grid; grid-template-columns: 1fr 2fr; } }
```

- Unidades relativas (`rem`, `%`, `ch`) para texto e espaçamento; `px` apenas para bordas finas.
- Propriedades lógicas (`margin-inline`, `padding-block`) facilitam idiomas da direita para a esquerda.
- Altura de tela em celular: `min-height: 100dvh` em vez de `100vh`.
- Evite `!important` e seletores com mais de três níveis; use camadas (`@layer reset, base, components, utilities`) para controlar a cascata.

## 3. Componentes e Estado

- Componentes pequenos, com props tipadas e sem efeitos colaterais na renderização.
- Estado no nível mais baixo possível; estado do servidor com uma biblioteca de cache (TanStack Query, SWR, Pinia Colada) em vez de copiar dados para um store global.
- Estado que deve sobreviver a recarregar ou ser compartilhável (filtros, aba, página) vai na URL.
- Formulários: validação com esquema compartilhado (Zod, Valibot) entre cliente e servidor; o servidor sempre revalida.

```tsx
type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "danger";
  loading?: boolean;
};

export function Button({ variant = "primary", loading = false, disabled, children, ...rest }: ButtonProps) {
  return (
    <button
      type="button"
      className={`btn btn--${variant}`}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      {...rest}
    >
      {loading ? <span className="btn__spinner" aria-hidden="true" /> : null}
      {children}
    </button>
  );
}
```

## 4. Performance (Core Web Vitals)

| Métrica | Meta (p75) | Alavancas principais |
|---|---|---|
| LCP | ≤ 2,5 s | Imagem principal com `fetchpriority="high"` e sem `loading="lazy"`; SSR/SSG; fontes com `font-display: swap` e pré-carregamento seletivo |
| INP | ≤ 200 ms | Menos JavaScript, tarefas longas quebradas, listas grandes virtualizadas, trabalho pesado fora da thread principal |
| CLS | ≤ 0,1 | `width`/`height` ou `aspect-ratio` em mídia; espaço reservado para anúncios, banners e conteúdo assíncrono |

- Imagens em AVIF/WebP com `srcset`/`sizes`; `loading="lazy"` abaixo da dobra.
- Divisão de código por rota e importação dinâmica de componentes pesados (editores, gráficos, mapas).
- Orçamento de bundle declarado (por exemplo ≤ 170 KB de JavaScript comprimido na rota inicial) e verificado no CI.
- Meça em campo (CrUX, `web-vitals`) e em laboratório (Lighthouse, aba Performance do DevTools com CPU e rede limitadas).

## 5. Segurança no Cliente

- Nunca use `innerHTML`/`dangerouslySetInnerHTML`/`v-html` com conteúdo não sanitizado; se for inevitável, sanitize com DOMPurify.
- Variáveis de ambiente expostas ao cliente (`VITE_*`, `NEXT_PUBLIC_*`) são públicas: nunca coloque segredos nelas.
- Defina `Content-Security-Policy`, cookies de sessão `HttpOnly; Secure; SameSite` e links externos com `rel="noopener noreferrer"` quando usarem `target="_blank"`.

## 6. Internacionalização

- Textos fora do código (arquivos de mensagens), interpolação com plural (`Intl.PluralRules` ou a biblioteca de i18n do framework).
- Layout tolera textos 30–40% mais longos (alemão, português) sem cortar.
- `lang` correto no `<html>` e em trechos em outro idioma.

## 7. Testes e Qualidade

| Camada | Ferramenta típica | O que cobre |
|---|---|---|
| Estática | ESLint, Stylelint, Prettier, `tsc --noEmit` | Erros de tipo, padrões proibidos, formatação |
| Unidade/componente | Vitest/Jest + Testing Library | Comportamento observável, consultas por papel e rótulo |
| Visual | Storybook + Chromatic, Playwright `toHaveScreenshot()` | Regressão visual por estado, tema e largura |
| Ponta a ponta | Playwright ou Cypress | Fluxos críticos em navegadores reais |
| Acessibilidade | axe em testes de componente e e2e | Violações automáticas detectáveis |

Teste comportamento, não implementação: consulte por `getByRole`/`getByLabelText`, não por classe CSS.

```bash
npx tsc --noEmit && npx eslint . && npx vitest run
npx playwright test   # projetos (chromium, webkit, celular) conforme playwright.config
```

Declare quais desses comandos foram de fato executados e o resultado observado.
