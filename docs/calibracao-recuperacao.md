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

## Quando recalibrar

- A cada lote novo de fichas: mais fichas aumentam a chance de uma conversa comum ficar perto de alguma delas.
- Ao trocar o modelo de embeddings ou a dimensão.
- Quando a validação manual (prints fictícios ou demonstração) mostrar golpe sem correspondência ou conversa comum com correspondência.

Para recalibrar: rode o script, inclua em `mensagens.json` os casos novos (sempre inventados) e registre abaixo os valores e o resultado. Depois, confirme o efeito em `teste.json` sem mudar esse arquivo para melhorar o número. Ao incluir mensagem em `teste.json`, rode `npm run conferir-teste`.

## Registro de versões

| Versão | Data | Autor | Alteração |
| --- | --- | --- | --- |
| 1.0 | 2026-11-03 | Equipe Phize | Proposta inicial: 3 padrões, limiar 0,70, decisão de correspondência pelo modelo. Pendente de validação pela equipe. |
