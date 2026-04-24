# 7diffs

Comparador de texto rápido e portátil construído com Flutter. Cole dois textos ou abra arquivos e veja as diferenças em tempo real.

## Funcionalidades

- **Diff em tempo real** — o resultado é recalculado a cada tecla digitada
- **Algoritmo LCS** — diff linha a linha baseado na Longest Common Subsequence; fallback automático para arquivos com mais de 8.000 linhas
- **Diff inline** — para linhas similares, destaca exatamente quais caracteres mudaram
- **Abertura de arquivos** — suporta `.dart`, `.py`, `.js`, `.ts`, `.json`, `.yaml`, `.md`, `.sql` e muitos outros formatos de texto
- **Copiar diff unificado** — gera saída no formato `--- / +++` e copia para a área de transferência
- **Trocar painéis** — inverte original e modificado com um clique
- **Layout responsivo** — lado a lado em telas largas (> 720 px); abas separadas em mobile
- **Tema claro/escuro** — alternável pela barra superior

## Plataformas

| Plataforma | Status |
|---|---|
| macOS | Suportado |
| Android | Suportado |
| iOS | Suportado |

## Pré-requisitos

- Flutter ≥ 3.x com Dart SDK `^3.11.4`
- Para macOS: Xcode instalado
- Para Android: Android Studio / SDK

## Como executar

```bash
# Instalar dependências
flutter pub get

# Rodar em desktop (macOS)
flutter run -d macos

# Rodar no emulador/device Android
flutter run -d android

# Rodar em modo release
flutter build macos --release
flutter build apk --release
```

## Estrutura do projeto

```
lib/
├── main.dart                   # Ponto de entrada
├── app.dart                    # MaterialApp + gerenciamento de tema
├── core/
│   └── diff_engine.dart        # Motor de diff (LCS + diff inline de caracteres)
├── screens/
│   └── home_screen.dart        # Tela principal com layouts wide/narrow
├── theme/
│   └── app_theme.dart          # Tokens de cor e ThemeData
└── widgets/
    ├── editor_panel.dart       # Painel de texto com file picker e drag & drop
    ├── diff_view.dart          # Renderização do diff linha a linha
    └── diff_counter_badge.dart # Barra de estatísticas (+N / -N linhas)
```

## Dependências

| Pacote | Uso |
|---|---|
| `file_picker` | Seleção de arquivos nativos em todas as plataformas |
| `flutter` | Framework UI |
