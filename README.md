# 🛡️ Phize — Aplicativo de Segurança Preventiva e Educação Digital

> Projeto desenvolvido como requisito de avaliação prático no Centro Universitário CESUSC — 2026.  
> Orientador: Prof. Sérgio

---

## 📌 Sobre o Projeto

O **Phize** é um aplicativo móvel multiplataforma (Android e iOS) focado na proteção de usuários contra fraudes digitais e ataques de engenharia social. Em 2024, mais de 51% dos brasileiros foram vítimas de golpes digitais — o Phize nasce para preencher a lacuna entre a sofisticação dos crimes cibernéticos e a vulnerabilidade comportamental do cidadão.

Diferente de antivírus tradicionais, o Phize atua na camada humana: usa Inteligência Artificial para analisar links suspeitos e prints de conversas, identificar táticas de manipulação psicológica e educar o usuário no momento do ataque.

---

## 👥 Equipe

| Nome | GitHub |
|------|--------|
| Gabriel Mascia | [@gabriel](https://github.com/) |
| Hevelyn Leivas | [@hevelyn](https://github.com/) |
| Maisa Grundler | [@maisa](https://github.com/) |

---

## 🚀 Funcionalidades

- 🔐 **Cadastro e Login** — autenticação segura via Firebase (e-mail/senha, Google, Apple)
- 🔗 **Analisador de Links** — detecta typosquatting, blacklists e domínios suspeitos
- 🖼️ **Análise de Prints** — OCR via Google Cloud Vision + LLM para detectar engenharia social
- 🌡️ **Score de Risco** — termômetro visual com porcentagem de periculosidade
- 🤝 **Comunidade de Reporte** — banco colaborativo de golpes com hashes criptográficas
- 📋 **Histórico de Alertas** — registro das análises realizadas (sem armazenar imagens)

---

## 🛠️ Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter / Dart |
| Backend | Firebase (BaaS) |
| Banco de dados | Cloud Firestore (NoSQL) |
| Autenticação | Firebase Authentication |
| Visão Computacional | Google Cloud Vision API (OCR) |
| Inteligência Artificial | OpenAI GPT-4o / Google Gemini + RAG |
| Design | Figma |
| Segurança | Hash SHA-256, Zero-Persistence, LGPD |

---

## 🌿 Estrutura de Branches

```
main
└── develop
    ├── feature/cadastro-login
    ├── feature/firebase-setup
    ├── feature/figma-prototype
    ├── feature/url-checker
    ├── feature/score-risco
    ├── feature/analise-print
    └── feature/comunidade-reporte
```

### Regras de uso

| Branch | Descrição | Quem usa |
|--------|-----------|----------|
| `main` | Versão estável e entregável. Merge somente via Pull Request aprovado. | Todos (via PR) |
| `develop` | Integração contínua. Todas as features fazem merge aqui antes de ir para main. | Todos |
| `feature/*` | Uma branch por história de usuário. Criada a partir de develop, merge de volta em develop. | Responsável pela HU |

### Fluxo de trabalho

```
1. Criar branch a partir de develop:
   git checkout develop
   git pull origin develop
   git checkout -b feature/nome-da-feature

2. Desenvolver e commitar:
   git add .
   git commit -m "feat: descrição clara do que foi feito"

3. Subir a branch:
   git push origin feature/nome-da-feature

4. Abrir Pull Request para develop no GitHub

5. Code review por pelo menos 1 membro

6. Merge aprovado → deletar a feature branch
```

---

## 📝 Padrão de Commits

Seguimos o padrão **Conventional Commits**:

```
feat:     nova funcionalidade
fix:      correção de bug
docs:     documentação
style:    formatação (sem mudança de lógica)
refactor: refatoração de código
test:     adição ou correção de testes
chore:    tarefas de configuração/build
```

**Exemplos:**
```
feat: adiciona tela de cadastro com validação de senha
feat: integra Firebase Authentication ao Flutter
fix: corrige bloqueio após 5 tentativas de login
docs: adiciona estrutura de coleções Firestore
test: testa fluxo de login em Android e iOS
chore: configura Firebase no projeto Flutter
```

---

## 🗂️ Estrutura do Projeto

```
phize/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── routes/
│   │   └── theme/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── url_checker/
│   │   ├── print_analysis/
│   │   ├── community/
│   │   ├── history/
│   │   └── score/
│   └── shared/
│       ├── widgets/
│       └── services/
├── test/
├── android/
├── ios/
├── docs/
│   ├── uml/
│   │   ├── casos_de_uso.png
│   │   ├── sequencia_login.png
│   │   ├── sequencia_analise.png
│   │   ├── sequencia_crud.png
│   │   └── diagrama_classes.png
│   └── dossies/
│       ├── Dossie_Tecnico_Sprint1_Phize.docx
│       └── Dossie_Tecnico_Sprint2_Phize.docx
├── pubspec.yaml
└── README.md
```

---

## 🗄️ Modelagem NoSQL — Cloud Firestore

### `usuarios/{uid}`
```json
{
  "id": "string (UID Firebase Auth)",
  "nome": "string",
  "email": "string",
  "dataCadastro": "Timestamp",
  "provedor": "email | google | apple"
}
```

### `usuarios/{uid}/Historico_Alertas/{alertaId}`
```json
{
  "id": "string",
  "usuarioId": "string",
  "origem": "LINK_URL | PRINT_TELA",
  "textoAnalisado": "string",
  "scoreRisco": "BAIXO_VERDE | MEDIO_AMARELO | ALTO_VERMELHO",
  "percentualRisco": "number (0-100)",
  "diagnosticoEducativo": "string",
  "dataAnalise": "Timestamp"
}
```

### `Reportes/{reporteId}`
```json
{
  "id": "string",
  "usuarioId": "string",
  "hashAmeaca": "string (SHA-256)",
  "categoria": "TYPOSQUATTING | URGENCIA_FINANCEIRA | FALSO_BOLETO | OUTROS",
  "descricaoGolpe": "string",
  "contadorIncidencias": "number",
  "curtidas": "number",
  "dataReporte": "Timestamp"
}
```

---

## 📋 Sprints

| Sprint | Período | Meta | Status |
|--------|---------|------|--------|
| Sprint 1 | 12/06 → 26/06/2026 | Fundação e Autenticação | 🔄 Em andamento |
| Sprint 2 | 27/06 → 11/07/2026 | Core de Análise com IA | ⏳ Planejada |
| Sprint 3 | 12/07 → 26/07/2026 | Comunidade e Finalização | ⏳ Planejada |

---

## ▶️ Como rodar o projeto

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão 3.x ou superior)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) ou [Xcode](https://developer.apple.com/xcode/) (para iOS)
- Conta no [Firebase](https://firebase.google.com/) com projeto configurado

### Instalação

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/phize.git
cd phize

# 2. Instale as dependências
flutter pub get

# 3. Configure o Firebase
# Adicione o arquivo google-services.json (Android) em android/app/
# Adicione o arquivo GoogleService-Info.plist (iOS) em ios/Runner/

# 4. Rode o projeto
flutter run
```

---

## 📐 Artefatos UML

Os diagramas estão disponíveis na pasta `/docs/uml/`:

- **Diagrama de Casos de Uso** — visão macro das interações usuário × sistema
- **Diagrama de Sequência — Cadastro/Login** — fluxo de autenticação com Firebase
- **Diagrama de Sequência — Análise de Ameaças** — fluxo OCR + LLM + RAG
- **Diagrama de Sequência — CRUD Reportes** — ciclo de vida de uma denúncia
- **Diagrama de Classes** — entidades Usuário, AnaliseRisco e ReporteComunidade

---

## 🔒 Privacidade e LGPD

O Phize foi desenvolvido seguindo o princípio de **Zero-Persistence**:

- Imagens enviadas para análise são processadas em memória volátil e **deletadas imediatamente** após a extração de texto via OCR
- Nenhuma imagem de conversa é armazenada nos servidores
- Links denunciados são convertidos em **hash SHA-256** antes de qualquer armazenamento
- Metadados de imagens anexadas em reportes são removidos automaticamente

---

## 📄 Licença

Projeto acadêmico — Centro Universitário CESUSC, 2026.
