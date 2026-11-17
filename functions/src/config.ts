/**
 * Configuração da camada intermediária (arquitetura, seção 2 — Proteção de
 * Credenciais). Valores operacionais da Function, sem relação com os pesos
 * do Score de Risco (esses ficam exclusivamente em docs/score-calibracao.md
 * e no ScoreConfig do app).
 */

/** Região de publicação (São Paulo). O emulador usa o mesmo nome na URL. */
export const REGIAO = "southamerica-east1";

/** Máximo de consultas aceitas por usuário dentro de JANELA_LIMITE_MS. */
export const LIMITE_REQUISICOES_POR_USUARIO = 30;

/** Janela deslizante do rate limiting por usuário. */
export const JANELA_LIMITE_MS = 60_000;

/**
 * Tempo máximo de espera pelo Safe Browsing. Menor que o timeout do app
 * (5 s, RNF03), para que a Function responda "não concluída" antes de o
 * app desistir por conta própria.
 */
export const TIMEOUT_SAFE_BROWSING_MS = 4_000;

/** Nome da variável de ambiente que guarda a chave do Safe Browsing. */
export const VARIAVEL_CHAVE_SAFE_BROWSING = "SAFE_BROWSING_API_KEY";

/**
 * Máximo de análises de texto (LLM) aceitas por usuário dentro de
 * JANELA_LIMITE_MS. Menor que o da reputação: cada chamada tem custo
 * recorrente (arquitetura, seção 2 — Custos Operacionais).
 */
export const LIMITE_ANALISES_TEXTO_POR_USUARIO = 10;

/**
 * Tempo máximo de espera pelo Gemini. Menor que o timeout do app, para que
 * a Function responda "não concluída" antes de o app desistir.
 */
export const TIMEOUT_LLM_MS = 25_000;

/** Maior texto mascarado aceito, em caracteres. */
export const TAMANHO_MAXIMO_TEXTO = 8_000;

/**
 * Modelo de embeddings da base de conhecimento (arquitetura, seção 3.2 b).
 * O índice registra o modelo com que foi gerado; a consulta (Prompt 7.2)
 * precisa usar o mesmo, ou os vetores não são comparáveis.
 */
export const MODELO_EMBEDDING = "gemini-embedding-2";

/** Dimensão dos vetores pedida ao modelo de embeddings. */
export const DIMENSAO_EMBEDDING = 768;

/** Tempo máximo de espera por um embedding na indexação (script). */
export const TIMEOUT_EMBEDDING_MS = 20_000;

/**
 * Recuperação na base (Prompt 7.2). Fonte única destes valores e do
 * registro das calibragens: docs/calibracao-recuperacao.md.
 */
export const QUANTIDADE_PADROES = 3;
export const LIMIAR_SIMILARIDADE = 0.7;

/**
 * Tempo máximo de espera pelo embedding da consulta, dentro da análise.
 * Curto: se o provedor demorar, a análise segue sem a base (degradação
 * controlada) em vez de estourar o timeout do app.
 */
export const TIMEOUT_EMBEDDING_CONSULTA_MS = 4_000;

/** Nome da variável de ambiente que guarda a chave do Gemini. */
export const VARIAVEL_CHAVE_GEMINI = "GEMINI_API_KEY";

/** Variável de ambiente opcional com o modelo do Gemini a usar. */
export const VARIAVEL_MODELO_GEMINI = "GEMINI_MODEL";

/**
 * Modelo usado quando VARIAVEL_MODELO_GEMINI não está definida. O
 * `gemini-2.5-flash` deixou de ser oferecido a chaves novas (404 em
 * 2026-10-27); o substituto é o indicado pela própria mensagem de erro.
 */
export const MODELO_GEMINI_PADRAO = "gemini-3.8-flash";

/**
 * Denúncias de contas distintas que ocultam um reporte da comunidade até a
 * revisão da equipe (RF11; decisão da equipe de 2026-11-16).
 */
export const LIMIAR_DENUNCIAS_OCULTACAO = 3;
