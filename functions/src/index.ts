/**
 * Camada intermediária do Phize (arquitetura, seção 2 — Proteção de
 * Credenciais): as chaves das APIs de terceiros ficam no servidor e nunca
 * no pacote do app.
 *
 * Nesta fase roda apenas no emulador local (docs/ROADMAP.md, Fase 5). O
 * mesmo código é publicado depois sem alteração; muda só a URL que o app
 * recebe por configuração.
 *
 * Privacidade: nenhum log desta Function contém a URL ou o domínio
 * consultados, nem o texto analisado. Ambos chegam no corpo do POST (e não
 * na URL da chamada) para não aparecer nos registros de requisição do
 * emulador ou do Cloud Run.
 *
 * Não há endpoint de OCR: a extração de caracteres é embarcada no
 * dispositivo e a imagem nunca sai dele (RNF06; decisão de 2026-10-07).
 */
import path from "node:path";

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";

import { analisarTextoGemini, textoValido } from "./analiseTexto";
import {
  DIMENSAO_EMBEDDING,
  JANELA_LIMITE_MS,
  LIMIAR_DENUNCIAS_OCULTACAO,
  LIMIAR_SIMILARIDADE,
  LIMITE_ANALISES_TEXTO_POR_USUARIO,
  LIMITE_REQUISICOES_POR_USUARIO,
  MODELO_EMBEDDING,
  MODELO_GEMINI_PADRAO,
  QUANTIDADE_PADROES,
  REGIAO,
  TAMANHO_MAXIMO_TEXTO,
  TIMEOUT_EMBEDDING_CONSULTA_MS,
  TIMEOUT_LLM_MS,
  TIMEOUT_SAFE_BROWSING_MS,
  VARIAVEL_CHAVE_GEMINI,
  VARIAVEL_CHAVE_SAFE_BROWSING,
  VARIAVEL_MODELO_GEMINI,
} from "./config";
import { LimiteRequisicoes } from "./limiteRequisicoes";
import { deveOcultar } from "./moderacao";
import { carregarIndice, consultarBase } from "./recuperacao";
import { consultarSafeBrowsing, urlValida } from "./safeBrowsing";

initializeApp();

const limite = new LimiteRequisicoes(
  LIMITE_REQUISICOES_POR_USUARIO,
  JANELA_LIMITE_MS,
);

const limiteAnaliseTexto = new LimiteRequisicoes(
  LIMITE_ANALISES_TEXTO_POR_USUARIO,
  JANELA_LIMITE_MS,
);

/**
 * Índice da base de conhecimento, publicado junto com a Function
 * (functions/base-conhecimento/README.md). Lido uma vez por instância;
 * ausente ou de outro modelo, as análises seguem sem a base e o app é
 * avisado por `baseConsultada: false`.
 */
const indiceBase = carregarIndice(
  path.join(__dirname, "..", "..", "base-conhecimento", "indice.json"),
  { modelo: MODELO_EMBEDDING, dimensao: DIMENSAO_EMBEDDING },
);

/**
 * POST com `Authorization: Bearer <ID token do Firebase Auth>` e corpo
 * `{ "url": "https://exemplo.com.br/caminho" }` — URL já normalizada no
 * app: domínio e caminho, sem query string nem fragmento.
 *
 * Respostas:
 * - 200 `{ status: "listado", tiposAmeaca: [...] }`
 * - 200 `{ status: "nao_listado" }`
 * - 200 `{ status: "nao_concluida", motivo: "..." }`
 * - 400 URL ausente, inválida ou com query/fragmento/credenciais
 * - 401 sem token ou token inválido
 * - 405 método diferente de POST
 * - 429 limite de requisições do usuário excedido
 */
export const reputacaoDominio = onRequest(
  // `cors: true` permite a chamada a partir do app rodando no Chrome. A
  // proteção real é o token do Firebase Auth, exigido abaixo.
  { region: REGIAO, cors: true, maxInstances: 1 },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        res.status(405).json({ erro: "metodo_nao_permitido" });
        return;
      }

      const cabecalho = req.get("Authorization") ?? "";
      const token = cabecalho.startsWith("Bearer ")
        ? cabecalho.slice("Bearer ".length).trim()
        : "";
      if (!token) {
        res.status(401).json({ erro: "nao_autenticado" });
        return;
      }

      let uid: string;
      try {
        uid = (await getAuth().verifyIdToken(token)).uid;
      } catch {
        res.status(401).json({ erro: "nao_autenticado" });
        return;
      }

      if (!limite.permitir(uid)) {
        res.status(429).json({ erro: "limite_excedido" });
        return;
      }

      const url: unknown = req.body?.url;
      if (!urlValida(url)) {
        res.status(400).json({ erro: "url_invalida" });
        return;
      }

      const resultado = await consultarSafeBrowsing(
        url,
        process.env[VARIAVEL_CHAVE_SAFE_BROWSING],
        { timeoutMs: TIMEOUT_SAFE_BROWSING_MS },
      );

      if (resultado.status === "nao_concluida") {
        // Só o motivo — nunca a URL nem o domínio.
        logger.warn("Safe Browsing não concluído", {
          motivo: resultado.motivo,
        });
      }

      res.status(200).json(resultado);
    } catch {
      // Rede de segurança: nenhuma falha derruba a Function nem expõe
      // detalhes (nem a URL) na resposta ou no log.
      logger.error("Falha inesperada na consulta de reputação");
      if (!res.headersSent) {
        res
          .status(200)
          .json({ status: "nao_concluida", motivo: "indisponivel" });
      }
    }
  },
);

