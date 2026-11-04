package com.phize.phize

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Recebe o conteúdo do menu de compartilhamento do Android (RF10 / UC11).
 *
 * A imagem é lida direto do provedor do outro aplicativo para a memória e
 * entregue ao Dart, sem nenhum arquivo intermediário: o RF10 proíbe gravar em
 * disco o conteúdo recebido, e é por isso que não se usa um pacote pronto, que
 * copiaria a imagem para o cache do aplicativo. Nada aqui vai para log.
 */
class MainActivity : FlutterActivity() {
    private var canal: MethodChannel? = null
    private var pendente: Map<String, Any?>? = null
    private var dartPronto = false
    private val principal = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Reabrir pelos apps recentes reentrega o intent antigo.
        val doHistorico = intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        if (savedInstanceState == null && !doHistorico) tratar(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        tratar(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL).also {
            it.setMethodCallHandler { chamada, resposta ->
                if (chamada.method == "pronto") {
                    dartPronto = true
                    resposta.success(pendente)
                    pendente = null
                } else {
                    resposta.notImplemented()
                }
            }
        }
    }

    private fun tratar(recebido: Intent) {
        if (recebido.action != Intent.ACTION_SEND) return
        val tipo = recebido.type.orEmpty()
        val texto = recebido.getStringExtra(Intent.EXTRA_TEXT)
        val uri = uriRecebida(recebido)
        // O intent não deve guardar o conteúdo além deste ponto.
        setIntent(Intent(Intent.ACTION_MAIN))

        Thread {
            val conteudo = montarConteudo(tipo, uri, texto)
            principal.post { entregar(conteudo) }
        }.start()
    }

    private fun montarConteudo(tipo: String, uri: Uri?, texto: String?): Map<String, Any?> {
        if (tipo.startsWith("image/") && uri != null) {
            val imagem = lerImagem(uri) ?: return mapOf("naoSuportado" to true)
            return mapOf("imagem" to imagem, "texto" to texto)
        }
        if (tipo.startsWith("text/") && !texto.isNullOrBlank()) {
            return mapOf("texto" to texto)
        }
        return mapOf("naoSuportado" to true)
    }

    /** Devolve `null` se a leitura falhar ou a imagem passar do limite. */
    private fun lerImagem(uri: Uri): ByteArray? {
        return try {
            contentResolver.openInputStream(uri)?.use { entrada ->
                val saida = ByteArrayOutputStream()
                val bloco = ByteArray(64 * 1024)
                var total = 0
                while (true) {
                    val lidos = entrada.read(bloco)
                    if (lidos < 0) break
                    total += lidos
                    if (total > TAMANHO_MAXIMO_IMAGEM) return null
                    saida.write(bloco, 0, lidos)
                }
                saida.toByteArray()
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun entregar(conteudo: Map<String, Any?>) {
        if (dartPronto) {
            canal?.invokeMethod("conteudoRecebido", conteudo)
        } else {
            pendente = conteudo
        }
    }

    @Suppress("DEPRECATION")
    private fun uriRecebida(recebido: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            recebido.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            recebido.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private companion object {
        const val CANAL = "com.phize.phize/compartilhamento"

        /** Bem acima de qualquer print; protege a memória do aparelho. */
        const val TAMANHO_MAXIMO_IMAGEM = 25 * 1024 * 1024
    }
}
