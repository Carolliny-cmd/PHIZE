import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/conta/data/preferencias_repository_local.dart';
import 'package:phize/features/conta/domain/preferencias_aparencia.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_preferencias_repository.dart';

double _fator(TextScaler escala) => escala.scale(16) / 16;

void main() {
  group('aplicarTamanhoLetra', () {
    test('normal mantém a escala do aparelho', () {
      const aparelho = TextScaler.linear(1.15);
      expect(aplicarTamanhoLetra(aparelho, TamanhoLetra.normal), aparelho);
    });

    test('grande e muito grande ampliam a letra', () {
      expect(
        _fator(aplicarTamanhoLetra(TextScaler.noScaling, TamanhoLetra.grande)),
        TamanhoLetra.grande.fator,
      );
      expect(
        _fator(
          aplicarTamanhoLetra(TextScaler.noScaling, TamanhoLetra.muitoGrande),
        ),
        TamanhoLetra.muitoGrande.fator,
      );
    });

    test('nunca diminui a letra já ampliada no aparelho', () {
      const aparelho = TextScaler.linear(2);
      expect(aplicarTamanhoLetra(aparelho, TamanhoLetra.grande), aparelho);
    });

    test('os tamanhos crescem nessa ordem', () {
      final fatores = TamanhoLetra.values.map((t) => t.fator).toList();
      expect(fatores, orderedEquals([...fatores]..sort()));
      expect(fatores.first, 1);
    });
  });

  group('ControlePreferencias', () {
    test('carrega o que estava gravado', () async {
      final controle = await ControlePreferencias.carregar(
        FakePreferenciasRepository(
          gravadas: const PreferenciasAparencia(
            tamanhoLetra: TamanhoLetra.grande,
            tema: TemaPreferido.escuro,
          ),
        ),
      );
      expect(controle.atual.tamanhoLetra, TamanhoLetra.grande);
      expect(controle.atual.tema, TemaPreferido.escuro);
    });

    test('mudar avisa a tela e grava, sem perder a outra preferência', () async {
      final repositorio = FakePreferenciasRepository();
      final controle = ControlePreferencias(repositorio);
      var avisos = 0;
      controle.addListener(() => avisos++);

      await controle.mudarTema(TemaPreferido.escuro);
      await controle.mudarTamanhoLetra(TamanhoLetra.muitoGrande);

      expect(avisos, 2);
      expect(repositorio.gravadas.tema, TemaPreferido.escuro);
      expect(repositorio.gravadas.tamanhoLetra, TamanhoLetra.muitoGrande);
    });

    test('falha ao gravar mantém a preferência aplicada e lança', () async {
      final controle = ControlePreferencias(
        FakePreferenciasRepository(falhaAoSalvar: true),
      );

      await expectLater(
        controle.mudarTema(TemaPreferido.claro),
        throwsStateError,
      );
      expect(controle.atual.tema, TemaPreferido.claro);
    });
  });

  group('PreferenciasRepositoryLocal', () {
    test('sem nada gravado, valem as padrão', () async {
      SharedPreferences.setMockInitialValues({});
      final lidas = await PreferenciasRepositoryLocal().ler();
      expect(lidas.tamanhoLetra, TamanhoLetra.normal);
      expect(lidas.tema, TemaPreferido.sistema);
    });

    test('grava e lê de volta', () async {
      SharedPreferences.setMockInitialValues({});
      final repositorio = PreferenciasRepositoryLocal();
      await repositorio.salvar(
        const PreferenciasAparencia(
          tamanhoLetra: TamanhoLetra.muitoGrande,
          tema: TemaPreferido.escuro,
        ),
      );

      final lidas = await PreferenciasRepositoryLocal().ler();
      expect(lidas.tamanhoLetra, TamanhoLetra.muitoGrande);
      expect(lidas.tema, TemaPreferido.escuro);
    });

    test('valor desconhecido volta ao padrão', () async {
      SharedPreferences.setMockInitialValues({
        PreferenciasRepositoryLocal.chaveTamanhoLetra: 'gigante',
        PreferenciasRepositoryLocal.chaveTema: 'roxo',
      });
      final lidas = await PreferenciasRepositoryLocal().ler();
      expect(lidas.tamanhoLetra, TamanhoLetra.normal);
      expect(lidas.tema, TemaPreferido.sistema);
    });
  });
}
