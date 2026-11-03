# ROADMAP DE DESENVOLVIMENTO — PROJETO PHIZE

Guia de execução do projeto com Claude Code.
Cada fase contém os prompts a serem usados e os pontos de verificação.

---

## ONDE PARAMOS

- **Data:** 2026-11-03
- **Última tarefa concluída:** Fase 7.1 — schema das fichas, validação e script de indexação da base de conhecimento (45 testes na Function); antes, Fase 6.3 validada no emulador Android
- **Correções aplicadas na Fase 6.3:** D1 a D4 (primeira auditoria); D1-a, D3-a e D3-b (segunda auditoria) — falha de rede ao obter o token deixou de ser tratada como falha de autenticação nos clientes de análise de texto e de reputação de domínio; texto da tela de seleção ajustado ao que de fato é enviado
- **Base de conhecimento:** 18 fichas revisadas e indexadas; 2 rascunhos corrigidos na auditoria de 2026-11-03 (`falso-sequestro`, `falso-consignado-inss`) aguardando nova revisão em `functions/base-conhecimento/rascunhos/`
- **Próximo passo:** Prompt 7.2, em paralelo com a revisão do segundo lote; a base continua crescendo depois do 7.2

---

## COMO LER ESTE DOCUMENTO

Todo comando ou prompt está marcado com o lugar onde vai:

| Marcação | O que é | Como identificar |
|---|---|---|
| **[TERMINAL]** | Shell do Windows dentro do VS Code | Prompt tipo `PS C:\dev\Phize>`. Abre com `Ctrl+'` |
| **[CLAUDE CODE]** | Sessão da IA | Abre digitando `claude` no terminal. Sai com `/exit` |
| **[WINDOWS]** | Interface gráfica | Menu iniciar, explorador de arquivos, navegador |

Regra prática: **texto em português explicando o que você quer → Claude Code. Comando curto em inglês → terminal.**

---

## REGRAS DE TRABALHO

Estas três valem para o projeto inteiro e importam mais que os prompts em si.

**1. Um commit por prompt.**
Se o resultado sair errado, você reverte com `git checkout .` e refaz o prompt melhor. Sem Git, você tenta consertar conversando com a IA — e isso quase sempre piora.

**2. Peça o teste junto com o código, no mesmo prompt.**
Depois é sempre pior.

**3. Quando o Claude Code contrariar a documentação, a documentação ganha.**
Corrija o `CLAUDE.md` em vez de corrigir o mesmo erro toda sessão.

**4. Sempre leia o que ele gerou antes de aceitar.**
Principalmente em arquivos de configuração e regras de segurança.

---

## AMBIENTE — CONCLUÍDO

- [x] Flutter 3.47.4 instalado em `C:\src\flutter`
- [x] PATH configurado
- [x] VS Code com extensões Flutter e Dart
- [x] Chrome verde no `flutter doctor`
- [x] Projeto criado com `flutter create`
- [ ] Android Studio — **instalar em paralelo, não bloqueia agora**

### Decisão de plataforma

O desenvolvimento começa pelo **Chrome** (`flutter run -d chrome`). O Android só se torna obrigatório a partir da Fase 6.

**Itens que NÃO funcionam na web** e exigirão teste em Android real:
- RF10 / UC11 — compartilhamento nativo
- UC04 — seleção de imagem da galeria
- UC04 / RNF06 — reconhecimento de texto embarcado (Google ML Kit Text Recognition)

Depois de instalar o Android Studio:

**[TERMINAL]**
```
flutter doctor --android-licenses
```

### Nota sobre o `flutter doctor`

- ✗ em **Visual Studio** → ignorar. É só para app desktop Windows, fora do escopo.
- ✗ em **Xcode** → ignorar. iOS só compila em Mac.

---

## FASE 0 — CONTEXTO

Objetivo: fazer o Claude Code conhecer o projeto antes de escrever qualquer código.

### Status

- [x] Documentos convertidos para `.md` em `docs/`
- [x] `CLAUDE.md` gerado e revisado
- [x] `docs/BACKLOG.md` gerado
- [x] Git inicializado

### Prompt 0.1 — CLAUDE.md (feito)

**[CLAUDE CODE]**
```
Leia os documentos do projeto Phize:
@docs/requisitos.md
@docs/arquitetura.md
@docs/casos-de-uso.md
@docs/uml.md
@docs/viabilidade.md
@docs/stakeholders.md

Com base neles, crie um arquivo CLAUDE.md na raiz do projeto contendo:

1. Resumo do produto em até 5 linhas
2. Stack definida: Flutter/Dart, Firebase Authentication, Cloud Firestore
3. As 3 garantias cumulativas de privacidade do RNF01, e as 4 etapas
   do ciclo de vida do dado textual do RNF07 — marcadas como regras
   invioláveis
4. A regra do RF07: o Score de Risco NUNCA é calculado pelo modelo
   de linguagem, apenas por função determinística na aplicação
5. A rotulagem obrigatória das 3 faixas, registrando que o termo
   "Seguro" é proibido
6. Estrutura de pastas e convenções de código do projeto
7. Uma instrução final: em caso de conflito entre o código e os
   documentos em /docs, os documentos prevalecem

Não crie nenhum outro arquivo e não escreva código de aplicação ainda.
```

### Prompt 0.1b — Correções do CLAUDE.md

**[CLAUDE CODE]**
```
Edite o CLAUDE.md (não crie arquivo novo) com três acréscimos:

1. Na Seção 2, ao lado da Google Safe Browsing API, registre que ela é
   licenciada apenas para uso não comercial, e que qualquer evolução
   para modelo de receita exige migração prévia para a Web Risk API.

2. Crie uma nova seção "Degradação Controlada", com a regra:
   a indisponibilidade de uma fonte externa NÃO interrompe a análise.
   O sistema apresenta o resultado com os sinais disponíveis e informa
   ao usuário qual verificação específica não pôde ser concluída.
   Referência: seção 6 da arquitetura e fluxos de exceção do UC03.

3. Na Seção 7, registre que docs/requisitos.md é a fonte canônica dos
   RF e RNF. O docs/relatorio-completo.md os reproduz para fins
   acadêmicos e, em caso de divergência entre os dois, requisitos.md
   prevalece.

Não altere nenhuma outra parte do arquivo.
```

Corrigir manualmente: o typo `typosquetting` → `typosquatting` na Seção 2.

### Prompt 0.2 — Backlog

