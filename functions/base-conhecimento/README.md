# Base de conhecimento de padrões de fraude

Base própria de modalidades de golpe praticadas no Brasil, consultada pela análise de print (RNF05, RDEV04; arquitetura, seção 3.2). Cada modalidade é uma **ficha** em `fichas/`, catalogada manualmente pela equipe a partir de fontes públicas. O script de indexação converte as fichas em embeddings e grava o índice vetorial em `indice.json`, versionado no repositório.

A curadoria é humana: nenhum conteúdo entra na base de forma automática. A IA pode ajudar a formatar uma ficha, mas quem catalogou revisa e assina.

## Pastas e arquivos

| Caminho | O que é |
| --- | --- |
| `fichas/<id>.json` | Uma ficha por modalidade. O nome do arquivo é o `id` da ficha. |
| `modelo-ficha.json` | Modelo para copiar. Fica fora de `fichas/` e não é indexado. |
| `rascunhos/<id>.json` | Fichas ainda não revisadas, com `curadoria` em branco. Não são indexadas. |
| `indice.json` | Índice gerado pelo script. Não editar à mão. |
| `avaliacao/mensagens.json` | Mensagens inventadas, rotuladas, para medir a recuperação (`npm run avaliar-recuperacao`; ver `docs/calibracao-recuperacao.md`). |
| `avaliacao/teste.json` | Conjunto de **teste** (`"tipo": "teste"`): mensagens inventadas que não repetem frases das fichas, em três estilos, com golpes fora da base e mensagens legítimas difíceis. Só para medir, nunca para ajustar. `npm run conferir-teste` confere a trava contra cópia sem chamar a API; `npm run avaliar-recuperacao -- --arquivo teste.json` mede a busca. |
| `avaliacao/ocr-teste.json` | OCR (ML Kit, emulador Android) dos prints sintéticos desenhados a partir de `teste.json`, com o texto e a posição de cada linha. Conteúdo fictício. Ver `docs/calibracao-recuperacao.md`, "Texto de print". |
| `avaliacao/teste-ocr-{bruto,ordenado,recebidas}.json` | Conjuntos de teste com o texto como o app o envia, gerados de `ocr-teste.json` por `test/avaliacao/conjuntos_ocr_test.dart`. Não editar à mão. |
| `avaliacao/independente.json` | Mensagens escritas por pessoas de fora, usadas na comparação com e sem a base (`npm run avaliar-analise`). Mesmo formato de `mensagens.json`, com `id` e `esperado` nulo quando nenhuma ficha cobre o golpe. Ainda não existe. |
| `avaliacao/relatorios/` | Resultados de `avaliar-analise`: identificadores e sinais, nunca o texto das mensagens. |

O índice fica dentro de `functions/` porque a consulta (Prompt 7.2) precisa gerar o embedding do texto com a chave do Gemini, que só existe na camada intermediária. Ele é publicado junto com a Function, que o lê ao iniciar: uma ficha nova só vale na análise depois que as Functions forem publicadas de novo (ou o emulador reiniciado).

Na análise, a Function recupera as fichas mais parecidas com o texto mascarado e as envia ao modelo, que só pode apontar correspondência com uma delas. Quantidade e limiar: `docs/calibracao-recuperacao.md`. Depois de um lote novo de fichas, rode `npm run avaliar-recuperacao` e, se preciso, inclua em `avaliacao/mensagens.json` uma mensagem inventada para cada modalidade nova.

## Campos da ficha

Os cinco primeiros vêm da seção 3.2 (a) da arquitetura. Os demais garantem a ligação com o restante do sistema e a rastreabilidade da curadoria.

