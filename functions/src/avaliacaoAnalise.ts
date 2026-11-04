/**
 * Cálculo das métricas da comparação com e sem a base de conhecimento
 * (`scripts/avaliarAnalise.ts`). Não usa os pesos do score: "detectou" é ter
 * ao menos um sinal, o que basta para tirar a mensagem da faixa verde segundo
 * `docs/score-calibracao.md`, sem duplicar números daquele documento.
 */

export type ModoAvaliacao = "com_base" | "sem_base";

export interface Rodada {
  mensagem: string;
  grupo: "golpe" | "legitima";
  modo: ModoAvaliacao;
  sinais: string[];
  padrao: string | null;
  /** Ficha que a mensagem deveria encontrar; nula quando nenhuma cobre. */
  esperado: string | null;
}

export interface ResumoModo {
  mensagensGolpe: number;
  golpesDetectados: number;
  golpesPerdidos: string[];
  mensagensLegitimas: number;
  falsosAlarmes: string[];
  correspondenciasCertas: number;
  correspondenciasErradas: string[];
  instaveis: string[];
}

/** Maioria das repetições, com empate contando como detectado. */
function detectou(rodadas: Rodada[]): boolean {
  const comSinal = rodadas.filter((r) => r.sinais.length > 0).length;
  return comSinal * 2 >= rodadas.length;
}

function instavel(rodadas: Rodada[]): boolean {
  const conjuntos = new Set(rodadas.map((r) => [...r.sinais].sort().join(",")));
  return conjuntos.size > 1;
}

export function resumirRodadas(rodadas: Rodada[], modo: ModoAvaliacao): ResumoModo {
  const porMensagem = new Map<string, Rodada[]>();
  for (const rodada of rodadas) {
    if (rodada.modo !== modo) continue;
    porMensagem.set(rodada.mensagem, [
      ...(porMensagem.get(rodada.mensagem) ?? []),
      rodada,
    ]);
  }

  const resumo: ResumoModo = {
    mensagensGolpe: 0,
    golpesDetectados: 0,
    golpesPerdidos: [],
    mensagensLegitimas: 0,
    falsosAlarmes: [],
    correspondenciasCertas: 0,
    correspondenciasErradas: [],
    instaveis: [],
  };

  for (const [mensagem, grupo] of porMensagem) {
    const [primeira] = grupo;
    if (instavel(grupo)) resumo.instaveis.push(mensagem);

    if (primeira.grupo === "legitima") {
      resumo.mensagensLegitimas++;
      if (detectou(grupo)) resumo.falsosAlarmes.push(mensagem);
      continue;
    }

    resumo.mensagensGolpe++;
    if (detectou(grupo)) resumo.golpesDetectados++;
    else resumo.golpesPerdidos.push(mensagem);

    const esperado = primeira.esperado;
    const padroes = grupo.map((r) => r.padrao).filter((p) => p !== null);
    if (esperado !== null && padroes.includes(esperado)) {
      resumo.correspondenciasCertas++;
    } else if (padroes.length > 0) {
      resumo.correspondenciasErradas.push(mensagem);
    }
  }
  return resumo;
}

/**
 * Trava de segurança antes de enviar ao provedor: as mensagens de avaliação
 * não podem ter dado pessoal sem marcador, enquanto valer a exceção do nível
 * gratuito (RNF07). Devolve o que foi encontrado, sem repetir o valor.
 */
export function encontrarDadoSemMarcador(texto: string): string | null {
  if (/\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/.test(texto)) return "CPF";
  if (/\(?\b\d{2}\)?[\s-]?9?\d{4}[\s-]?\d{4}\b/.test(texto)) return "telefone";
  if (/[\w.+-]+@[\w-]+\.[\w.-]+/.test(texto)) return "e-mail";
  return null;
}
