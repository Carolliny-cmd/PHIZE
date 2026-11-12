import assert from "node:assert/strict";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { test } from "node:test";

import {
  divergenciasIndice,
  gerarEmbeddingGemini,
  hashEntrada,
  montarIndice,
  normalizar,
  serializarIndice,
  textoParaEmbedding,
  validarFicha,
  type Ficha,
  type IndiceBase,
} from "../src/baseConhecimento";
import { DIMENSAO_EMBEDDING, MODELO_EMBEDDING } from "../src/config";

/** Ficha fictícia, só para teste — não é conteúdo catalogado. */
const fichaTeste = (id = "golpe-teste", extra: Partial<Ficha> = {}): Ficha => ({
  id,
  modalidade: "Golpe de teste",
  categoria: "falso_contato",
  canais: ["WhatsApp"],
  gatilhosLinguisticos: ["troquei de número", "me ajuda com um Pix"],
  padraoSolicitacaoFinanceira: "Pix para conta de terceiro",
  orientacaoPreventiva: "Confirme por outro canal antes de pagar.",
  fontes: [
    {
      titulo: "Cartilha fictícia",
      publicador: "Fonte de teste",
      url: "https://exemplo.test/cartilha",
      consultadoEm: "2026-11-01",
    },
  ],
  curadoria: { revisadoPor: "Equipe de teste", revisadoEm: "2026-11-02" },
  ...extra,
});

const OPCOES = { modelo: "modelo-teste", dimensao: 3 };

/** Gera vetores previsíveis e conta as chamadas. */
function embeddingFalso() {
  const chamadas: string[] = [];
  return {
    chamadas,
    gerar: async (texto: string) => {
      chamadas.push(texto);
      return [texto.length, 1, 2];
    },
  };
}

test("ficha válida não tem erros", () => {
  assert.deepEqual(validarFicha(fichaTeste(), "golpe-teste"), []);
});

test("url de fonte é opcional", () => {
  const ficha = fichaTeste();
  delete ficha.fontes[0].url;
  assert.deepEqual(validarFicha(ficha, "golpe-teste"), []);
});

test("id diferente do nome do arquivo é rejeitado", () => {
  const erros = validarFicha(fichaTeste(), "outro-nome");
  assert.equal(erros.length, 1);
  assert.match(erros[0], /nome do arquivo/);
});

test("id com maiúscula, acento ou espaço é rejeitado", () => {
  for (const id of ["Golpe", "golpe-ação", "golpe teste", "-golpe"]) {
    assert.ok(validarFicha(fichaTeste(id), id).length > 0, id);
  }
});

test("sem_indicios e categoria fora da lista são rejeitadas", () => {
  for (const categoria of ["sem_indicios", "golpe_novo"]) {
    const ficha = { ...fichaTeste(), categoria };
    assert.ok(
      validarFicha(ficha, "golpe-teste").some((e) => e.includes("categoria")),
      categoria,
    );
  }
});

test("curadoria humana é obrigatória: sem fonte ou sem revisão, rejeita", () => {
  const semFonte = { ...fichaTeste(), fontes: [] };
  assert.ok(validarFicha(semFonte, "golpe-teste").some((e) => e.includes("fontes")));

  const { curadoria: _ignorada, ...semCuradoria } = fichaTeste();
  assert.ok(
    validarFicha(semCuradoria, "golpe-teste").some((e) => e.includes("curadoria")),
  );
});

test("datas e url de fonte são validadas", () => {
  const ficha = fichaTeste();
  ficha.fontes[0].consultadoEm = "2026-02-30";
  ficha.fontes[0].url = "http://sem-tls.test";
  ficha.curadoria.revisadoEm = "02/11/2026";
  const erros = validarFicha(ficha, "golpe-teste");
  assert.ok(erros.some((e) => e.includes("consultadoEm")));
  assert.ok(erros.some((e) => e.includes("url")));
  assert.ok(erros.some((e) => e.includes("revisadoEm")));
});

test("campos vazios, listas vazias e campos desconhecidos são rejeitados", () => {
  const ficha = {
    ...fichaTeste(),
    modalidade: "  ",
    gatilhosLinguisticos: [],
    observacao: "campo extra",
  };
  const erros = validarFicha(ficha, "golpe-teste");
  assert.ok(erros.some((e) => e.includes("modalidade")));
  assert.ok(erros.some((e) => e.includes("gatilhosLinguisticos")));
  assert.ok(erros.some((e) => e.includes("observacao")));
});

