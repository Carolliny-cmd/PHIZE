/**
 * Base de conhecimento de padrões de fraude (RNF05, RDEV04; arquitetura,
 * seção 3.2). Este módulo define o schema das fichas catalogadas
 * manualmente pela equipe, valida cada ficha e monta o índice vetorial
 * persistido em `base-conhecimento/indice.json`.
 *
 * A curadoria é humana: o código só aceita ficha com fonte declarada e
 * revisão registrada, e nunca cria ou altera conteúdo de ficha.
 *
 * As fichas descrevem modalidades de golpe a partir de fontes públicas.
 * Nenhum conteúdo de conversa de usuário passa por este módulo.
 */

import { createHash } from "node:crypto";

import { CATEGORIAS_PERMITIDAS, type CategoriaAmeaca } from "./analiseTexto";

/** Versão do schema da ficha e do índice. Muda quando um campo muda. */
export const VERSAO_SCHEMA = 1;

/** Categorias aceitas em ficha: todas as de golpe, sem `sem_indicios`. */
export const CATEGORIAS_FICHA = CATEGORIAS_PERMITIDAS.filter(
  (c) => c !== "sem_indicios",
);

export interface FonteFicha {
  titulo: string;
  publicador: string;
  url?: string;
  consultadoEm: string;
}

export interface CuradoriaFicha {
  revisadoPor: string;
  revisadoEm: string;
}

/** Documento estruturado da seção 3.2 (a) da arquitetura. */
export interface Ficha {
  id: string;
  modalidade: string;
  categoria: CategoriaAmeaca;
  canais: string[];
  gatilhosLinguisticos: string[];
  /**
   * Situações legítimas parecidas com o golpe (etapa 3 do plano do RAG).
   * Opcional. Hoje não vai ao prompt nem entra no embedding: guardado nas
   * fichas para uma nova tentativa (docs/calibracao-recuperacao.md).
   */
  situacoesLegitimas?: string[];
  padraoSolicitacaoFinanceira: string;
  orientacaoPreventiva: string;
  fontes: FonteFicha[];
  curadoria: CuradoriaFicha;
}

export interface EntradaIndice {
  id: string;
  /** Hash do texto embutido e do modelo; muda quando o vetor precisa mudar. */
  hash: string;
  ficha: Ficha;
  vetor: number[];
}

export interface IndiceBase {
  versaoSchema: number;
  modeloEmbedding: string;
  dimensao: number;
  fichas: EntradaIndice[];
}

const CAMPOS_FICHA = [
  "id",
  "modalidade",
  "categoria",
  "canais",
  "gatilhosLinguisticos",
  "situacoesLegitimas",
  "padraoSolicitacaoFinanceira",
  "orientacaoPreventiva",
  "fontes",
  "curadoria",
];
const CAMPOS_FONTE = ["titulo", "publicador", "url", "consultadoEm"];
const CAMPOS_CURADORIA = ["revisadoPor", "revisadoEm"];

const PADRAO_ID = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const TAMANHO_MAXIMO_CAMPO = 1_500;
const TAMANHO_MAXIMO_ITEM = 300;
const MAXIMO_ITENS = 30;

function dataValida(valor: unknown): boolean {
  if (typeof valor !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(valor)) {
    return false;
  }
  const data = new Date(`${valor}T00:00:00Z`);
  return !Number.isNaN(data.getTime()) && data.toISOString().startsWith(valor);
}

function textoPreenchido(valor: unknown, tamanhoMaximo: number): boolean {
  return (
    typeof valor === "string" &&
    valor.trim().length > 0 &&
    valor.length <= tamanhoMaximo
  );
}

function camposDesconhecidos(
  objeto: Record<string, unknown>,
  permitidos: string[],
): string[] {
  return Object.keys(objeto).filter((c) => !permitidos.includes(c));
}

function listaDeTextos(
  valor: unknown,
  campo: string,
  erros: string[],
): void {
  if (!Array.isArray(valor) || valor.length === 0) {
    erros.push(`"${campo}" deve ser uma lista com ao menos um item`);
    return;
  }
  if (valor.length > MAXIMO_ITENS) {
    erros.push(`"${campo}" aceita no máximo ${MAXIMO_ITENS} itens`);
  }
  valor.forEach((item, i) => {
    if (!textoPreenchido(item, TAMANHO_MAXIMO_ITEM)) {
      erros.push(
        `"${campo}[${i}]" deve ser texto preenchido de até ` +
          `${TAMANHO_MAXIMO_ITEM} caracteres`,
      );
    }
  });
}

