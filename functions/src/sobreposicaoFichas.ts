/**
 * Trava contra cópia entre as mensagens de avaliação e as fichas da base
 * (docs/calibracao-recuperacao.md, "Conjunto de teste").
 *
 * Uma mensagem de teste que repete uma frase da ficha mede a busca de
 * forma otimista: o embedding encontra a ficha porque as palavras são as
 * mesmas, não porque reconhece o golpe. Este módulo procura sequências de
 * `tamanho` palavras (padrão 3) que aparecem tanto na mensagem quanto no
 * texto da ficha usado no embedding (modalidade, gatilhos e pedido).
 *
 * Sequências feitas quase só de palavras comuns ("para o seu", "do seu
 * banco") não contam: é preciso ao menos `minimoPalavrasConteudo` palavras
 * fora da lista de palavras comuns. Acentos, maiúsculas e pontuação são
 * ignorados, para que "número" e "numero" sejam a mesma palavra.
 *
 * Funciona sem rede e sem chave: roda antes de qualquer chamada à API.
 */

/** O mínimo de cada ficha necessário para a comparação. */
export interface FichaComparavel {
  id: string;
  modalidade: string;
  gatilhosLinguisticos: string[];
  padraoSolicitacaoFinanceira: string;
}

export interface Sobreposicao {
  /** Ficha de onde veio a frase repetida. */
  ficha: string;
  /** Sequência repetida, já normalizada (sem acento e em minúsculas). */
  trecho: string;
}

export interface OpcoesSobreposicao {
  tamanho?: number;
  minimoPalavrasConteudo?: number;
}

/**
 * Palavras comuns do português que, sozinhas, não indicam cópia. Inclui
 * artigos, preposições, pronomes, verbos auxiliares e os marcadores de
 * mascaramento, que aparecem em qualquer mensagem.
 */
const PALAVRAS_COMUNS = new Set(
  (
    "a o as os um uma uns umas de do da dos das no na nos nas em ao aos " +
    "por pelo pela pelos pelas para pra pro com sem sobre ate entre e ou " +
    "mas que se nao sim ja so mais muito bem eu tu ele ela nos voces " +
    "voce vc eles elas me te lhe meu minha meus minhas seu sua seus suas " +
    "nosso nossa esse essa esses essas este esta isso isto aquele aquela " +
    "aqui ai la hoje agora e foi ser ter tem tenho temos estou esta estao " +
    "vai vou sao era como quando onde qual quem oi ola bom boa dia tarde " +
    "noite obrigado obrigada favor por isso pode posso tudo todo toda " +
    "cpf cnpj telefone email chave_pix cartao_mascarado boleto_mascarado"
  ).split(" "),
);

/** Minúsculas, sem acento, sem pontuação; uma palavra por item. */
export function palavras(texto: string): string[] {
  return texto
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/\[([a-z_]+)\]/g, (_, m: string) =>
      m === "cartao" ? "cartao_mascarado" : m === "boleto" ? "boleto_mascarado" : m,
    )
    .split(/[^a-z0-9_]+/)
    .filter((p) => p.length > 0);
}

function sequencias(
  lista: string[],
  tamanho: number,
  minimoConteudo: number,
): Set<string> {
  const resultado = new Set<string>();
  for (let i = 0; i + tamanho <= lista.length; i++) {
    const trecho = lista.slice(i, i + tamanho);
    const conteudo = trecho.filter((p) => !PALAVRAS_COMUNS.has(p)).length;
    if (conteudo >= minimoConteudo) resultado.add(trecho.join(" "));
  }
  return resultado;
}

/** Texto da ficha que entra no embedding, menos os canais. */
function textosDaFicha(ficha: FichaComparavel): string[] {
  return [
    ficha.modalidade,
    ...ficha.gatilhosLinguisticos,
    ficha.padraoSolicitacaoFinanceira,
  ];
}

/**
 * Frases da mensagem que repetem trechos de alguma ficha. Lista vazia
 * significa que a mensagem não copia nenhuma ficha. Cada trecho aparece
 * uma vez por ficha, em ordem de ficha e de trecho.
 */
export function encontrarSobreposicoes(
  texto: string,
  fichas: FichaComparavel[],
  opcoes: OpcoesSobreposicao = {},
): Sobreposicao[] {
  const tamanho = opcoes.tamanho ?? 3;
  const minimo = opcoes.minimoPalavrasConteudo ?? 2;
  const daMensagem = sequencias(palavras(texto), tamanho, minimo);
  if (daMensagem.size === 0) return [];

  const encontradas: Sobreposicao[] = [];
  for (const ficha of [...fichas].sort((a, b) => a.id.localeCompare(b.id))) {
    const daFicha = new Set<string>();
    for (const t of textosDaFicha(ficha)) {
      for (const s of sequencias(palavras(t), tamanho, minimo)) daFicha.add(s);
    }
    const comuns = [...daMensagem].filter((s) => daFicha.has(s)).sort();
    for (const trecho of comuns) encontradas.push({ ficha: ficha.id, trecho });
  }
  return encontradas;
}