/**
 * Análise do texto de um print pelo modelo de linguagem (UC04, etapas 7 e
 * 8). POST com `Authorization: Bearer <ID token do Firebase Auth>` e corpo
 * `{ "texto": "..." }` — texto JÁ MASCARADO no dispositivo (RNF07, etapa 1).
 *
 * Antes do modelo, o texto é comparado com a base de conhecimento
 * (Prompt 7.2), e os padrões mais parecidos vão no prompt. Se a base não
 * puder ser consultada, a análise segue sem ela (degradação controlada) e
 * a resposta diz isso, para o app tratar como verificação incompleta.
 *
 * Respostas:
 * - 200 `{ status: "concluida", baseConsultada, analise: { sinais,
 *   padraoCorrespondente, categoria, explicacao } }`
 * - 200 `{ status: "nao_concluida", motivo: "..." }` (inclui
 *   `limite_provedor` quando o Gemini recusa por cota)
 * - 400 texto ausente, vazio ou longo demais
 * - 401 sem token ou token inválido
 * - 405 método diferente de POST
 * - 429 limite de análises do usuário excedido
 *
 * O modelo não devolve score: os sinais são convertidos em número pelo
 * motor determinístico do app (RF07).
 */
export const analiseTexto = onRequest(
  { region: REGIAO, cors: true, maxInstances: 1 },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        res.status(405).json({ erro: "metodo_nao_permitido" });
        return;
      }

      const cabecalho = req.get("Authorization") ?? "";
      const token = cabecalho.startsWith("Bearer ")
        ? cabecalho.slice("Bearer ".length).trim()
        : "";
      if (!token) {
        res.status(401).json({ erro: "nao_autenticado" });
        return;
      }

      let uid: string;
      try {
        uid = (await getAuth().verifyIdToken(token)).uid;
      } catch {
        res.status(401).json({ erro: "nao_autenticado" });
        return;
      }

      if (!limiteAnaliseTexto.permitir(uid)) {
        res.status(429).json({ erro: "limite_excedido" });
        return;
      }

      const texto: unknown = req.body?.texto;
      if (!textoValido(texto, TAMANHO_MAXIMO_TEXTO)) {
        res.status(400).json({ erro: "texto_invalido" });
        return;
      }

      const chave = process.env[VARIAVEL_CHAVE_GEMINI];
      const base = await consultarBase(texto, chave, {
        indice: indiceBase,
        quantidade: QUANTIDADE_PADROES,
        limiar: LIMIAR_SIMILARIDADE,
        timeoutMs: TIMEOUT_EMBEDDING_CONSULTA_MS,
      });
      if (base.status === "nao_consultada") {
        // Só o motivo — nunca o texto.
        logger.warn("Base de conhecimento não consultada", {
          motivo: base.motivo,
        });
      }

      const resultado = await analisarTextoGemini(texto, chave, {
        modelo: process.env[VARIAVEL_MODELO_GEMINI] || MODELO_GEMINI_PADRAO,
        timeoutMs: TIMEOUT_LLM_MS,
        padroes: base.status === "consultada" ? base.padroes : [],
      });

      if (resultado.status === "nao_concluida") {
        // Só o motivo — nunca o texto.
        logger.warn("Análise de texto não concluída", {
          motivo: resultado.motivo,
        });
        res.status(200).json(resultado);
        return;
      }

      res.status(200).json({
        ...resultado,
        baseConsultada: base.status === "consultada",
      });
    } catch {
      // Rede de segurança: nenhuma falha derruba a Function nem expõe o
      // texto na resposta ou no log.
      logger.error("Falha inesperada na análise de texto");
      if (!res.headersSent) {
        res
          .status(200)
          .json({ status: "nao_concluida", motivo: "indisponivel" });
      }
    }
  },
);

/**
 * Ocultação automática (RF11; arquitetura, 5.7). Acionada pela gravação de
 * uma denúncia, que as regras só aceitam junto com o +1 no contador do
 * reporte. Ao atingir o limiar, o reporte pendente passa a `oculto` e sai do
 * feed até a revisão da equipe. Em transação, para que duas denúncias
 * simultâneas não se atrapalhem.
 *
 * Privacidade: o log traz só o identificador do reporte, nunca o texto, o
 * motivo nem a conta que denunciou.
 */
export const ocultarReporteDenunciado = onDocumentCreated(
  { document: "reportes/{reporteId}/denuncias/{uid}", region: REGIAO },
  async (evento) => {
    const reporteId = evento.params.reporteId;
    const banco = getFirestore();
    const reporte = banco.collection("reportes").doc(reporteId);
    try {
      const ocultou = await banco.runTransaction(async (transacao) => {
        const atual = await transacao.get(reporte);
        if (!atual.exists) return false;
        if (!deveOcultar(atual.data(), LIMIAR_DENUNCIAS_OCULTACAO)) {
          return false;
        }
        transacao.update(reporte, { status: "oculto" });
        return true;
      });
      if (ocultou) {
        logger.info("Reporte ocultado por denúncias", { reporteId });
      }
    } catch {
      // Sem relançar: a denúncia já está gravada e conta para a revisão;
      // a próxima denúncia tenta de novo.
      logger.error("Falha ao conferir denúncias do reporte", { reporteId });
    }
  },
);