/**
 * Valida uma ficha lida de `nomeArquivo` (sem extensão). Devolve a lista
 * de erros, vazia quando a ficha é válida. Mensagens em português, para
 * quem catalogou corrigir o arquivo.
 */
export function validarFicha(dado: unknown, nomeArquivo: string): string[] {
  const erros: string[] = [];
  if (typeof dado !== "object" || dado === null || Array.isArray(dado)) {
    return ["o arquivo deve conter um único objeto JSON"];
  }
  const ficha = dado as Record<string, unknown>;

  for (const campo of camposDesconhecidos(ficha, CAMPOS_FICHA)) {
    erros.push(`campo desconhecido "${campo}"`);
  }

  if (typeof ficha.id !== "string" || !PADRAO_ID.test(ficha.id)) {
    erros.push(
      '"id" deve usar só letras minúsculas sem acento, números e hífens',
    );
  } else if (ficha.id !== nomeArquivo) {
    erros.push(`"id" deve ser igual ao nome do arquivo ("${nomeArquivo}")`);
  }

  for (const campo of [
    "modalidade",
    "padraoSolicitacaoFinanceira",
    "orientacaoPreventiva",
  ]) {
    if (!textoPreenchido(ficha[campo], TAMANHO_MAXIMO_CAMPO)) {
      erros.push(
        `"${campo}" deve ser texto preenchido de até ` +
          `${TAMANHO_MAXIMO_CAMPO} caracteres`,
      );
    }
  }

  if (!(CATEGORIAS_FICHA as readonly unknown[]).includes(ficha.categoria)) {
    erros.push(
      `"categoria" deve ser uma de: ${CATEGORIAS_FICHA.join(", ")} ` +
        "(docs/categorias-ameaca.md)",
    );
  }

  listaDeTextos(ficha.canais, "canais", erros);
  listaDeTextos(ficha.gatilhosLinguisticos, "gatilhosLinguisticos", erros);
  if (ficha.situacoesLegitimas !== undefined) {
    listaDeTextos(ficha.situacoesLegitimas, "situacoesLegitimas", erros);
  }

  if (!Array.isArray(ficha.fontes) || ficha.fontes.length === 0) {
    erros.push('"fontes" deve listar ao menos uma fonte pública consultada');
  } else {
    ficha.fontes.forEach((fonte: unknown, i: number) => {
      const rotulo = `fontes[${i}]`;
      if (typeof fonte !== "object" || fonte === null) {
        erros.push(`"${rotulo}" deve ser um objeto`);
        return;
      }
      const f = fonte as Record<string, unknown>;
      for (const campo of camposDesconhecidos(f, CAMPOS_FONTE)) {
        erros.push(`campo desconhecido "${rotulo}.${campo}"`);
      }
      for (const campo of ["titulo", "publicador"]) {
        if (!textoPreenchido(f[campo], TAMANHO_MAXIMO_ITEM)) {
          erros.push(`"${rotulo}.${campo}" deve ser texto preenchido`);
        }
      }
      if (
        f.url !== undefined &&
        (typeof f.url !== "string" || !f.url.startsWith("https://"))
      ) {
        erros.push(`"${rotulo}.url", quando informada, deve começar com https://`);
      }
      if (!dataValida(f.consultadoEm)) {
        erros.push(`"${rotulo}.consultadoEm" deve ser data AAAA-MM-DD`);
      }
    });
  }

  const curadoria = ficha.curadoria;
  if (typeof curadoria !== "object" || curadoria === null) {
    erros.push('"curadoria" deve registrar quem revisou a ficha e quando');
  } else {
    const c = curadoria as Record<string, unknown>;
    for (const campo of camposDesconhecidos(c, CAMPOS_CURADORIA)) {
      erros.push(`campo desconhecido "curadoria.${campo}"`);
    }
    if (!textoPreenchido(c.revisadoPor, TAMANHO_MAXIMO_ITEM)) {
      erros.push('"curadoria.revisadoPor" deve ser texto preenchido');
    }
    if (!dataValida(c.revisadoEm)) {
      erros.push('"curadoria.revisadoEm" deve ser data AAAA-MM-DD');
    }
  }

  return erros;
}

