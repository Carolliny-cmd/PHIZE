import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../shared/domain/categoria_ameaca.dart';
import '../../../shared/domain/dominio_registravel.dart';
import '../../../shared/domain/marcas_conhecidas.dart';
import '../../../shared/domain/mascaramento_local.dart';
import '../../../shared/domain/normalizacao_url.dart';
import 'novo_reporte.dart';
import 'palavras_busca.dart';

/// Limites do reporte, os mesmos das regras do Firestore
/// (`docs/comunidade-dados.md`).
const int tamanhoMinimoTitulo = 3;
const int tamanhoMaximoTitulo = 80;
const int tamanhoMaximoRelato = 1000;

/// Por que o reporte não pode ser publicado. Cada motivo tem a mensagem
/// mostrada ao usuário.
enum MotivoRecusaReporte {
  linkInvalido(
    'Isso não parece ser um link. Confira o endereço (exemplo: site.com.br).',
  ),
  dominioOficial(
    'Esse é o endereço oficial de uma instituição conhecida. Para não acusar '
    'quem não tem culpa, ele não pode ser reportado. Se recebeu uma mensagem '
    'suspeita citando a instituição, reporte o relato ou o print.',
  ),
  tituloCurto('Escreva um título com pelo menos 3 letras.'),
  relatoVazio('Conte o que aconteceu, ou escolha um print com texto.'),
  relatoLongo('O texto passou de 1.000 caracteres. Resuma um pouco.');

  const MotivoRecusaReporte(this.mensagem);

  final String mensagem;
}

sealed class PreparacaoReporte {
  const PreparacaoReporte();
}

class ReportePronto extends PreparacaoReporte {
  const ReportePronto(this.reporte);

  final NovoReporte reporte;
}

class ReporteRecusado extends PreparacaoReporte {
  const ReporteRecusado(this.motivo);

  final MotivoRecusaReporte motivo;
}

/// Hash do link reportado (RF05, RF15; arquitetura, 5.5): SHA-256 do domínio
/// normalizado (sem esquema, "www.", caminho, parâmetros ou fragmento), para
/// que variações do mesmo endereço caiam no mesmo reporte. `null` se
/// [entrada] não for um link.
String? hashDoLink(String entrada) {
  final dominio = normalizarDominio(entrada);
  if (dominio == null) return null;
  return sha256.convert(utf8.encode(dominio)).toString();
}

/// O domínio é o endereço oficial de uma marca da lista da análise de link
/// (inclusive subdomínios dele), ou a própria categoria do Registro.br, como
/// `gov.br`, que ninguém registra como endereço novo.
bool dominioOficial(String entrada) {
  final dominio = normalizarDominio(entrada);
  if (dominio == null) return false;
  final registravel = registravelDe(dominio);
  if (registravel == null) return true;
  return marcasConhecidas.any((m) => m.dominioOficial == registravel);
}

/// Texto que pode ir para a comunidade: dados pessoais estruturados
/// mascarados (RNF07, etapa 1) e links trocados por `[LINK]` (arquitetura,
/// 5.5), tudo no aparelho, antes do envio.
String textoPublico(String texto) =>
    esconderLinks(mascararTextoLocal(texto)).trim();

/// Monta o reporte a publicar (RF05). Função pura: não grava nem envia nada.
PreparacaoReporte prepararReporte({
  required TipoReporte tipo,
  required String titulo,
  required String relato,
  required CategoriaAmeaca categoria,
  String link = '',
}) {
  String? hash;
  if (tipo == TipoReporte.link) {
    hash = hashDoLink(link);
    if (hash == null) {
      return const ReporteRecusado(MotivoRecusaReporte.linkInvalido);
    }
    if (dominioOficial(link)) {
      return const ReporteRecusado(MotivoRecusaReporte.dominioOficial);
    }
  }

  final tituloPublico = textoPublico(titulo);
  if (tituloPublico.length < tamanhoMinimoTitulo) {
    return const ReporteRecusado(MotivoRecusaReporte.tituloCurto);
  }
  final relatoPublico = textoPublico(relato);
  if (tipo != TipoReporte.link && relatoPublico.isEmpty) {
    return const ReporteRecusado(MotivoRecusaReporte.relatoVazio);
  }
  if (relatoPublico.length > tamanhoMaximoRelato) {
    return const ReporteRecusado(MotivoRecusaReporte.relatoLongo);
  }

  return ReportePronto(
    NovoReporte(
      tipo: tipo,
      titulo: tituloPublico.length > tamanhoMaximoTitulo
          ? tituloPublico.substring(0, tamanhoMaximoTitulo)
          : tituloPublico,
      relato: relatoPublico,
      categoria: categoria,
      palavras: palavrasDeBusca([tituloPublico, categoria.nome]),
      hashLink: hash,
    ),
  );
}

/// Título e relato corrigidos pelo autor (RF16), prontos para gravar.
class EdicaoPronta {
  const EdicaoPronta({
    required this.titulo,
    required this.relato,
    required this.palavras,
  });

  final String titulo;
  final String relato;
  final List<String> palavras;
}

/// Prepara a edição de um reporte (RF16, UC09): título e relato passam de
/// novo pelo mascaramento e pela troca de links, com os mesmos limites do
/// reporte novo. Tipo e categoria não mudam; o link nunca é editável.
/// Devolve [EdicaoPronta] ou o [MotivoRecusaReporte].
Object prepararEdicao({
  required TipoReporte tipo,
  required String titulo,
  required String relato,
  required CategoriaAmeaca categoria,
}) {
  final tituloPublico = textoPublico(titulo);
  if (tituloPublico.length < tamanhoMinimoTitulo) {
    return MotivoRecusaReporte.tituloCurto;
  }
  final relatoPublico = textoPublico(relato);
  if (tipo != TipoReporte.link && relatoPublico.isEmpty) {
    return MotivoRecusaReporte.relatoVazio;
  }
  if (relatoPublico.length > tamanhoMaximoRelato) {
    return MotivoRecusaReporte.relatoLongo;
  }
  final tituloFinal = tituloPublico.length > tamanhoMaximoTitulo
      ? tituloPublico.substring(0, tamanhoMaximoTitulo)
      : tituloPublico;
  return EdicaoPronta(
    titulo: tituloFinal,
    relato: relatoPublico,
    palavras: palavrasDeBusca([tituloFinal, categoria.nome]),
  );
}
