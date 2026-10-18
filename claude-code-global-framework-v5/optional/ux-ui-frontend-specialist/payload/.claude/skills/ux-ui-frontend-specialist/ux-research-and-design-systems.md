# Pesquisa, Fluxos e Design System

## 1. Enquadramento Antes do Layout

Responda por escrito antes de desenhar ou codificar:

| Pergunta | Exemplo de resposta |
|---|---|
| Quem usa e em que contexto? | Operador de NOC, monitor grande, turno de 12 h, pouca interação com mouse |
| Qual tarefa principal? | Identificar em menos de 5 s qual serviço está degradado |
| Qual o critério de sucesso? | Tempo até a ação, taxa de conclusão, erros por tarefa |
| Quais dispositivos e larguras? | Desktop 1920 px e celular 360–430 px para plantão |
| Quais restrições? | Design system existente, WCAG 2.2 AA, i18n pt-BR/en |

Quando não houver pesquisa com usuários, registre as premissas e proponha validação barata (teste de usabilidade com 5 pessoas, teste de clique, análise de eventos) em vez de apresentar a suposição como fato.

## 2. Fluxos e Arquitetura de Informação

- Mapeie o fluxo como sequência de telas e decisões, incluindo caminhos de erro e de volta.
- Navegação: no máximo 5–7 itens de primeiro nível; rótulos com a palavra que o usuário usa, não o nome interno do sistema.
- Use **divulgação progressiva**: o essencial visível, o avançado sob demanda.
- Formulários: um campo por linha, rótulo sempre visível (placeholder não substitui rótulo), validação no envio e ao sair do campo, mensagem de erro ao lado do campo e resumo no topo em formulários longos.

### Estados obrigatórios de cada tela ou componente de dados

| Estado | O que mostrar |
|---|---|
| Carregando | Skeleton com o formato do conteúdo; spinner só para ações curtas |
| Vazio | Explicação e próxima ação ("Nenhum host cadastrado. Adicionar host") |
| Erro | O que falhou, por quê (se conhecido) e como tentar de novo |
| Parcial | Dados disponíveis e aviso do que faltou |
| Sem permissão | O que o usuário pode fazer e a quem pedir acesso |
| Sucesso | Confirmação discreta (toast) ou mudança de estado visível |

## 3. Design Tokens

Organize em três camadas: **primitivos** (paleta bruta), **semânticos** (papel na interface) e **de componente** (opcional).

```css
:root {
  /* Primitivos */
  --blue-600: #2563eb;
  --gray-50: #f9fafb;
  --gray-900: #111827;

  /* Semânticos: o código de componente usa somente estes */
  --color-bg: var(--gray-50);
  --color-fg: var(--gray-900);
  --color-accent: var(--blue-600);
  --color-danger: #b91c1c;

  --space-1: 0.25rem; --space-2: 0.5rem; --space-3: 0.75rem;
  --space-4: 1rem;    --space-6: 1.5rem; --space-8: 2rem;

  --radius-sm: 4px; --radius-md: 8px;
  --font-sans: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --text-sm: 0.875rem; --text-base: 1rem; --text-lg: 1.25rem; --text-xl: 1.5rem;
  --duration-fast: 120ms; --ease-out: cubic-bezier(0.2, 0, 0, 1);
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --color-bg: #0b0f17;
    --color-fg: #e5e7eb;
    --color-accent: #60a5fa;
  }
}
:root[data-theme="dark"] { --color-bg: #0b0f17; --color-fg: #e5e7eb; --color-accent: #60a5fa; }
```

- Tema escuro não é inversão de cores: reduza saturação, use superfícies em camadas e verifique contraste novamente.
- Cor nunca é o único portador de significado (status também tem ícone, texto ou forma).
- Para tokens compartilhados entre web e aplicativos, mantenha uma fonte única (JSON no formato do W3C Design Tokens Community Group) e gere CSS, Swift, Kotlin ou Dart com uma ferramenta como Style Dictionary.

## 4. Tipografia, Espaçamento e Layout

- Escala tipográfica modular (por exemplo razão 1.2–1.25), corpo de texto com no mínimo 16 px na web, altura de linha 1.4–1.6 e linhas de 45–75 caracteres.
- Números em tabelas e métricas com `font-variant-numeric: tabular-nums` para não "pular" ao atualizar.
- Espaçamento em grade de 4/8 px; mais espaço entre grupos do que dentro deles (proximidade comunica relação).
- No máximo duas famílias tipográficas; pesos limitados (400, 500/600, 700).

## 5. Componentes

Todo componente documentado declara:

- **Anatomia** e variantes (primária, secundária, destrutiva; tamanhos).
- **Estados**: padrão, hover, foco, ativo, desabilitado, carregando, erro.
- **Acessibilidade**: elemento nativo usado, nome acessível, comportamento de teclado.
- **Conteúdo**: limite de texto, truncamento e quebra de linha.

Registre componentes no Storybook (ou equivalente) com uma história por estado; isso serve de documentação viva e de base para testes visuais.

## 6. Microinteração e Movimento

- Durações de 100–300 ms; entradas com `ease-out`, saídas mais curtas.
- Animação comunica mudança de estado ou relação espacial; não é decoração.
- Com `prefers-reduced-motion: reduce`, substitua deslocamentos por fade ou remova a animação.

## 7. Revisão Heurística Rápida

Use as 10 heurísticas de Nielsen como checklist de revisão: visibilidade do estado, linguagem do usuário, controle e saída, consistência, prevenção de erros, reconhecimento em vez de memorização, eficiência para experientes, design minimalista, recuperação de erros e ajuda. Registre cada problema com tela, heurística, severidade (0–4) e recomendação.