test("situacoesLegitimas é opcional, mas, se vier, segue as regras de lista", () => {
  assert.deepEqual(validarFicha(fichaTeste(), "golpe-teste"), []);
  assert.deepEqual(
    validarFicha(
      { ...fichaTeste(), situacoesLegitimas: ["aviso real do banco"] },
      "golpe-teste",
    ),
    [],
  );
  const vazia = validarFicha(
    { ...fichaTeste(), situacoesLegitimas: [] },
    "golpe-teste",
  );
  assert.ok(vazia.some((e) => e.includes("situacoesLegitimas")));
  const itemVazio = validarFicha(
    { ...fichaTeste(), situacoesLegitimas: ["  "] },
    "golpe-teste",
  );
  assert.ok(itemVazio.some((e) => e.includes("situacoesLegitimas[0]")));
});

test("situações legítimas não entram no embedding nem mudam o hash", () => {
  const com = { ...fichaTeste(), situacoesLegitimas: ["aviso real do banco"] };
  assert.doesNotMatch(textoParaEmbedding(com), /aviso real do banco/);
  assert.equal(hashEntrada(com, "m", 3), hashEntrada(fichaTeste(), "m", 3));
});

test("arquivo que não é objeto é rejeitado", () => {
  assert.equal(validarFicha([fichaTeste()], "golpe-teste").length, 1);
  assert.equal(validarFicha(null, "golpe-teste").length, 1);
});

test("texto do embedding leva gatilhos e pedido, mas não orientação nem fontes", () => {
  const texto = textoParaEmbedding(fichaTeste());
  assert.match(texto, /troquei de número/);
  assert.match(texto, /Pix para conta de terceiro/);
  assert.doesNotMatch(texto, /Confirme por outro canal/);
  assert.doesNotMatch(texto, /Cartilha fictícia/);
});

test("hash muda com o texto embutido e com o modelo, não com a orientação", () => {
  const base = hashEntrada(fichaTeste(), "m", 3);
  assert.equal(
    hashEntrada(fichaTeste("golpe-teste", { orientacaoPreventiva: "Outra." }), "m", 3),
    base,
  );
  assert.notEqual(
    hashEntrada(fichaTeste("golpe-teste", { gatilhosLinguisticos: ["outro"] }), "m", 3),
    base,
  );
  assert.notEqual(hashEntrada(fichaTeste(), "m2", 3), base);
  assert.notEqual(hashEntrada(fichaTeste(), "m", 4), base);
});

test("normalizar produz norma 1 e rejeita vetor nulo", () => {
  const v = normalizar([3, 4]);
  assert.deepEqual(v, [0.6, 0.8]);
  assert.throws(() => normalizar([0, 0]));
});

test("montarIndice ordena por id e gera um embedding por ficha", async () => {
  const falso = embeddingFalso();
  const r = await montarIndice(
    [fichaTeste("b-golpe"), fichaTeste("a-golpe")],
    undefined,
    { ...OPCOES, gerarEmbedding: falso.gerar },
  );
  assert.deepEqual(r.indice.fichas.map((e) => e.id), ["a-golpe", "b-golpe"]);
  assert.equal(falso.chamadas.length, 2);
  assert.deepEqual(r.geradas, ["a-golpe", "b-golpe"]);
  for (const e of r.indice.fichas) {
    const norma = Math.sqrt(e.vetor.reduce((s, x) => s + x * x, 0));
    assert.ok(Math.abs(norma - 1) < 1e-5);
  }
});

test("ficha sem mudança reaproveita o vetor; alterada gera de novo", async () => {
  const primeira = await montarIndice(
    [fichaTeste("a-golpe"), fichaTeste("b-golpe")],
    undefined,
    { ...OPCOES, gerarEmbedding: embeddingFalso().gerar },
  );

  const falso = embeddingFalso();
  const alterada = fichaTeste("b-golpe", { gatilhosLinguisticos: ["novo gatilho"] });
  const segunda = await montarIndice(
    [fichaTeste("a-golpe"), alterada],
    primeira.indice,
    { ...OPCOES, gerarEmbedding: falso.gerar },
  );
  assert.deepEqual(segunda.reaproveitadas, ["a-golpe"]);
  assert.deepEqual(segunda.geradas, ["b-golpe"]);
  assert.equal(falso.chamadas.length, 1);
});

