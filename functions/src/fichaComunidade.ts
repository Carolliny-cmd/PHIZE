/**
 * Entradas da base de conhecimento geradas de reportes da comunidade
 * (RNF05; arquitetura, 3.2 d; decisão da equipe de 2026-11-17). A
 * curadoria é a inclusão expressa por conta moderadora ("Aprovar e incluir
 * na base"); daqui em diante, nada é reescrito:
 *
 * - modalidade: o título do reporte;
 * - gatilhos: as frases do relato, já mascarado no aparelho;
 * - categoria: a do reporte;
 * - canais e pedido financeiro: "Não informado";
 * - orientação: a padrão da categoria (abaixo);
 * - fonte: o próprio reporte aprovado.
 *
 * As entradas ficam em `baseComunidade/{reporteId}` e saem quando o
 * reporte é excluído, ocultado, devolvido a pendente ou editado pelo autor.
 * Este módulo só monta e confere; quem grava é `index.ts`.
 */

import type { CategoriaAmeaca } from "./analiseTexto";
import {
  CATEGORIAS_FICHA,
  VERSAO_SCHEMA,
  type EntradaIndice,
  type Ficha,
  type IndiceBase,
} from "./baseConhecimento";

type CategoriaFicha = Exclude<CategoriaAmeaca, "sem_indicios">;

/**
 * Orientação preventiva padrão de cada categoria, usada nas entradas da
 * comunidade. Versão 1.0, provisória: escrita a partir das orientações das
 * fichas de fontes públicas e pendente de revisão pela equipe
 * (docs/ROADMAP.md, etapa 10.7).
 */
export const ORIENTACAO_PADRAO: Record<CategoriaFicha, string> = {
  falso_contato:
    "Antes de pagar ou passar qualquer dado, ligue para o número que você já tinha da pessoa ou da empresa. Não confie em número novo enviado por mensagem.",
  falsa_central_ou_instituicao:
    "Desligue ou pare de responder e procure a instituição pelos canais oficiais, digitando você mesmo o endereço ou o número do verso do cartão. Ninguém de verdade pede senha, código ou transferência para proteger sua conta.",
  cobranca_ou_boleto_falso:
    "Não pague por link ou boleto recebido em mensagem. Emita a cobrança no site ou aplicativo oficial de quem cobra e confira o beneficiário antes de pagar.",
  oferta_ou_premio_falso:
    "Desconfie de prêmio, vaga ou preço bom demais que pede pagamento antecipado. Pesquise a empresa por conta própria e não pague para receber.",
  ameaca_ou_extorsao:
    "Não pague nem responda sob pressão. Procure a pessoa ou o órgão citado pelos canais oficiais e registre ocorrência na polícia.",
  roubo_de_dados:
    "Não informe senha, código de verificação, CPF ou dados do cartão por mensagem ou link. Acesse o serviço só pelo aplicativo ou site oficial.",
  outro_golpe:
    "Na dúvida, não clique em links, não passe códigos e não faça pagamentos. Confirme direto com a pessoa ou a instituição, pelos canais oficiais.",
};

export const NAO_INFORMADO = "Não informado";
export const PUBLICADOR_COMUNIDADE = "Comunidade Phize";

const MAXIMO_GATILHOS = 30;
const TAMANHO_MAXIMO_GATILHO = 300;
const TAMANHO_MINIMO_GATILHO = 8;

/**
 * As frases do relato, como estão: corta em fim de frase e quebra de linha,
 * descarta pedaços curtos ou feitos só de marcadores do mascaramento
 * (`[CPF]`, `[LINK]`...), sem repetir, até 30 de até 300 caracteres.
 */
export function gatilhosDoRelato(relato: string): string[] {
  const frases = relato
    .split(/(?<=[.!?])\s+|\n+/)
    .map((f) => f.trim())
    .filter((f) => {
      const semMarcadores = f.replace(/\[[A-Z_]+\]/g, "").replace(/[^\p{L}\p{N}]/gu, "");
      return f.length >= TAMANHO_MINIMO_GATILHO && semMarcadores.length >= 5;
    })
    .map((f) => (f.length > TAMANHO_MAXIMO_GATILHO ? f.slice(0, TAMANHO_MAXIMO_GATILHO) : f));
  return [...new Set(frases)].slice(0, MAXIMO_GATILHOS);
}

export type MotivoRecusaInclusao =
  | "reporte_inexistente"
  | "nao_aprovado"
  | "reporte_de_link"
  | "sem_frases";

