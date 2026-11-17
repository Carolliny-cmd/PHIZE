import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/moderacao_repository.dart';
import '../domain/motivo_denuncia.dart';
import '../domain/reporte_comunidade.dart';
import 'feed_repository_firestore.dart';

class ModeracaoRepositoryFirestore implements ModeracaoRepository {
  ModeracaoRepositoryFirestore({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reportes =>
      _firestore.collection('reportes');

  @override
  Future<bool> ehModerador() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final marca = await _firestore.collection('moderadores').doc(uid).get();
      return marca.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ReporteComunidade>> listar(StatusReporte status) async {
    final resultado = await _reportes
        .where('status', isEqualTo: status.codigo)
        .orderBy('criadoEm', descending: true)
        .limit(100)
        .get();
    return [
      for (final documento in resultado.docs)
        ?reporteDoDocumento(
          documento.id,
          documento.data(),
          incluirOcultos: true,
        ),
    ];
  }

  @override
  Future<Map<MotivoDenuncia, int>> motivosDasDenuncias(String reporteId) async {
    final denuncias = await _reportes
        .doc(reporteId)
        .collection('denuncias')
        .get();
    final contagem = <MotivoDenuncia, int>{};
    for (final denuncia in denuncias.docs) {
      final motivo = MotivoDenuncia.doCodigo(denuncia.data()['motivo']);
      if (motivo != null) contagem[motivo] = (contagem[motivo] ?? 0) + 1;
    }
    return contagem;
  }

  @override
  Future<void> mudarStatus(String reporteId, StatusReporte status) =>
      _reportes.doc(reporteId).update({'status': status.codigo});

  @override
  Future<void> excluir(String reporteId) => _reportes.doc(reporteId).delete();
}
