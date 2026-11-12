/**
 * Recuperação na base de conhecimento (Prompt 7.2; arquitetura, seção
 * 3.2 c; RNF05). Converte o texto já mascarado em embedding, compara com o
 * índice versionado em `base-conhecimento/indice.json` e devolve os
 * padrões de maior similaridade, que vão ao prompt do modelo como
 * referência factual.
 *
 * A similaridade só pré-seleciona candidatos: quem decide se a mensagem
 * corresponde a um padrão é o modelo, que precisa apontar qual deles
 * (docs/calibracao-recuperacao.md).
 *
 * Nunca lança exceção: falha de índice ou de embedding vira resultado
 * "nao_consultada", e a análise segue sem a base (degradação controlada,
 * arquitetura, seção 6). Nenhuma função deste módulo registra o texto.
 */

import { existsSync, readFileSync } from "node:fs";

import {
  gerarEmbeddingGemini,
  normalizar,
  VERSAO_SCHEMA,
  type IndiceBase,
} from "./baseConhecimento";

/** O que do padrão recuperado vai ao prompt. Fontes e curadoria ficam fora. */
export interface PadraoRecuperado {
  id: string;
  modalidade: string;
  gatilhosLinguisticos: string[];
  /** Situações legítimas parecidas; lista vazia quando a ficha não tem. */
  situacoesLegitimas: string[];
  padraoSolicitacaoFinanceira: string;
  orientacaoPreventiva: string;
  similaridade: number;
}

export type MotivoBaseNaoConsultada =
  | "indice_indisponivel"
  | "chave_ausente"
  | "embedding_indisponivel";

export type ResultadoConsultaBase =
  | { status: "consultada"; padroes: PadraoRecuperado[] }
  | { status: "nao_consultada"; motivo: MotivoBaseNaoConsultada };

/**
 * Lê e confere o índice. Devolve `undefined` se o arquivo faltar, estiver
 * corrompido, for de outro schema, de outro modelo ou dimensão, ou tiver
 * vetor fora da dimensão — nesses casos a base não é consultada.
 */
export function carregarIndice(
  arquivo: string,
  esperado: { modelo: string; dimensao: number },
): IndiceBase | undefined {
  try {
    if (!existsSync(arquivo)) return undefined;
    const indice = JSON.parse(readFileSync(arquivo, "utf8")) as IndiceBase;
    if (
      indice?.versaoSchema !== VERSAO_SCHEMA ||
      indice.modeloEmbedding !== esperado.modelo ||
      indice.dimensao !== esperado.dimensao ||
      !Array.isArray(indice.fichas) ||
      !indice.fichas.every(
        (e) =>
          typeof e?.id === "string" &&
          Array.isArray(e.vetor) &&
          e.vetor.length === esperado.dimensao &&
          typeof e.ficha?.modalidade === "string",
      )
    ) {
      return undefined;
    }
    return indice;
  } catch {
    return undefined;
  }
}

/** Produto escalar; os vetores do índice e da consulta já têm norma 1. */
function similaridade(a: number[], b: number[]): number {
  let soma = 0;
  for (let i = 0; i < a.length; i++) soma += a[i] * b[i];
  return soma;
}

/**
 * Os `quantidade` padrões mais parecidos com a consulta, em ordem
 * decrescente, descartados os que ficam abaixo de `limiar`. Empate é
 * desfeito pelo id, para que a mesma consulta dê sempre a mesma lista.
 */
export function recuperarPadroes(
  consulta: number[],
  indice: IndiceBase,
  opcoes: { quantidade: number; limiar: number },
): PadraoRecuperado[] {
  return indice.fichas
    .map((e) => ({ entrada: e, s: similaridade(consulta, e.vetor) }))
    .filter(({ s }) => s >= opcoes.limiar)
    .sort((a, b) => b.s - a.s || a.entrada.id.localeCompare(b.entrada.id))
    .slice(0, opcoes.quantidade)
    .map(({ entrada, s }) => ({
      id: entrada.id,
      modalidade: entrada.ficha.modalidade,
      gatilhosLinguisticos: entrada.ficha.gatilhosLinguisticos,
      situacoesLegitimas: entrada.ficha.situacoesLegitimas ?? [],
      padraoSolicitacaoFinanceira: entrada.ficha.padraoSolicitacaoFinanceira,
      orientacaoPreventiva: entrada.ficha.orientacaoPreventiva,
      similaridade: Math.round(s * 1000) / 1000,
    }));
}

/**
 * Consulta a base para um texto mascarado: embedding da consulta
 * (RETRIEVAL_QUERY) e recuperação. Lista vazia com status "consultada"
 * significa que a base foi consultada e nada passou do limiar.
 */
export async function consultarBase(
  texto: string,
  chave: string | undefined,
  opcoes: {
    indice: IndiceBase | undefined;
    quantidade: number;
    limiar: number;
    timeoutMs: number;
    fetchFn?: typeof fetch;
  },
): Promise<ResultadoConsultaBase> {
  if (!opcoes.indice) {
    return { status: "nao_consultada", motivo: "indice_indisponivel" };
  }
  if (!chave) return { status: "nao_consultada", motivo: "chave_ausente" };

  const r = await gerarEmbeddingGemini(texto, chave, {
    modelo: opcoes.indice.modeloEmbedding,
    dimensao: opcoes.indice.dimensao,
    taskType: "RETRIEVAL_QUERY",
    timeoutMs: opcoes.timeoutMs,
    fetchFn: opcoes.fetchFn,
  });
  if (r.status !== "ok" || r.vetor.length !== opcoes.indice.dimensao) {
    return { status: "nao_consultada", motivo: "embedding_indisponivel" };
  }

  let consulta: number[];
  try {
    consulta = normalizar(r.vetor);
  } catch {
    return { status: "nao_consultada", motivo: "embedding_indisponivel" };
  }
  return {
    status: "consultada",
    padroes: recuperarPadroes(consulta, opcoes.indice, opcoes),
  };
}
