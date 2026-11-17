import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/moderacao_repository.dart';
import '../domain/motivo_denuncia.dart';
import '../domain/novo_reporte.dart';
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
  Future<void> mudarStatus(
    ReporteComunidade reporte,
    StatusReporte status,
  ) async {
    final lote = _firestore.batch()
      ..update(_reportes.doc(reporte.id), {'status': status.codigo});
    if (reporte.tipo == TipoReporte.link) {
      // No reporte de link, o identificador é a própria hash.
      final ameaca = _firestore.collection('ameacas').doc(reporte.id);
      if (status == StatusReporte.aprovado) {
        lote.set(ameaca, {'validadoEm': FieldValue.serverTimestamp()});
      } else {
        lote.delete(ameaca);
      }
    }
    await lote.commit();
  }

  @override
  Future<void> excluir(String reporteId) => _reportes.doc(reporteId).delete();

  CollectionReference<Map<String, dynamic>> get _pedidos =>
      _firestore.collection('curadoriaComunidade');

  @override
  Future<Map<String, SituacaoNaBase>> situacoesNaBase() async {
    final pedidos = await _pedidos.get();
    return {
      for (final pedido in pedidos.docs)
        pedido.id: SituacaoNaBase(switch (pedido.data()['status']) {
          'incluido' => EstadoNaBase.incluido,
          'recusado' => EstadoNaBase.recusado,
          'falhou' => EstadoNaBase.falhou,
          _ => EstadoNaBase.aguardando,
        }, pedido.data()['motivo'] as String?),
    };
  }

  @override
  Future<void> incluirNaBase(ReporteComunidade reporte) async {
    final lote = _firestore.batch();
    if (reporte.status != StatusReporte.aprovado) {
      lote.update(_reportes.doc(reporte.id), {
        'status': StatusReporte.aprovado.codigo,
      });
    }
    lote.set(_pedidos.doc(reporte.id), {
      'solicitadoEm': FieldValue.serverTimestamp(),
    });
    await lote.commit();
  }

  @override
  Future<void> pedirInclusaoDeNovo(String reporteId) => _pedidos
      .doc(reporteId)
      .set({'solicitadoEm': FieldValue.serverTimestamp()});
}