/**
 * Texto convertido em embedding. Reúne só o que se parece com a mensagem
 * que o usuário recebe (modalidade, canais, gatilhos e pedido financeiro);
 * orientação, fontes e curadoria não ajudam a comparar com uma conversa.
 */
export function textoParaEmbedding(ficha: Ficha): string {
  return [
    `Modalidade: ${ficha.modalidade}`,
    `Canais: ${ficha.canais.join(", ")}`,
    "Gatilhos linguísticos:",
    ...ficha.gatilhosLinguisticos.map((g) => `- ${g}`),
    `Pedido financeiro: ${ficha.padraoSolicitacaoFinanceira}`,
  ].join("\n");
}

export function hashEntrada(
  ficha: Ficha,
  modelo: string,
  dimensao: number,
): string {
  return createHash("sha256")
    .update(`${modelo}\n${dimensao}\n${textoParaEmbedding(ficha)}`)
    .digest("hex");
}

/**
 * Normaliza o vetor para norma 1, para que a similaridade de cosseno vire
 * produto escalar. Arredonda a 6 casas para manter o arquivo estável e
 * menor. Vetor nulo é rejeitado.
 */
export function normalizar(vetor: number[]): number[] {
  const norma = Math.sqrt(vetor.reduce((soma, v) => soma + v * v, 0));
  if (!Number.isFinite(norma) || norma === 0) {
    throw new Error("embedding nulo ou inválido");
  }
  return vetor.map((v) => Math.round((v / norma) * 1e6) / 1e6);
}

export type GerarEmbedding = (texto: string) => Promise<number[]>;

export interface ResumoIndexacao {
  indice: IndiceBase;
  geradas: string[];
  reaproveitadas: string[];
  removidas: string[];
}

/**
 * Monta o índice a partir das fichas válidas. Reaproveita o vetor de uma
 * entrada do índice anterior quando o hash não mudou, e só chama
 * `gerarEmbedding` para fichas novas ou alteradas. A saída é ordenada por
 * id, para que a mesma base sempre produza o mesmo arquivo.
 */
export async function montarIndice(
  fichas: Ficha[],
  anterior: IndiceBase | undefined,
  opcoes: { modelo: string; dimensao: number; gerarEmbedding: GerarEmbedding },
): Promise<ResumoIndexacao> {
  const reaproveitaveis = new Map<string, EntradaIndice>();
  if (
    anterior?.versaoSchema === VERSAO_SCHEMA &&
    anterior.modeloEmbedding === opcoes.modelo &&
    anterior.dimensao === opcoes.dimensao
  ) {
    for (const entrada of anterior.fichas) {
      reaproveitaveis.set(entrada.hash, entrada);
    }
  }

  const geradas: string[] = [];
  const reaproveitadas: string[] = [];
  const entradas: EntradaIndice[] = [];

  const ordenadas = [...fichas].sort((a, b) => a.id.localeCompare(b.id));
  for (const ficha of ordenadas) {
    const hash = hashEntrada(ficha, opcoes.modelo, opcoes.dimensao);
    const existente = reaproveitaveis.get(hash);
    let vetor: number[];
    if (existente) {
      vetor = existente.vetor;
      reaproveitadas.push(ficha.id);
    } else {
      const bruto = await opcoes.gerarEmbedding(textoParaEmbedding(ficha));
      if (bruto.length !== opcoes.dimensao) {
        throw new Error(
          `embedding da ficha "${ficha.id}" veio com ${bruto.length} ` +
            `dimensões, esperado ${opcoes.dimensao}`,
        );
      }
      vetor = normalizar(bruto);
      geradas.push(ficha.id);
    }
    entradas.push({ id: ficha.id, hash, ficha, vetor });
  }

  const ids = new Set(fichas.map((f) => f.id));
  const removidas = (anterior?.fichas ?? [])
    .map((e) => e.id)
    .filter((id) => !ids.has(id));

  return {
    indice: {
      versaoSchema: VERSAO_SCHEMA,
      modeloEmbedding: opcoes.modelo,
      dimensao: opcoes.dimensao,
      fichas: entradas,
    },
    geradas,
    reaproveitadas,
    removidas,
  };
}

/**
 * Diferenças entre as fichas e o índice gravado, sem chamar a API. Lista
 * vazia significa índice em dia.
 */
