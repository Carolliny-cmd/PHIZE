/**
 * Ocultação automática de reportes da comunidade (RF11; arquitetura, 5.7).
 * Só decide; a gravação fica no gatilho de `index.ts`.
 */

/**
 * Se o reporte deve passar a `oculto`. Só reporte ainda pendente é
 * ocultado: o aprovado já passou pela revisão da equipe, e o oculto já está
 * fora do feed. Dados fora do formato não ocultam nada.
 */
export function deveOcultar(dados: unknown, limiar: number): boolean {
  if (typeof dados !== "object" || dados === null) return false;
  const { status, denuncias } = dados as Record<string, unknown>;
  return (
    status === "pendente" &&
    typeof denuncias === "number" &&
    Number.isInteger(denuncias) &&
    denuncias >= limiar
  );
}
