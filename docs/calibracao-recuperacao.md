# Calibração da Recuperação na Base de Conhecimento (RAG)

Este documento é a **fonte** dos valores que controlam a recuperação de padrões na base de conhecimento (Prompt 7.2; arquitetura, seção 3.2 c; RNF05): quantos padrões vão ao modelo e a partir de que similaridade. O código espelha os valores em um único ponto, `functions/src/config.ts` (`QUANTIDADE_PADROES` e `LIMIAR_SIMILARIDADE`), que deve mudar junto com este documento.

Não trata de pesos nem de faixas do Score de Risco, que constam exclusivamente de `docs/score-calibracao.md`.

## Versão 1.0 (2026-11-03)

**Provisória, pendente de validação pela equipe.** Os documentos do projeto não definiam esses valores. Ver "Registro de versões" ao final.

| Parâmetro | Valor | Papel |
| --- | --- | --- |
| Quantidade de padrões | 3 | Padrões mais parecidos enviados ao modelo como referência. |
| Limiar de similaridade | 0,70 | Padrão abaixo do limiar não é enviado. Se nenhum passar, o modelo recebe a informação de que não há padrão próximo. |

A similaridade é o cosseno entre o embedding do texto mascarado e o de cada ficha (modelo e dimensão em `functions/src/config.ts`), de −1 a 1.

## Como a decisão é tomada

A similaridade **não decide** se há correspondência com padrão catalogado. Ela só pré-seleciona candidatos. A decisão é do modelo de linguagem, que recebe os padrões recuperados e só pode emitir o sinal "correspondência com padrão catalogado" apontando qual deles a mensagem segue. A Function descarta a resposta inteira se o padrão apontado não estiver entre os enviados, ou se o sinal e o padrão apontado não vierem juntos.

Motivo: na medição abaixo, mensagens legítimas parecidas com golpe (aviso de compra no cartão, racha de conta por Pix, boleto de condomínio) ficaram a poucos centésimos da mensagem de golpe menos parecida com a sua ficha. Um limiar único não separa os dois grupos sem perder golpes. Por isso o limiar é baixo, para não perder golpe, e o julgamento fica com o modelo, como prevê a arquitetura (seção 3.2 c): "declarar ausência de correspondência quando não houver similaridade suficiente, em vez de inferir livremente".

São enviados três padrões, e não só o mais parecido, porque modalidades distintas nas fontes ficam próximas entre si (falsa central, mão fantasma e phishing; devolução de empréstimo e Pix errado). Com três, a ficha certa chega ao modelo mesmo quando uma vizinha fica em primeiro lugar.

## Medição da versão 1.0

`npm run avaliar-recuperacao`, na pasta `functions`, com as mensagens fictícias de `functions/base-conhecimento/avaliacao/mensagens.json` e o índice de 18 fichas de 2026-11-03.

| Medida | Resultado |
| --- | --- |
| Golpes com a ficha certa em 1º lugar | 18 de 18 |
| Golpes com a ficha certa entre as enviadas ao modelo | 18 de 18 |
| Menor similaridade de golpe com a ficha certa | 0,787 (falso boleto) |
| Maior similaridade de mensagem sem golpe | 0,746 (aviso legítimo de compra no cartão) |
| Mensagens sem golpe que chegam ao modelo com padrões | 3 de 8 (racha de conta, aviso de compra no cartão, boleto de condomínio) |

As mensagens de `falso-consignado-inss` e `falso-sequestro` não entraram: as fichas estavam em revisão, fora do índice.

> **Esta medição é otimista.** A trava contra cópia (abaixo) mostrou que 13 das 28 mensagens de `mensagens.json` repetem frases das fichas, como "troquei de número" e "segue o boleto". A busca acerta em parte porque as palavras são as mesmas.

## Conjunto de teste

Para medir sem esse viés, existem dois conjuntos com papéis separados:

