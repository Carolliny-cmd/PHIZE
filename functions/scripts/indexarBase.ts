/**
 * Gera o índice vetorial da base de conhecimento (Prompt 7.1; arquitetura,
 * seção 3.2 b) a partir das fichas catalogadas em
 * `base-conhecimento/fichas/`. Ver `base-conhecimento/README.md`.
 *
 *   npm run indexar-base                  gera ou atualiza o índice
 *   npm run indexar-base -- --verificar   só confere fichas e índice, sem API
 *
 * `--base <pasta>` troca a pasta da base (usado em testes manuais).
 */

import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";

import {
  divergenciasIndice,
  gerarEmbeddingGemini,
  montarIndice,
  serializarIndice,
  validarFicha,
  type Ficha,
  type IndiceBase,
} from "../src/baseConhecimento";
import {
  DIMENSAO_EMBEDDING,
  MODELO_EMBEDDING,
  TIMEOUT_EMBEDDING_MS,
  VARIAVEL_CHAVE_GEMINI,
} from "../src/config";

/** Esperas entre novas tentativas quando o provedor recusa ou cai. */
const ESPERAS_NOVA_TENTATIVA_MS = [2_000, 5_000, 10_000];

const PASTA_FUNCTIONS = path.resolve(__dirname, "..", "..");

function argumento(nome: string): string | undefined {
  const i = process.argv.indexOf(nome);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

function lerFichas(pasta: string): { fichas: Ficha[]; erros: string[] } {
  const fichas: Ficha[] = [];
  const erros: string[] = [];
  if (!existsSync(pasta)) {
    return { fichas, erros: [`pasta de fichas não encontrada: ${pasta}`] };
  }
  const arquivos = readdirSync(pasta)
    .filter((a) => a.endsWith(".json"))
    .sort();
  for (const arquivo of arquivos) {
    const nome = arquivo.slice(0, -".json".length);
    let dado: unknown;
    try {
      dado = JSON.parse(readFileSync(path.join(pasta, arquivo), "utf8"));
    } catch (e) {
      erros.push(`${arquivo}: JSON inválido (${(e as Error).message})`);
      continue;
    }
    const problemas = validarFicha(dado, nome);
    if (problemas.length > 0) {
      erros.push(...problemas.map((p) => `${arquivo}: ${p}`));
    } else {
      fichas.push(dado as Ficha);
    }
  }
  return { fichas, erros };
}

function lerIndice(arquivo: string): IndiceBase | undefined {
  if (!existsSync(arquivo)) return undefined;
  return JSON.parse(readFileSync(arquivo, "utf8")) as IndiceBase;
}

function chaveGemini(): string {
  if (!process.env[VARIAVEL_CHAVE_GEMINI]) {
    const envLocal = path.join(PASTA_FUNCTIONS, ".env.local");
    if (existsSync(envLocal)) process.loadEnvFile(envLocal);
  }
  const chave = process.env[VARIAVEL_CHAVE_GEMINI];
  if (!chave) {
    throw new Error(
      `${VARIAVEL_CHAVE_GEMINI} não definida (nem em functions/.env.local)`,
    );
  }
  return chave;
}

async function embeddingComNovasTentativas(
  texto: string,
  chave: string,
): Promise<number[]> {
  for (let tentativa = 0; ; tentativa++) {
    const r = await gerarEmbeddingGemini(texto, chave, {
      modelo: MODELO_EMBEDDING,
      dimensao: DIMENSAO_EMBEDDING,
      taskType: "RETRIEVAL_DOCUMENT",
      timeoutMs: TIMEOUT_EMBEDDING_MS,
    });
    if (r.status === "ok") return r.vetor;
    const espera = ESPERAS_NOVA_TENTATIVA_MS[tentativa];
    if (r.motivo === "resposta_invalida" || espera === undefined) {
      const http = r.httpStatus ? ` (HTTP ${r.httpStatus})` : "";
      throw new Error(`falha ao gerar embedding: ${r.motivo}${http}`);
    }
    console.log(`  ${r.motivo}; nova tentativa em ${espera / 1000} s`);
    await new Promise((ok) => setTimeout(ok, espera));
  }
}

async function main(): Promise<number> {
  const base = path.resolve(
    argumento("--base") ?? path.join(PASTA_FUNCTIONS, "base-conhecimento"),
  );
  const arquivoIndice = path.join(base, "indice.json");
  const configuracao = { modelo: MODELO_EMBEDDING, dimensao: DIMENSAO_EMBEDDING };

  const { fichas, erros } = lerFichas(path.join(base, "fichas"));
  if (erros.length > 0) {
    console.error("Fichas com problema — corrija antes de indexar:");
    for (const erro of erros) console.error(`  - ${erro}`);
    return 1;
  }

  const anterior = lerIndice(arquivoIndice);

  if (process.argv.includes("--verificar")) {
    const divergencias = divergenciasIndice(fichas, anterior, configuracao);
    if (divergencias.length > 0) {
      console.error("Índice desatualizado — rode `npm run indexar-base`:");
      for (const d of divergencias) console.error(`  - ${d}`);
      return 1;
    }
    console.log(`Índice em dia: ${fichas.length} ficha(s).`);
    return 0;
  }

  let chave: string | undefined;
  const resumo = await montarIndice(fichas, anterior, {
    ...configuracao,
    gerarEmbedding: (texto) => {
      chave ??= chaveGemini();
      return embeddingComNovasTentativas(texto, chave);
    },
  });

  writeFileSync(arquivoIndice, serializarIndice(resumo.indice), "utf8");
  console.log(`Índice gravado em ${path.relative(process.cwd(), arquivoIndice)}`);
  console.log(`  fichas: ${resumo.indice.fichas.length}`);
  console.log(`  embeddings gerados: ${resumo.geradas.length}`);
  console.log(`  reaproveitados: ${resumo.reaproveitadas.length}`);
  console.log(`  removidos do índice: ${resumo.removidas.length}`);
  return 0;
}

main().then(
  (codigo) => process.exit(codigo),
  (e: unknown) => {
    console.error(`Erro: ${(e as Error).message}`);
    process.exit(1);
  },
);
