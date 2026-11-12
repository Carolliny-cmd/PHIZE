#!/usr/bin/env bash
# Passa os prints sintéticos pelo ML Kit no emulador Android e traz o OCR de
# volta para build/prints_sinteticos/ocr/ (etapa 2 do plano do RAG).
#
#   bash tool/prints_sinteticos/rodar_ocr.sh
#
# Pré-requisitos: emulador ligado e prints gerados por gerar_prints.py. Usa
# `run-as`, que só funciona com o APK de debug. Não usa rede: os prints vão
# por `adb push`, e o resultado volta por `run-as cat`.
set -euo pipefail
# No Git Bash do Windows, impede que /data/... vire caminho do Windows.
export MSYS_NO_PATHCONV=1

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
ADB="${ADB:-$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe}"
PACOTE=com.phize.phize
PASTA_LOCAL="$RAIZ/build/prints_sinteticos"
PASTA_APP=files/prints_sinteticos

cd "$RAIZ"
flutter build apk --debug -t integration_test/ocr_prints_sinteticos_test.dart
"$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk

# Copia os prints para a pasta do app (o app de debug pode ler /data/local/tmp
# só via run-as).
"$ADB" shell rm -rf /data/local/tmp/prints_sinteticos
# adb.exe é programa do Windows: recebe o caminho local no formato dele.
ORIGEM="$PASTA_LOCAL"
command -v cygpath >/dev/null && ORIGEM="$(cygpath -w "$PASTA_LOCAL")"
"$ADB" push "$ORIGEM" /data/local/tmp/ >/dev/null
"$ADB" shell run-as "$PACOTE" sh -c "'rm -rf $PASTA_APP && mkdir -p files && cp -r /data/local/tmp/prints_sinteticos $PASTA_APP && rm -rf $PASTA_APP/ocr'"

"$ADB" logcat -c
"$ADB" shell am force-stop "$PACOTE"
"$ADB" shell monkey -p "$PACOTE" -c android.intent.category.LAUNCHER 1 >/dev/null

until "$ADB" logcat -d -s flutter:I | grep -q "ocr concluido\|tests failed"; do sleep 5; done
"$ADB" logcat -d -s flutter:I | grep -E "Exception|tests" || true

mkdir -p "$PASTA_LOCAL/ocr"
for id in $("$ADB" shell run-as "$PACOTE" ls "$PASTA_APP/ocr" | tr -d '\r'); do
  "$ADB" exec-out run-as "$PACOTE" cat "$PASTA_APP/ocr/$id" > "$PASTA_LOCAL/ocr/$id"
done
"$ADB" shell rm -rf /data/local/tmp/prints_sinteticos
"$ADB" shell run-as "$PACOTE" rm -rf "$PASTA_APP"
echo "OCR em $PASTA_LOCAL/ocr: $(ls "$PASTA_LOCAL/ocr" | wc -l) arquivos"