| Arquivo | Papel | Trava contra cópia |
| --- | --- | --- |
| `avaliacao/mensagens.json` | **Ajuste:** usado para escolher limiar, quantidade e redação das fichas. | Só avisa. |
| `avaliacao/teste.json` (`"tipo": "teste"`) | **Medida:** nunca usado para ajustar. | Recusa o arquivo antes de chamar a API. |

A **trava contra cópia** (`functions/src/sobreposicaoFichas.ts`) procura sequências de 3 palavras que aparecem tanto na mensagem quanto no texto da ficha usado no embedding (modalidade, gatilhos e pedido), desconsiderando acentos, maiúsculas e pontuação. Sequências com menos de 2 palavras fora da lista de palavras comuns ("para o seu", "do seu banco") não contam. Ela compara com as fichas revisadas e com os rascunhos. Conferir sem chamar a API: `npm run conferir-teste`.

O conjunto de teste tem, sem nenhuma conversa real:

- 3 golpes por modalidade indexada, em estilos diferentes: **formal**, **informal** (abreviações e erros de digitação) e **paráfrase** (o mesmo pretexto contado com outras palavras);
- 2 golpes para cada ficha em rascunho, ignorados até a ficha ser indexada;
- 5 golpes de modalidades **fora da base** (`esperado` nulo): aluguel de temporada, vaquinha falsa, comprovante falso, falso advogado e empréstimo com taxa antecipada;
- 26 mensagens **legítimas parecidas com golpe**: aviso real de compra, rastreio, código pedido pela própria pessoa, cobrança de escola e condomínio, entrevista de emprego, alerta de golpe na família, entre outras.

As mensagens foram escritas com ajuda da IA e passaram pela trava. Não substituem mensagens escritas por outras pessoas: servem para medir a busca sem o viés da cópia enquanto essa coleta não é possível.

### Medição da versão 1.0 no conjunto de teste (2026-11-11)

`npm run avaliar-recuperacao -- --arquivo teste.json`, índice de 18 fichas. Relatório: `avaliacao/relatorios/2026-11-11-recuperacao-teste.json`.

| Medida | `mensagens.json` | `teste.json` |
| --- | --- | --- |
| Golpes com a ficha certa em 1º lugar | 18 de 18 | 52 de 54 |
| Golpes com a ficha certa entre as enviadas ao modelo | 18 de 18 | 53 de 54 |
| Menor similaridade de golpe com a ficha certa | 0,787 | 0,696 (falso motoboy, paráfrase) |
| Maior similaridade de mensagem sem golpe | 0,746 | 0,824 (alerta de golpe na família) |
| Mensagens sem golpe que chegam ao modelo com padrões | 3 de 8 | 14 de 26 |
| Golpes fora da base que chegam ao modelo com padrões | — | 5 de 5, sempre com ficha de outra modalidade |

Por estilo: formal 18 de 18 em 1º lugar; informal 16 de 18 (as duas ficaram em 2º lugar e ainda foram enviadas); paráfrase 18 de 18 em 1º lugar, mas uma ficou abaixo do limiar.

O que isso mostra:

- **A ordenação resiste a outras palavras.** Mesmo sem cópia, a ficha certa fica em 1º lugar em 96% dos golpes. O embedding reconhece o pretexto, não só o vocabulário.
- **O limiar quase não filtra.** As faixas de golpes e de mensagens legítimas se sobrepõem por completo (0,696 a 0,887 contra 0,635 a 0,824). Mais da metade das legítimas e todos os golpes fora da base chegam ao modelo com fichas. A proteção contra correspondência errada depende inteiramente do modelo, como previsto na seção "Como a decisão é tomada", mas em escala maior do que a medição anterior indicava.
- **O próximo passo é medir o modelo**, não a busca: rodar `npm run avaliar-analise -- --arquivo teste.json` e contar correspondências erradas nas legítimas e nos golpes fora da base.

Os valores da versão 1.0 **não foram alterados** com base nesta medição: o conjunto de teste não serve para ajustar.

