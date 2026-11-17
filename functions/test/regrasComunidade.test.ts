/**
 * Testes das regras do Firestore da comunidade (Fase 10, etapa 10.1;
 * RF05, RF06, RF08, RF11, RF12, RF16). Rodam contra o emulador do Firestore
 * já ligado (porta 8085), num projeto de teste separado, sem tocar nos dados
 * do app: `npm run test:regras`. Todo conteúdo é fictício.
 */
import { readFileSync } from "node:fs";
import path from "node:path";
import { after, before, beforeEach, describe, test } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  type Firestore,
  deleteDoc,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";

const HASH_A = "a".repeat(64);
const HASH_B = "b".repeat(64);

let ambiente: RulesTestEnvironment;

const db = (uid?: string): Firestore =>
  (uid
    ? ambiente.authenticatedContext(uid).firestore()
    : ambiente.unauthenticatedContext().firestore()) as unknown as Firestore;

/** Campos de um reporte novo e válido; [extra] sobrescreve ou acrescenta. */
const reporte = (extra: Record<string, unknown> = {}) => ({
  tipo: "relato",
  titulo: "Falso parente pedindo Pix",
  relato: "Mensagem de número novo dizendo que trocou de celular.",
  categoria: "falso_contato",
  palavras: ["falso", "parente", "pix"],
  curtidas: 0,
  denuncias: 0,
  incidencias: 1,
  status: "pendente",
  criadoEm: serverTimestamp(),
  ...extra,
});

/** Grava reporte e autoria juntos, como o app fará. */
const criar = (uid: string, id: string, dados = reporte()) => {
  const banco = db(uid);
  const lote = writeBatch(banco);
  lote.set(doc(banco, "reportes", id), dados);
  lote.set(doc(banco, "users", uid, "reportes", id), {
    criadoEm: serverTimestamp(),
  });
  return lote.commit();
};

/** Semeia sem regras: reporte da Ana (id "r1") e moderadora "mod". */
const semear = (status = "pendente") =>
  ambiente.withSecurityRulesDisabled(async (ctx) => {
    const banco = ctx.firestore() as unknown as Firestore;
    await setDoc(doc(banco, "reportes", "r1"), {
      ...reporte({ status }),
      criadoEm: new Date(),
    });
    await setDoc(doc(banco, "users", "ana", "reportes", "r1"), {
      criadoEm: new Date(),
    });
    await setDoc(doc(banco, "moderadores", "mod"), {});
  });

/** +1 no contador junto com a marca da conta, como o app fará. */
const maisUm = (uid: string, campo: string, marca: string[]) => {
  const banco = db(uid);
  const lote = writeBatch(banco);
  lote.update(doc(banco, "reportes", "r1"), { [campo]: increment(1) });
  const [colecao, ...resto] = marca;
  lote.set(
    doc(banco, colecao, ...resto),
    campo === "denuncias"
      ? { motivo: "falso", criadoEm: serverTimestamp() }
      : { criadoEm: serverTimestamp() },
  );
  return lote.commit();
};

before(async () => {
  ambiente = await initializeTestEnvironment({
    projectId: "demo-phize-regras",
    firestore: {
      rules: readFileSync(
        path.resolve(__dirname, "..", "..", "..", "firestore.rules"),
        "utf8",
      ),
      host: "127.0.0.1",
      port: 8085,
    },
  });
});

after(async () => {
  await ambiente?.cleanup();
});

beforeEach(async () => {
  await ambiente.clearFirestore();
});

