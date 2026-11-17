import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/comunidade/data/feed_repository_firestore.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';

Map<String, dynamic> _documento([Map<String, dynamic> extra = const {}]) => {
  'tipo': 'link',
  'titulo': 'Entrega com taxa',
  'relato': '',
  'categoria': 'cobranca_ou_boleto_falso',
  'hashLink': 'a' * 64,
  'palavras': ['entrega', 'taxa'],
  'curtidas': 4,
  'denuncias': 0,
  'incidencias': 2,
  'status': 'aprovado',
  'criadoEm': Timestamp.fromDate(DateTime(2026, 11, 16, 10)),
  ...extra,
};

void main() {
  test('lê o reporte público do feed', () {
    final reporte = reporteDoDocumento('a' * 64, _documento())!;
    expect(reporte.id, 'a' * 64);
    expect(reporte.tipo, TipoReporte.link);
    expect(reporte.categoria, CategoriaAmeaca.cobrancaOuBoletoFalso);
    expect(reporte.curtidas, 4);
    expect(reporte.incidencias, 2);
    expect(reporte.status, StatusReporte.aprovado);
    expect(reporte.criadoEm, DateTime(2026, 11, 16, 10));
  });

  test('reporte oculto ou fora do formato não aparece', () {
    expect(reporteDoDocumento('x', _documento({'status': 'oculto'})), isNull);
    expect(reporteDoDocumento('x', _documento({'categoria': 'nada'})), isNull);
    expect(reporteDoDocumento('x', _documento({'curtidas': '4'})), isNull);
    expect(reporteDoDocumento('x', _documento({'tipo': 'imagem'})), isNull);
  });

  test('gravação ainda sem hora do servidor usa a hora atual', () {
    final reporte = reporteDoDocumento('x', _documento({'criadoEm': null}))!;
    expect(
      DateTime.now().difference(reporte.criadoEm).inSeconds.abs(),
      lessThan(5),
    );
  });
}