test("só a orientação mudou: reaproveita o vetor e atualiza a ficha", async () => {
  const primeira = await montarIndice([fichaTeste()], undefined, {
    ...OPCOES,
    gerarEmbedding: embeddingFalso().gerar,
  });
  const falso = embeddingFalso();
  const nova = fichaTeste("golpe-teste", { orientacaoPreventiva: "Ligue para o banco." });
  const segunda = await montarIndice([nova], primeira.indice, {
    ...OPCOES,
    gerarEmbedding: falso.gerar,
  });
  assert.equal(falso.chamadas.length, 0);
  assert.equal(segunda.indice.fichas[0].ficha.orientacaoPreventiva, "Ligue para o banco.");
});

test("troca de modelo descarta todos os vetores anteriores", async () => {
  const primeira = await montarIndice([fichaTeste()], undefined, {
    ...OPCOES,
    gerarEmbedding: embeddingFalso().gerar,
  });
  const falso = embeddingFalso();
  await montarIndice([fichaTeste()], primeira.indice, {
    ...OPCOES,
    modelo: "outro-modelo",
    gerarEmbedding: falso.gerar,
  });
  assert.equal(falso.chamadas.length, 1);
});

test("ficha removida sai do índice", async () => {
  const primeira = await montarIndice(
    [fichaTeste("a-golpe"), fichaTeste("b-golpe")],
    undefined,
    { ...OPCOES, gerarEmbedding: embeddingFalso().gerar },
  );
  const segunda = await montarIndice([fichaTeste("a-golpe")], primeira.indice, {
    ...OPCOES,
    gerarEmbedding: embeddingFalso().gerar,
  });
  assert.deepEqual(segunda.removidas, ["b-golpe"]);
  assert.deepEqual(segunda.indice.fichas.map((e) => e.id), ["a-golpe"]);
});

test("embedding com dimensão errada interrompe a indexação", async () => {
  await assert.rejects(
    montarIndice([fichaTeste()], undefined, {
      ...OPCOES,
      gerarEmbedding: async () => [1, 2],
    }),
    /dimensões/,
  );
});

test("mesma base produz o mesmo arquivo de índice", async () => {
  const gerar = async () => {
    const r = await montarIndice([fichaTeste("b"), fichaTeste("a")], undefined, {
      ...OPCOES,
      gerarEmbedding: embeddingFalso().gerar,
    });
    return serializarIndice(r.indice);
  };
  assert.equal(await gerar(), await gerar());
});

test("índice serializado volta igual e mantém cada vetor numa linha", async () => {
  const r = await montarIndice([fichaTeste()], undefined, {
    ...OPCOES,
    gerarEmbedding: embeddingFalso().gerar,
  });
  const texto = serializarIndice(r.indice);
  assert.deepEqual(JSON.parse(texto), r.indice);
  assert.match(texto, /"vetor": \[[^\n]+\]/);
});

test("divergenciasIndice aponta ficha nova, alterada, removida e modelo trocado", async () => {
  const { indice } = await montarIndice(
    [fichaTeste("a-golpe"), fichaTeste("b-golpe")],
    undefined,
    { ...OPCOES, gerarEmbedding: embeddingFalso().gerar },
  );
  assert.deepEqual(
    divergenciasIndice([fichaTeste("a-golpe"), fichaTeste("b-golpe")], indice, OPCOES),
    [],
  );

  const problemas = divergenciasIndice(
    [
      fichaTeste("a-golpe", { orientacaoPreventiva: "Mudou." }),
      fichaTeste("c-golpe"),
    ],
    indice,
    OPCOES,
  );
  assert.equal(problemas.length, 3);
  assert.ok(problemas.some((p) => p.includes('"a-golpe" alterada')));
  assert.ok(problemas.some((p) => p.includes('"c-golpe" fora')));
  assert.ok(problemas.some((p) => p.includes('"b-golpe"')));

  assert.ok(
    divergenciasIndice([], indice, { ...OPCOES, modelo: "outro" }).some((p) =>
      p.includes("outro"),
    ),
  );
  assert.deepEqual(divergenciasIndice([], undefined, OPCOES), ["índice ausente"]);
});