### Medição do modelo e das faixas no conjunto de teste (2026-11-11)

`npm run avaliar-analise -- --arquivo teste.json --repeticoes 1`, com `gemini-3.5-flash-lite` no nível gratuito. As faixas foram calculadas pelo motor do app, sem copiar os pesos:

```
flutter test test/avaliacao/relatorio_faixas_test.dart --dart-define=RELATORIO=2026-11-11-teste.json
```

Relatórios: `avaliacao/relatorios/2026-11-11-teste.json` (sinais) e `2026-11-11-teste-faixas.json` (faixas). A faixa "sem a base" é calculada sem a regra de verificação incompleta, para medir o que o modelo encontra sozinho. No app, a base indisponível impede a faixa verde.

**O modelo recusou todas as correspondências erradas.**

| Grupo | Chegaram ao modelo com fichas | Correspondência apontada |
| --- | --- | --- |
| Mensagens legítimas | 14 de 26 | 0 |
| Golpes fora da base | 5 de 5 | 0 |
| Golpes de fichas indexadas | 53 de 54 | 51 certas, 0 erradas |

As três correspondências que faltaram: `leilao-formal` e `amor-formal` (a ficha foi enviada, mas o modelo não a apontou) e `motoboy-parafrase` (a ficha ficou abaixo do limiar). Um golpe de ficha em rascunho (`consignado-informal`) foi ligado a `devolucao-de-emprestimo`, uma modalidade vizinha, o que é esperado enquanto o rascunho não é indexado.

**A base muda a faixa dos golpes e não prejudica as mensagens legítimas.**

| Grupo | Sem a base | Com a base |
| --- | --- | --- |
| Golpes de fichas da base, inclusive rascunhos (58) | 32 amarelos, 26 vermelhos | 5 amarelos, 53 vermelhos |
| Golpes fora da base (5) | 1 verde, 3 amarelos, 1 vermelho | igual |
| Mensagens legítimas (26) | 24 verdes, 2 amarelos | 25 verdes, 1 amarelo |

- 28 golpes subiram de amarelo para vermelho com a base, nos três estilos de escrita. Nenhuma mensagem legítima subiu de faixa.
- Golpes fora da base não ganham nem perdem com a base, como esperado. O **comprovante falso** passou sem nenhum sinal nos dois modos: é candidato a ficha nova.
- O único falso alarme com a base é o pedido de Pix do presente da professora (amarelo por pedido financeiro), que acontece também sem a base. É efeito da tabela de pesos, não da recuperação.

**Limitações:** uma repetição por mensagem, então a variação entre execuções não foi medida. Um golpe (`sequestro-formal`) caiu de faixa com a base sem relação com a recuperação: foi variação do modelo entre as duas chamadas. Mensagens escritas com ajuda da IA, ainda que sem cópia das fichas.

## Texto de print

O conjunto de teste tem frases limpas. No app, porém, o texto de um print vem do OCR do ML Kit, e isso muda o que chega à busca:

- os blocos vêm **fora da ordem de leitura**;
- vêm junto com a **interface** do aplicativo de conversa: horários, "online", "Hoje", bateria, a barra de digitação;
- vêm junto com as **respostas da própria pessoa**, que não fazem parte do golpe e não precisam sair do aparelho.

### Como foi medido, sem coletar conversas

1. `tool/prints_sinteticos/gerar_prints.py` desenha um print de conversa fictício para cada mensagem de `teste.json` (89 prints, 1080×2340, tema claro e escuro, contato e números inventados, resposta da vítima antes ou depois, mensagem dividida em até 3 balões).
2. `tool/prints_sinteticos/rodar_ocr.sh` instala no emulador Android um teste de integração (`integration_test/ocr_prints_sinteticos_test.dart`) que passa cada print pelo ML Kit **como o app faz** (`InputImage.fromBitmap`, escrita latina) e traz o texto e a posição de cada linha. O resultado fica em `avaliacao/ocr-teste.json`; daí em diante o emulador não é mais necessário.
3. `flutter test test/avaliacao/conjuntos_ocr_test.dart --dart-define=GERAR_OCR=true` monta três conjuntos de teste, todos com o mascaramento local do app:
   - `teste-ocr-bruto.json`: o texto como o ML Kit devolve, que era o que o app enviava;
   - `teste-ocr-ordenado.json`: em ordem de leitura e sem a interface;
   - `teste-ocr-recebidas.json`: além disso, só as mensagens recebidas (lado esquerdo).

