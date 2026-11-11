/**
 * Leitura dos conjuntos de mensagens de avaliação e aplicação da trava
 * contra cópia (`src/sobreposicaoFichas.ts`), comum aos scripts
 * `avaliar-recuperacao`, `avaliar-analise` e `conferir-teste`.
 *
 * Um conjunto com `"tipo": "teste"` é recusado se alguma mensagem repetir
 * frase de ficha: ele serve para medir, e a medida só vale sem cópia. Os
 * demais (como `mensagens.json`, usado para ajustar) recebem só um aviso.
 */

import { existsSync, readdirSync, readFileSync } from "node:fs";
import path from "node:path";

import {
  encontrarSobreposicoes,
  type FichaComparavel,
} from "../src/sobreposicaoFichas";

export const PASTA_FUNCTIONS = path.resolve(__dirname, "..", "..");
export const BASE = path.join(PASTA_FUNCTIONS, "base-conhecimento");

export interface MensagemConjunto {
  id?: string;
  nome?: string;
  esperado?: string | null;
  /** Como a mensagem foi escrita: formal, informal, parafrase... */
  estilo?: string;
  texto: string;
}

export interface Conjunto {
  descricao?: string;
  /** "teste" bloqueia cópia de ficha; ausente ou "ajuste" só avisa. */
  tipo?: "teste" | "ajuste";
  golpes: MensagemConjunto[];
  semGolpe: MensagemConjunto[];
}

export function lerConjunto(nomeArquivo: string): Conjunto {
  const arquivo = path.join(BASE, "avaliacao", nomeArquivo);
  if (!existsSync(arquivo)) throw new Error(`Arquivo não encontrado: ${nomeArquivo}`);
  return JSON.parse(readFileSync(arquivo, "utf8")) as Conjunto;
}

/** Identificador legível da mensagem, sem o texto. */
export function rotulo(m: MensagemConjunto, i: number, grupo: string): string {
  return m.id ?? m.nome ?? m.esperado ?? `${grupo}-${i + 1}`;
}

/**
 * Fichas revisadas e rascunhos: um rascunho entra no índice depois de
 * revisado, e a mensagem de teste não pode copiá-lo desde já.
 */
export function lerFichasComparaveis(): FichaComparavel[] {
  const fichas: FichaComparavel[] = [];
  for (const pasta of ["fichas", "rascunhos"]) {
    const caminho = path.join(BASE, pasta);
    if (!existsSync(caminho)) continue;
    for (const nome of readdirSync(caminho).filter((n) => n.endsWith(".json")).sort()) {
      const f = JSON.parse(readFileSync(path.join(caminho, nome), "utf8"));
      fichas.push({
        id: String(f.id),
        modalidade: String(f.modalidade ?? ""),
        gatilhosLinguisticos: Array.isArray(f.gatilhosLinguisticos)
          ? f.gatilhosLinguisticos.map(String)
          : [],
        padraoSolicitacaoFinanceira: String(f.padraoSolicitacaoFinanceira ?? ""),
      });
    }
  }
  return fichas;
}

/**
 * Confere o conjunto e imprime as cópias encontradas (identificador da
 * mensagem, ficha e trecho normalizado). Devolve `false` quando o conjunto
 * é de teste e tem cópia — o script deve parar antes de chamar a API.
 */
export function conferirSobreposicao(conjunto: Conjunto, nomeArquivo: string): boolean {
  const fichas = lerFichasComparaveis();
  const mensagens = [
    ...conjunto.golpes.map((m, i) => ({ m, id: rotulo(m, i, "golpe") })),
    ...conjunto.semGolpe.map((m, i) => ({ m, id: rotulo(m, i, "legitima") })),
  ];
  let comCopia = 0;
  for (const { m, id } of mensagens) {
    const achados = encontrarSobreposicoes(m.texto, fichas);
    if (achados.length === 0) continue;
    comCopia++;
    const resumo = achados.map((a) => `${a.ficha}: "${a.trecho}"`).join("; ");
    console.log(`  cópia em ${id} -> ${resumo}`);
  }
  if (comCopia === 0) {
    console.log(`Trava contra cópia: nenhuma das ${mensagens.length} mensagens repete frase de ficha.`);
    return true;
  }
  if (conjunto.tipo === "teste") {
    console.error(
      `Trava contra cópia: ${comCopia} mensagem(ns) de ${nomeArquivo} repetem frase de ficha. ` +
        "Reescreva com outras palavras. Nada foi enviado.",
    );
    return false;
  }
  console.log(
    `Aviso: ${comCopia} de ${mensagens.length} mensagens de ${nomeArquivo} repetem frase de ficha; ` +
      "o resultado tende a ser otimista. Use um conjunto de teste para medir.",
  );
  return true;
}