**[CLAUDE CODE]**
```
Leia @docs/requisitos.md e @docs/casos-de-uso.md.

Crie o arquivo docs/BACKLOG.md com as tarefas técnicas derivadas
dos RF01-RF12 e RNF01-RNF07.

Formato: uma tabela com as colunas
ID | Tarefa | Requisito de origem | MVP ou Expansão | Depende de

Regras:
- toda tarefa cita o RF/RNF de origem
- a coluna "Depende de" usa os IDs das outras tarefas desta mesma
  tabela; tarefa sem dependência fica em branco
- classifique como MVP ou Expansão conforme a seção 2 de requisitos.md,
  não pelo seu próprio julgamento
- ao final, liste separadamente as decisões que ainda NÃO estão
  definidas nos documentos e que bloqueiam implementação

Não escreva código.
```

**A lista de lacunas ao final do arquivo é a parte mais importante.** Ela vira a pauta da próxima reunião da equipe.

### Git

**[TERMINAL]**
```
git init
```
```
git add .
```
```
git commit -m "chore: setup inicial, documentacao e CLAUDE.md"
```

---

## DECISÕES PENDENTES DA EQUIPE

Nenhuma delas está nos documentos. São decisões humanas — se ninguém definir, o Claude Code inventa um número plausível no meio do código.

| Decisão | Bloqueia | Origem |
|---|---|---|
| ~~Tabela de pesos dos 8 sinais~~ — **decidido: v1.0, ver docs/score-calibracao.md** | ~~Fase 2~~ Resolvida | RF07 |
| ~~Pontos de corte entre as 3 faixas de cor~~ — **decidido: v1.0, ver docs/score-calibracao.md** | ~~Fase 2~~ Resolvida | RF07 |
| ~~Limite de domínio recém-criado~~ — **decidido: v1.0, ver docs/score-calibracao.md** | ~~Fase 2~~ Resolvida | RF07 |
| ~~Regra de verificação incompleta~~ — **decidido: v1.0, ver docs/score-calibracao.md** | ~~Fase 2~~ Resolvida | RF07 |
| ~~Volume mínimo de texto do OCR~~ — **decidido: v1.1, ver docs/limite-texto-ocr.md** | ~~Fase 6~~ Resolvida | UC04 |
| Limiar de denúncias para ocultar reporte | Fase 9 | RF11 |
| ~~Estrutura de pastas: por camada ou por feature~~ — **decidido: por feature** | ~~Fase 1~~ Resolvida | CLAUDE.md §6, commit `f17bb5c` |
| Bloquear acesso de usuário com e-mail não verificado? | Fase 1 (pode ser revista depois) | RF01 / UC01 |
| Tempo de expiração do bloqueio de login (provisório: 15 min) | Revisão | RF02 |
| Bloquear usuário com e-mail não verificado (padrão atual: não) | Revisão | RF01/UC01 |
| Validação da tabela v1.0 (docs/score-calibracao.md) pela equipe | Não bloqueante | RF07 |
| Ativar o plano Blaze para deploy das Cloud Functions | Publicação e testes em dispositivo real | Fase 5 |
| ~~Provedor de LLM com termos que vedem uso para treinamento (RNF07)~~ — **decidido: contratado** | ~~Fase 6.2~~ Resolvida | custo recorrente |
| **Ativar faturamento no projeto da chave do Gemini** — a chave em uso está no nível gratuito, cujos termos permitem uso do conteúdo para treinamento (exceção temporária ao RNF07, registrada na Fase 6.3) | Qualquer uso com conversa real; fim da exceção | RNF07, custo recorrente |
| ~~Ativar Cloud Vision e criar chave restrita~~ — **dispensado: OCR embarcado (decisão de 2026-10-07)** | ~~Fase 6.2~~ Resolvida | console |
| Validação da troca do OCR para reconhecimento embarcado (ML Kit), decisão de 2026-10-07 | Não bloqueante | RNF06 |
| Validação das categorias de ameaça v1.0 (docs/categorias-ameaca.md) | Não bloqueante | RNF07 / UC04 |
| Validação do limite de texto v1.1 (docs/limite-texto-ocr.md) | Não bloqueante | RF04 / UC04 |
| **Catalogar as modalidades iniciais da base de conhecimento** — trabalho manual da equipe (RDEV04), uma ficha por modalidade | Prompt 7.2 (validação com fichas reais) | RNF05 / RDEV04 |
| Limiar de similaridade para "correspondência com padrão catalogado" — deve ficar em documento de calibração, não no código | Prompt 7.2 | RF07 / RNF05 |
| Índice da base dentro da Function: a atualização da base passa a exigir nova publicação das Functions, não nova versão do app (arquitetura, seção 3.2 b, fala em nova versão do aplicativo) | Revisão do documento | Arquitetura 3.2 b |

> Padrão adotado: **não bloquear**, seguindo o UC01.

---

## PENDÊNCIAS TÉCNICAS

