// Confere as regras de users/{uid} (firestore.rules; RF01, RF12, RF14) no
// emulador do Firestore, com casos que devem passar e casos que devem ser
// recusados. Usa tokens não assinados, que só o emulador aceita, e dados
// fictícios. Precisa do Java 11 ou mais novo (o do Android Studio serve).
//
//   firebase emulators:exec --only firestore "node tool/regras_firestore/conferir_perfil.mjs"
//
const base =
  "http://127.0.0.1:8085/v1/projects/phize-de7a1/databases/(default)/documents";

function token(uid) {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const agora = Math.floor(Date.now() / 1000);
  return `${b64({ alg: "none", typ: "JWT" })}.${b64({
    sub: uid,
    user_id: uid,
    iat: agora,
    exp: agora + 3600,
    aud: "phize-de7a1",
    iss: "https://securetoken.google.com/phize-de7a1",
    firebase: { sign_in_provider: "password" },
  })}.`;
}

const valor = (v) =>
  v === null
    ? { nullValue: null }
    : v instanceof Date
      ? { timestampValue: v.toISOString() }
      : typeof v === "string"
        ? { stringValue: v }
        : { integerValue: String(v) };

async function pedir(metodo, caminho, uid, campos, mascara) {
  const url = new URL(`${base}/${caminho}`);
  for (const m of mascara ?? []) url.searchParams.append("updateMask.fieldPaths", m);
  const corpo = campos && {
    fields: Object.fromEntries(Object.entries(campos).map(([k, v]) => [k, valor(v)])),
  };
  const r = await fetch(url, {
    method: metodo,
    headers: { Authorization: `Bearer ${token(uid)}`, "Content-Type": "application/json" },
    body: corpo ? JSON.stringify(corpo) : undefined,
  });
  return r.status;
}

const casos = [];
async function caso(nome, esperaOk, promessa) {
  const status = await promessa;
  const ok = status >= 200 && status < 300;
  casos.push({ nome, passou: ok === esperaOk, status });
}

const perfil = { uid: "u1", email: "maria@exemplo.com", createdAt: new Date() };
await caso("cria o perfil do cadastro", true, pedir("PATCH", "users/u1", "u1", perfil));
await caso("outra pessoa não cria", false, pedir("PATCH", "users/u2", "u1", { ...perfil, uid: "u2" }));
await caso("cadastro com campo extra é recusado", false,
  pedir("PATCH", "users/u3", "u3", { ...perfil, uid: "u3", telefone: "x" }));
await caso("cadastro com uid de outro é recusado", false,
  pedir("PATCH", "users/u4", "u4", { ...perfil, uid: "u1" }));
await caso("cadastro do Google sem e-mail", true,
  pedir("PATCH", "users/u5", "u5", { uid: "u5", email: null, createdAt: new Date() }));
await caso("grava o nome de exibição", true,
  pedir("PATCH", "users/u1", "u1", { nomeExibicao: "Maria" }, ["nomeExibicao"]));
await caso("nome com 40 letras", true,
  pedir("PATCH", "users/u1", "u1", { nomeExibicao: "a".repeat(40) }, ["nomeExibicao"]));
await caso("nome com 41 letras é recusado", false,
  pedir("PATCH", "users/u1", "u1", { nomeExibicao: "a".repeat(41) }, ["nomeExibicao"]));
await caso("nome vazio é recusado", false,
  pedir("PATCH", "users/u1", "u1", { nomeExibicao: "" }, ["nomeExibicao"]));
await caso("nome que não é texto é recusado", false,
  pedir("PATCH", "users/u1", "u1", { nomeExibicao: 7 }, ["nomeExibicao"]));
await caso("apaga o nome", true, pedir("PATCH", "users/u1", "u1", {}, ["nomeExibicao"]));
await caso("mudar o e-mail é recusado", false,
  pedir("PATCH", "users/u1", "u1", { email: "outro@exemplo.com" }, ["email"]));
await caso("campo novo na atualização é recusado", false,
  pedir("PATCH", "users/u1", "u1", { telefone: "x" }, ["telefone"]));
await caso("outra pessoa não muda o nome", false,
  pedir("PATCH", "users/u1", "u2", { nomeExibicao: "Intrusa" }, ["nomeExibicao"]));
await caso("dona lê o perfil", true, pedir("GET", "users/u1", "u1"));
await caso("outra pessoa não lê", false, pedir("GET", "users/u1", "u2"));
await caso("outra pessoa não apaga", false, pedir("DELETE", "users/u1", "u2"));
await caso("dona apaga o perfil (exclusão da conta)", true, pedir("DELETE", "users/u1", "u1"));

for (const c of casos) console.log(`${c.passou ? "ok  " : "FALHOU"} ${c.nome} (${c.status})`);
const falhas = casos.filter((c) => !c.passou).length;
console.log(`\n${casos.length - falhas} de ${casos.length} casos como esperado`);
process.exitCode = falhas ? 1 : 0;
