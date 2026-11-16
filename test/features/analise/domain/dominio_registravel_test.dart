import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/dominio_registravel.dart';

void main() {
  group('registravelDe', () {
    test('nome sob categoria .br fica com três rótulos', () {
      expect(registravelDe('itau.com.br'), 'itau.com.br');
      expect(registravelDe('www2.itau.com.br'), 'itau.com.br');
      expect(registravelDe('meu.inss.gov.br'), 'inss.gov.br');
    });

    test('categorias além das cinco mais comuns são reconhecidas', () {
      expect(registravelDe('www.tse.jus.br'), 'tse.jus.br');
      expect(registravelDe('camara.leg.br'), 'camara.leg.br');
      expect(registravelDe('portal.mpf.mp.br'), 'mpf.mp.br');
      expect(registravelDe('loja.blog.br'), 'loja.blog.br');
    });

    test('sufixo estadual do gov.br é tratado como no RDAP do Registro.br', () {
      expect(registravelDe('saopaulo.sp.gov.br'), 'sp.gov.br');
    });

    test('a própria categoria não tem parte registrável', () {
      expect(registravelDe('gov.br'), isNull);
      expect(registravelDe('com.br'), isNull);
    });

    test('.br sem categoria e domínios genéricos usam os dois últimos '
        'rótulos', () {
      expect(registravelDe('nic.br'), 'nic.br');
      expect(registravelDe('sub.registro.br'), 'registro.br');
      expect(registravelDe('picpay.com'), 'picpay.com');
      expect(registravelDe('a.b.exemplo.net'), 'exemplo.net');
    });
  });
}