- `firestore.rules` não cobre subcoleções de `users/{uid}`; o histórico (Fases 4 e 8) exigirá regra nova.
- Restringir os campos graváveis em `users/{uid}` aos três previstos (melhoria de segurança).
- Adicionar ao roadmap os passos de publicação das regras pelo console e teste no Playground.
- Sincronizar os .docx acadêmicos com as alterações de RF07, arquitetura 3.3 e 6, UC03 e relatório 4.8.
- A rotina de mascaramento local pode lançar `StateError` (falha na restauração do isolamento de URL/domínio). O fluxo do UC04 (Fase 6) deve tratar essa exceção interrompendo a análise, sem expor o texto ao usuário nem a log.
- O cálculo do domínio registrável reconhece apenas `com`/`gov`/`org`/`net`/`edu` sob `.br`. Sufixos como `app.br`, `adv.br` e `co.uk` fazem a consulta RDAP no próprio sufixo, e a idade do domínio nunca é avaliada para eles. Degrada com segurança (verificação não concluída, nunca verde nem data falsa), mas a mensagem ao usuário é imprecisa. Solução futura: lista completa de sufixos públicos.
- Dois testes de widget anteriores perderam asserções de rótulo e aviso ao eliminar o caminho fictício da tela de Resultado; a cobertura passou para `test/features/analise/presentation/analise_link_flow_test.dart`.
- A tela de Histórico exibe rótulos de faixa sem o aviso permanente; avaliar na Fase 8 (UC06).
- Restam dados fictícios fora do fluxo de análise: lista do Histórico e saudação do Dashboard.
- Migrar do emulador para a Function publicada antes de qualquer teste em Android real ou entrega que não rode na máquina de desenvolvimento.
- Restringir no console as chaves públicas do Firebase às APIs do Firebase, impedindo que sejam usadas para chamar o Safe Browsing direto e contornar a Function.
- O contador de rate limiting é mantido em memória e zera a cada reinício da Function; migrar para armazenamento compartilhado antes do deploy com mais de uma instância.
- O mapa do rate limiting nunca remove usuários antigos.
- Chamadas com URL inválida consomem o limite antes da validação; comportamento deliberado, a documentar.
- ~~A Function nunca foi exercitada contra o Safe Browsing real; validar com a chave configurada.~~ — **resolvida: validada em 2026-09-24, ver Fase 5**
- A Function passou a receber caminho de URL além do domínio; avaliar se o ciclo de vida desse dado merece registro próprio na documentação, já que o RNF07 trata apenas do texto de OCR.
- Conectar o RAG ao fluxo do UC04 na Fase 7; o Prompt 6.2 é implementado sem recuperação na base de conhecimento (ver decisão de 2026-10-07 na Fase 6).
- A limpeza de cópias órfãs do seletor cobre apenas Android; no iOS o seletor grava em `tmp/` e isso não foi tratado nem validado.
- A remoção real do temporário nunca foi validada em dispositivo ou emulador Android; os testes usam sistema de arquivos em memória.
- Quando o fluxo for ligado à tela (6.2), avaliar a coincidência de tempo entre a limpeza da inicialização e uma seleção em curso.
- A camada de tela não pode exibir nem gravar em log a `FileSystemException` da captura: a mensagem traz o caminho do temporário, que inclui o nome original do print.
- Validar o reconhecimento embarcado (ML Kit) em aparelho Android, com prints reais de WhatsApp e SMS, em tema claro e escuro, antes de considerar o RNF06 cumprido.
- A arquitetura (3.2) não define onde o texto analisado é convertido em embedding para a recuperação RAG. Se a conversão ocorrer por API, haverá uma segunda etapa remota, o que afeta o RNF03 e exige registro no ciclo de vida do dado textual do RNF07. Definir na Fase 7.
- Validar a chamada ao Gemini real (Function `analiseTexto`) com a chave configurada em `functions/.env.local`.
- O mascaramento local não cobre todas as grafias dos dados listados; os formatos não cobertos estão registrados na limitação declarada do RNF07 (`docs/requisitos.md`).
- O modelo é instruído a nunca afirmar que a mensagem é segura, mas o código não verifica a explicação devolvida.
- Os trechos destacados do RF04 não são devolvidos pelo pipeline do UC04; decidir no passo da tela, considerando que carregam conteúdo da conversa.
- O streaming do RNF03 não foi implementado: a resposta do modelo chega inteira.

---

## FASE 1 — FUNDAÇÃO

### Prompt 1.1 — Esqueleto de navegação (concluído)

**[CLAUDE CODE]**
```
Crie o esqueleto de navegação do app, substituindo o contador padrão
gerado pelo flutter create.

Telas (apenas layout, sem lógica de negócio):
- Login
- Cadastro
- Dashboard
- Histórico
- Resultado da Análise

Requisitos:
- siga a estrutura de pastas definida no CLAUDE.md
- use dados fictícios embutidos nas telas; sem Firebase, sem API
- na tela de Resultado, já aplique a rotulagem obrigatória das
  três faixas e o aviso permanente do RF07
- navegação funcional entre as telas

Não implemente autenticação ainda.
```

**Verificação [TERMINAL]:**
```
flutter run -d chrome
```
Navegue por todas as telas. Depois commit.

### Firebase — configuração manual

**[WINDOWS]** No console do Firebase:
1. Criar projeto
2. Ativar Authentication → provedor E-mail/senha
3. Criar o Firestore

> **ATENÇÃO:** ao criar o Firestore, escolha **modo produção**, não modo teste.
> Modo teste deixa o banco aberto para qualquer pessoa ler e escrever por 30 dias.
> Para um app cujo diferencial declarado é privacidade, é um começo ruim.

### Pré-requisitos (não constavam na versão original)

**[WINDOWS]** Instalar o Node.js LTS (nodejs.org), sem marcar "Tools for Native Modules". Reiniciar o VS Code.

**[TERMINAL]** Se o npm for bloqueado por política de execução:
```
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**[TERMINAL]**
```
npm install -g firebase-tools
```
```
firebase login
```

**[WINDOWS]** Adicionar ao PATH do usuário a pasta `C:\Users\<usuario>\AppData\Local\Pub\Cache\bin`, fechar TODAS as janelas do VS Code e reabrir. Verificar com:
```
flutterfire --version
```

**[TERMINAL]**
```
dart pub global activate flutterfire_cli
```
```
flutterfire configure
```

No `flutterfire configure`, marcar apenas **android** e **web**.

> **Nota:** a `apiKey` presente em `lib/firebase_options.dart` é um identificador público do projeto Firebase, não um segredo; a proteção do banco é feita pelas `firestore.rules`. A regra de não embarcar chaves (seção 2 da arquitetura) se aplica às APIs pagas, que passarão pela Cloud Function na Fase 5.

### Prompt 1.2 — Autenticação (concluído)

**[CLAUDE CODE]**
```
Leia o @CLAUDE.md e implemente UC01 (cadastro) e UC02 (login)
conforme @docs/casos-de-uso.md, usando Firebase Authentication.

1. Dependências e inicialização
- adicione firebase_core, firebase_auth e cloud_firestore
- inicialize o Firebase no main.dart usando o
  lib/firebase_options.dart já gerado pelo flutterfire configure

2. Cadastro (UC01 / RF01)
- apenas e-mail e senha; NÃO implemente login social
  (Google/Apple) neste passo
- validação local de senha com mínimo de 8 caracteres
- envio de e-mail de verificação após o cadastro, sem bloquear
  o acesso (o UC01 redireciona direto ao Dashboard)
- criação do documento do usuário em users/{uid} no Firestore,
  contendo SOMENTE uid, e-mail e data de criação (princípio de
  minimização do RNF01)

3. Login (UC02 / RF02)
- opção "Esqueci minha senha" com envio de e-mail de redefinição
- mensagens de erro genéricas que NUNCA revelem se um e-mail
  existe na base: use "E-mail ou senha incorretos" para
  credenciais inválidas, e resposta idêntica na redefinição de
  senha, exista ou não a conta