A organização é feita por `organizarTextoPrint` (`lib/shared/domain/organizacao_texto_print.dart`), função pura usada pelo próprio app desde esta medição.

### Resultado da busca (2026-11-11)

`npm run avaliar-recuperacao -- --arquivo teste-ocr-<variante>.json`. Relatórios: `avaliacao/relatorios/2026-11-11-recuperacao-teste-ocr-*.json`.

| Texto | Ficha certa em 1º lugar | Legítimas que chegam ao modelo com fichas |
| --- | --- | --- |
| Frase limpa (`teste.json`) | 52 de 54 | 14 de 26 |
| OCR bruto | 45 de 54 | 21 de 26 |
| OCR ordenado, sem interface | 49 de 54 | 24 de 26 |
| OCR só com as recebidas | 52 de 54 | 20 de 26 |

- **O texto bruto custa 7 acertos.** A ordem embaralhada e a resposta da vítima ("Oi, quem fala?", "Pode mandar") afastam o embedding do pretexto.
- **Ordenar e tirar a interface recupera parte**; ficar só com as recebidas recupera a qualidade do texto limpo.
- Com OCR, mais legítimas passam do limiar do que com frase limpa. Ver a medição do modelo abaixo.

### Resultado do modelo e das faixas (2026-11-11)

`npm run avaliar-analise -- --arquivo teste-ocr-<variante>.json --repeticoes 1`, depois `relatorio_faixas_test.dart` com o relatório. Relatórios: `2026-11-11-teste-ocr-bruto.json` e `2026-11-12-teste-ocr-recebidas.json`, com os respectivos `-faixas.json`.

Modelo `gemini-3.5-flash-lite`, uma repetição, nenhuma chamada com falha nos dois relatórios (a variante "recebidas" foi concluída em 2026-11-12 com `--retomar`, depois de a cota gratuita esgotar).

| | OCR bruto | OCR só com as recebidas |
| --- | --- | --- |
| Golpes detectados, com a base | 62 de 63 | 62 de 63 |
| Correspondências certas | 50 | 53 |
| Correspondências erradas | `codigo-informal`, `consignado-informal` | `consignado-informal` |
| Correspondência apontada em legítima | `legit-leilao-judicial` → `falso-leilao-de-veiculos` | `legit-codigo-proprio` → `whatsapp-pedido-de-codigo` |
| Golpes da base (58), com a base | amarelo 4, vermelho 54 | amarelo 4, vermelho 54 |
| Golpes que subiram de faixa com a base | 31 | 31 |
| Golpes fora da base (5), com a base | verde 1, amarelo 4 | verde 1, amarelo 3, vermelho 1 |
| Legítimas (26), com a base | verde 25, **vermelho 1** | verde 25, **amarelo 1** |
| Legítimas que subiram de faixa com a base | 1 (`legit-leilao-judicial`, verde → vermelho) | 1 (`legit-codigo-proprio`, verde → amarelo) |