const fetchJson = (corpo: unknown, status = 200): typeof fetch =>
  (async () => new Response(JSON.stringify(corpo), { status })) as typeof fetch;

const OPCOES_GEMINI = {
  modelo: "modelo-teste",
  dimensao: 3,
  taskType: "RETRIEVAL_DOCUMENT" as const,
  timeoutMs: 1000,
};

test("gerarEmbeddingGemini: devolve o vetor e envia chave no cabeçalho", async () => {
  let pedido: RequestInit | undefined;
  let endereco = "";
  const fetchFn = (async (url: string, init: RequestInit) => {
    endereco = url;
    pedido = init;
    return new Response(JSON.stringify({ embedding: { values: [0.1, 0.2, 0.3] } }));
  }) as unknown as typeof fetch;

  const r = await gerarEmbeddingGemini("texto", "chave-teste", { ...OPCOES_GEMINI, fetchFn });
  assert.deepEqual(r, { status: "ok", vetor: [0.1, 0.2, 0.3] });
  assert.doesNotMatch(endereco, /chave-teste/);
  assert.equal((pedido?.headers as Record<string, string>)["x-goog-api-key"], "chave-teste");
  const corpo = JSON.parse(String(pedido?.body));
  assert.equal(corpo.taskType, "RETRIEVAL_DOCUMENT");
  assert.equal(corpo.outputDimensionality, 3);
});

test("gerarEmbeddingGemini: 429, 503, rede e corpo inválido viram falha", async () => {
  assert.deepEqual(
    await gerarEmbeddingGemini("t", "k", { ...OPCOES_GEMINI, fetchFn: fetchJson({}, 429) }),
    { status: "falha", motivo: "limite_provedor", httpStatus: 429 },
  );
  assert.deepEqual(
    await gerarEmbeddingGemini("t", "k", { ...OPCOES_GEMINI, fetchFn: fetchJson({}, 503) }),
    { status: "falha", motivo: "indisponivel", httpStatus: 503 },
  );
  const semRede = (async () => {
    throw new TypeError("fetch failed");
  }) as typeof fetch;
  assert.deepEqual(
    await gerarEmbeddingGemini("t", "k", { ...OPCOES_GEMINI, fetchFn: semRede }),
    { status: "falha", motivo: "indisponivel" },
  );
  for (const corpo of [{}, { embedding: { values: [] } }, { embedding: { values: ["x"] } }]) {
    assert.deepEqual(
      await gerarEmbeddingGemini("t", "k", { ...OPCOES_GEMINI, fetchFn: fetchJson(corpo) }),
      { status: "falha", motivo: "resposta_invalida" },
    );
  }
});

test("gerarEmbeddingGemini: timeout vira falha por timeout", async () => {
  const lento = ((_: string, init: RequestInit) =>
    new Promise((_ok, falha) => {
      init.signal?.addEventListener("abort", () => falha(new Error("abortado")));
    })) as unknown as typeof fetch;
  const r = await gerarEmbeddingGemini("t", "k", {
    ...OPCOES_GEMINI,
    timeoutMs: 10,
    fetchFn: lento,
  });
  assert.deepEqual(r, { status: "falha", motivo: "timeout" });
});

/**
 * Guarda do repositório: as fichas versionadas são válidas e o índice
 * versionado está em dia com elas e com o modelo configurado.
 */
test("base versionada: fichas válidas e índice em dia", () => {
  const base = path.resolve(__dirname, "..", "..", "base-conhecimento");
  const pastaFichas = path.join(base, "fichas");
  const fichas: Ficha[] = [];
  for (const arquivo of readdirSync(pastaFichas).filter((a) => a.endsWith(".json"))) {
    const dado = JSON.parse(readFileSync(path.join(pastaFichas, arquivo), "utf8"));
    assert.deepEqual(validarFicha(dado, arquivo.slice(0, -5)), [], arquivo);
    fichas.push(dado as Ficha);
  }
  const arquivoIndice = path.join(base, "indice.json");
  const indice = existsSync(arquivoIndice)
    ? (JSON.parse(readFileSync(arquivoIndice, "utf8")) as IndiceBase)
    : undefined;
  assert.deepEqual(
    divergenciasIndice(fichas, indice, {
      modelo: MODELO_EMBEDDING,
      dimensao: DIMENSAO_EMBEDDING,
    }),
    [],
  );
});