4. Bloqueio após 5 tentativas (RF02)
- a proteção real contra força bruta é a do próprio Firebase
  Auth: trate o erro too-many-requests com mensagem clara
- mantenha um contador local de tentativas persistido no
  dispositivo, que sobreviva ao reinício do app, apenas como
  camada de interface
- registre essa decisão no CLAUDE.md, explicando que o contador
  local não é a barreira de segurança

5. Fluxos de exceção do UC01 e UC02
e-mail já cadastrado, senha fora do padrão, credenciais
inválidas, falha de conexão

6. Regras do Firestore
crie firestore.rules negando tudo por padrão e liberando apenas
leitura e escrita em users/{uid} quando request.auth.uid == uid.
Não publique as regras; eu faço isso manualmente.

7. Testes unitários
- validador de senha, incluindo casos-limite (7 e 8 caracteres,
  vazia)
- conversão dos códigos de erro do Firebase em mensagens,
  provando que nenhuma mensagem revela a existência do e-mail
- contador de tentativas (incremento, bloqueio na 5ª, reset
  após login bem-sucedido)

Restrições:
- nunca registre senha ou e-mail em log ou print
- conecte às telas de Login e Cadastro já existentes, seguindo
  a estrutura por feature do CLAUDE.md
- ao final, liste os arquivos criados e alterados
```

**O que revisar no resultado:**

1. **Bloqueio após 5 tentativas** — se foi implementado só com uma variável na tela, não serve: some quando o app reinicia. Pergunte onde o contador persiste.
2. **Mensagens de erro** — não podem revelar se o e-mail existe na base. "E-mail ou senha incorretos" é o certo; "senha incorreta" entrega ao atacante que aquela conta existe.
3. **`firestore.rules`** — precisa ser publicado no console, não basta existir no repositório. Teste tentando ler documento de outro usuário.

### Prompt de auditoria (usar após cada prompt de implementação)

Prompt somente leitura — não pede alterações de código, só compara o que foi pedido com o que existe no repositório.

**[CLAUDE CODE]**
```
Não altere nenhum arquivo. Isto é uma auditoria somente leitura.

Releia o prompt de implementação [colar o prompt do passo concluído]
e compare item por item com o código atual do repositório.

Para cada item do prompt, verifique no código se foi de fato
implementado, parcialmente implementado ou não implementado, e
cite o arquivo e trecho que comprova a conclusão (ou a ausência
dela).

Retorne uma tabela:
Item | Status | Evidência

Ao final, liste separadamente qualquer desvio em relação ao
CLAUDE.md ou aos documentos em /docs.
```

A auditoria não pode se limitar a conferir se a suíte de testes passa: deve incluir a execução mental de textos reais de exemplo, cobrindo casos que os testes existentes talvez não previram. Foi esse método — e não a suíte de testes, que passava integralmente — que revelou, na Fase 3, três problemas na rotina de mascaramento local: vazamento de número de cartão sem separadores, corrupção de domínio por dígito colado ao hostname, e colisão do marcador temporário de isolamento de URL.

### Prompt de auditoria de tela (usar após prompts que montam tela)

Complementa o prompt de auditoria acima quando o passo conecta lógica a uma tela. Também somente leitura. Foi a execução do fluxo sobre entradas reais — e não a suíte de testes — que revelou, na Fase 4, a data de registro de outro domínio atribuída ao endereço analisado (redirecionamento do Registro.br).

**[CLAUDE CODE]**
```
Auditoria SOMENTE DE LEITURA. Não altere nada.

1. Percorra o código e informe, para cada entrada de exemplo,
   score, faixa (com o rótulo exibido), sinais e avisos:
   [listar as entradas: caso legítimo, caso de golpe, caso que
   soma sinais, entrada inválida, fonte externa fora do ar]

2. Tabela (Item | Status | Evidência com arquivo e trecho):
   - "Seguro" (ou equivalente) não aparece em nenhuma saída
   - o aviso permanente aparece em todos os resultados
   - nada do conteúdo analisado é persistido nem escrito em log,
     inclusive em mensagens de erro e de verificação não concluída
   - nada é gravado no Firestore fora do previsto no passo
   - nenhum teste acessa a rede
   - nenhum teste anterior foi removido ou enfraquecido
   - nenhum dado fictício permaneceu como fallback

Conclua em uma frase: fase completa, parcial ou incompleta.
```

---

## FASE 2 — MOTOR DE SCORE

Lógica pura em Dart. Sem custo, sem API, 100% testável.

### Prompt 2.1 — usa os valores de docs/score-calibracao.md

---

## FASE 3 — MASCARAMENTO LOCAL (RNF07) — concluída

Também lógica pura. Pré-requisito legal de qualquer envio à nuvem.

**[CLAUDE CODE]**
```
Implemente a rotina de mascaramento local do RNF07.

Expressões regulares para: CPF, CNPJ, telefone, e-mail,
chave Pix aleatória, número de cartão e linha digitável de boleto.
Substituir por marcadores genéricos ([TELEFONE], [CPF], etc).

Escreva testes com exemplos reais de cada formato,
incluindo casos-limite (CPF com e sem pontuação,
telefone com e sem DDI).

A rotina não pode alterar verbos de urgência, valores
monetários ou domínios — teste isso também.
```

---

## FASE 4 — TRILHA DO LINK (UC03) — concluída

Primeiro fluxo ponta a ponta. RDAP e análise de anatomia são gratuitos.

### Prompt 4.1 — Typosquatting (concluído)

**[CLAUDE CODE]**
```
Implemente a análise de anatomia de URL (typosquatting):
normalização do endereço, isolamento de domínio, e comparação
por distância de edição contra uma lista curada de marcas
brasileiras frequentemente imitadas.

Comece a lista com os 20 principais bancos e serviços do Brasil.
Testes obrigatórios.
```

### Prompt 4.2 — RDAP (concluído)

**[CLAUDE CODE]**
```
Implemente a consulta de idade de registro do domínio via RDAP.

Trate: domínio inexistente, RDAP indisponível, timeout.

Em caso de falha, o sistema deve seguir com os demais sinais
e informar ao usuário qual verificação não foi concluída
(degradação controlada, seção 6 da arquitetura).
```

### Prompt 4.3 — Tela de resultado (concluído)

**[CLAUDE CODE]**
```
Monte a tela de resultado do UC03 conectando:
anatomia + RDAP + motor de score da Fase 2.

