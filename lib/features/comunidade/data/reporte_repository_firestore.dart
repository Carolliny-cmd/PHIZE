import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/novo_reporte.dart';
import '../domain/reporte_repository.dart';

/// Documento público `reportes/{id}`. Esta é a lista completa de campos que
/// as regras aceitam (`firestore.rules`; `docs/comunidade-dados.md`): não há
/// onde gravar autor, link em texto puro ou imagem.
Map<String, Object> reporteParaDocumento(NovoReporte reporte) => {
  'tipo': reporte.tipo.codigo,
  'titulo': reporte.titulo,
  'relato': reporte.relato,
  'categoria': reporte.categoria.codigo,
  'hashLink': ?reporte.hashLink,
  'palavras': reporte.palavras,
  'curtidas': 0,
  'denuncias': 0,
  'incidencias': 1,
  'status': 'pendente',
  'criadoEm': FieldValue.serverTimestamp(),
};

class ReporteRepositoryFirestore implements ReporteRepository {
  ReporteRepositoryFirestore({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sem usuário autenticado.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _usuario(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<ResultadoPublicacao> publicar(NovoReporte reporte) async {
    final uid = _uid;
    final hash = reporte.hashLink;
    final reportes = _firestore.collection('reportes');
    final documento = hash == null ? reportes.doc() : reportes.doc(hash);

    if (hash != null) {
      final DocumentSnapshot<Map<String, dynamic>> existente;
      try {
        existente = await documento.get(
          const GetOptions(source: Source.server),
        );
      } on FirebaseException catch (e) {
        // Reporte oculto: só a moderação lê (RF11).
        if (e.code == 'permission-denied') return ResultadoPublicacao.emRevisao;
        rethrow;
      }
      if (existente.exists) return _registrarIncidencia(uid, hash);
    }

    final lote = _firestore.batch()
      ..set(documento, reporteParaDocumento(reporte))
      ..set(_usuario(uid).collection('reportes').doc(documento.id), {
        'criadoEm': FieldValue.serverTimestamp(),
      });
    await lote.commit();
    return ResultadoPublicacao.publicado;
  }

  /// O link já foi reportado: +1 incidência com a marca da conta, uma vez
  /// por conta (UC05, ameaça já reportada).
  Future<ResultadoPublicacao> _registrarIncidencia(
    String uid,
    String hash,
  ) async {
    final usuario = _usuario(uid);
    final marca = usuario.collection('incidencias').doc(hash);
    final (autoria, jaMarcado) = await (
      usuario.collection('reportes').doc(hash).get(),
      marca.get(),
    ).wait;
    if (autoria.exists || jaMarcado.exists) {
      return ResultadoPublicacao.jaRegistradoPorVoce;
    }

    final lote = _firestore.batch()
      ..update(_firestore.collection('reportes').doc(hash), {
        'incidencias': FieldValue.increment(1),
      })
      ..set(marca, {'criadoEm': FieldValue.serverTimestamp()});
    await lote.commit();
    return ResultadoPublicacao.incidenciaRegistrada;
  }
}
