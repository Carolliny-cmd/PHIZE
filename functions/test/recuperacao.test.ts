import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";

import { VERSAO_SCHEMA, type Ficha, type IndiceBase } from "../src/baseConhecimento";
import {
  carregarIndice,
  consultarBase,
  recuperarPadroes,
} from "../src/recuperacao";

/** Ficha fictícia, só para teste. */
const ficha = (id: string): Ficha => ({
  id,
  modalidade: `Golpe ${id}`,
  categoria: "falso_contato",
  canais: ["WhatsApp"],
  gatilhosLinguisticos: [`frase ${id}`],
  padraoSolicitacaoFinanceira: "Pix",
  orientacaoPreventiva: "Confirme por outro canal.",
  fontes: [{ titulo: "t", publicador: "p", consultadoEm: "2026-11-01" }],
  curadoria: { revisadoPor: "Equipe de teste", revisadoEm: "2026-11-02" },
});

/** Índice com vetores unitários de dimensão 3. */
const indice = (vetores: Record<string, number[]>): IndiceBase => ({
  versaoSchema: VERSAO_SCHEMA,
  modeloEmbedding: "modelo-teste",
  dimensao: 3,
  fichas: Object.entries(vetores).map(([id, vetor]) => ({
    id,
    hash: "h",
    ficha: ficha(id),
    vetor,
  })),
});

const INDICE = indice({
  a: [1, 0, 0],
  b: [0.8, 0.6, 0],
  c: [0, 1, 0],
  d: [0, 0, 1],
});

test("recupera os mais parecidos em ordem, até a quantidade", () => {
  const r = recuperarPadroes([1, 0, 0], INDICE, { quantidade: 2, limiar: -1 });
  assert.deepEqual(r.map((p) => p.id), ["a", "b"]);
  assert.equal(r[0].similaridade, 1);
  assert.equal(r[1].similaridade, 0.8);
});

test("o limiar descarta os pouco parecidos, mesmo dentro da quantidade", () => {
  const r = recuperarPadroes([1, 0, 0], INDICE, { quantidade: 3, limiar: 0.7 });
  assert.deepEqual(r.map((p) => p.id), ["a", "b"]);
});

test("nada acima do limiar: lista vazia", () => {
  assert.deepEqual(recuperarPadroes([0, 0, 1], indice({ a: [1, 0, 0] }), { quantidade: 3, limiar: 0.5 }), []);
});

test("empate é desfeito pelo id, para a mesma consulta dar a mesma lista", () => {
  const empatado = indice({ z: [1, 0, 0], m: [1, 0, 0] });
  const r = recuperarPadroes([1, 0, 0], empatado, { quantidade: 2, limiar: 0 });
  assert.deepEqual(r.map((p) => p.id), ["m", "z"]);
});

test("o padrão recuperado não leva fontes nem curadoria", () => {
  const [p] = recuperarPadroes([1, 0, 0], INDICE, { quantidade: 1, limiar: 0 });
  assert.deepEqual(Object.keys(p).sort(), [
    "gatilhosLinguisticos",
    "id",
    "modalidade",
    "orientacaoPreventiva",
    "padraoSolicitacaoFinanceira",
    "similaridade",
  ]);
});

test("carregarIndice aceita índice válido e recusa os incompatíveis", () => {
  const pasta = mkdtempSync(path.join(tmpdir(), "phize-indice-"));
  const gravar = (nome: string, conteudo: string) => {
    const arquivo = path.join(pasta, nome);
    writeFileSync(arquivo, conteudo);
    return arquivo;
  };
  const esperado = { modelo: "modelo-teste", dimensao: 3 };

  assert.ok(carregarIndice(gravar("ok.json", JSON.stringify(INDICE)), esperado));
  assert.equal(carregarIndice(path.join(pasta, "nao-existe.json"), esperado), undefined);
  assert.equal(carregarIndice(gravar("corrompido.json", "{ nao é json"), esperado), undefined);
  assert.equal(
    carregarIndice(gravar("modelo.json", JSON.stringify({ ...INDICE, modeloEmbedding: "outro" })), esperado),
    undefined,
  );
  assert.equal(
    carregarIndice(gravar("schema.json", JSON.stringify({ ...INDICE, versaoSchema: 99 })), esperado),
    undefined,
  );
  const vetorCurto = { ...INDICE, fichas: [{ ...INDICE.fichas[0], vetor: [1, 0] }] };
  assert.equal(carregarIndice(gravar("vetor.json", JSON.stringify(vetorCurto)), esperado), undefined);
});

const fetchVetor = (valores: number[], status = 200): typeof fetch =>
  (async () =>
    new Response(JSON.stringify({ embedding: { values: valores } }), { status })) as typeof fetch;

const OPCOES = { indice: INDICE, quantidade: 3, limiar: 0.7, timeoutMs: 1000 };

test("consultarBase: gera o embedding da consulta e recupera", async () => {
  let corpo: { taskType?: string } = {};
  const fetchFn = (async (_u: string, i: RequestInit) => {
    corpo = JSON.parse(String(i.body));
    return new Response(JSON.stringify({ embedding: { values: [2, 0, 0] } }));
  }) as unknown as typeof fetch;
  const r = await consultarBase("texto", "k", { ...OPCOES, fetchFn });
  assert.equal(corpo.taskType, "RETRIEVAL_QUERY");
  assert.equal(r.status, "consultada");
  assert.deepEqual(
    (r as { padroes: { id: string }[] }).padroes.map((p) => p.id),
    ["a", "b"],
  );
});

test("consultarBase: consultada mesmo quando nada passa do limiar", async () => {
  const r = await consultarBase("texto", "k", { ...OPCOES, fetchFn: fetchVetor([0, 0, -1]) });
  assert.deepEqual(r, { status: "consultada", padroes: [] });
});

test("consultarBase: sem índice, sem chave ou falha do embedding, não consultada", async () => {
  let chamou = false;
  const espiao = (async () => {
    chamou = true;
    return new Response("{}");
  }) as typeof fetch;
  assert.deepEqual(
    await consultarBase("t", "k", { ...OPCOES, indice: undefined, fetchFn: espiao }),
    { status: "nao_consultada", motivo: "indice_indisponivel" },
  );
  assert.deepEqual(
    await consultarBase("t", undefined, { ...OPCOES, fetchFn: espiao }),
    { status: "nao_consultada", motivo: "chave_ausente" },
  );
  assert.equal(chamou, false);

  for (const fetchFn of [fetchVetor([1, 0, 0], 503), fetchVetor([1, 0]), fetchVetor([0, 0, 0])]) {
    assert.deepEqual(await consultarBase("t", "k", { ...OPCOES, fetchFn }), {
      status: "nao_consultada",
      motivo: "embedding_indisponivel",
    });
  }
});

test("índice versionado do repositório carrega com o modelo configurado", async () => {
  const { DIMENSAO_EMBEDDING, MODELO_EMBEDDING } = await import("../src/config");
  const arquivo = path.resolve(__dirname, "..", "..", "base-conhecimento", "indice.json");
  assert.ok(carregarIndice(arquivo, { modelo: MODELO_EMBEDDING, dimensao: DIMENSAO_EMBEDDING }));
});