Exiba o termômetro semafórico, a lista de sinais verificados
com atribuição de fonte, e o aviso permanente de que
a análise não substitui verificação junto à instituição.

Ainda sem Safe Browsing e sem LLM.
```

Sem Safe Browsing (Fase 5), a verificação de link fica incompleta e, pela regra do score v1.0, nunca resulta em verde. Comportamento esperado, não é bug. Essa limitação valeu apenas até a Fase 5.1, quando o Safe Browsing foi conectado e a faixa verde voltou a ser possível.

**Marco:** aqui o app já é demonstrável, sem ter gasto um centavo.

---

## FASE 5 — CAMADA INTERMEDIÁRIA — concluída

> **DECISÃO (2026-09-23):** a Cloud Function é desenvolvida e testada com o emulador local do Firebase, sem deploy. O plano Blaze é obrigatório para publicar Functions e exige cartão cadastrado, ainda que a cota gratuita cubra o uso previsto. A decisão de ativar o Blaze fica com a equipe e não bloqueia o desenvolvimento: o código da Function é o mesmo, muda apenas o endereço que o app chama.
>
> Consequências enquanto o emulador for usado:
> - a Function só responde com o emulador rodando na máquina de quem desenvolve
> - a demonstração precisa do emulador ativo junto com o app
> - testes em Android real ou por outros integrantes exigem o deploy
> - a chave do Safe Browsing é gratuita e **NÃO** depende do Blaze

> **ESCOPO DIVIDIDO:** nesta fase foi implementado o endpoint de reputação (Safe Browsing), que recebe a URL normalizada; o nome `reputacaoDominio` foi mantido por decisão. Os endpoints de OCR e de LLM são acrescentados à mesma Function nas Fases 6 e 7, quando houver consumidor real para eles. **[Superado pela decisão de 2026-10-07 quanto ao endpoint de OCR — ver ATUALIZAÇÃO abaixo.]**

> **ATUALIZAÇÃO (2026-10-07):** com a troca para OCR embarcado (decisão registrada na Fase 6), o endpoint de OCR não será necessário. Apenas o endpoint de LLM é acrescentado à Function, na Fase 6.2.

> **VALIDAÇÃO (2026-09-24):** a consulta foi validada contra o Safe Browsing real, pela Function no emulador, com usuário autenticado no Auth emulado (`docs/emulador-local.md`). Os endereços oficiais de teste do Google retornaram listado, e um domínio legítimo retornou não listado.

> **DECISÃO — escopo da consulta de reputação:** a Function recebe a URL normalizada com domínio e caminho; a query string e o fragmento são descartados no dispositivo, antes da transmissão (arquitetura, seção 4, etapa 2). Motivo: os endereços de teste só aparecem como listados com o caminho completo, o que confirma que enviar apenas o domínio deixaria passar golpes hospedados em caminho de site legítimo. RDAP e typosquatting continuam usando só o domínio.

Obrigatória antes de qualquer API paga.

> **[Superado pela decisão de 2026-10-07 quanto ao Vision:]** o prompt abaixo é mantido como registro histórico. O proxy para a API de visão não será implementado, pois o OCR passou a ser embarcado no dispositivo; a Function atende apenas Safe Browsing e LLM.

**[CLAUDE CODE]**
```
Implemente uma Cloud Function que funcione como proxy
para as APIs externas (Safe Browsing, Vision, LLM).

Requisito de segurança: nenhuma chave de API pode estar
no pacote do aplicativo (seção 2 da arquitetura).

O app autentica na Function via token do Firebase Auth.
Inclua rate limiting por usuário.
```

---

## FASE 5.1 — CONECTAR O SAFE BROWSING À TELA DE RESULTADO — concluída

> **VALIDAÇÃO (2026-09-25):** a faixa verde foi validada no app, com as três verificações (typosquatting, RDAP e Safe Browsing) concluindo sem sinais.

Substituir o marcador provisório da Fase 4 em `analisador_link.dart` pela consulta real, passando o sinal ao motor de score conforme `docs/score-calibracao.md`, e remover a condição de verificação sempre incompleta para a reputação.

---

## FASE 6 — TRILHA DO PRINT (UC04) — concluída quanto ao código

**A partir daqui o Android é obrigatório.**

### Prompt 6.1 — Captura e descarte (concluído)

**[CLAUDE CODE]**
```
Implemente a seleção de imagem da galeria com Zero-Persistence:
carregamento em memória volátil, remoção do arquivo temporário
gerado pelo seletor de mídia, e descarte garantido por bloco
finally executado inclusive em caso de falha.

Escreva o teste que prova o descarte no caminho de exceção.
```

Após a auditoria, que apontou cópias órfãs do seletor em caso de falha na remoção ou fechamento do app no meio do fluxo:

**[CLAUDE CODE]**
```
Corrija a lacuna apontada na auditoria do 6.1. Não altere nada
além do necessário.

1. Limpeza na inicialização
Implemente uma rotina que, ao iniciar o app, remova as pastas
<uuid>/ deixadas pelo seletor de imagem no diretório de cache.
Ela fecha os cenários d e e, em que a cópia fica órfã sem que
retrieveLostData a recupere.

Requisitos:
- a limpeza não pode lançar exceção nem impedir o app de abrir
- deve remover apenas o que pertence ao seletor, nunca outros
  arquivos de cache do app
- nenhum nome de arquivo é escrito em log
- documente no código por que ela existe: o plugin copia a imagem
  para o cache antes de devolver o caminho, e deleteOnExit não é
  confiável no Android, então o RNF01 exige uma varredura própria

2. Falha de cópia tratada como cancelamento
Quando a cópia falhar no plugin e ele devolver null, a rotina de
limpeza acima passa a cobrir eventual arquivo parcial.

3. A mensagem de FileSystemException traz o caminho, que inclui o
nome original do print. Registre no código que essa exceção não
pode ser exibida ao usuário nem gravada em log pela camada de
tela.

Testes obrigatórios:
- a limpeza remove as pastas do seletor
- a limpeza não toca em outros arquivos do cache
- a limpeza falhando não impede o app de iniciar
- nenhum teste acessa o sistema de arquivos real

