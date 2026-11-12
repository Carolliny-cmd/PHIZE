/**
 * Compara a análise com e sem a base de conhecimento, para medir o diferencial
 * do Phize (Fase 9, item 3).
 *
 *   npm run avaliar-analise -- --arquivo independente.json --repeticoes 3
 *
 * Opções: --arquivo (em base-conhecimento/avaliacao/, padrão independente.json),
 * --repeticoes (padrão 3), --limite (mensagens de cada grupo), --espera (ms
 * entre chamadas, padrão 4000), --retomar (relatório em avaliacao/relatorios/
 * cujas chamadas que falharam serão refeitas; as rodadas já obtidas são
 * mantidas e o mesmo relatório é regravado).
 *
 * Depois de 3 falhas seguidas (limite da API, em geral), a rodada para e grava
 * o que conseguiu; dá para continuar depois com --retomar.
 *
 * Só aceita mensagens fictícias ou públicas: a chave em uso está no nível
 * gratuito (exceção temporária ao RNF07). O relatório grava só identificadores
 * e sinais, nunca o texto das mensagens.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";

import { analisarTextoGemini } from "../src/analiseTexto";
import {
  encontrarDadoSemMarcador,
  resumirRodadas,
  type ModoAvaliacao,
  type ResumoModo,
  type Rodada,
} from "../src/avaliacaoAnalise";
import {
  DIMENSAO_EMBEDDING,
  LIMIAR_SIMILARIDADE,
  MODELO_EMBEDDING,
  MODELO_GEMINI_PADRAO,
  QUANTIDADE_PADROES,
  TIMEOUT_EMBEDDING_CONSULTA_MS,
  TIMEOUT_LLM_MS,
  VARIAVEL_CHAVE_GEMINI,
  VARIAVEL_MODELO_GEMINI,
} from "../src/config";
import {
  carregarIndice,
  consultarBase,
  type PadraoRecuperado,
} from "../src/recuperacao";
import { conferirSobreposicao, lerConjunto } from "./conjuntoAvaliacao";

const PASTA_FUNCTIONS = path.resolve(__dirname, "..", "..");
const BASE = path.join(PASTA_FUNCTIONS, "base-conhecimento");
const ESPERAS_FALHA_MS = [5_000, 15_000, 30_000, 60_000];

interface MensagemArquivo {
  id?: string;
  nome?: string;
  esperado?: string | null;
  texto: string;
}

interface Mensagem {
  id: string;
  grupo: Rodada["grupo"];
  esperado: string | null;
  texto: string;
}

function opcao(nome: string, padrao: string): string {
  const i = process.argv.indexOf(`--${nome}`);
  return i >= 0 ? process.argv[i + 1] : padrao;
}

function carregarMensagens(arquivo: string, limite: number): Mensagem[] {
  const dados = JSON.parse(readFileSync(arquivo, "utf8")) as {
    golpes: MensagemArquivo[];
    semGolpe: MensagemArquivo[];
  };
  const golpes = dados.golpes.slice(0, limite).map((m, i): Mensagem => ({
    id: m.id ?? m.esperado ?? `golpe-${i + 1}`,
    grupo: "golpe",
    esperado: m.esperado ?? null,
    texto: m.texto,
  }));
  const legitimas = dados.semGolpe.slice(0, limite).map((m, i): Mensagem => ({
    id: m.id ?? m.nome ?? `legitima-${i + 1}`,
    grupo: "legitima",
    esperado: null,
    texto: m.texto,
  }));
  return [...golpes, ...legitimas];
}

function imprimir(modo: ModoAvaliacao, r: ResumoModo): void {
  console.log(`\n${modo === "com_base" ? "COM a base" : "SEM a base"}`);
  console.log(`  golpes detectados: ${r.golpesDetectados} de ${r.mensagensGolpe}`);
  console.log(`  falsos alarmes: ${r.falsosAlarmes.length} de ${r.mensagensLegitimas}`);
  if (modo === "com_base") {
    console.log(`  correspondências certas: ${r.correspondenciasCertas}`);
    console.log(`  correspondências erradas: ${r.correspondenciasErradas.join(", ") || "nenhuma"}`);
  }
  console.log(`  golpes perdidos: ${r.golpesPerdidos.join(", ") || "nenhum"}`);
  console.log(`  falsos alarmes em: ${r.falsosAlarmes.join(", ") || "nenhuma"}`);
  console.log(`  mensagens com sinais instáveis: ${r.instaveis.length}`);
}

async function principal(): Promise<void> {
  process.loadEnvFile(path.join(PASTA_FUNCTIONS, ".env.local"));
  const chave = process.env[VARIAVEL_CHAVE_GEMINI];
  if (!chave) throw new Error(`${VARIAVEL_CHAVE_GEMINI} não configurada.`);

  const nomeArquivo = opcao("arquivo", "independente.json");
  const arquivo = path.join(BASE, "avaliacao", nomeArquivo);
  if (!existsSync(arquivo)) throw new Error(`Arquivo não encontrado: ${nomeArquivo}`);
  const repeticoes = Number(opcao("repeticoes", "3"));
  const limite = Number(opcao("limite", "100000"));
  const espera = Number(opcao("espera", "4000"));
  const modelo = process.env[VARIAVEL_MODELO_GEMINI] || MODELO_GEMINI_PADRAO;

  if (!conferirSobreposicao(lerConjunto(nomeArquivo), nomeArquivo)) {
    throw new Error("Conjunto de teste recusado pela trava contra cópia.");
  }

  const mensagens = carregarMensagens(arquivo, limite);
  for (const m of mensagens) {
    const dado = encontrarDadoSemMarcador(m.texto);
    if (dado) throw new Error(`Mensagem ${m.id} tem ${dado} sem marcador. Nada foi enviado.`);
  }

  const indice = carregarIndice(path.join(BASE, "indice.json"), {
    modelo: MODELO_EMBEDDING,
    dimensao: DIMENSAO_EMBEDDING,
  });
  if (!indice) throw new Error("Índice da base indisponível.");

  const pasta = path.join(BASE, "avaliacao", "relatorios");
  const retomar = opcao("retomar", "");
  const anterior = retomar
    ? (JSON.parse(readFileSync(path.join(pasta, retomar), "utf8")) as {
        repeticoes: number;
        falhas: string[];
        rodadas: Rodada[];
      })
    : null;
  const pendentes = anterior ? new Set(anterior.falhas) : null;

  const rodadas: Rodada[] = anterior ? [...anterior.rodadas] : [];
  const falhas: string[] = [];

  const analisar = async (m: Mensagem, modo: ModoAvaliacao) => {
    for (let tentativa = 0; ; tentativa++) {
      let padroes: PadraoRecuperado[] = [];
      if (modo === "com_base") {
        const base = await consultarBase(m.texto, chave, {
          indice,
          quantidade: QUANTIDADE_PADROES,
          limiar: LIMIAR_SIMILARIDADE,
          timeoutMs: TIMEOUT_EMBEDDING_CONSULTA_MS * 3,
        });
        if (base.status === "consultada") padroes = base.padroes;
      }
      const r = await analisarTextoGemini(m.texto, chave, {
        modelo,
        timeoutMs: TIMEOUT_LLM_MS * 2,
        padroes,
      });
      if (r.status === "concluida") return r.analise;
      const pausa = ESPERAS_FALHA_MS[tentativa];
      if (pausa === undefined) return null;
      await new Promise((ok) => setTimeout(ok, pausa));
    }
  };

  const vezes = anterior ? 1 : repeticoes;
  const chamadas = mensagens.flatMap((m) =>
    (["com_base", "sem_base"] as const)
      .filter((modo) => !pendentes || pendentes.has(`${m.id} (${modo})`))
      .flatMap((modo) => Array.from({ length: vezes }, () => ({ m, modo }))),
  );
  const total = chamadas.length;
  let feitas = 0;
  let falhasSeguidas = 0;
  for (const [n, { m, modo }] of chamadas.entries()) {
    if (falhasSeguidas >= 3) {
      falhas.push(...chamadas.slice(n).map((c) => `${c.m.id} (${c.modo})`));
      console.log("3 falhas seguidas: parando. Continue depois com --retomar.");
      break;
    }
    const analise = await analisar(m, modo);
    feitas++;
    falhasSeguidas = analise ? 0 : falhasSeguidas + 1;
    if (analise) {
      rodadas.push({
        mensagem: m.id,
        grupo: m.grupo,
        modo,
        sinais: analise.sinais,
        padrao: analise.padraoCorrespondente,
        esperado: m.esperado,
      });
    } else {
      falhas.push(`${m.id} (${modo})`);
    }
    console.log(`${feitas}/${total}`);
    await new Promise((ok) => setTimeout(ok, espera));
  }

  const comBase = resumirRodadas(rodadas, "com_base");
  const semBase = resumirRodadas(rodadas, "sem_base");
  imprimir("com_base", comBase);
  imprimir("sem_base", semBase);
  if (falhas.length > 0) console.log(`\nFalhas após as novas tentativas: ${falhas.length}`);

  mkdirSync(pasta, { recursive: true });
  const nome =
    retomar || `${new Date().toISOString().slice(0, 10)}-${path.parse(nomeArquivo).name}.json`;
  const relatorio = {
    modelo,
    repeticoes: anterior ? anterior.repeticoes : repeticoes,
    comBase,
    semBase,
    falhas,
    rodadas,
  };
  writeFileSync(path.join(pasta, nome), `${JSON.stringify(relatorio, null, 2)}\n`);
  console.log(`\nRelatório: avaliacao/relatorios/${nome}`);
}

principal().catch((erro: Error) => {
  console.error(erro.message);
  process.exitCode = 1;
});
