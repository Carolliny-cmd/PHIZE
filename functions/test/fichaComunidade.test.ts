import assert from "node:assert/strict";
import { test } from "node:test";

import { CATEGORIAS_FICHA, VERSAO_SCHEMA, type IndiceBase } from "../src/baseConhecimento";
import {
  combinarIndices,
  deveRetirarDaBase,
  entradasComunidade,
  fichaDoReporte,
  gatilhosDoRelato,
  NAO_INFORMADO,
  ORIENTACAO_PADRAO,
  PUBLICADOR_COMUNIDADE,
} from "../src/fichaComunidade";

/** Conteúdo fictício em todos os casos. */
const reporte = (extra: Record<string, unknown> = {}) => ({
  tipo: "relato",
  titulo: "Vaga de emprego pedindo taxa",
  relato:
    "Ofereceram vaga em casa. Pediram Pix de cadastro para o CPF [CPF]!\nMandaram o site [LINK].",
  categoria: "oferta_ou_premio_falso",
  status: "aprovado",
  ...extra,
});

test("gatilhos são as frases do relato, sem reescrita", () => {
  assert.deepEqual(gatilhosDoRelato(reporte().relato), [
    "Ofereceram vaga em casa.",
    "Pediram Pix de cadastro para o CPF [CPF]!",
    "Mandaram o site [LINK].",
  ]);
});

test("gatilhos descartam pedaços curtos, só marcadores e repetidos", () => {
  assert.deepEqual(gatilhosDoRelato("Oi. [CPF] [LINK].\nPague hoje sem falta.\nPague hoje sem falta."), [
    "Pague hoje sem falta.",
  ]);
});

test("gatilhos: até 30, de até 300 caracteres", () => {
  const longo = "a".repeat(400) + ".";
  assert.equal(gatilhosDoRelato(longo)[0].length, 300);
  const muitas = Array.from({ length: 40 }, (_, i) => `Frase de teste número ${i}.`).join(" ");
  assert.equal(gatilhosDoRelato(muitas).length, 30);
});

test("ficha do reporte: título, frases, campos padrão e fonte da comunidade", () => {
  const r = fichaDoReporte("abc123", reporte(), new Date("2026-11-17T15:00:00Z"));
  assert.ok("ficha" in r);
  const { ficha } = r;
  assert.equal(ficha.id, "comunidade-abc123");
  assert.equal(ficha.modalidade, "Vaga de emprego pedindo taxa");
  assert.equal(ficha.categoria, "oferta_ou_premio_falso");
  assert.deepEqual(ficha.canais, [NAO_INFORMADO]);
  assert.equal(ficha.padraoSolicitacaoFinanceira, NAO_INFORMADO);
  assert.equal(ficha.orientacaoPreventiva, ORIENTACAO_PADRAO.oferta_ou_premio_falso);
  assert.equal(ficha.gatilhosLinguisticos.length, 3);
  assert.deepEqual(ficha.fontes, [
    {
      titulo: "Reporte aprovado da comunidade Phize",
      publicador: PUBLICADOR_COMUNIDADE,
      consultadoEm: "2026-11-17",
    },
  ]);
  // Sem nome nem identificador de quem moderou.
  assert.deepEqual(ficha.curadoria, {
    revisadoPor: "Moderação da comunidade",
    revisadoEm: "2026-11-17",
  });
});

test("só entra reporte aprovado, de relato ou print, com frases", () => {
  const hoje = new Date();
  assert.deepEqual(fichaDoReporte("x", undefined, hoje), { recusa: "reporte_inexistente" });
  assert.deepEqual(fichaDoReporte("x", reporte({ status: "pendente" }), hoje), {
    recusa: "nao_aprovado",
  });
  assert.deepEqual(fichaDoReporte("x", reporte({ tipo: "link", relato: "" }), hoje), {
    recusa: "reporte_de_link",
  });
  assert.deepEqual(fichaDoReporte("x", reporte({ relato: "[CPF]" }), hoje), {
    recusa: "sem_frases",
  });
  assert.ok("ficha" in fichaDoReporte("x", reporte({ tipo: "print" }), hoje));
});

test("toda categoria de ficha tem orientação padrão", () => {
  for (const categoria of CATEGORIAS_FICHA) {
    assert.ok(ORIENTACAO_PADRAO[categoria].length > 20, categoria);
    assert.doesNotMatch(ORIENTACAO_PADRAO[categoria], /seguro/i);
  }
});

test("retira da base quando o reporte some, sai de aprovado ou é editado", () => {
  const aprovado = reporte();
  assert.equal(deveRetirarDaBase(aprovado, undefined), true);
  assert.equal(deveRetirarDaBase(aprovado, { ...aprovado, status: "oculto" }), true);
  assert.equal(deveRetirarDaBase(aprovado, { ...aprovado, status: "pendente" }), true);
  assert.equal(deveRetirarDaBase(aprovado, { ...aprovado, relato: "Outro texto." }), true);
  assert.equal(deveRetirarDaBase(aprovado, { ...aprovado, titulo: "Outro" }), true);
  // Curtida ou denúncia não muda o texto: a entrada fica.
  assert.equal(deveRetirarDaBase(aprovado, { ...aprovado, curtidas: 3 }), false);
  // Reporte criado agora: nada a retirar.
  assert.equal(deveRetirarDaBase(undefined, aprovado), false);
});

const esperado = { modelo: "m", dimensao: 3 };
const entradaValida = {
  ficha: fichaDoReporte("abc", reporte(), new Date()),
  vetor: [1, 0, 0],
  modelo: "m",
  dimensao: 3,
};

test("só aproveita entradas do mesmo modelo e dimensão", () => {
  const ficha = (entradaValida.ficha as { ficha: unknown }).ficha;
  const valida = { ...entradaValida, ficha };
  const entradas = entradasComunidade(
    [valida, { ...valida, modelo: "outro" }, { ...valida, vetor: [1, 0] }, null, { ficha: null }],
    esperado,
  );
  assert.equal(entradas.length, 1);
  assert.equal(entradas[0].id, "comunidade-abc");
});

test("a consulta soma o arquivo e a comunidade", () => {
  const indice: IndiceBase = {
    versaoSchema: VERSAO_SCHEMA,
    modeloEmbedding: "m",
    dimensao: 3,
    fichas: [],
  };
  const ficha = (entradaValida.ficha as { ficha: unknown }).ficha;
  const comunidade = entradasComunidade([{ ...entradaValida, ficha }], esperado);
  assert.equal(combinarIndices(indice, comunidade)?.fichas.length, 1);
  assert.equal(combinarIndices(indice, []), indice);
  assert.equal(combinarIndices(undefined, comunidade), undefined);
});
