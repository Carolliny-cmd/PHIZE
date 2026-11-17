import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/meus_reportes_repository.dart';
import '../domain/motivo_denuncia.dart';
import '../domain/preparacao_reporte.dart';
import 'feed_repository_firestore.dart';

DateTime _data(Object? valor) =>
    valor is Timestamp ? valor.toDate() : DateTime.now();

class MeusReportesRepositoryFirestore implements MeusReportesRepository {
  MeusReportesRepositoryFirestore({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sem usuário autenticado.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _usuario =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _reportes =>
      _firestore.collection('reportes');

  @override
  Future<List<MeuReporte>> listar() async {
    final autorias = await _usuario
        .collection('reportes')
        .orderBy('criadoEm', descending: true)
        .get();
    return Future.wait([
      for (final autoria in autorias.docs)
        _reportes
            .doc(autoria.id)
            .get()
            .then(
              (documento) => MeuReporte(
                id: autoria.id,
                publicadoEm: _data(autoria.data()['criadoEm']),
                // O autor lê o próprio reporte mesmo oculto (RF16).
                reporte: switch (documento.data()) {
                  final dados? => reporteDoDocumento(
                    documento.id,
                    dados,
                    incluirOcultos: true,
                  ),
                  null => null,
                },
              ),
            ),
    ]);
  }

  @override
  Future<void> editar(String reporteId, EdicaoPronta edicao) =>
      _reportes.doc(reporteId).update({
        'titulo': edicao.titulo,
        'relato': edicao.relato,
        'palavras': edicao.palavras,
        'editadoEm': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> excluir(String reporteId) async {
    final lote = _firestore.batch()
      ..delete(_reportes.doc(reporteId))
      ..delete(_usuario.collection('reportes').doc(reporteId));
    await lote.commit();
  }

  @override
  Future<void> esquecer(String reporteId) =>
      _usuario.collection('reportes').doc(reporteId).delete();

  @override
  Future<ParticipacaoComunidade> participacao() async {
    final uid = _uid;
    const servidor = GetOptions(source: Source.server);
    final (reportes, curtidas, denuncias, incidencias) = await (
      listar(),
      _usuario.collection('curtidas').get(servidor),
      _usuario.collection('denuncias').get(servidor),
      _usuario.collection('incidencias').get(servidor),
    ).wait;
    final motivos = await Future.wait([
      for (final denuncia in denuncias.docs)
        _reportes
            .doc(denuncia.id)
            .collection('denuncias')
            .doc(uid)
            .get()
            .then((marca) => MotivoDenuncia.doCodigo(marca.data()?['motivo'])),
    ]);
    return ParticipacaoComunidade(
      reportes: reportes,
      curtidas: {
        for (final curtida in curtidas.docs)
          curtida.id: _data(curtida.data()['criadoEm']),
      },
      denuncias: {
        for (var i = 0; i < denuncias.docs.length; i++)
          denuncias.docs[i].id: motivos[i],
      },
      incidencias: {
        for (final incidencia in incidencias.docs)
          incidencia.id: _data(incidencia.data()['criadoEm']),
      },
    );
  }
}

/// O que a exclusão de conta precisa apagar na comunidade (RF12): só
/// identificadores, lidos do servidor antes de registrar a pendência.
class DocumentosComunidade {
  const DocumentosComunidade({
    required this.reportes,
    required this.curtidas,
    required this.denuncias,
    required this.incidencias,
  });

  final List<String> reportes;
  final List<String> curtidas;
  final List<String> denuncias;
  final List<String> incidencias;
}

/// Limpeza da comunidade na exclusão de conta (RF12, decisão da equipe de
/// 2026-11-17): os reportes da conta são excluídos com a autoria, e as
/// curtidas e denúncias saem dos reportes de outras pessoas com -1 no
/// contador. As incidências ("também recebi") saem da conta; o contador do
/// reporte não guarda quem foi. A hash de link validado pela equipe continua
/// em `ameacas`, sem autor.
class LimpezaComunidadeConta {
  LimpezaComunidadeConta(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _usuario =>
      _firestore.collection('users').doc(_uid);

  DocumentReference<Map<String, dynamic>> _reporte(String id) =>
      _firestore.collection('reportes').doc(id);

  Future<DocumentosComunidade> ler() async {
    const servidor = GetOptions(source: Source.server);
    Future<List<String>> ids(String colecao) async =>
        (await _usuario.collection(colecao).get(servidor)).docs
            .map((d) => d.id)
            .toList();
    final (reportes, curtidas, denuncias, incidencias) = await (
      ids('reportes'),
      ids('curtidas'),
      ids('denuncias'),
      ids('incidencias'),
    ).wait;
    return DocumentosComunidade(
      reportes: reportes,
      curtidas: curtidas,
      denuncias: denuncias,
      incidencias: incidencias,
    );
  }

  Future<void> remover(DocumentosComunidade documentos) async {
    for (final id in documentos.reportes) {
      final lote = _firestore.batch()
        ..delete(_reporte(id))
        ..delete(_usuario.collection('reportes').doc(id));
      await lote.commit();
    }
    for (final id in documentos.curtidas) {
      await _retirarMarca(id, 'curtidas');
    }
    for (final id in documentos.denuncias) {
      await _retirarMarca(id, 'denuncias');
    }
    for (final id in documentos.incidencias) {
      await _usuario.collection('incidencias').doc(id).delete();
    }
  }

  /// Marca, índice e -1 no contador, juntos, como pedem as regras. Se o
  /// reporte já não existe, sai só a marca com o índice.
  Future<void> _retirarMarca(String reporteId, String campo) async {
    final reporte = _reporte(reporteId);
    bool existe;
    try {
      existe = (await reporte.get(const GetOptions(source: Source.server)))
          .exists;
    } on FirebaseException catch (e) {
      // Reporte oculto (RF11): existe, mas só a moderação lê.
      if (e.code != 'permission-denied') rethrow;
      existe = true;
    }
    final lote = _firestore.batch()
      ..delete(reporte.collection(campo).doc(_uid))
      ..delete(_usuario.collection(campo).doc(reporteId));
    if (existe) lote.update(reporte, {campo: FieldValue.increment(-1)});
    await lote.commit();
  }
}
