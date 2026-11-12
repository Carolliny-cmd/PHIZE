#!/usr/bin/env bash
# Aquece as Functions no emulador local, para a primeira análise do app não
# esbarrar no tempo limite.
#
# O emulador só inicia cada Function na primeira chamada, e essa partida
# leva mais que os 5 s que a análise de link espera pela consulta de
# reputação (RF03). Sem o aquecimento, a primeira análise depois de ligar os
# emuladores mostra "verificação não concluída".
#
# As chamadas vão sem login e sem conteúdo: a Function recusa com 401, mas
# já fica iniciada. Nada é enviado ao Safe Browsing nem ao Gemini.
#
# Uso, com os emuladores já ligados (docs/emulador-local.md):
#   bash tool/emuladores/aquecer_functions.sh
set -u

BASE="${PHIZE_FUNCTIONS_BASE:-http://127.0.0.1:5001/phize-de7a1/southamerica-east1}"
falhas=0

for funcao in reputacaoDominio analiseTexto; do
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 60 \
    -X POST -H "Content-Type: application/json" -d '{}' "$BASE/$funcao")
  if [ "$status" = "000" ]; then
    echo "$funcao: sem resposta (os emuladores estão ligados?)"
    falhas=$((falhas + 1))
  else
    echo "$funcao: pronta (HTTP $status)"
  fi
done

exit "$falhas"
