import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/domain/categoria_ameaca.dart';
import '../domain/feed_repository.dart';
import '../domain/motivo_denuncia.dart';
import '../domain/novo_reporte.dart';
import '../domain/reporte_comunidade.dart';

/// Converte `reportes/{id}` no reporte do feed. Documento fora do formato
/// das regras, ou oculto, volta `null` e não aparece. A moderação usa
/// [incluirOcultos] para ver também os ocultos.
ReporteComunidade? reporteDoDocumento(
  String id,
  Map<String, dynamic> dados, {
  bool incluirOcultos = false,
}) {
  final tipo = switch (dados['tipo']) {
    'link' => TipoReporte.link,
    'relato' => TipoReporte.relato,
    'print' => TipoReporte.print,
    _ => null,
  };
  final categoria = CategoriaAmeaca.doCodigo(dados['categoria']);
  final status = StatusReporte.doCodigo(dados['status']);
  final titulo = dados['titulo'];
  final relato = dados['relato'];
  final curtidas = dados['curtidas'];
  final incidencias = dados['incidencias'];
  final denuncias = dados['denuncias'];
  if (tipo == null ||
      categoria == null ||
      status == null ||
      (status == StatusReporte.oculto && !incluirOcultos) ||
      titulo is! String ||
      relato is! String ||
      curtidas is! int ||
      incidencias is! int) {
    return null;
  }
  final criadoEm = dados['criadoEm'];
  return ReporteComunidade(
    id: id,
    tipo: tipo,
    titulo: titulo,
    relato: relato,
    categoria: categoria,
    curtidas: curtidas,
    denuncias: denuncias is int ? denuncias : 0,
    incidencias: incidencias,
    status: status,
    // Gravação ainda sem a hora do servidor (só no próprio aparelho).
    criadoEm: criadoEm is Timestamp ? criadoEm.toDate() : DateTime.now(),
  );
}

class FeedRepositoryFirestore implements FeedRepository {
  FeedRepositoryFirestore({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sem usuário autenticado.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _reportes =>
      _firestore.collection('reportes');

  @override
  Future<List<ReporteComunidade>> listar(OrdemFeed ordem) async {
    // O filtro de status é exigido pelas regras: sem ele, a consulta poderia
    // trazer reportes ocultos e é recusada inteira (RF11).
    var consulta = _reportes.where(
      'status',
      whereIn: [StatusReporte.pendente.codigo, StatusReporte.aprovado.codigo],
    );
    consulta = switch (ordem) {
      OrdemFeed.emAlta =>
        consulta
            .orderBy('curtidas', descending: true)
            .orderBy('criadoEm', descending: true),
      OrdemFeed.maisRecentes => consulta.orderBy('criadoEm', descending: true),
    };
    final resultado = await consulta.limit(FeedRepository.limite).get();
    return [
      for (final documento in resultado.docs)
        ?reporteDoDocumento(documento.id, documento.data()),
    ];
  }

  @override
  Future<bool> jaCurtiu(String reporteId) async {
    final marca = await _reportes
        .doc(reporteId)
        .collection('curtidas')
        .doc(_uid)
        .get();
    return marca.exists;
  }

  @override
  Future<void> curtir(String reporteId) async {
    final uid = _uid;
    final reporte = _reportes.doc(reporteId);
    final lote = _firestore.batch()
      ..update(reporte, {'curtidas': FieldValue.increment(1)})
      ..set(reporte.collection('curtidas').doc(uid), {
        'criadoEm': FieldValue.serverTimestamp(),
      });
    await lote.commit();
  }

  @override
  Future<bool> jaDenunciou(String reporteId) async {
    final marca = await _reportes
        .doc(reporteId)
        .collection('denuncias')
        .doc(_uid)
        .get();
    return marca.exists;
  }

  @override
  Future<void> denunciar(String reporteId, MotivoDenuncia motivo) async {
    final uid = _uid;
    final reporte = _reportes.doc(reporteId);
    final lote = _firestore.batch()
      ..update(reporte, {'denuncias': FieldValue.increment(1)})
      ..set(reporte.collection('denuncias').doc(uid), {
        'motivo': motivo.codigo,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    await lote.commit();
  }
}
