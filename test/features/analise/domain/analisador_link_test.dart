import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/analisador_link.dart';
import 'package:phize/features/analise/domain/consulta_idade_dominio.dart';
import 'package:phize/features/analise/domain/consulta_reputacao_dominio.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/rdap_client.dart';
import 'package:phize/features/analise/domain/reputacao_dominio_client.dart';
import 'package:phize/features/analise/domain/verificacao_link.dart';

/// RDAP fictício: responde com data antiga para o domínio pedido e guarda
/// quais domínios foram consultados.
class _RdapFake implements RdapClient {
  final consultados = <String>[];

  @override
  Future<Map<String, dynamic>> consultarDominio(String dominio) async {
    consultados.add(dominio);
    return {
      'ldhName': dominio,
      'events': [
        {'eventAction': 'registration', 'eventDate': '2010-01-01T00:00:00Z'},
      ],
    };
  }
}

class _ReputacaoNaoListado implements ReputacaoDominioClient {
  @override
  Future<Map<String, dynamic>> consultarUrl(String url) async => {
    'status': 'nao_listado',
  };
}

void main() {
  late _RdapFake rdap;
  late AnalisadorLink analisador;

  setUp(() {
    rdap = _RdapFake();
    analisador = AnalisadorLink(
      ConsultaIdadeDominio(rdap, agora: () => DateTime.utc(2026, 11, 16)),
      ConsultaReputacaoDominio(_ReputacaoNaoListado()),
    );
  });

  test(
    'link do próprio gov.br: sem consulta ao RDAP e faixa de baixo risco',
    () async {
      final resultado = await analisador.analisar('https://www.gov.br/inss');

      expect(rdap.consultados, isEmpty);
      expect(resultado!.score.faixa, FaixaRisco.baixo);
      expect(resultado.score.verificacaoIncompleta, isFalse);
      final idade = resultado.verificacoes[1];
      expect(idade.status, StatusVerificacao.semSinal);
      expect(idade.descricao, contains('gov.br'));
    },
  );

  test('subdomínio de órgão consulta o nome registrado, não a '
      'categoria', () async {
    await analisador.analisar('https://www.tse.jus.br/eleicoes');
    expect(rdap.consultados, ['tse.jus.br']);
  });

  test('domínio comum continua consultando o RDAP', () async {
    final resultado = await analisador.analisar('https://www.correios.com.br');
    expect(rdap.consultados, ['correios.com.br']);
    expect(resultado!.score.faixa, FaixaRisco.baixo);
  });
}
