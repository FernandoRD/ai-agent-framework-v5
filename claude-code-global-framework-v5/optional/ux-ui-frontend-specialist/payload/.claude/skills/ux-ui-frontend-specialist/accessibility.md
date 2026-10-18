# Acessibilidade e Usabilidade (WCAG 2.2 AA)

## 1. Ordem de Preferência

1. Elemento HTML nativo (`<button>`, `<a href>`, `<input>`, `<select>`, `<dialog>`, `<details>`).
2. Elemento nativo estilizado.
3. Componente customizado com ARIA seguindo o padrão do WAI-ARIA Authoring Practices Guide (APG).

"Nenhum ARIA é melhor que ARIA errado": `role` sem o comportamento de teclado correspondente piora a experiência.

## 2. Checklist Essencial

| Área | Requisito | Critério WCAG |
|---|---|---|
| Texto alternativo | `alt` descritivo; `alt=""` em imagem decorativa | 1.1.1 |
| Estrutura | Um `<h1>`, níveis de título sem saltos, landmarks (`header`, `nav`, `main`, `footer`) | 1.3.1 |
| Contraste | Texto 4.5:1 (grande 3:1); bordas de campo, ícones e foco 3:1 | 1.4.3, 1.4.11 |
| Reflow | Sem rolagem horizontal a 320 px CSS de largura (zoom 400%) | 1.4.10 |
| Espaçamento de texto | Layout resiste a altura de linha 1.5 e espaçamento entre letras 0.12em | 1.4.12 |
| Teclado | Tudo operável por teclado, sem armadilha de foco | 2.1.1, 2.1.2 |
| Ordem de foco | Segue a ordem visual e lógica; sem `tabindex` positivo | 2.4.3 |
| Foco visível | Indicador claro e não encoberto por cabeçalhos fixos | 2.4.7, 2.4.11 |
| Alvo de toque | Pelo menos 24×24 px CSS ou espaçamento equivalente | 2.5.8 |
| Arrastar | Alternativa sem arrastar (botões, campos) | 2.5.7 |
| Rótulos | Todo campo com `<label>` associado; instruções visíveis | 3.3.2 |
| Erros | Identificados em texto, com sugestão de correção | 3.3.1, 3.3.3 |
| Autenticação | Sem teste cognitivo obrigatório; permitir colar senha e gerenciador | 3.3.8 |
| Nome, função, valor | Controles customizados expõem nome, papel e estado | 4.1.2 |
| Mensagens de status | Avisos dinâmicos em região `aria-live`/`role="status"` | 4.1.3 |

## 3. Padrões de Código

```html
<!-- Link para pular navegação -->
<a class="skip-link" href="#conteudo">Pular para o conteúdo</a>

<!-- Botão só com ícone: nome acessível obrigatório -->
<button type="button" aria-label="Fechar painel">
  <svg aria-hidden="true" focusable="false">…</svg>
</button>

<!-- Campo com erro -->
<label for="email">E-mail</label>
<input id="email" type="email" autocomplete="email"
       aria-invalid="true" aria-describedby="email-erro">
<p id="email-erro">Informe um e-mail no formato nome@dominio.com.</p>

<!-- Status assíncrono -->
<div role="status" aria-live="polite" id="feedback"></div>
```

```css
/* Foco visível sem afetar clique de mouse */
:focus-visible { outline: 3px solid var(--color-accent); outline-offset: 2px; }

/* Rolagem com cabeçalho fixo não esconde o foco */
html { scroll-padding-top: 4rem; }

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; scroll-behavior: auto !important; }
}
```

- Diálogos: prefira `<dialog>` com `showModal()` (foco preso e `Esc` nativos); devolva o foco ao elemento que abriu.
- Rotas de SPA: ao trocar de página, atualize `document.title` e mova o foco para o título principal ou anuncie a navegação.
- Tabelas de dados: `<th scope>` e `<caption>`; não use `<div>` em grade para dados tabulares.
- Gráficos: forneça resumo em texto ou tabela equivalente; não dependa apenas de cor para séries.

## 4. Verificação

Automática (detecta parte dos problemas, não substitui teste manual):

```bash
npx @axe-core/cli http://localhost:5173 --exit
npx lighthouse http://localhost:5173 --only-categories=accessibility --view
```

- Em testes: `@axe-core/playwright` ou `jest-axe`/`vitest-axe` nos componentes.
- Lint: `eslint-plugin-jsx-a11y` (React), `eslint-plugin-vuejs-accessibility` (Vue); o Svelte já emite avisos de acessibilidade no compilador.

Manual (declare o que foi feito e o que não foi):

1. Navegar a tela inteira só com `Tab`, `Shift+Tab`, `Enter`, `Espaço`, setas e `Esc`.
2. Zoom de 200% e 400% no navegador; largura de 320 px.
3. Leitor de tela: NVDA ou JAWS (Windows), VoiceOver (macOS/iOS) e TalkBack (Android).
4. Modo de alto contraste do Windows (`forced-colors: active`) e tema escuro.

## 5. Usabilidade de Conteúdo

- Microtexto direto, voz ativa, verbo no botão ("Salvar alterações", não "OK").
- Confirmação só para ações destrutivas ou irreversíveis, nomeando o objeto ("Excluir 3 hosts?"); prefira desfazer a confirmar quando possível.
- Datas, números e moedas formatados com `Intl` no locale do usuário.