- **Ficar só com as recebidas melhora a correspondência:** 53 certas contra 50. O `codigo-informal` passou a apontar a ficha certa (`whatsapp-pedido-de-codigo`); no bruto, a resposta da vítima levava ao `falso-premio-sorteio`.
- **O falso vermelho do leilão judicial desaparece.** No bruto, o texto da interface e a resposta da vítima fizeram o modelo ligar o aviso legítimo de leilão ao `falso-leilao-de-veiculos`. Só com as recebidas, a mensagem fica verde com e sem a base.
- **Ainda há uma legítima que sobe:** `legit-codigo-proprio` (a própria pessoa avisando que vai receber um código) foi ligada a `whatsapp-pedido-de-codigo` e subiu de verde para amarelo. É menos grave que o vermelho do bruto, mas mostra que o pedido de código é o gatilho mais sensível a contexto. Candidato a `situacoesLegitimas` na etapa 3.
- **`consignado-informal` continua apontando `devolucao-de-emprestimo`** nas duas variantes. As duas fichas tratam de empréstimo; a faixa final (vermelho) não muda, mas a explicação cita o golpe vizinho.
- **Golpes da base:** a mesma distribuição nas duas variantes; a base continua elevando 31 golpes de amarelo para vermelho, mais que os 28 da frase limpa.
- **O comprovante falso de pagamento segue sem sinal** (`fora-comprovante-falso`, verde), como na frase limpa: confirma a ficha nova da etapa 4.
- Diferenças de uma mensagem entre variantes (`legit-presente-professora`, `legit-mae-pix`, `sequestro-formal`, que desceu de vermelho para amarelo) estão dentro do que uma única repetição permite distinguir. A medição com 3 repetições, já prevista, dirá se são variação do modelo.

**Conclusão:** o app passa a enviar só as mensagens recebidas, em ordem de leitura, como já faz `organizarTextoPrint`. Com print, o desempenho com a base fica próximo ao da frase limpa, e o único falso vermelho medido some.

**Limitações:** prints sintéticos com um único layout de aplicativo de conversa, desenhados sem fotos, figurinhas, áudio, citação de mensagem ou link com prévia; OCR medido em emulador, não em aparelho; uma repetição por mensagem. O fluxo completo do app (compartilhar o print e ver o resultado) não foi refeito no emulador com a organização ligada. A regra de "lado esquerdo" supõe o layout comum dos aplicativos de conversa; prints de SMS, e-mail ou página, sem balão à direita, são analisados inteiros.

### Como refazer

```
python -I tool/prints_sinteticos/gerar_prints.py
bash tool/prints_sinteticos/rodar_ocr.sh
flutter test test/avaliacao/conjuntos_ocr_test.dart --dart-define=GERAR_OCR=true
```

O primeiro passo só é necessário ao mudar `teste.json`; os dois primeiros, ao mudar o desenho dos prints ou a versão do ML Kit. `npm run avaliar-analise` aceita `--retomar <relatório>` para refazer só as chamadas que falharam por limite da API.

## Situações legítimas nas fichas (etapa 3, 2026-11-12)

Cada ficha ganhou o campo opcional `situacoesLegitimas`: duas situações reais parecidas com o golpe, escritas com ajuda da IA a partir da orientação preventiva e das fontes da própria ficha, nunca das mensagens de teste (a trava contra cópia passou a comparar também este campo e barrou uma frase, reescrita na ficha). O campo vai ao modelo junto com o padrão, com a instrução de não apontar o padrão quando a mensagem se encaixa numa dessas situações. Não entra no embedding: a busca e o limiar não mudaram, e o índice foi regravado sem gerar vetor novo.

Medição: `npm run avaliar-analise -- --arquivo teste-ocr-recebidas.json --repeticoes 1 --sufixo -etapa3 --sem-base-de 2026-11-12-teste-ocr-recebidas.json`, que refaz só a análise com a base e reaproveita a sem a base (89 chamadas em vez de 178). Relatórios: `2026-11-12-teste-ocr-recebidas-etapa3.json` e o `-faixas.json`, comparados com `2026-11-12-teste-ocr-recebidas.json`.

