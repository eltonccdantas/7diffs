<h1 align="center">7diffs</h1>
<p align="center"><strong>Compare textos e arquivos — rápido, offline e direto ao ponto</strong></p>
<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue" alt="version" />
  <img src="https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS-informational" alt="platforms" />
  <img src="https://img.shields.io/badge/100%25%20offline-no%20cloud-success" alt="offline" />
</p>

---

## O que é o 7diffs?

7diffs é um comparador de texto que roda inteiramente no seu dispositivo — **sem internet, sem servidor, sem envio de arquivos**.

Cole dois textos nos painéis ou abra arquivos diretamente, e o diff aparece em tempo real usando um algoritmo LCS (Longest Common Subsequence) com destaque inline de caracteres alterados.

---

## Funcionalidades

- **Diff em tempo real** — resultado atualizado a cada tecla, calculado em thread separada
- **Algoritmo LCS** — diff linha a linha preciso; fallback automático para arquivos com mais de 8.000 linhas
- **Diff inline** — para linhas similares, destaca exatamente quais caracteres foram adicionados ou removidos
- **Abertura de arquivos** — suporta `.dart`, `.py`, `.js`, `.ts`, `.json`, `.yaml`, `.md`, `.sql` e mais de 30 formatos de texto
- **Copiar diff unificado** — exporta no formato `--- / +++` para a área de transferência
- **Trocar painéis** — inverte original e modificado com um clique
- **Layout responsivo** — painéis lado a lado em telas largas; navegação por abas em mobile
- **Tema claro/escuro** — alternável pela barra superior

---

## Como usar

1. **Cole o texto** — use os painéis _Original_ e _Modificado_, ou abra arquivos pelo ícone de pasta
2. **Veja o diff** — as diferenças aparecem automaticamente no painel inferior
3. **Analise** — linhas verdes (`+`) foram adicionadas, vermelhas (`-`) foram removidas; caracteres alterados ficam destacados dentro da linha
4. **Exporte** — clique em copiar no cabeçalho do diff para obter a saída unificada

Sem cadastro, sem configuração, sem internet.

---

## Plataformas

| Plataforma | Status |
|---|---|
| macOS | ✅ Suportado |
| Android | ✅ Suportado |
| iOS | ✅ Suportado |

---

## Download

Acesse a [página de releases](https://github.com/eltonccdantas/7diffs/releases) para baixar a versão mais recente.

---

## Stack

| Componente | Tecnologia |
|---|---|
| UI framework | Flutter (Material 3) |
| Algoritmo de diff | LCS puro em Dart |
| Diff inline | LCS de caracteres (nível de rune) |
| Seleção de arquivos | `file_picker` |
| Execução assíncrona | Flutter `compute` (Isolate) |

---

## Privacidade

- **100% offline** — o app nunca acessa a internet
- **Sem conta** — nenhum dado pessoal coletado
- **Processamento local** — seus textos e arquivos nunca saem do dispositivo
- **Código aberto** — o código-fonte completo está disponível para inspeção

---

## Como rodar localmente

```bash
# Instalar dependências
flutter pub get

# macOS
flutter run -d macos

# Android
flutter run -d android

# Build de release
flutter build macos --release
flutter build apk --release
```

**Pré-requisitos:** Flutter ≥ 3.x com Dart SDK `^3.11.4`

---

## Apoie o projeto

Se o 7diffs te economizou tempo, considere apoiar o desenvolvimento:

- ⭐ Deixe uma estrela no repositório
- 🐛 Abra uma [issue](https://github.com/eltonccdantas/7diffs/issues) se encontrar um bug ou tiver uma sugestão
- **PIX (Brasil):** `3a2b8066-7987-4e10-b0da-8ccc4c9da565`
- **PayPal:** [paypal.me/eltondantas](https://www.paypal.com/qrcodes/p2pqrc/XQ3ZNNY4G6KAY)

---

<p align="center">
  eltondantas.com &nbsp;=)
</p>
