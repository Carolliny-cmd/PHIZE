import 'package:phize/features/auth/domain/auth_exception.dart';
import 'package:phize/features/conta/domain/compartilhador_arquivo.dart';
import 'package:phize/features/conta/domain/conta_repository.dart';

class FakeContaRepository implements ContaRepository {
  FakeContaRepository({this.pendente = false});

  bool pendente;
  @override
  bool exigeSenha = true;
  Object? erroExclusao;
  bool falhaPerfil = false;
  bool falhaSalvarNome = false;
  String? nomeExibicao;
  @override
  IdentidadeConta identidade = const IdentidadeConta(
    email: 'maria@exemplo.com',
    emailVerificado: true,
    entraComSenha: true,
    entraComGoogle: false,
  );
  String? senhaRecebida;
  int exclusoes = 0;

  /// Senha que a troca aceita como atual.
  String senhaAtual = 'senha-atual-123';
  String? novaSenhaGravada;
  Object? erroTrocaSenha;
  int reenvios = 0;
  Object? erroReenvio;
  IdentidadeConta? identidadeAtualizada;
  bool falhaAtualizarIdentidade = false;

  @override
  Future<PerfilConta> carregarPerfil() async {
    if (falhaPerfil) throw StateError('falha simulada');
    return PerfilConta(
      uid: 'uid-teste',
      email: 'maria@exemplo.com',
      criadaEm: DateTime(2026, 1, 2),
      nomeExibicao: nomeExibicao,
    );
  }

  @override
  Future<void> salvarNomeExibicao(String? nome) async {
    if (falhaSalvarNome) throw StateError('falha simulada');
    nomeExibicao = nome;
  }

  @override
  Future<IdentidadeConta> atualizarIdentidade() async {
    if (falhaAtualizarIdentidade) throw StateError('falha simulada');
    return identidadeAtualizada ?? identidade;
  }

  @override
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final erro = erroTrocaSenha;
    if (erro != null) throw erro;
    if (senhaAtual != this.senhaAtual) {
      throw const AuthException('Senha atual incorreta.');
    }
    novaSenhaGravada = novaSenha;
    this.senhaAtual = novaSenha;
  }

  @override
  Future<void> reenviarVerificacao() async {
    final erro = erroReenvio;
    if (erro != null) throw erro;
    reenvios++;
  }

  @override
  Future<void> excluirConta({String? senha}) async {
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