/** Data no formato AAAA-MM-DD, como nas fichas. */
export function dataFicha(instante: Date): string {
  return instante.toISOString().slice(0, 10);
}

/**
 * Monta a ficha de um reporte, ou diz por que ele não pode entrar. Só
 * reporte aprovado, de relato ou print (o índice compara texto; o de link já
 * vira hash validada em `ameacas`), com ao menos uma frase aproveitável.
 */
export function fichaDoReporte(
  reporteId: string,
  dados: unknown,
  hoje: Date,
): { ficha: Ficha } | { recusa: MotivoRecusaInclusao } {
  if (typeof dados !== "object" || dados === null) {
    return { recusa: "reporte_inexistente" };
  }
  const { tipo, titulo, relato, categoria, status } = dados as Record<string, unknown>;
  if (status !== "aprovado") return { recusa: "nao_aprovado" };
  if (tipo !== "relato" && tipo !== "print") return { recusa: "reporte_de_link" };
  if (
    typeof titulo !== "string" ||
    typeof relato !== "string" ||
    !(CATEGORIAS_FICHA as readonly string[]).includes(categoria as string)
  ) {
    return { recusa: "reporte_inexistente" };
  }
  const gatilhos = gatilhosDoRelato(relato);
  if (gatilhos.length === 0) return { recusa: "sem_frases" };

  const data = dataFicha(hoje);
  const categoriaFicha = categoria as CategoriaFicha;
  return {
    ficha: {
      id: `comunidade-${reporteId}`,
      modalidade: titulo,
      categoria: categoriaFicha,
      canais: [NAO_INFORMADO],
      gatilhosLinguisticos: gatilhos,
      padraoSolicitacaoFinanceira: NAO_INFORMADO,
      orientacaoPreventiva: ORIENTACAO_PADRAO[categoriaFicha],
      fontes: [
        {
          titulo: "Reporte aprovado da comunidade Phize",
          publicador: PUBLICADOR_COMUNIDADE,
          consultadoEm: data,
        },
      ],
      // Sem o nome nem o identificador de quem moderou.
      curadoria: { revisadoPor: "Moderação da comunidade", revisadoEm: data },
    },
  };
}

/**
 * O reporte mudou de um jeito que tira a entrada da base: deixou de
 * existir, saiu de "aprovado" ou teve título ou relato editado pelo autor.
 */
export function deveRetirarDaBase(antes: unknown, depois: unknown): boolean {
  if (typeof antes !== "object" || antes === null) return false;
  if (typeof depois !== "object" || depois === null) return true;
  const a = antes as Record<string, unknown>;
  const d = depois as Record<string, unknown>;
  return d.status !== "aprovado" || a.titulo !== d.titulo || a.relato !== d.relato;
}

/**
 * Entradas de `baseComunidade` aproveitáveis na consulta: mesmo modelo e
 * dimensão do índice, vetor completo. As demais são ignoradas.
 */
export function entradasComunidade(
  documentos: unknown[],
  esperado: { modelo: string; dimensao: number },
): EntradaIndice[] {
  const entradas: EntradaIndice[] = [];
  for (const doc of documentos) {
    if (typeof doc !== "object" || doc === null) continue;
    const { ficha, vetor, modelo, dimensao, hash } = doc as Record<string, unknown>;
    if (
      modelo !== esperado.modelo ||
      dimensao !== esperado.dimensao ||
      !Array.isArray(vetor) ||
      vetor.length !== esperado.dimensao ||
      !vetor.every((v) => typeof v === "number" && Number.isFinite(v)) ||
      typeof ficha !== "object" ||
      ficha === null ||
      typeof (ficha as Ficha).id !== "string" ||
      typeof (ficha as Ficha).modalidade !== "string" ||
      !Array.isArray((ficha as Ficha).gatilhosLinguisticos)
    ) {
      continue;
    }
    entradas.push({
      id: (ficha as Ficha).id,
      hash: typeof hash === "string" ? hash : "",
      ficha: ficha as Ficha,
      vetor: vetor as number[],
    });
  }
  return entradas;
}

/** Índice do arquivo somado às entradas da comunidade. */
export function combinarIndices(
  indice: IndiceBase | undefined,
  comunidade: EntradaIndice[],
): IndiceBase | undefined {
  if (!indice) return undefined;
  if (comunidade.length === 0) return indice;
  return { ...indice, versaoSchema: VERSAO_SCHEMA, fichas: [...indice.fichas, ...comunidade] };
}
