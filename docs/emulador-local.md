# Emulador local das Cloud Functions

Nesta fase a camada intermediária (arquitetura, seção 2 — Proteção de Credenciais) roda **apenas no emulador local do Firebase**, sem deploy. A decisão e suas consequências estão na Fase 5 de `docs/ROADMAP.md`.

## O que existe

| Item | Onde |
| --- | --- |
| Código da Function (TypeScript) | `functions/src/` |
| Configuração do emulador | `firebase.json` (seção `emulators`) |
| Projeto Firebase padrão | `.firebaserc` |
| Endereço que o app chama | `lib/core/config/proxy_config.dart` |

Function disponível: `reputacaoDominio` (Google Safe Browsing), na região `southamerica-east1`.

## Pré-requisitos (uma vez só)

**[TERMINAL]**, na raiz do projeto:
```
npm --prefix functions install
```

## Configurar a chave do Safe Browsing localmente

A chave **nunca** vai para o código nem para o repositório. Ela fica em um arquivo local, lido pelo emulador como variável de ambiente.

1. **[WINDOWS]** Gere a chave no Google Cloud Console: *APIs e serviços → Biblioteca → Safe Browsing API → Ativar*, depois *Credenciais → Criar credenciais → Chave de API*. A chave é gratuita e **não** depende do plano Blaze. Restrinja a chave à Safe Browsing API.

2. **[WINDOWS]** Crie o arquivo `functions/.env.local` com uma única linha:
   ```
   SAFE_BROWSING_API_KEY=<cole a chave aqui>
   ```

3. **[TERMINAL]** Confirme que o Git ignora o arquivo (a saída deve citar a regra do `.gitignore`):
   ```
   git check-ignore -v functions/.env.local
   ```

Nunca cole a chave em prompt, commit, issue, print de tela ou mensagem de grupo. Se isso acontecer, apague a chave no console e gere outra.

Sem o arquivo, a Function continua funcionando: toda consulta responde "verificação não concluída" (motivo `chave_ausente`), e o app segue com os demais sinais (degradação controlada).

## Rodar o emulador

**[TERMINAL]**, na raiz do projeto:
```
npm --prefix functions run build
```
```
firebase emulators:start --only functions
```

Quando aparecer `All emulators ready`, a Function responde em:
```
http://127.0.0.1:5001/phize-de7a1/southamerica-east1/reputacaoDominio
```
e o painel do emulador fica em `http://127.0.0.1:4000`. `Ctrl+C` encerra.

Em outro terminal, rode o app normalmente (`flutter run -d chrome`). O endereço padrão do app já aponta para o emulador.

> **Para testar o app logado no Firebase real, suba o emulador apenas com `--only functions`.** Com o emulador de Auth ativo (`--only functions,auth`), o app logado no Firebase real recebe `401` na chamada à Function, e a reputação aparece como "verificação não concluída". Para usar o app com o Auth emulado, veja "App autenticado nos emuladores de Auth e Firestore" abaixo.

Avisos esperados na inicialização, que podem ser ignorados:
- *"The following emulators are not running..."* — com `--only functions`, Auth e Firestore não são emulados. Os tokens do login real são verificados normalmente pela Function.
- *"requested node version 22 doesn't match your global version"* — o emulador usa o Node instalado na máquina.

Para recompilar automaticamente enquanto edita o TypeScript, deixe rodando em outro terminal:
```
npm --prefix functions run build:watch
```

## Testes da Function

**[TERMINAL]**
```
npm --prefix functions test
```
Os testes simulam o Safe Browsing e não acessam a rede.

## Verificação rápida sem o app

Sem token, a Function deve recusar a chamada com `401`:
```
curl -X POST -H "Content-Type: application/json" -d "{\"url\":\"https://exemplo.com.br/\"}" http://127.0.0.1:5001/phize-de7a1/southamerica-east1/reputacaoDominio
```

## Teste ponta a ponta com o emulador de Auth

Para testar a Function com um usuário autenticado sem tocar na produção, o `firebase.json` também configura o emulador de Auth (porta `9099`). Ele só sobe quando pedido explicitamente.

> **ATENÇÃO:** com o Auth emulado ativo, a Function passa a aceitar **apenas** tokens do emulador. O app logado no Firebase real recebe `401` e mostra a reputação como "verificação não concluída". Para usar o app nesse cenário, rode-o com `PHIZE_AUTH_EMULATOR` e `PHIZE_FIRESTORE_EMULATOR` (seção seguinte) ou volte a subir só `--only functions`.

