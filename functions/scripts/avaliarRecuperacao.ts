/**
 * Mede a recuperação da base com as mensagens fictícias de
 * `base-conhecimento/avaliacao/mensagens.json`, para calibrar
 * QUANTIDADE_PADROES e LIMIAR_SIMILARIDADE (docs/calibracao-recuperacao.md).
 *
 *   npm run avaliar-recuperacao
 *
 * Mensagens cujo padrão esperado não está no índice (ficha ainda em
 * rascunho) são ignoradas e listadas. Chama a API de embeddings uma vez
 * por mensagem.
 */

import { existsSync, readFileSync } from "node:fs";
import path from "node:path";

import { gerarEmbeddingGemini, normalizar } from "../src/baseConhecimento";
import {
  DIMENSAO_EMBEDDING,
  LIMIAR_SIMILARIDADE,
  MODELO_EMBEDDING,
  QUANTIDADE_PADROES,
  TIMEOUT_EMBEDDING_MS,
  VARIAVEL_CHAVE_GEMINI,
} from "../src/config";
import { carregarIndice, recuperarPadroes } from "../src/recuperacao";

const PASTA_FUNCTIONS = path.resolve(__dirname, "..", "..");
const BASE = path.join(PASTA_FUNCTIONS, "base-conhecimento");
const ESPERAS_MS = [2_000, 5_000, 10_000];

interface Mensagens {
  golpes: { esperado: string; texto: string }[];
  semGolpe: { nome: string; texto: string }[];
}

async function embedding(texto: string, chave: string): Promise<number[]> {
  for (let tentativa = 0; ; tentativa++) {
    const r = await gerarEmbeddingGemini(texto, chave, {
      modelo: MODELO_EMBEDDING,
      dimensao: DIMENSAO_EMBEDDING,
      taskType: "RETRIEVAL_QUERY",
      timeoutMs: TIMEOUT_EMBEDDING_MS,
    });
    if (r.status === "ok") return normalizar(r.vetor);
    const espera = ESPERAS_MS[tentativa];
    if (espera === undefined) throw new Error(`falha ao gerar embedding: ${r.motivo}`);
    await new Promise((ok) => setTimeout(ok, espera));
  }
}

const f3 = (n: number) => n.toFixed(3);

async function main(): Promise<number> {
  const indice = carregarIndice(path.join(BASE, "indice.json"), {
    modelo: MODELO_EMBEDDING,
    dimensao: DIMENSAO_EMBEDDING,
  });
  if (!indice) {
    console.error("Índice ausente ou de outro modelo — rode `npm run indexar-base`.");
    return 1;
  }
  const envLocal = path.join(PASTA_FUNCTIONS, ".env.local");
  if (!process.env[VARIAVEL_CHAVE_GEMINI] && existsSync(envLocal)) {
    process.loadEnvFile(envLocal);
  }
  const chave = process.env[VARIAVEL_CHAVE_GEMINI];
  if (!chave) {
    console.error(`${VARIAVEL_CHAVE_GEMINI} não definida.`);
    return 1;
  }

  const mensagens = JSON.parse(
    readFileSync(path.join(BASE, "avaliacao", "mensagens.json"), "utf8"),
  ) as Mensagens;
  const ids = new Set(indice.fichas.map((e) => e.id));
  // Sem limiar e com todas as fichas: mostra a lista completa.
  const tudo = { quantidade: indice.fichas.length, limiar: -1 };
  const config = { quantidade: QUANTIDADE_PADROES, limiar: LIMIAR_SIMILARIDADE };

  console.log(
    `Índice: ${indice.fichas.length} fichas | quantidade ${QUANTIDADE_PADROES} | limiar ${LIMIAR_SIMILARIDADE}\n`,
  );

  const ignoradas: string[] = [];
  let primeiro = 0;
  let recuperado = 0;
  const notasCertas: number[] = [];
  console.log("Golpes (nota da ficha esperada | 1º lugar):");
  for (const { esperado, texto } of mensagens.golpes) {
    if (!ids.has(esperado)) {
      ignoradas.push(esperado);
      continue;
    }
    const q = await embedding(texto, chave);
    const lista = recuperarPadroes(q, indice, tudo);
    const certa = lista.find((p) => p.id === esperado)!;
    notasCertas.push(certa.similaridade);
    if (lista[0].id === esperado) primeiro++;
    const entra = recuperarPadroes(q, indice, config).some((p) => p.id === esperado);
    if (entra) recuperado++;
    console.log(
      `  ${entra ? "ok  " : "FORA"} ${esperado.padEnd(36)} ${f3(certa.similaridade)} | ${lista[0].id} ${f3(lista[0].similaridade)}`,
    );
  }

  let passaram = 0;
  const notasSemGolpe: number[] = [];
  console.log("\nSem golpe (melhor ficha | vai ao modelo?):");
  for (const { nome, texto } of mensagens.semGolpe) {
    const q = await embedding(texto, chave);
    const melhor = recuperarPadroes(q, indice, tudo)[0];
    notasSemGolpe.push(melhor.similaridade);
    const vai = recuperarPadroes(q, indice, config).length > 0;
    if (vai) passaram++;
    console.log(`  ${vai ? "sim" : "não"}  ${nome.padEnd(28)} ${f3(melhor.similaridade)} ${melhor.id}`);
  }

  const total = notasCertas.length;
  console.log("\nResumo:");
  console.log(`  golpes com a ficha certa em 1º lugar: ${primeiro}/${total}`);
  console.log(`  golpes com a ficha certa entre as enviadas ao modelo: ${recuperado}/${total}`);
  console.log(`  menor nota de ficha certa: ${f3(Math.min(...notasCertas))}`);
  console.log(`  maior nota sem golpe: ${f3(Math.max(...notasSemGolpe))}`);
  console.log(`  mensagens sem golpe que chegam ao modelo com padrões: ${passaram}/${notasSemGolpe.length}`);
  if (ignoradas.length > 0) {
    console.log(`  ignoradas (ficha fora do índice): ${ignoradas.join(", ")}`);
  }
  return 0;
}

main().then(
  (codigo) => process.exit(codigo),
  (e: unknown) => {
    console.error(`Erro: ${(e as Error).message}`);
    process.exit(1);
  },
);