Rode flutter analyze e flutter test e me mostre o resultado dos
dois. Trabalhe na branch atual, sem commits.
```

### Prompt 6.2 — OCR e pipeline (concluído)

> **DESBLOQUEADO (2026-10-07):** as quatro definições de que dependia foram resolvidas — volume mínimo de texto do OCR (`docs/limite-texto-ocr.md`), provedor de LLM (contratado), chave do Cloud Vision (dispensada pelo OCR embarcado) e execução sem RAG antes da Fase 7 (decisão abaixo).

> **DECISÃO (2026-10-07, pendente de validação pela equipe):** a extração de caracteres passa a ser executada no próprio dispositivo, com reconhecimento de texto embarcado (Google ML Kit Text Recognition), em vez da API de visão computacional em nuvem. Justificativa, em ordem de importância:
> 1. **Privacidade:** a imagem deixa de ser transmitida a terceiros. A seção 5.1 da arquitetura já define a captura de tela como o dado mais sensível manipulado pela aplicação; com o processamento local, a mídia não sai do dispositivo em nenhuma hipótese, e a questão de retenção pelo provedor de OCR deixa de existir.
> 2. **Independência de infraestrutura:** elimina a necessidade de endpoint de OCR na camada intermediária e de chave de API para essa etapa.
> 3. **Custo operacional nulo** para a extração, como consequência.
>
> Limitações:
> - precisão inferior à de serviços em nuvem em imagens de baixa qualidade, aceitável para prints de conversa, que são texto limpo sobre fundo uniforme
> - aumento do tamanho do pacote do aplicativo
> - indisponível na plataforma web, que já não suportava a seleção de imagem da galeria
> - o reconhecimento embarcado não substitui o restante do fluxo: o texto extraído continua sendo transmitido ao modelo de linguagem, de modo que o RNF07 permanece integralmente aplicável

> **DECISÃO (2026-10-07):** o Prompt 6.2 é implementado **SEM RAG**. A recuperação na base de conhecimento é acrescentada na Fase 7, conforme o RNF05, que a define como condição de operação da camada de PLN. Até lá o veredito do modelo não é fundamentado em padrões catalogados, o que deve ser considerado em qualquer demonstração.

> **DECISÃO (2026-10-07):** enquanto a base de conhecimento não existir, a análise de print é tratada como **verificação incompleta**. Aplica-se a regra de `docs/score-calibracao.md` que impede a faixa verde, preservando a pontuação real, e o usuário é informado de que a comparação com padrões catalogados não foi realizada. A regra deixa de valer quando o RAG for conectado ao UC04 na Fase 7.

**[CLAUDE CODE]**
```
Conecte o fluxo do UC04: imagem → OCR embarcado no dispositivo
(Google ML Kit Text Recognition) → descarte da imagem →
verificação de suficiência do texto → mascaramento local (Fase 3)
→ nova verificação de suficiência → envio ao LLM via proxy (novo
endpoint na Function da Fase 5) → score (Fase 2) → descarte do
texto.

A imagem não é transmitida em nenhuma etapa. Não crie endpoint
de OCR na Function.