| Com a base, só as mensagens recebidas | Antes | Com situações legítimas |
| --- | --- | --- |
| Golpes detectados | 62 de 63 | 62 de 63 |
| Correspondências certas | 53 | 50 |
| Correspondência em legítima ou em golpe fora da base | `legit-codigo-proprio` → `whatsapp-pedido-de-codigo` | `fora-falso-advogado` → `falso-premio-sorteio` |
| Golpes da base (58) | amarelo 4, vermelho 54 | amarelo 4, vermelho 54 |
| Golpes fora da base (5) | verde 1, amarelo 3, vermelho 1 | verde 1, amarelo 2, vermelho 2 |
| Legítimas (26) | verde 25, amarelo 1 | **verde 26** |

- **O alvo foi atingido:** a pessoa avisando que vai receber o próprio código deixou de ser ligada ao golpe do código e voltou a verde. Com a base, nenhuma legítima ficou fora do verde.
- **Nenhum golpe mudou de faixa.** Três perderam a correspondência (`amor-formal`, `emprego-informal`, `leilao-formal`), mas seguiram vermelhos pelos outros sinais. No leilão, a situação legítima "leilão oficial com edital" pode ter pesado contra a mensagem que imita o edital.
- O golpe do falso advogado, que não tem ficha, foi ligado ao falso prêmio: a faixa (vermelho) é adequada, mas a explicação cita o golpe vizinho.
- **Uma repetição não basta para concluir.** Entre esta execução e a anterior, o sinal de urgência apareceu e sumiu em mensagens que a etapa 3 não afeta (as três do código, por exemplo). As diferenças de uma ou duas correspondências estão dentro dessa variação; a medição com 3 repetições, só com a base, dirá se as perdas são da etapa 3.

**Repetição das mensagens que mudaram (2026-11-12).** As 5 mensagens em que a correspondência mudou foram analisadas 3 vezes com as situações legítimas e 3 vezes sem elas (`--ids`, `--sem-situacoes`; relatórios `-etapa3-com-situacoes.json` e `-etapa3-sem-situacoes.json`, 30 chamadas). Ficha apontada em cada repetição:

| Mensagem | Com situações | Sem situações | Leitura |
| --- | --- | --- | --- |
| `emprego-informal` (golpe) | nenhuma nas 3 | `falsa-vaga-de-emprego` nas 3 | perda causada pela etapa 3 |
| `leilao-formal` (golpe) | nenhuma nas 3 | certa em 1 de 3 | ficha já instável sem a etapa 3 |
| `amor-formal` (golpe) | certa em 2 de 3 | nenhuma nas 3 | variação do modelo, não perda |
| `legit-codigo-proprio` (legítima) | nenhuma nas 3 | nenhuma nas 3 | o alarme falso da primeira medição foi variação |
| `fora-falso-advogado` (sem ficha) | falso prêmio em 1 de 2 (1 falha) | nenhuma nas 3 | possível efeito, pouco frequente |

- **O ganho não se confirmou:** sem as situações, a mensagem do código próprio também não foi ligada ao golpe nas 3 repetições. O alarme falso que motivou a etapa 3 apareceu numa única execução.
- **Uma perda se confirmou:** o golpe de "curtir vídeos e ganhar" com taxa de cadastro deixou de ser ligado à falsa vaga de emprego nas 3 repetições. Nenhuma situação legítima da ficha descreve essa mensagem (ambas excluem cobrança); a leitura mais provável é que a instrução nova torna o modelo mais cauteloso em correspondências limítrofes. A faixa não muda (vermelho pelos outros sinais), mas a explicação deixa de citar o golpe.
- As situações não foram reescritas a partir deste resultado: ajustar a ficha à mensagem de teste viciaria a medição. A revisão da curadoria deve partir das fontes.

**Pendente:** as situações legítimas foram escritas com ajuda da IA e precisam da revisão de quem assina a curadoria de cada ficha. **Decisão (2026-11-12):** com o ganho não confirmado e uma perda confirmada, as situações legítimas saíram do prompt; o conteúdo enviado ao modelo voltou a ser o de antes da etapa 3. O campo continua nas fichas (validado e comparado pela trava contra cópia) para uma nova tentativa com outra formulação.

## Fichas novas (etapa 4, 2026-11-12)

