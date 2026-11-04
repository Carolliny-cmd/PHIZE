import 'package:flutter/foundation.dart';

import 'conteudo_compartilhado.dart';

/// Guarda em memória o conteúdo recebido até ele poder ser analisado, inclusive
/// enquanto o usuário faz login (RF10). Nada aqui é gravado em disco.
class CaixaCompartilhamento extends ChangeNotifier {
  /// A instância usada pelo aplicativo; os testes criam a sua própria.
  static final CaixaCompartilhamento instancia = CaixaCompartilhamento();

  ConteudoCompartilhado? _pendente;

  bool get temPendente => _pendente != null;

  /// Um conteúdo novo substitui o anterior, que é descartado.
  void guardar(ConteudoCompartilhado conteudo) {
    _pendente?.descartar();
    _pendente = conteudo;
    notifyListeners();
  }

  /// Entrega o conteúdo uma única vez. Quem retira passa a ser responsável
  /// por descartá-lo.
  ConteudoCompartilhado? retirar() {
    final conteudo = _pendente;
    _pendente = null;
    if (conteudo != null) notifyListeners();
    return conteudo;
  }
}
