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

  DocumentReference<Map<String, dynamic>> _usuario(String uid) =>
      _firestore.collection('users').doc(uid);

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
      })
      // Índice privado: é por ele que a exclusão de conta acha a marca
      // (RF12). As regras exigem os três juntos.
      ..set(_usuario(uid).collection('curtidas').doc(reporteId), {
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
      })
      ..set(_usuario(uid).collection('denuncias').doc(reporteId), {
        'criadoEm': FieldValue.serverTimestamp(),
      });
    await lote.commit();
  }

  @override
  Future<ResultadoPesquisaLink> pesquisarLink(String hash) async {
    ReporteComunidade? reporte;
    try {
      final documento = await _reportes.doc(hash).get();
      final dados = documento.data();
      if (dados != null) reporte = reporteDoDocumento(documento.id, dados);
    } on FirebaseException catch (e) {
      // Reporte oculto, em revisão (RF11): não aparece na pesquisa.
      if (e.code != 'permission-denied') rethrow;
    }
    final validado = await _firestore.collection('ameacas').doc(hash).get();
    return ResultadoPesquisaLink(
      reporte: reporte,
      validadoPelaEquipe: validado.exists,
    );
  }

  @override
  Future<List<ReporteComunidade>> pesquisarPalavras(
    List<String> palavras,
  ) async {
    if (palavras.isEmpty) return const [];
    // Uma consulta por status visível: as regras exigem o filtro, e o
    // Firestore não combina `whereIn` com `array-contains-any` em todos os
    // casos.
    final resultados = await Future.wait([
      for (final status in [StatusReporte.pendente, StatusReporte.aprovado])
        _reportes
            .where('status', isEqualTo: status.codigo)
            .where('palavras', arrayContainsAny: palavras)
            .limit(FeedRepository.limite)
            .get(),
    ]);
    final procuradas = palavras.toSet();
    final encontrados = <(ReporteComunidade, int)>[];
    for (final resultado in resultados) {
      for (final documento in resultado.docs) {
        final dados = documento.data();
        final reporte = reporteDoDocumento(documento.id, dados);
        if (reporte == null) continue;
        final palavrasReporte = dados['palavras'];
        final acertos = palavrasReporte is List
            ? palavrasReporte.where(procuradas.contains).length
            : 0;
        encontrados.add((reporte, acertos));
      }
    }
    encontrados.sort((a, b) {
      final porAcertos = b.$2.compareTo(a.$2);
      if (porAcertos != 0) return porAcertos;
      final porCurtidas = b.$1.curtidas.compareTo(a.$1.curtidas);
      if (porCurtidas != 0) return porCurtidas;
      return b.$1.criadoEm.compareTo(a.$1.criadoEm);
    });
    return [for (final (reporte, _) in encontrados) reporte];
  }
}
