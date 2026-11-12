import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Peças das cenas simuladas, comuns aos tutoriais de link e de print
/// (RF13).

class ExplicacaoEtapa extends StatelessWidget {
  const ExplicacaoEtapa({super.key, required this.texto, this.experimente});

  final String texto;
  final String? experimente;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(texto),
        if (experimente != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.touch_app_outlined, color: CoresPhize.azul),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  experimente!,
                  style: const TextStyle(
                    color: CoresPhize.azulEscuro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Transição curta das cenas; nenhuma com a redução de movimento ligada.
Duration transicaoCena(BuildContext context) =>
    MediaQuery.of(context).disableAnimations
    ? Duration.zero
    : const Duration(milliseconds: 200);

/// Barra superior das telas simuladas.
class BarraCena extends StatelessWidget {
  const BarraCena({super.key, required this.titulo, this.icone, this.cor});

  final String titulo;
  final IconData? icone;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cor ?? Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 10),
      child: Row(
        children: [
          if (icone != null) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: CoresPhize.borda,
              child: Icon(icone, size: 16, color: CoresPhize.textoSecundario),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class BalaoRecebido extends StatelessWidget {
  const BalaoRecebido({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: child,
    );
  }
}

/// Opção de exemplo que quebra linha com letra grande, em vez de cortar o
/// texto.
class OpcaoExemplo extends StatelessWidget {
  const OpcaoExemplo({
    super.key,
    required this.texto,
    required this.selecionado,
    required this.aoTocar,
  });

  final String texto;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selecionado ? CoresPhize.azul : CoresPhize.borda,
        width: selecionado ? 2 : 1,
      ),
    );
    return Semantics(
      button: true,
      selected: selecionado,
      inMutuallyExclusiveGroup: true,
      child: Material(
        shape: forma,
        color: selecionado ? CoresPhize.azulClaro : Colors.white,
        child: InkWell(
          customBorder: forma,
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selecionado
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: CoresPhize.azul,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(texto)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
