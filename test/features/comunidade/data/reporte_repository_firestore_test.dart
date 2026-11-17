import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/comunidade/data/reporte_repository_firestore.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';

void main() {
  test('grava só os campos aceitos pelas regras, sem autor nem link', () {
    final documento = reporteParaDocumento(
      NovoReporte(
        tipo: TipoReporte.link,
        titulo: 'Entrega com taxa',
        relato: '',
        categoria: CategoriaAmeaca.cobrancaOuBoletoFalso,
        palavras: const ['entrega', 'taxa'],
        hashLink: 'a' * 64,
      ),
    );

    expect(documento.keys.toSet(), {
      'tipo',
      'titulo',
      'relato',
      'categoria',
      'hashLink',
      'palavras',
      'curtidas',
      'denuncias',
      'incidencias',
      'status',
      'criadoEm',
    });
    expect(documento['tipo'], 'link');
    expect(documento['categoria'], 'cobranca_ou_boleto_falso');
    expect(documento['curtidas'], 0);
    expect(documento['denuncias'], 0);
    expect(documento['incidencias'], 1);
    expect(documento['status'], 'pendente');
    expect(documento['criadoEm'], isA<FieldValue>());
  });

  test('relato não leva hashLink', () {
    final documento = reporteParaDocumento(
      const NovoReporte(
        tipo: TipoReporte.relato,
        titulo: 'Falso parente',
        relato: 'Pediu Pix.',
        categoria: CategoriaAmeaca.falsoContato,
        palavras: ['falso', 'parente'],
      ),
    );
    expect(documento.containsKey('hashLink'), isFalse);
  });
}