| Campo | Obrigatório | Conteúdo |
| --- | --- | --- |
| `id` | sim | Igual ao nome do arquivo: letras minúsculas sem acento, números e hífens. Ex.: `falso-parente-troca-de-numero`. |
| `modalidade` | sim | Nome do golpe, como as fontes o chamam. |
| `canais` | sim | Lista de canais em que o golpe chega (WhatsApp, SMS, e-mail, ligação...). |
| `gatilhosLinguisticos` | sim | Lista de frases e expressões típicas do golpista. É o campo que mais pesa na comparação com a mensagem recebida. Até 30 itens de até 300 caracteres. |
| `situacoesLegitimas` | não | Lista de situações reais parecidas com o golpe, descritas a partir da orientação das fontes (ex.: o SMS automático do serviço com o código que a própria pessoa pediu). Hoje não vai ao modelo nem entra no embedding: enviado ao modelo, deixou-o cauteloso demais sem ganho confirmado (ver `docs/calibracao-recuperacao.md`). Fica guardado para uma nova tentativa. Até 30 itens de até 300 caracteres. Nunca escreva a partir das mensagens de `avaliacao/`: a trava contra cópia também compara este campo. |
| `padraoSolicitacaoFinanceira` | sim | O que o golpista pede (Pix, boleto, dados do cartão, código de verificação), ou "não há pedido financeiro direto". |
| `orientacaoPreventiva` | sim | O que a pessoa deve fazer, segundo as fontes. |
| `categoria` | sim | Uma das categorias de `docs/categorias-ameaca.md`, exceto `sem_indicios`. |
| `fontes` | sim, ao menos uma | `titulo`, `publicador`, `consultadoEm` (AAAA-MM-DD) e, se houver, `url` (https). |
| `curadoria` | sim | `revisadoPor` e `revisadoEm` (AAAA-MM-DD): quem da equipe revisou a ficha e quando. |

Campo fora da lista é rejeitado, para que um erro de digitação não passe despercebido.

O embedding é gerado só com modalidade, canais, gatilhos e pedido financeiro: é o que se parece com a mensagem que o usuário recebe. Mudar apenas a orientação, as situações legítimas, a categoria, as fontes ou a curadoria atualiza o índice sem gerar embedding novo.

## Fontes aceitas

Conteúdo público e de acesso irrestrito (arquitetura, seção 3.2 a): cartilhas e boletins da Febraban e do Banco Central; alertas de órgãos estaduais e federais de defesa do consumidor; comunicados de segurança de instituições financeiras; matérias de veículos de referência.

Nunca use conversa real de alguém como fonte ou como gatilho (RNF01, RNF07). Os gatilhos descrevem o padrão do golpe, não reproduzem a mensagem de uma vítima.

## Como catalogar uma modalidade

1. Copie `modelo-ficha.json` para `fichas/<id>.json` e preencha.
2. **[TERMINAL]**, na pasta `functions`:
   ```
   npm run indexar-base
   ```
   O script valida todas as fichas e para com a lista de erros se alguma estiver incompleta. Com as fichas válidas, gera embedding só para as novas ou alteradas e reaproveita as demais. Precisa de `GEMINI_API_KEY` em `functions/.env.local`. Recusas temporárias do provedor (503, 429) são repetidas automaticamente.
3. Faça commit da ficha **e** do `indice.json` juntos.

## Rascunhos

Um rascunho (escrito por alguém da equipe ou com ajuda da IA) fica em `rascunhos/` até ser revisado. Para revisar:

1. Abra cada fonte listada e confira que a ficha diz o que a fonte diz: modalidade, pretextos, pedido e orientação. Ajuste o que estiver impreciso.
2. Confira que os gatilhos descrevem o padrão do golpe e não reproduzem a conversa de alguém.
3. Preencha `curadoria.revisadoPor` com o seu nome e `curadoria.revisadoEm` com a data da revisão.
4. Mova o arquivo para `fichas/` e rode `npm run indexar-base`.

Quem preenche a curadoria responde pelo conteúdo da ficha. Rascunho sem revisão não entra no índice.

Os rascunhos de 2026-11-03 foram escritos com ajuda da IA a partir de páginas oficiais (Febraban, Detran, Secretarias de Fazenda, INSS, Receita Federal, PGFN e órgãos de segurança pública), listadas em `fontes` de cada um. Eles parafraseiam as fontes; os gatilhos são exemplos de frases que seguem os pretextos descritos, não citações.

As datas de `consultadoEm` e `revisadoEm` usam o formato AAAA-MM-DD (ex.: `2026-11-03`), não DD/MM/AAAA.

## Conferir sem chamar a API

Para conferir sem chamar a API:

```
npm run indexar-base -- --verificar
```

O `npm test` da Function faz a mesma conferência: ficha inválida ou índice desatualizado reprova os testes.

## Modelo de embeddings

`MODELO_EMBEDDING` e `DIMENSAO_EMBEDDING` em `functions/src/config.ts`. O índice registra com qual modelo foi gerado, e a consulta precisa usar o mesmo. Trocar o modelo exige rodar `npm run indexar-base` de novo, que então gera todos os embeddings outra vez.

O texto das fichas é público, e o embedding passa pelo mesmo provedor que já recebe o texto mascarado da análise. Nenhum dado de usuário passa pela indexação.