No PowerShell, use `curl.exe` (e não `curl`, que é um apelido de outro comando).

1. **[TERMINAL]** Subir Functions e Auth:
   ```
   firebase emulators:start --only functions,auth
   ```

2. **[TERMINAL]** Criar um usuário de teste no Auth emulado. O e-mail e a senha são fictícios e só existem no emulador; nada é criado no projeto real. A resposta traz o campo `idToken`:
   ```
   curl.exe -X POST "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake" -H "Content-Type: application/json" -d "{\"email\":\"teste@exemplo.com\",\"password\":\"senha-teste-123\",\"returnSecureToken\":true}"
   ```
   Se o usuário já existir, faça login com `accounts:signInWithPassword` no mesmo endereço e com o mesmo corpo.

3. **[TERMINAL]** Chamar a Function com o token, usando o endereço de teste oficial do Google. A resposta deve ser `listado`:
   ```
   curl.exe -X POST -H "Authorization: Bearer <idToken>" -H "Content-Type: application/json" -d "{\"url\":\"http://testsafebrowsing.appspot.com/s/phishing.html\"}" http://127.0.0.1:5001/phize-de7a1/southamerica-east1/reputacaoDominio
   ```
   Com `https://www.google.com/` no lugar, a resposta deve ser `nao_listado`.

Os usuários do Auth emulado somem quando o emulador é encerrado.

## App autenticado nos emuladores de Auth e Firestore

Para validar no app as trilhas de print e de link com Functions e Auth emulados, o app precisa autenticar no **mesmo** emulador de Auth que a Function usa para verificar o token. O Firestore também precisa ser emulado: o cadastro grava `users/{uid}`, e o Firestore de produção recusa o token do emulador, o que deixa a tela de cadastro carregando sem fim. Tudo é ligado por `--dart-define`, sem alterar código:

| Variável | Formato | Sem a variável |
| --- | --- | --- |
| `PHIZE_AUTH_EMULATOR` | `host:porta` | o app autentica contra o Firebase de produção |
| `PHIZE_FIRESTORE_EMULATOR` | `host:porta` | o app grava no Firestore de produção |
| `PHIZE_FUNCTIONS_URL` | URL base das Functions | emulador em `127.0.0.1` (`lib/core/config/proxy_config.dart`) |

O host da máquina de desenvolvimento muda por plataforma, e é escolhido pelo valor passado na compilação (não há condicional de plataforma no código): `10.0.2.2` no emulador Android, `127.0.0.1` no navegador. As três variáveis devem usar o mesmo host. As portas são as de `firebase.json` (Auth `9099`, Firestore `8085`). Valor fora do formato `host:porta` interrompe a inicialização, para o app não cair em produção sem aviso, e o mesmo vale para informar só uma das duas variáveis de emulador (`lib/core/config/emulator_config.dart`).

O emulador do Firestore carrega as regras de `firestore.rules`, as mesmas publicadas no console.

### Java para o emulador do Firestore

O emulador do Firestore roda em Java e não aceita o Java 8. Se `java -version` mostrar `1.8`, use o Java que acompanha o Android Studio **só no terminal do emulador**, sem alterar a configuração do Windows:

```
$env:PATH = "C:\Program Files\Android\Android Studio\jbr\bin;" + $env:PATH
```

1. **[TERMINAL]** Subir Functions, Auth e Firestore (no mesmo terminal em que o `PATH` foi ajustado):
   ```
   firebase emulators:start --only functions,auth,firestore
   ```

2. **[TERMINAL]** Rodar o app, em outro terminal.

   Emulador Android:
   ```
   flutter run --dart-define=PHIZE_AUTH_EMULATOR=10.0.2.2:9099 --dart-define=PHIZE_FIRESTORE_EMULATOR=10.0.2.2:8085 --dart-define=PHIZE_FUNCTIONS_URL=http://10.0.2.2:5001/phize-de7a1/southamerica-east1
   ```

   Navegador:
   ```
   flutter run -d chrome --dart-define=PHIZE_AUTH_EMULATOR=127.0.0.1:9099 --dart-define=PHIZE_FIRESTORE_EMULATOR=127.0.0.1:8085 --dart-define=PHIZE_FUNCTIONS_URL=http://127.0.0.1:5001/phize-de7a1/southamerica-east1
   ```

3. **[APP]** Criar uma conta pela tela de cadastro. A conta existe só no emulador (aparece em `http://127.0.0.1:4000/auth`, e o documento `users/{uid}` em `http://127.0.0.1:4000/firestore`) e some quando ele é encerrado; nada é criado no projeto real.

