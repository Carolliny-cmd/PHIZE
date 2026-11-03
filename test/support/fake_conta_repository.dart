import 'package:phize/features/conta/domain/compartilhador_arquivo.dart';
import 'package:phize/features/conta/domain/conta_repository.dart';

class FakeContaRepository implements ContaRepository {
  FakeContaRepository({this.pendente = false});

  bool pendente;
  Object? erroExclusao;
  bool falhaPerfil = false;
  String? senhaRecebida;
  int exclusoes = 0;

  @override
  Future<PerfilConta> carregarPerfil() async {
    if (falhaPerfil) throw StateError('falha simulada');
    return PerfilConta(
      uid: 'uid-teste',
      email: 'maria@exemplo.com',
      criadaEm: DateTime(2026, 1, 2),
    );
  }

  @override
  Future<void> excluirConta({required String senha}) async {
    senhaRecebida = senha;
    exclusoes++;
    final erro = erroExclusao;
    if (erro != null) throw erro;
    pendente = false;
  }

  @override
  Future<bool> exclusaoPendente() async => pendente;
}

class FakeCompartilhador implements CompartilhadorArquivo {
  String? nomeArquivo;
  String? conteudo;

  @override
  Future<void> compartilhar({
    required String nomeArquivo,
    required String conteudo,
  }) async {
    this.nomeArquivo = nomeArquivo;
    this.conteudo = conteudo;
  }
}