Três rascunhos revisados pela curadoria entraram na base: `comprovante-pix-falso` (escrito com ajuda da IA a partir de páginas da Cielo, da Serasa e do Neon), `falso-sequestro` e `falso-consignado-inss` (rascunhos de 2026-11-03). A base passou a 21 fichas; a indexação gerou só os 3 embeddings novos. A trava contra cópia segue sem achados nas 89 mensagens.

Medição: `npm run avaliar-analise -- --arquivo teste-ocr-recebidas.json --repeticoes 1 --sufixo -fichas-novas --sem-base-de 2026-11-12-teste-ocr-recebidas.json` (89 chamadas; o relatório saiu com a data de 2026-11-13 porque o script usa o horário UTC). Comparação com `2026-11-12-teste-ocr-recebidas.json`.

| Com a base, só as mensagens recebidas | Antes (18 fichas) | Depois (21 fichas) |
| --- | --- | --- |
| Golpes detectados | 62 de 63 | **63 de 63** |
| Correspondências certas | 53 | 55, mais o comprovante falso ligado à ficha nova |
| Correspondência errada | `consignado-informal` | `consignado-informal` |
| Golpes da base (58) | amarelo 4, vermelho 54 | amarelo 3, vermelho 55 |
| Golpes fora da base (5) | verde 1, amarelo 3, vermelho 1 | **verde 0**, amarelo 3, vermelho 2 |
| Legítimas (26) | verde 25, amarelo 1 | verde 26 |

- **O comprovante falso deixou de passar em verde:** com a ficha nova, a mensagem foi ligada a ela e ficou vermelha. Era o único golpe do conjunto que o Phize não detectava.
- `consignado-formal` e `sequestro-informal` passaram a ser ligados às fichas certas. `consignado-informal` continua ligado à ficha vizinha `devolucao-de-emprestimo`, sem mudar de faixa.
- Nenhuma legítima saiu do verde com a base.
- O relatório conta o comprovante como "correspondência errada" só porque a mensagem ainda está rotulada como golpe fora da base no conjunto de teste; a ficha apontada é a certa.
- Uma repetição só: as diferenças de uma mensagem seguem sujeitas à variação do modelo vista na etapa 3.

**Rótulo trocado (2026-11-12, decisão da equipe):** `fora-comprovante-falso` passou a golpe da base em `avaliacao/teste.json`, com `esperado` igual a `comprovante-pix-falso` e o estilo novo `ficha-posterior`; os conjuntos de OCR foram gerados de novo a partir dele e só esse rótulo mudou. O identificador foi mantido para comparar com os relatórios anteriores. **Ressalva:** a ficha foi escrita depois de esta mensagem revelar a lacuna, então o resultado dela tende a ser otimista e deve ser lido à parte; o estilo próprio a separa nas estatísticas por estilo de `avaliar-recuperacao`. Daqui em diante o conjunto tem 59 golpes da base e 4 fora da base. Os relatórios já gravados mantêm o rótulo antigo.

## Quando recalibrar

- A cada lote novo de fichas: mais fichas aumentam a chance de uma conversa comum ficar perto de alguma delas.
- Ao trocar o modelo de embeddings ou a dimensão.
- Quando a validação manual (prints fictícios ou demonstração) mostrar golpe sem correspondência ou conversa comum com correspondência.

Para recalibrar: rode o script, inclua em `mensagens.json` os casos novos (sempre inventados) e registre abaixo os valores e o resultado. Depois, confirme o efeito em `teste.json` sem mudar esse arquivo para melhorar o número. Ao incluir mensagem em `teste.json`, rode `npm run conferir-teste`.

## Registro de versões

| Versão | Data | Autor | Alteração |
| --- | --- | --- | --- |
| 1.0 | 2026-11-03 | Equipe Phize | Proposta inicial: 3 padrões, limiar 0,70, decisão de correspondência pelo modelo. Pendente de validação pela equipe. |
