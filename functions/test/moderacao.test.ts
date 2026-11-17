import assert from "node:assert/strict";
import { test } from "node:test";

import { LIMIAR_DENUNCIAS_OCULTACAO } from "../src/config";
import { deveOcultar } from "../src/moderacao";

const L = LIMIAR_DENUNCIAS_OCULTACAO;

test("o limiar é de 3 denúncias (RF11)", () => {
  assert.equal(L, 3);
});

test("pendente com 3 denúncias é ocultado", () => {
  assert.equal(deveOcultar({ status: "pendente", denuncias: 3 }, L), true);
  assert.equal(deveOcultar({ status: "pendente", denuncias: 7 }, L), true);
});

test("pendente com menos de 3 continua no feed", () => {
  assert.equal(deveOcultar({ status: "pendente", denuncias: 2 }, L), false);
});

test("aprovado pela equipe não é ocultado de novo", () => {
  assert.equal(deveOcultar({ status: "aprovado", denuncias: 5 }, L), false);
});

test("já oculto não muda", () => {
  assert.equal(deveOcultar({ status: "oculto", denuncias: 3 }, L), false);
});

test("dados fora do formato não ocultam", () => {
  assert.equal(deveOcultar(undefined, L), false);
  assert.equal(deveOcultar(null, L), false);
  assert.equal(deveOcultar({ status: "pendente", denuncias: "3" }, L), false);
  assert.equal(deveOcultar({ status: "pendente", denuncias: 3.5 }, L), false);
});
