/**
 * Mede a recuperação da base com mensagens fictícias, para calibrar
 * QUANTIDADE_PADROES e LIMIAR_SIMILARIDADE (docs/calibracao-recuperacao.md).
 *
 *   npm run avaliar-recuperacao                          (mensagens.json, ajuste)
 *   npm run avaliar-recuperacao -- --arquivo teste.json  (conjunto de teste)
 *
 * Antes de chamar a API, aplica a trava contra cópia: um conjunto de teste
 * que repete frase de ficha é recusado (`scripts/conjuntoAvaliacao.ts`).
 *
 * Golpes cujo padrão esperado não está no índice (ficha em rascunho) são
 * ignorados e listados. Golpes com `esperado` nulo são de modalidades fora
 * da base: o certo é nenhuma ficha passar do limiar, ou o modelo recusar a
 * correspondência. Chama a API de embeddings uma vez por mensagem. O
 * relatório em `avaliacao/relatorios/` guarda ids e notas, nunca o texto.
 */

import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";

import { encontrarDadoSemMarcador } from "../src/avaliacaoAnalise";
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
import {
  BASE,
  PASTA_FUNCTIONS,
  conferirSobreposicao,
  lerConjunto,
  rotulo,
} from "./conjuntoAvaliacao";

const ESPERAS_MS = [2_000, 5_000, 10_000];

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

interface PorEstilo {
  total: number;
  primeiro: number;
  recuperado: number;
}

