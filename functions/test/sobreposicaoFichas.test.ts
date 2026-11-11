import assert from "node:assert/strict";
import { test } from "node:test";

import {
  encontrarSobreposicoes,
  palavras,
  type FichaComparavel,
} from "../src/sobreposicaoFichas";

/** Ficha fictícia, só para teste. */
const ficha = (id: string, gatilhos: string[]): FichaComparavel => ({
  id,
  modalidade: `Golpe ${id}`,
  gatilhosLinguisticos: gatilhos,
  padraoSolicitacaoFinanceira: "Pix para conta de terceiro.",
});

const parente = ficha("falso-parente", ["oi, troquei de número, salva esse"]);

test("normaliza acento, maiúscula e pontuação", () => {
  assert.deepEqual(palavras("Oi, TROQUEI de número!"), ["oi", "troquei", "de", "numero"]);
});

test("acusa frase da ficha repetida na mensagem, mesmo sem acento", () => {
  const r = encontrarSobreposicoes(
    "Oi mae, troquei de numero, salva esse. Me faz um pix?",
    [parente],
  );
  assert.ok(r.length > 0);
  assert.ok(r.every((s) => s.ficha === "falso-parente"));
  assert.ok(r.some((s) => s.trecho === "troquei de numero"));
});

test("aceita o mesmo pretexto contado com outras palavras", () => {
  const r = encontrarSobreposicoes(
    "Mãe, esse aqui é meu contato agora, o outro aparelho estragou.",
    [parente],
  );
  assert.deepEqual(r, []);
});

test("ignora sequência feita só de palavras comuns", () => {
  const f = ficha("f", ["entre em contato com o seu banco"]);
  const r = encontrarSobreposicoes("Vou falar com o seu irmão amanhã.", [f]);
  assert.deepEqual(r, []);
});

test("marcadores de mascaramento não contam como palavra de conteúdo", () => {
  const f = ficha("f", ["mande o CPF e o telefone"]);
  const r = encontrarSobreposicoes("Anotei [CPF] e [TELEFONE] na ficha.", [f]);
  assert.deepEqual(r, []);
});

test("compara também com modalidade e pedido financeiro", () => {
  const f: FichaComparavel = {
    id: "f",
    modalidade: "Falso leilão de veículos",
    gatilhosLinguisticos: ["lance mínimo"],
    padraoSolicitacaoFinanceira: "Pagamento antecipado por boleto.",
  };
  const r = encontrarSobreposicoes(
    "Participe do falso leilão de veículos. Exige pagamento antecipado por boleto.",
    [f],
  );
  assert.ok(r.some((s) => s.trecho.includes("leilao de veiculos")));
  assert.ok(r.some((s) => s.trecho.includes("pagamento antecipado")));
});

test("respeita o tamanho de sequência pedido", () => {
  const f = ficha("f", ["pague a taxa de liberação"]);
  const texto = "É preciso pagar a taxa de liberação.";
  assert.ok(encontrarSobreposicoes(texto, [f], { tamanho: 3 }).length > 0);
  assert.deepEqual(encontrarSobreposicoes(texto, [f], { tamanho: 5 }), []);
});

test("resultado não depende da ordem das fichas", () => {
  const a = ficha("a", ["pague a taxa de liberação"]);
  const b = ficha("b", ["troquei de número hoje"]);
  const texto = "Troquei de número hoje e preciso da taxa de liberação.";
  assert.deepEqual(
    encontrarSobreposicoes(texto, [a, b]),
    encontrarSobreposicoes(texto, [b, a]),
  );
});
