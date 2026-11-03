# Sobe Functions, Auth e Firestore emulados (docs/emulador-local.md).
# O emulador do Firestore não aceita Java 8; usa o Java do Android Studio
# só nesta sessão do terminal, sem alterar a configuração do Windows.
$jbr = 'C:\Program Files\Android\Android Studio\jbr\bin'
if (Test-Path $jbr) { $env:PATH = "$jbr;$env:PATH" }

Set-Location (Split-Path $PSScriptRoot -Parent)
npm --prefix functions run build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
firebase emulators:start --only functions,auth,firestore
