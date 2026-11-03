import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/analise_risco.dart';
import '../domain/categoria_ameaca.dart';
import '../domain/faixa_risco.dart';
import '../domain/historico_repository.dart';
import '../domain/resultado_analise_print.dart';

/// Documento gravado em `users/{uid}/analises/{id}`. Esta é a lista completa
/// do que a persistência seletiva admite (RNF07, etapa 4; arquitetura, 5.4),
/// conferida também por `firestore.rules`.
Map<String, Object> analiseParaDocumento(AnaliseRisco analise) {
  final categoria = analise.categoria;
  return {
    'score': analise.score,
    'faixa': analise.faixa.name,
    'categoria': ?categoria?.codigo,
    'explicacao': analise.explicacao,
    'tipoEntrada': analise.tipoEntrada.name,
    'data': Timestamp.fromDate(analise.data),
  };
}

/// Devolve `null` para documento fora do formato, que fica fora da lista.
AnaliseRisco? analiseDeDocumento(String id, Map<String, dynamic> documento) {
  final score = documento['score'];
  final faixa = FaixaRisco.values.asNameMap()[documento['faixa']];
  final tipoEntrada = TipoEntrada.values.asNameMap()[documento['tipoEntrada']];
  final explicacao = documento['explicacao'];
  final data = documento['data'];
  final codigoCategoria = documento['categoria'];
  final categoria = CategoriaAmeaca.doCodigo(codigoCategoria);

  if (score is! int ||
      faixa == null ||
      tipoEntrada == null ||
      explicacao is! String ||
      data is! Timestamp ||
      (codigoCategoria != null && categoria == null)) {
    return null;
  }
  return AnaliseRisco(
    id: id,
    score: score,
    faixa: faixa,
    categoria: categoria,
    explicacao: explicacao,
    tipoEntrada: tipoEntrada,
    data: data.toDate(),
  );
}

class HistoricoRepositoryFirestore implements HistoricoRepository {
  HistoricoRepositoryFirestore({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _analises {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sem usuário autenticado.');
    return _firestore.collection('users').doc(uid).collection('analises');
  }

  @override
  Future<void> salvar(AnaliseRisco analise) async {
    await _analises.add(analiseParaDocumento(analise));
  }

  @override
  Future<List<AnaliseRisco>> listar() async {
    final consulta = await _analises.orderBy('data', descending: true).get();
    return consulta.docs
        .map((doc) => analiseDeDocumento(doc.id, doc.data()))
        .nonNulls
        .toList();
  }
}
