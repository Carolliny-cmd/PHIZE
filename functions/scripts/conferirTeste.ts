/**
 * Confere, sem chamar a API, se um conjunto de avaliação repete frases das
 * fichas (docs/calibracao-recuperacao.md, "Conjunto de teste").
 *
 *   npm run conferir-teste
 *   npm run conferir-teste -- --arquivo mensagens.json
 *
 * Também aplica a trava de dado pessoal sem marcador. Sai com código 1 se
 * o conjunto não puder ser usado.
 */

import { encontrarDadoSemMarcador } from "../src/avaliacaoAnalise";
import { conferirSobreposicao, lerConjunto, rotulo } from "./conjuntoAvaliacao";

function main(): number {
  const i = process.argv.indexOf("--arquivo");
  const nomeArquivo = i >= 0 ? process.argv[i + 1] : "teste.json";
  const conjunto = lerConjunto(nomeArquivo);

  let valido = conferirSobreposicao(conjunto, nomeArquivo);

  const todas = [
    ...conjunto.golpes.map((m, j) => ({ m, id: rotulo(m, j, "golpe") })),
    ...conjunto.semGolpe.map((m, j) => ({ m, id: rotulo(m, j, "legitima") })),
  ];
  const ids = new Set<string>();
  for (const { m, id } of todas) {
    const dado = encontrarDadoSemMarcador(m.texto);
    if (dado) {
      console.error(`  ${id} tem ${dado} sem marcador.`);
      valido = false;
    }
    if (ids.has(id)) {
      console.error(`  id repetido: ${id}`);
      valido = false;
    }
    ids.add(id);
  }

  console.log(
    `${nomeArquivo}: ${conjunto.golpes.length} golpes, ${conjunto.semGolpe.length} sem golpe — ` +
      (valido ? "pode ser usado." : "corrija antes de usar."),
  );
  return valido ? 0 : 1;
}

process.exit(main());
