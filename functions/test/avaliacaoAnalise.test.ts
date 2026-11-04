import assert from "node:assert/strict";
import { test } from "node:test";

import {
  encontrarDadoSemMarcador,
  resumirRodadas,
  type Rodada,
} from "../src/avaliacaoAnalise";

const rodada = (dados: Partial<Rodada>): Rodada => ({
  mensagem: "m1",
  grupo: "golpe",
  modo: "com_base",
  sinais: [],
  padrao: null,
  esperado: null,
  ...dados,
});

test("conta golpe detectado e golpe perdido", () => {
  const r = resumirRodadas(
    [
      rodada({ mensagem: "a", sinais: ["ameaca"] }),
      rodada({ mensagem: "b" }),
    ],
    "com_base",
  );
  assert.equal(r.mensagensGolpe, 2);
  assert.equal(r.golpesDetectados, 1);
  assert.deepEqual(r.golpesPerdidos, ["b"]);
});

test("mensagem legítima com sinal é falso alarme", () => {
  const r = resumirRodadas(
    [
      rodada({ mensagem: "a", grupo: "legitima", sinais: ["ameaca"] }),
      rodada({ mensagem: "b", grupo: "legitima" }),
    ],
    "com_base",
  );
  assert.equal(r.mensagensLegitimas, 2);
  assert.deepEqual(r.falsosAlarmes, ["a"]);
});

test("separa os modos", () => {
  const rodadas = [
    rodada({ modo: "com_base", sinais: ["ameaca"] }),
    rodada({ modo: "sem_base" }),
  ];
  assert.equal(resumirRodadas(rodadas, "com_base").golpesDetectados, 1);
  assert.equal(resumirRodadas(rodadas, "sem_base").golpesDetectados, 0);
});

test("repetições com sinais diferentes contam como instáveis; a ordem não importa", () => {
  const estavel = resumirRodadas(
    [
      rodada({ mensagem: "a", sinais: ["ameaca", "inducao_urgencia"] }),
      rodada({ mensagem: "a", sinais: ["inducao_urgencia", "ameaca"] }),
    ],
    "com_base",
  );
  assert.deepEqual(estavel.instaveis, []);

  const variavel = resumirRodadas(
    [
      rodada({ mensagem: "a", sinais: ["ameaca"] }),
      rodada({ mensagem: "a", sinais: ["ameaca", "inducao_urgencia"] }),
    ],
    "com_base",
  );
  assert.deepEqual(variavel.instaveis, ["a"]);
});

test("a detecção usa a maioria das repetições", () => {
  const r = resumirRodadas(
    [
      rodada({ sinais: [] }),
      rodada({ sinais: [] }),
      rodada({ sinais: ["ameaca"] }),
    ],
    "com_base",
  );
  assert.equal(r.golpesDetectados, 0);
});

test("confere a correspondência com a ficha esperada", () => {
  const r = resumirRodadas(
    [
      rodada({ mensagem: "a", esperado: "x", padrao: "x", sinais: ["s"] }),
      rodada({ mensagem: "b", esperado: "x", padrao: "y", sinais: ["s"] }),
      rodada({ mensagem: "c", esperado: "x", sinais: ["s"] }),
    ],
    "com_base",
  );
  assert.equal(r.correspondenciasCertas, 1);
  assert.deepEqual(r.correspondenciasErradas, ["b"]);
});

test("mensagem sem ficha que recebe correspondência conta como errada", () => {
  const r = resumirRodadas(
    [rodada({ mensagem: "a", padrao: "x", sinais: ["s"] })],
    "com_base",
  );
  assert.deepEqual(r.correspondenciasErradas, ["a"]);
});

test("a trava encontra dado pessoal sem marcador", () => {
  assert.equal(encontrarDadoSemMarcador("meu cpf 123.456.789-09"), "CPF");
  assert.equal(encontrarDadoSemMarcador("liga (11) 98765-4321"), "telefone");
  assert.equal(encontrarDadoSemMarcador("fala com ana@exemplo.com"), "e-mail");
});

test("a trava aceita marcadores e valores comuns", () => {
  assert.equal(
    encontrarDadoSemMarcador("CPF [CPF], telefone [TELEFONE], Pix de R$ 1.850,00"),
    null,
  );
});