describe("criar reporte (RF05)", () => {
  test("relato válido, com autoria na mesma gravação", async () => {
    await assertSucceeds(criar("ana", "r1"));
  });

  test("sem a autoria, o reporte é recusado", async () => {
    await assertFails(setDoc(doc(db("ana"), "reportes", "r1"), reporte()));
  });

  test("autoria sem reporte é recusada", async () => {
    await assertFails(
      setDoc(doc(db("ana"), "users", "ana", "reportes", "r1"), {
        criadoEm: serverTimestamp(),
      }),
    );
  });

  test("sem login, nada é gravado", async () => {
    await assertFails(setDoc(doc(db(), "reportes", "r1"), reporte()));
  });

  test("link usa a hash como identificador", async () => {
    await assertSucceeds(
      criar("ana", HASH_A, reporte({ tipo: "link", hashLink: HASH_A, relato: "" })),
    );
  });

  test("link com identificador diferente da hash é recusado", async () => {
    await assertFails(
      criar("ana", "outro", reporte({ tipo: "link", hashLink: HASH_A })),
    );
  });

  test("o mesmo link não vira dois reportes", async () => {
    await criar("ana", HASH_A, reporte({ tipo: "link", hashLink: HASH_A }));
    await assertFails(
      criar("bia", HASH_A, reporte({ tipo: "link", hashLink: HASH_A })),
    );
  });

  test("hash fora do formato é recusada", async () => {
    await assertFails(
      criar("ana", "xyz", reporte({ tipo: "link", hashLink: "xyz" })),
    );
  });

  test("relato com hash de link é recusado", async () => {
    await assertFails(criar("ana", HASH_B, reporte({ hashLink: HASH_B })));
  });

  for (const [nome, extra] of [
    ["campo de autor no reporte público", { autorUid: "ana" }],
    ["link em texto puro", { link: "https://exemplo.test" }],
    ["status aprovado já na criação", { status: "aprovado" }],
    ["curtidas iniciais", { curtidas: 5 }],
    ["incidências iniciais diferentes de 1", { incidencias: 0 }],
    ["categoria sem_indicios", { categoria: "sem_indicios" }],
    ["título curto demais", { titulo: "ab" }],
    ["relato vazio num relato", { relato: "" }],
    ["relato longo demais", { relato: "x".repeat(1001) }],
    ["palavras demais", { palavras: Array(21).fill("p") }],
    ["data escolhida pelo app", { criadoEm: new Date(2020, 0, 1) }],
  ] as const) {
    test(`recusa ${nome}`, async () => {
      await assertFails(criar("ana", "r1", reporte(extra)));
    });
  }
});

describe("ler (RF08, RF11)", () => {
  test("conta logada lê reporte pendente", async () => {
    await semear();
    await assertSucceeds(getDoc(doc(db("bia"), "reportes", "r1")));
  });

  test("sem login não lê", async () => {
    await semear();
    await assertFails(getDoc(doc(db(), "reportes", "r1")));
  });

  test("oculto só a moderação lê", async () => {
    await semear("oculto");
    await assertFails(getDoc(doc(db("bia"), "reportes", "r1")));
    await assertSucceeds(getDoc(doc(db("mod"), "reportes", "r1")));
  });

  test("a autoria é privada", async () => {
    await semear();
    await assertSucceeds(getDoc(doc(db("ana"), "users", "ana", "reportes", "r1")));
    await assertFails(getDoc(doc(db("bia"), "users", "ana", "reportes", "r1")));
  });
});

describe("curtir, denunciar e incidência (RF06, RF11, UC05)", () => {
  const casos = [
    ["curtidas", (uid: string) => ["reportes", "r1", "curtidas", uid]],
    ["denuncias", (uid: string) => ["reportes", "r1", "denuncias", uid]],
    ["incidencias", (uid: string) => ["users", uid, "incidencias", "r1"]],
  ] as const;

  for (const [campo, marca] of casos) {
    test(`${campo}: +1 com a marca da conta`, async () => {
      await semear();
      await assertSucceeds(maisUm("bia", campo, [...marca("bia")]));
    });

    test(`${campo}: a mesma conta não repete`, async () => {
      await semear();
      await maisUm("bia", campo, [...marca("bia")]);
      await assertFails(maisUm("bia", campo, [...marca("bia")]));
    });

    test(`${campo}: +1 sem a marca é recusado`, async () => {
      await semear();
      await assertFails(
        updateDoc(doc(db("bia"), "reportes", "r1"), { [campo]: increment(1) }),
      );
    });

    test(`${campo}: +2 é recusado`, async () => {
      await semear();
      const banco = db("bia");
      const lote = writeBatch(banco);
      lote.update(doc(banco, "reportes", "r1"), { [campo]: increment(2) });
      const [colecao, ...resto] = marca("bia");
      lote.set(
        doc(banco, colecao, ...resto),
        campo === "denuncias"
          ? { motivo: "falso", criadoEm: serverTimestamp() }
          : { criadoEm: serverTimestamp() },
      );
      await assertFails(lote.commit());
    });

    test(`${campo}: marca sem o +1 é recusada`, async () => {
      await semear();
      const [colecao, ...resto] = marca("bia");
      await assertFails(
        setDoc(
          doc(db("bia"), colecao, ...resto),
          campo === "denuncias"
            ? { motivo: "falso", criadoEm: serverTimestamp() }
            : { criadoEm: serverTimestamp() },
        ),
      );
    });
  }

  test("denúncia com motivo fora da lista é recusada", async () => {
    await semear();
    const banco = db("bia");
    const lote = writeBatch(banco);
    lote.update(doc(banco, "reportes", "r1"), { denuncias: increment(1) });
    lote.set(doc(banco, "reportes", "r1", "denuncias", "bia"), {
      motivo: "nao_gostei",
      criadoEm: serverTimestamp(),
    });
    await assertFails(lote.commit());
  });

  test("ninguém lê a curtida de outra conta", async () => {
    await semear();
    await maisUm("bia", "curtidas", ["reportes", "r1", "curtidas", "bia"]);
    await assertFails(getDoc(doc(db("ana"), "reportes", "r1", "curtidas", "bia")));
  });
});