export function divergenciasIndice(
  fichas: Ficha[],
  indice: IndiceBase | undefined,
  opcoes: { modelo: string; dimensao: number },
): string[] {
  if (!indice) return ["índice ausente"];
  const problemas: string[] = [];
  if (indice.versaoSchema !== VERSAO_SCHEMA) {
    problemas.push(`índice no schema ${indice.versaoSchema}, atual ${VERSAO_SCHEMA}`);
  }
  if (indice.modeloEmbedding !== opcoes.modelo) {
    problemas.push(
      `índice gerado com ${indice.modeloEmbedding}, configurado ${opcoes.modelo}`,
    );
  }
  if (indice.dimensao !== opcoes.dimensao) {
    problemas.push(
      `índice com dimensão ${indice.dimensao}, configurada ${opcoes.dimensao}`,
    );
  }
  const noIndice = new Map(indice.fichas.map((e) => [e.id, e]));
  for (const ficha of fichas) {
    const entrada = noIndice.get(ficha.id);
    if (!entrada) {
      problemas.push(`ficha "${ficha.id}" fora do índice`);
    } else if (
      entrada.hash !== hashEntrada(ficha, opcoes.modelo, opcoes.dimensao) ||
      JSON.stringify(entrada.ficha) !== JSON.stringify(ficha)
    ) {
      problemas.push(`ficha "${ficha.id}" alterada depois da indexação`);
    }
    noIndice.delete(ficha.id);
  }
  for (const id of noIndice.keys()) {
    problemas.push(`índice contém "${id}", que não existe mais nas fichas`);
  }
  return problemas;
}

/**
 * Serializa o índice com indentação, mas com cada vetor numa linha só,
 * para que o diff de uma ficha alterada fique legível.
 */
export function serializarIndice(indice: IndiceBase): string {
  const marcadores = indice.fichas.map((_, i) => `__VETOR_${i}__`);
  const semVetores = {
    ...indice,
    fichas: indice.fichas.map((e, i) => ({ ...e, vetor: marcadores[i] })),
  };
  let texto = JSON.stringify(semVetores, null, 2);
  indice.fichas.forEach((e, i) => {
    texto = texto.replace(`"${marcadores[i]}"`, JSON.stringify(e.vetor));
  });
  return `${texto}\n`;
}

export type ResultadoEmbedding =
  | { status: "ok"; vetor: number[] }
  | { status: "falha"; motivo: "indisponivel" | "limite_provedor" | "timeout" | "resposta_invalida"; httpStatus?: number };

/**
 * Pede um embedding ao Gemini. `taskType` é RETRIEVAL_DOCUMENT para as
 * fichas e RETRIEVAL_QUERY para o texto consultado (Prompt 7.2). A chave
 * vai no cabeçalho; nem a chave nem o texto são registrados em log.
 */
export async function gerarEmbeddingGemini(
  texto: string,
  chave: string,
  opcoes: {
    modelo: string;
    dimensao: number;
    taskType: "RETRIEVAL_DOCUMENT" | "RETRIEVAL_QUERY";
    timeoutMs: number;
    fetchFn?: typeof fetch;
  },
): Promise<ResultadoEmbedding> {
  const fetchFn = opcoes.fetchFn ?? fetch;
  const controle = new AbortController();
  const temporizador = setTimeout(() => controle.abort(), opcoes.timeoutMs);
  const endpoint =
    "https://generativelanguage.googleapis.com/v1beta/models/" +
    `${encodeURIComponent(opcoes.modelo)}:embedContent`;

  try {
    const resposta = await fetchFn(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": chave },
      body: JSON.stringify({
        content: { parts: [{ text: texto }] },
        taskType: opcoes.taskType,
        outputDimensionality: opcoes.dimensao,
      }),
      signal: controle.signal,
    });
    if (resposta.status === 429) {
      return { status: "falha", motivo: "limite_provedor", httpStatus: 429 };
    }
    if (!resposta.ok) {
      return { status: "falha", motivo: "indisponivel", httpStatus: resposta.status };
    }
    const corpo = (await resposta.json()) as { embedding?: { values?: unknown } };
    const valores = corpo?.embedding?.values;
    if (
      !Array.isArray(valores) ||
      valores.length === 0 ||
      !valores.every((v) => typeof v === "number" && Number.isFinite(v))
    ) {
      return { status: "falha", motivo: "resposta_invalida" };
    }
    return { status: "ok", vetor: valores as number[] };
  } catch {
    if (controle.signal.aborted) return { status: "falha", motivo: "timeout" };
    return { status: "falha", motivo: "indisponivel" };
  } finally {
    clearTimeout(temporizador);
  }
}
