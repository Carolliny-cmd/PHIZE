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

## Quando recalibrar

- A cada lote novo de fichas: mais fichas aumentam a chance de uma conversa comum ficar perto de alguma delas.
- Ao trocar o modelo de embeddings ou a dimensão.
- Quando a validação manual (prints fictícios ou demonstração) mostrar golpe sem correspondência ou conversa comum com correspondência.

Para recalibrar: rode o script, inclua em `mensagens.json` os casos novos (sempre inventados) e registre abaixo os valores e o resultado.

## Registro de versões

| Versão | Data | Autor | Alteração |
| --- | --- | --- | --- |
| 1.0 | 2026-11-03 | Equipe Phize | Proposta inicial: 3 padrões, limiar 0,70, decisão de correspondência pelo modelo. Pendente de validação pela equipe. |