Uma compilação sem essas variáveis, inclusive a de release, continua usando a produção.

### HTTP sem TLS para o emulador (só em debug)

O emulador do Firebase responde em HTTP, sem TLS. Desde o Android 9 o sistema bloqueia esse tipo de tráfego por padrão, e o app falha com `Cleartext HTTP traffic to 10.0.2.2 not permitted` no cadastro, no login e em qualquer chamada à Function.

Por isso a compilação de **debug** tem uma configuração de segurança de rede que libera HTTP sem TLS **somente** para estes hosts:

| Host | Uso |
| --- | --- |
| `10.0.2.2` | máquina de desenvolvimento vista do emulador Android |
| `127.0.0.1` e `localhost` | dispositivo físico conectado com redirecionamento de porta (`adb reverse tcp:9099 tcp:9099`, `adb reverse tcp:8085 tcp:8085` e `adb reverse tcp:5001 tcp:5001`) |

| Arquivo | Conteúdo |
| --- | --- |
| `android/app/src/debug/res/xml/network_security_config.xml` | `domain-config` com `cleartextTrafficPermitted="true"` apenas para os três hosts acima |
| `android/app/src/debug/AndroidManifest.xml` | `android:networkSecurityConfig` apontando para esse arquivo |

Os dois ficam no source set `debug`, que o Gradle só usa na compilação de debug. As compilações de release e de profile não recebem nem o arquivo nem o atributo, e qualquer outro destino continua exigindo TLS também em debug. Não há `usesCleartextTraffic` nem `cleartextTrafficPermitted` em escopo global.

> **Esta exceção não flexibiliza o RNF07.** O requisito exige transmissão sobre canal criptografado (TLS 1.2+), e isso continua valendo para todo tráfego que sai do dispositivo, inclusive o envio do texto mascarado ao provedor de LLM. A exceção cobre apenas o ambiente de desenvolvimento local, em que o tráfego vai do emulador Android para a própria máquina de quem desenvolve e não passa pela rede. O app publicado não tem a exceção.

## Contrato da Function

`POST` com cabeçalho `Authorization: Bearer <ID token do Firebase Auth>` e corpo `{"url": "https://exemplo.com.br/caminho"}`: a URL já normalizada no app, com domínio e caminho, sem query string nem fragmento (arquitetura, seção 4, etapa 2).

| HTTP | Corpo | Significado |
| --- | --- | --- |
| 200 | `{"status":"listado","tiposAmeaca":[...]}` | Consta como malicioso no Google Safe Browsing |
| 200 | `{"status":"nao_listado"}` | Não consta nas listas (não é garantia de ausência de risco) |
| 200 | `{"status":"nao_concluida","motivo":"..."}` | `chave_ausente`, `indisponivel`, `timeout` ou `resposta_inesperada` |
| 400 | `{"erro":"url_invalida"}` | URL ausente, inválida ou com query string, fragmento ou usuário/senha |
| 401 | `{"erro":"nao_autenticado"}` | Sem token ou token inválido |
| 405 | `{"erro":"metodo_nao_permitido"}` | Método diferente de POST |
| 429 | `{"erro":"limite_excedido"}` | Limite de consultas por usuário excedido |

O limite por usuário e os tempos máximos ficam em `functions/src/config.ts`.

Privacidade: a URL consultada vai no corpo do POST (não na URL da chamada) e nenhum log da Function a registra, nem o domínio.

## Troca para a Function publicada (quando o Blaze for ativado)

Nenhuma linha de lógica muda. Muda só a configuração:

1. Publicar: `firebase deploy --only functions`. A chave vai no arquivo local `functions/.env.phize-de7a1`, também ignorado pelo Git (ou, de preferência, no Secret Manager).
2. Rodar o app com o endereço publicado:
   ```
   flutter run --dart-define=PHIZE_FUNCTIONS_URL=https://southamerica-east1-phize-de7a1.cloudfunctions.net
   ```

Antes do deploy, revisar dois pontos:
- **Rate limiting:** o contador fica na memória da instância. É exato no emulador (instância única), mas depois do deploy vale por instância. Por isso a Function está com `maxInstances: 1`. Se precisar escalar, o contador tem que ir para um armazenamento compartilhado.
- **CORS:** está liberado (`cors: true`) para o app rodando no Chrome. A proteção real é o token do Firebase Auth, mas vale restringir às origens do app.