describe("editar e excluir o próprio reporte (RF16)", () => {
  test("autor muda título e relato", async () => {
    await semear();
    await assertSucceeds(
      updateDoc(doc(db("ana"), "reportes", "r1"), {
        titulo: "Falso parente com número novo",
        relato: "Texto corrigido.",
        editadoEm: serverTimestamp(),
      }),
    );
  });

  test("autor não muda categoria nem status", async () => {
    await semear();
    await assertFails(
      updateDoc(doc(db("ana"), "reportes", "r1"), {
        categoria: "outro_golpe",
        editadoEm: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db("ana"), "reportes", "r1"), { status: "aprovado" }),
    );
  });

  test("outra conta não edita", async () => {
    await semear();
    await assertFails(
      updateDoc(doc(db("bia"), "reportes", "r1"), {
        titulo: "Título trocado",
        editadoEm: serverTimestamp(),
      }),
    );
  });

  test("autor exclui reporte e autoria juntos", async () => {
    await semear();
    const banco = db("ana");
    const lote = writeBatch(banco);
    lote.delete(doc(banco, "reportes", "r1"));
    lote.delete(doc(banco, "users", "ana", "reportes", "r1"));
    await assertSucceeds(lote.commit());
  });

  test("outra conta não exclui", async () => {
    await semear();
    await assertFails(deleteDoc(doc(db("bia"), "reportes", "r1")));
  });

  test("autor dissocia a autoria e o reporte continua (RF12)", async () => {
    await semear("aprovado");
    await assertSucceeds(deleteDoc(doc(db("ana"), "users", "ana", "reportes", "r1")));
    await assertSucceeds(getDoc(doc(db("bia"), "reportes", "r1")));
  });
});

describe("moderação (RF11)", () => {
  test("moderadora muda o status", async () => {
    await semear();
    await assertSucceeds(
      updateDoc(doc(db("mod"), "reportes", "r1"), { status: "oculto" }),
    );
  });

  test("moderadora não muda o texto", async () => {
    await semear();
    await assertFails(
      updateDoc(doc(db("mod"), "reportes", "r1"), { titulo: "Outro título" }),
    );
  });

  test("conta comum não muda o status", async () => {
    await semear();
    await assertFails(
      updateDoc(doc(db("bia"), "reportes", "r1"), { status: "oculto" }),
    );
  });

  test("moderadora exclui reporte de outra conta", async () => {
    await semear();
    await assertSucceeds(deleteDoc(doc(db("mod"), "reportes", "r1")));
  });

  test("ninguém se torna moderador pelo app", async () => {
    await assertFails(setDoc(doc(db("bia"), "moderadores", "bia"), {}));
  });

  test("cada conta só lê o próprio registro de moderação", async () => {
    await semear();
    await assertSucceeds(getDoc(doc(db("mod"), "moderadores", "mod")));
    await assertFails(getDoc(doc(db("bia"), "moderadores", "mod")));
  });
});

describe("hashes de ameaças validadas (RF12)", () => {
  test("moderadora grava, conta logada lê", async () => {
    await semear();
    await assertSucceeds(
      setDoc(doc(db("mod"), "ameacas", HASH_A), { validadoEm: serverTimestamp() }),
    );
    await assertSucceeds(getDoc(doc(db("bia"), "ameacas", HASH_A)));
  });

  test("conta comum não grava", async () => {
    await assertFails(
      setDoc(doc(db("bia"), "ameacas", HASH_A), { validadoEm: serverTimestamp() }),
    );
  });

  test("sem autor nem outros campos", async () => {
    await semear();
    await assertFails(
      setDoc(doc(db("mod"), "ameacas", HASH_A), {
        validadoEm: serverTimestamp(),
        autorUid: "ana",
      }),
    );
  });
});
