# Interfaces de Aplicativos Móveis

## 1. Plataforma Primeiro

Aplicativo bom parece nativo da plataforma em que roda. Antes de desenhar, decida:

| Decisão | Opções |
|---|---|
| Tecnologia | Nativo (SwiftUI/UIKit, Jetpack Compose), multiplataforma (React Native/Expo, Flutter, Kotlin Multiplatform com Compose Multiplatform) ou web (PWA) |
| Linguagem visual | Apple Human Interface Guidelines no iOS, Material Design 3 no Android; marca aplicada sobre os padrões, não no lugar deles |
| Navegação | Barra de abas (3–5 destinos), pilha com voltar, gaveta apenas para destinos secundários |
| Offline | O que funciona sem rede, como sincroniza e como o conflito é mostrado |

Siga a stack existente do projeto; não troque de tecnologia sem decisão aprovada.

## 2. Diferenças de Convenção iOS × Android

| Elemento | iOS (HIG) | Android (Material 3) |
|---|---|---|
| Alvo mínimo de toque | 44×44 pt | 48×48 dp |
| Voltar | Botão no canto superior esquerdo e gesto de borda | Gesto/botão do sistema; predictive back no Android 14+ |
| Navegação principal | Tab bar inferior | Navigation bar inferior (ou rail em telas grandes) |
| Ação principal | Botão na barra de navegação ou no conteúdo | FAB ou botão em destaque |
| Tipografia | San Francisco, Dynamic Type | Roboto/fonte da marca, escala de tipo do Material |
| Alertas | Alert e action sheet | Dialog e bottom sheet |
| Cores dinâmicas | Cores semânticas do sistema | Dynamic color (Material You) opcional |

## 3. Layout e Ergonomia

- Respeite áreas seguras (notch, Dynamic Island, barra de gestos): `SafeAreaView`/`react-native-safe-area-context`, `SafeArea` no Flutter, `WindowInsets` no Compose e `env(safe-area-inset-*)` em PWA.
- Ações frequentes na metade inferior da tela (zona do polegar); ações destrutivas longe das frequentes.
- Teclado não pode cobrir o campo em foco nem o botão de envio (`KeyboardAvoidingView`, `imePadding()`, `resizeToAvoidBottomInset`).
- Tipos de teclado e preenchimento automático corretos (`keyboardType`/`inputMode`, `textContentType`/`autofillHints`, `autocomplete` na web).
- Suporte a tablet, orientação horizontal e telas dobráveis quando o público usar: layouts adaptativos por classe de largura (compact, medium, expanded).

## 4. Acessibilidade em Aplicativos

| Recurso | iOS | Android | React Native | Flutter |
|---|---|---|---|---|
| Leitor de tela | VoiceOver | TalkBack | `accessibilityLabel`, `accessibilityRole` | `Semantics(label:)` |
| Fonte do sistema | Dynamic Type | Escala de fonte | `allowFontScaling` (manter ativo) | `MediaQuery.textScaler` |
| Movimento reduzido | Reduce Motion | Remover animações | `AccessibilityInfo.isReduceMotionEnabled()` | `MediaQuery.disableAnimations` |

- Todo ícone tocável tem rótulo acessível; imagens decorativas ficam ocultas para o leitor de tela.
- Teste com a maior escala de fonte do sistema: texto quebra ou rola, nunca corta.

## 5. Desempenho e Percepção

- 60 fps (ou 120 em telas ProMotion/alta taxa): nada pesado na thread de UI; listas longas virtualizadas (`FlatList`/`FlashList`, `ListView.builder`, `LazyColumn`).
- Tempo até a primeira tela útil curto: splash mínima, dados em cache exibidos antes da rede.
- Imagens no tamanho de exibição, com cache e placeholder.
- Feedback tátil (haptics) com moderação e apenas para confirmações significativas.

## 6. Exemplos

```tsx
// React Native: botão de ícone com alvo mínimo e rótulo acessível
<Pressable
  onPress={onRefresh}
  accessibilityRole="button"
  accessibilityLabel="Atualizar alertas"
  hitSlop={8}
  style={({ pressed }) => [{ minWidth: 48, minHeight: 48, alignItems: "center", justifyContent: "center", opacity: pressed ? 0.6 : 1 }]}
>
  <RefreshIcon />{/* o rótulo do Pressable já nomeia a ação */}
</Pressable>
```

```dart
// Flutter: tema a partir de uma cor semente, claro e escuro
MaterialApp(
  theme: ThemeData(colorSchemeSeed: const Color(0xFF2563EB), useMaterial3: true),
  darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF2563EB), brightness: Brightness.dark, useMaterial3: true),
  themeMode: ThemeMode.system,
  home: const AlertsPage(),
);
```

## 7. Notificações e Permissões

- Peça permissão no momento em que o benefício é evidente, com uma tela de contexto antes do diálogo do sistema; nunca na primeira abertura sem explicação.
- Notificação acionável leva direto à tela relevante (deep link) e respeita categorias/canais que o usuário pode silenciar.

## 8. Testes e Publicação

- Componentes: Jest + React Native Testing Library; `flutter test` com widget tests; testes de UI do Compose.
- Ponta a ponta em dispositivo ou emulador: Maestro, Detox, XCUITest, Espresso ou `integration_test` do Flutter.
- Teste em pelo menos um aparelho de entrada (pouca memória, tela pequena) além do aparelho de desenvolvimento.
- Publicação em App Store ou Google Play, mudança de identificador do app, assinatura ou permissões declaradas exigem aprovação explícita; revise as diretrizes de revisão da loja antes de enviar.
