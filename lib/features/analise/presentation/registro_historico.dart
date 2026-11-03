import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/analise_risco.dart';
import '../domain/historico_repository.dart';

const String mensagemFalhaHistorico =
    'Não foi possível guardar esta análise no seu histórico.';

/// Grava o resultado sem atrasar a tela de Resultado: uma falha no histórico
/// não interrompe a análise (CLAUDE.md, Seção 8), e o usuário é avisado. A
/// exceção não é exibida nem registrada em log.
void registrarNoHistorico({
  required ScaffoldMessengerState mensageiro,
  required HistoricoRepository repositorio,
  required AnaliseRisco analise,
}) {
  unawaited(
    repositorio.salvar(analise).catchError((Object _) {
      mensageiro.showSnackBar(
        const SnackBar(content: Text(mensagemFalhaHistorico)),
      );
    }),
  );
}