async function main(): Promise<number> {
  const i = process.argv.indexOf("--arquivo");
  const nomeArquivo = i >= 0 ? process.argv[i + 1] : "mensagens.json";
  const conjunto = lerConjunto(nomeArquivo);

  // Travas antes de qualquer chamada à API.
  if (!conferirSobreposicao(conjunto, nomeArquivo)) return 1;
  const todas = [...conjunto.golpes, ...conjunto.semGolpe];
  for (const [j, m] of todas.entries()) {
    const dado = encontrarDadoSemMarcador(m.texto);
    if (dado) {
      console.error(`Mensagem ${rotulo(m, j, "mensagem")} tem ${dado} sem marcador. Nada foi enviado.`);
      return 1;
    }
  }

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

  const ids = new Set(indice.fichas.map((e) => e.id));
  // Sem limiar e com todas as fichas: mostra a lista completa.
  const tudo = { quantidade: indice.fichas.length, limiar: -1 };
  const config = { quantidade: QUANTIDADE_PADROES, limiar: LIMIAR_SIMILARIDADE };

  console.log(
    `\n${nomeArquivo} | índice: ${indice.fichas.length} fichas | quantidade ${QUANTIDADE_PADROES} | limiar ${LIMIAR_SIMILARIDADE}\n`,
  );

  const ignoradas: string[] = [];
  const porEstilo = new Map<string, PorEstilo>();
  const notasCertas: number[] = [];
  const golpesRelatorio: object[] = [];
  let primeiro = 0;
  let recuperado = 0;

  console.log("Golpes da base (nota da ficha esperada | 1º lugar):");
  for (const [j, m] of conjunto.golpes.entries()) {
    const id = rotulo(m, j, "golpe");
    const esperado = m.esperado ?? null;
    if (esperado === null) continue;
    if (!ids.has(esperado)) {
      ignoradas.push(id);
      continue;
    }
    const q = await embedding(m.texto, chave);
    const lista = recuperarPadroes(q, indice, tudo);
    const posicao = lista.findIndex((p) => p.id === esperado) + 1;
    const certa = lista[posicao - 1];
    const enviadas = recuperarPadroes(q, indice, config);
    const entra = enviadas.some((p) => p.id === esperado);
    notasCertas.push(certa.similaridade);
    if (posicao === 1) primeiro++;
    if (entra) recuperado++;

    const estilo = m.estilo ?? "sem estilo";
    const e = porEstilo.get(estilo) ?? { total: 0, primeiro: 0, recuperado: 0 };
    e.total++;
    if (posicao === 1) e.primeiro++;
    if (entra) e.recuperado++;
    porEstilo.set(estilo, e);

    golpesRelatorio.push({
      id,
      esperado,
      estilo,
      notaEsperada: certa.similaridade,
      posicao,
      primeiro: { id: lista[0].id, nota: lista[0].similaridade },
      enviadas: enviadas.map((p) => p.id),
    });
    console.log(
      `  ${entra ? "ok  " : "FORA"} ${id.padEnd(26)} ${esperado.padEnd(36)} ${f3(certa.similaridade)} (${posicao}º) | ${lista[0].id} ${f3(lista[0].similaridade)}`,
    );
  }

  // Golpes de modalidade fora da base e mensagens legítimas: o que importa é
  // quanto se aproximam da ficha mais parecida e se chegam ao modelo.
  const semFicha = async (lista: { m: (typeof todas)[number]; id: string }[]) => {
    const linhas: { id: string; melhor: string; nota: number; vai: boolean }[] = [];
    for (const { m, id } of lista) {
      const q = await embedding(m.texto, chave);
      const melhor = recuperarPadroes(q, indice, tudo)[0];
      const vai = recuperarPadroes(q, indice, config).length > 0;
      linhas.push({ id, melhor: melhor.id, nota: melhor.similaridade, vai });
      console.log(`  ${vai ? "sim" : "não"}  ${id.padEnd(28)} ${f3(melhor.similaridade)} ${melhor.id}`);
    }
    return linhas;
  };

  const foraDaBase = conjunto.golpes
    .map((m, j) => ({ m, id: rotulo(m, j, "golpe") }))
    .filter(({ m }) => (m.esperado ?? null) === null);
  let fora: Awaited<ReturnType<typeof semFicha>> = [];
  if (foraDaBase.length > 0) {
    console.log("\nGolpes fora da base (melhor ficha | vai ao modelo?):");
    fora = await semFicha(foraDaBase);
  }

  console.log("\nSem golpe (melhor ficha | vai ao modelo?):");
  const legitimas = await semFicha(
    conjunto.semGolpe.map((m, j) => ({ m, id: rotulo(m, j, "legitima") })),
  );

  const total = notasCertas.length;
  const notasLegitimas = legitimas.map((l) => l.nota);
  const passaram = legitimas.filter((l) => l.vai).length;
  const resumo = {
    golpesAvaliados: total,
    primeiroLugar: primeiro,
    entreEnviadas: recuperado,
    menorNotaCerta: Math.min(...notasCertas),
    maiorNotaSemGolpe: Math.max(...notasLegitimas),
    legitimasQueChegamAoModelo: passaram,
    legitimas: legitimas.length,
    foraDaBaseQueChegamAoModelo: fora.filter((l) => l.vai).length,
    foraDaBase: fora.length,
    porEstilo: Object.fromEntries(porEstilo),
    ignoradas,
  };

  console.log("\nResumo:");
  console.log(`  golpes com a ficha certa em 1º lugar: ${primeiro}/${total}`);
  console.log(`  golpes com a ficha certa entre as enviadas ao modelo: ${recuperado}/${total}`);
  for (const [estilo, e] of porEstilo) {
    console.log(`    ${estilo.padEnd(10)} 1º lugar ${e.primeiro}/${e.total} | enviada ${e.recuperado}/${e.total}`);
  }
  console.log(`  menor nota de ficha certa: ${f3(resumo.menorNotaCerta)}`);
  console.log(`  maior nota sem golpe: ${f3(resumo.maiorNotaSemGolpe)}`);
  console.log(`  mensagens sem golpe que chegam ao modelo com padrões: ${passaram}/${legitimas.length}`);
  if (fora.length > 0) {
    console.log(`  golpes fora da base que chegam ao modelo com padrões: ${resumo.foraDaBaseQueChegamAoModelo}/${fora.length}`);
  }
  if (ignoradas.length > 0) {
    console.log(`  ignoradas (ficha fora do índice): ${ignoradas.join(", ")}`);
  }

  const pasta = path.join(BASE, "avaliacao", "relatorios");
  mkdirSync(pasta, { recursive: true });
  const nome = `${new Date().toISOString().slice(0, 10)}-recuperacao-${path.parse(nomeArquivo).name}.json`;
  writeFileSync(
    path.join(pasta, nome),
    `${JSON.stringify(
      {
        modeloEmbedding: MODELO_EMBEDDING,
        quantidade: QUANTIDADE_PADROES,
        limiar: LIMIAR_SIMILARIDADE,
        resumo,
        golpes: golpesRelatorio,
        foraDaBase: fora,
        semGolpe: legitimas,
      },
      null,
      2,
    )}\n`,
  );
  console.log(`\nRelatório: avaliacao/relatorios/${nome}`);
  return 0;
}

main().then(
  (codigo) => process.exit(codigo),
  (e: unknown) => {
    console.error(`Erro: ${(e as Error).message}`);
    process.exit(1);
  },
);
