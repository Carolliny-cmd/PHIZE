# Regras do R8 para o build de release.
#
# O plugin google_mlkit_text_recognition referencia as opções de
# reconhecimento de todas as escritas (chinesa, devanágari, japonesa e
# coreana), mas o app usa só a latina (ReconhecedorTextoMlKit) e não inclui
# as dependências das outras. Sem estas regras, o R8 para o build de release
# com "Missing classes". As classes nunca são usadas em tempo de execução.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