Trate todas as exceções listadas no UC04.
```

> **REGISTRO — mascaramento local na Fase 6:** a rotina de mascaramento recebeu cinco rodadas de correção durante a Fase 6 (boleto em formato impresso; boleto de convênio; telefone com espaços e celular de 11 dígitos rotulado como CPF; CPF com espaços ou barra e telefone sem DDD; chave Pix sem hífens e CNPJ com espaços ou alfanumérico). Somadas às duas rodadas da Fase 3, são sete. Todas as lacunas foram encontradas pela execução do código sobre textos reais, não pela suíte de testes, que passava integralmente a cada rodada. Os formatos que permanecem sem cobertura estão na limitação declarada do RNF07.

---

## FASE 6.3 — CONECTAR O PIPELINE DO PRINT À INTERFACE — concluída quanto ao código

Análoga à Fase 5.1 para a trilha do link: o pipeline do UC04 (`analisador_print.dart`), implementado e testado no Prompt 6.2, passa a ser acionado pela interface. O pipeline não foi alterado.

Escopo:
- **Dashboard:** o botão "Analisar print", antes desabilitado, fica ao lado de "Analisar link", com a mesma hierarquia visual, e abre a nova tela "Analisar print". Na web segue desabilitado, porque não há seleção de imagem com Zero-Persistence nem OCR embarcado nessa plataforma.
- **Tela "Analisar print"** (`analisar_print_page.dart`): aciona a seleção na galeria pelo `SeletorImagemGaleria`, executa o pipeline com `ReconhecedorTextoMlKit` e `AnaliseTextoClientHttp` (todos já existentes em `data/`) e exibe o feedback de carregamento imediatamente após o acionamento (RNF03). Cancelamento da seleção volta ao estado inicial sem mensagem.
- **Interrupções:** cada motivo de `MotivoInterrupcaoPrint` é exibido com a mensagem própria dele, em linguagem não técnica (RNF04) — texto insuficiente antes e depois do mascaramento, falha de OCR, falha na chamada ao modelo e resposta inválida, esta com botão "Tentar novamente", que refaz a seleção (a imagem anterior já foi descartada). A tela nunca exibe nem registra em log a exceção original; em especial, a `FileSystemException` da captura, que traz o nome original do print.
- **Tela de resultado** (`resultado_analise_page.dart`): passa a exibir os dois tipos — `ResultadoAnalisePage(resultado:)` para link, inalterado, e `ResultadoAnalisePage.print(resultado:)` para print. Termômetro, rótulo do RF07 e aviso permanente ficam num único ponto, comuns aos dois. Para o print, a tela lista os sinais identificados, a categoria da ameaça e a explicação pedagógica, além do aviso de verificação incompleta. O aviso de falibilidade do Safe Browsing continua exclusivo do link.
- **Faixa verde bloqueada sem RAG:** a tela exibe a faixa que vem pronta de `CalculadoraScore`, que já recebe `verificacaoIncompleta: true` do pipeline enquanto `AnalisadorPrint.baseConhecimentoDisponivel` for `false`. A tela não recalcula nem reavalia a faixa e mostra `motivoSemBaseConhecimento` ao usuário.
- **Nenhum conteúdo em estado:** a tela guarda apenas o indicador de carregamento e o motivo da interrupção. `AnalisePrintConcluida` não tem campo para imagem ou texto, e nada é persistido (a gravação no histórico é da Fase 8).

> **PENDÊNCIA (Fase 6.3):** o RF04 e o UC04 (passo 9) pedem o destaque, na interface, das frases que motivaram cada gatilho. Isso não foi implementado: o resultado do pipeline não traz trechos do texto, por desenho (RNF07, descarte na origem), e o contrato da Function não devolve trechos. Exibir trechos exige decidir como conciliar o destaque com o descarte do texto — decisão da equipe, não da implementação.

> **PENDÊNCIA (Fase 6.3):** o RNF03 prevê streaming progressivo do texto gerado. A tela exibe carregamento imediato, mas o resultado aparece de uma só vez, porque a Function devolve a resposta completa e validada.

> **CORREÇÕES (auditoria da Fase 6.3):** D1 — sem sessão reconhecida pela Function, a mensagem deixou de usar a palavra "sessão" e a tela oferece o botão "Entrar de novo", que encerra a sessão (`AuthRepository.sair()`, método acrescentado sem alterar as demais regras de autenticação) e leva ao login; D2 — o estado vazio do resultado de print perdeu o ícone de confirmação e passou a dizer que nenhum sinal de golpe conhecido foi identificado e que a verificação não pôde ser completa; D3 — o texto da tela de seleção diz que a imagem não sai do celular e que o texto, com os dados estruturados escondidos, é enviado para análise; D4 — na resposta inválida, mensagem e botão ("Escolher o print de novo") deixam claro que o print precisa ser escolhido outra vez.

> **CORREÇÕES (segunda auditoria da Fase 6.3):** D1-a — sem conexão para renovar o token vencido (`network-request-failed`) ou com tempo esgotado, os clientes `AnaliseTextoClientHttp` e `ReputacaoDominioClientHttp` passaram a lançar a exceção de indisponibilidade, como já faziam para falha de conexão no POST; token rejeitado, usuário desativado e demais códigos seguem como não autenticado. No print, a falha de rede mantém o caminho de nova tentativa; no link, aparece como verificação não concluída por indisponibilidade, com a faixa elevada pela regra de verificação incompleta. D3-a e D3-b — o texto da tela de seleção passou a dizer que é enviado o texto que aparece no print e que o app procura esconder dados como CPF, telefone e cartão.

> **PENDÊNCIAS (auditoria da Fase 6.3, sem implementação):**
> - Sair da tela "Analisar print" durante o processamento não interrompe a transmissão do texto mascarado já em curso: o pipeline segue até o fim e só o resultado é descartado.
> - O aviso permanente do RF07 fica no fim da tela de resultado e pode exigir rolagem quando a explicação é longa. Definir se "permanente" significa sempre visível (ex.: fixo no rodapé).
> - A regra que impede a faixa verde sem base de conhecimento vive apenas no pipeline (`AnalisadorPrint`). Construtores futuros de `AnalisePrintConcluida`, como o histórico da Fase 8 e o compartilhamento do UC11, poderiam produzir score inconsistente sem que a tela detecte. Avaliar validação defensiva na camada de apresentação.
> - Os clientes HTTP instanciados no `builder` das rotas de link e de print (`app_router.dart`) nunca são fechados.

> **VALIDAÇÃO CONCLUÍDA (2026-11-03):** o fluxo completo (galeria, ML Kit, mascaramento, Function, Gemini, motor de score e tela de resultado) foi exercitado no emulador Android, com Functions, Auth e Firestore emulados, usando os quatro prints de `tools/gerador-prints/`. Os scores e as faixas conferiram com `docs/score-calibracao.md`, inclusive o teto da soma e a faixa verde impedida sem a base de conhecimento; no cenário com CPF e telefone, a explicação não reproduziu nenhum dos dois. Ajustes feitos a partir da validação: o aviso de verificação incompleta deixou de dizer "mesmo sem sinais encontrados", que soava errado quando havia sinais; e a instrução do Gemini passou a exigir acentuação, porque uma das explicações veio sem acentos. Respostas 503 do nível gratuito do Gemini apareceram de forma intermitente como "serviço indisponível"; repetir a análise resolveu.
>
> **Para revisar na Fase 7:** no cenário da falsa central, o modelo marcou também `inducao_urgencia` a partir da ameaça de encerramento da conta, sinal que o `README.md` do gerador não lista. O motor somou corretamente; a decisão é se a instrução do modelo deve separar ameaça de urgência.

> **EXCEÇÃO TEMPORÁRIA AO RNF07 (2026-10-27, decisão da equipe):** a validação da Fase 6.3 usa uma chave do Gemini no **nível gratuito**, cujos termos permitem ao Google usar o conteúdo enviado para melhorar os produtos, inclusive com revisão humana. Isso contraria o RNF07 (transmissão só por APIs que vedem uso para treinamento) e foi aceito conscientemente para destravar os testes. Condições: enviar **somente** os prints fictícios de `tools/gerador-prints/`, nunca conversa real nem dado pessoal real; a exceção termina quando o faturamento for ativado no projeto da chave, antes de qualquer demonstração com conteúdo real. O nível gratuito também é atendido por último em picos de demanda (respostas 503), o que aparece no app como "serviço indisponível".

> **MODELO (2026-10-27):** o `gemini-2.5-flash` deixou de ser oferecido a chaves novas (404). O padrão da Function passou a `gemini-3.8-flash` (`functions/src/config.ts`); a variável `GEMINI_MODEL` no `.env.local` permite trocar sem alterar código. A validação de 2026-11-03 usou `gemini-3.5-flash-lite`, definido em `GEMINI_MODEL` no `.env.local`, e a resposta seguiu o esquema JSON da Function; o padrão `gemini-3.8-flash` não foi exercitado.

> **FERRAMENTA (validação manual):** `tools/gerador-prints/` tem uma página HTML autocontida que desenha e exporta em PNG quatro conversas fictícias: falso parente com troca de número, falsa central bancária, conversa cotidiana sem sinais e mensagem com CPF e telefone inventados, para validar o mascaramento. O RNF07 veda enviar conversas reais ao provedor de LLM nesta fase. O `README.md` da pasta lista os sinais esperados de cada cenário e explica como colocar as imagens na galeria do emulador. Os pesos e as faixas continuam apenas em `docs/score-calibracao.md`.

---

## FASE 7 — BASE DE CONHECIMENTO E RAG

A catalogação é **trabalho manual humano** (RDEV04). A IA ajuda a estruturar e indexar, não a curar.

### Prompt 7.1 — Índice vetorial

**[CLAUDE CODE]**
```
Crie o schema padronizado dos documentos da base de conhecimento
conforme a seção 3.2(a) da arquitetura, mais um script que lê os
arquivos catalogados manualmente, gera embeddings e persiste o
índice vetorial em arquivo local versionado no repositório.
```

> **CONCLUÍDO (2026-11-03):** fichas em `functions/base-conhecimento/fichas/`, uma por modalidade, com os campos da seção 3.2 (a) da arquitetura, a categoria de `docs/categorias-ameaca.md` e, obrigatoriamente, fontes e curadoria (quem revisou e quando). `npm run indexar-base` valida as fichas, gera embeddings com o `gemini-embedding-2` (768 dimensões, `functions/src/config.ts`) só para as fichas novas ou alteradas e grava `indice.json`; `--verificar` confere sem chamar a API, e o `npm test` reprova ficha inválida ou índice desatualizado. Instruções de catalogação em `functions/base-conhecimento/README.md`. A base versionada está vazia: o conteúdo é catalogado pela equipe (RDEV04).
>
> **ÍNDICE NA FUNCTION:** o índice fica em `functions/` porque a consulta precisa do embedding do texto mascarado, gerado com a chave do Gemini, que só existe na camada intermediária. Consequência: atualizar a base exige publicar as Functions de novo, e não lançar nova versão do app como diz a arquitetura (seção 3.2 b). O índice continua em arquivo local versionado no repositório, como a arquitetura prevê. Pendente de revisão do documento pela equipe.
>
> **RASCUNHOS (2026-11-03):** 10 fichas em `functions/base-conhecimento/rascunhos/`, escritas com ajuda da IA a partir de duas páginas da Febraban (os 10 golpes mais aplicados em 2024 e o golpe do WhatsApp), com a curadoria em branco. Ficam fora do índice até a revisão de alguém da equipe. A troca de cartão na maquininha ficou de fora, por ser presencial e não aparecer em print. Numa cópia temporária indexada fora do repositório, o texto fictício dos prints de golpe teve a ficha da modalidade certa em primeiro lugar, e as conversas comuns ficaram abaixo de todas as fichas relacionadas a golpe.
>
> **PRIMEIRO LOTE REVISADO E SEGUNDO LOTE (2026-11-03):** as 10 fichas do primeiro lote foram revisadas pela equipe, sem alteração de conteúdo, e indexadas. O segundo lote tem 10 rascunhos a partir de páginas oficiais: falso leilão de veículos (Detran-PR), boleto falso de IPVA (Sefaz-MT), Pix errado (Febraban), falso consignado (INSS), falsa vaga de emprego (Febraban), falso sequestro (Sejusp-MS, alerta de 2017), golpe do amor (Agência Brasília), falso prêmio (Sefa-PR), taxa falsa de encomenda (Receita Federal) e falsa cobrança de dívida ativa (PGFN). O "valores a receber" do Banco Central ficou de fora: a página oficial não pôde ser lida. Numa cópia temporária com as 20 fichas, 11 mensagens fictícias de golpe tiveram a ficha da modalidade certa em primeiro lugar, e 4 conversas comuns ficaram abaixo de todas as mensagens de golpe.
>
> **AUDITORIA DA BASE (2026-11-03):** sobre as 20 fichas, comparação par a par dos embeddings, busca por gatilhos repetidos, teste de recuperação com uma mensagem fictícia por ficha e 6 conversas comuns (incluindo um racha de conta por Pix e um aviso legítimo de compra no cartão), e leitura de cada ficha contra a fonte. Sem duplicatas: as 20 mensagens recuperaram a ficha da modalidade certa em primeiro lugar. Pares próximos (falsa central, mão fantasma e phishing; devolução de empréstimo e Pix errado; IPVA e leilão; falsa venda e taxa de encomenda) são modalidades distintas nas fontes; trocar gatilhos não aumentou a separação, e as fichas foram mantidas. Uma variante do texto de embedding sem rótulos nem canais não melhorou a recuperação; o formato atual foi mantido. Corrigidas duas fichas com trechos sem respaldo na fonte citada: `falso-sequestro` (pedido) e `falso-consignado-inss` (pedido e gatilhos, com o Procon Goiás como segunda fonte); as duas voltaram para revisão. A fonte do falso sequestro é de 2017 e deve ser trocada por uma mais recente quando houver.
>
> **RECOMENDAÇÃO PARA O 7.2:** a conversa comum mais parecida com golpe (aviso legítimo de compra no cartão) ficou a poucos centésimos da mensagem de golpe menos parecida com a sua ficha. A similaridade sozinha não separa os dois casos: recuperar as três fichas mais próximas, usar o limiar só para descartar o que claramente não tem relação e deixar o modelo decidir se há correspondência (arquitetura, seção 3.2 c). As mensagens fictícias da auditoria servem de ponto de partida para a calibração.
>
> **SONDAGEM PARA O 7.2:** com duas fichas de teste fora do repositório, o texto fictício de cada print ficou mais próximo da ficha da sua modalidade, e a conversa comum ficou abaixo das duas. A distância entre "relacionado" e "sem relação" foi pequena, então o limiar de similaridade precisa ser calibrado com fichas reais e registrado em documento de calibração.

### Prompt 7.2 — Recuperação e prompt do LLM

**[CLAUDE CODE]**
```
Implemente a recuperação RAG e o prompt do LLM.

O modelo deve: identificar os 8 sinais do RF07, fundamentar
o veredito nos padrões recuperados, declarar ausência de
correspondência quando não houver similaridade suficiente,
e retornar JSON estruturado.

O modelo NÃO retorna score numérico.

Valide o JSON; resposta fora do formato é descartada
sem exibição parcial ao usuário.
```

---

## FASE 8 — FECHAMENTO DO MVP

**[CLAUDE CODE]**
```
Implemente UC06 (histórico com persistência seletiva),
UC12 (exportação e exclusão de dados — RF12) e
UC11/RF10 (recebimento por compartilhamento nativo).
```

---

## FASE 9 — EXPANSÃO (PÓS-MVP)

Comunidade (UC05, UC07–UC10) e moderação (RF11).
Só depois do MVP validado, como o documento de Requisitos posiciona.

---

## COMANDOS DE REFERÊNCIA

Todos em **[TERMINAL]**:

| Comando | O que faz |
|---|---|
| `flutter run -d chrome` | Roda o app no Chrome (`q` para sair) |
| `flutter doctor` | Verifica o ambiente |
| `flutter test` | Roda os testes |
| `claude` | Abre a sessão da IA (`/exit` para sair) |
| `git status` | Mostra o que mudou |
| `git add .` | Prepara tudo para o commit |
| `git commit -m "mensagem"` | Salva o ponto de retorno |
| `git checkout .` | Desfaz tudo que não foi commitado |
