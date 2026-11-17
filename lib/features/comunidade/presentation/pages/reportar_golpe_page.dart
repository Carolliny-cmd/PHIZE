import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/captura_imagem.dart';
import '../../../../shared/domain/categoria_ameaca.dart';
import '../../../../shared/domain/reconhecedor_texto.dart';
import '../../data/reporte_repository_firestore.dart';
import '../../domain/novo_reporte.dart';
import '../../domain/preparacao_reporte.dart';
import '../../domain/reporte_repository.dart';

/// Tela "Reportar golpe" (RF05, UC05). Tudo o que vai para a comunidade é
/// preparado no aparelho: link só como hash, título e relato mascarados e
/// sem links, print só como texto (a imagem é descartada logo depois da
/// leitura, RNF01). O reporte fica só em memória até ser publicado; numa
/// falha de envio, continua na tela para nova tentativa, sem cache (RNF07,
/// etapa 3).
class ReportarGolpePage extends StatefulWidget {
  const ReportarGolpePage({
    super.key,
    required this.captura,
    required this.reconhecedor,
    this.repositorio,
  });

  final CapturaImagem captura;
  final ReconhecedorTexto reconhecedor;
  final ReporteRepository? repositorio;

  static const String avisoPublico =
      'Seu reporte aparece para outras pessoas do Phize, sem seu nome. '
      'Escondemos CPF, telefone, e-mail, cartão e links, mas nomes e o resto '
      'do texto ficam visíveis. Use só conteúdo de teste.';

  @override
  State<ReportarGolpePage> createState() => _ReportarGolpePageState();
}

class _ReportarGolpePageState extends State<ReportarGolpePage> {
  late final ReporteRepository _repositorio =
      widget.repositorio ?? ReporteRepositoryFirestore();

  final _link = TextEditingController();
  final _titulo = TextEditingController();
  final _relato = TextEditingController();
  TipoReporte _tipo = TipoReporte.link;
  CategoriaAmeaca _categoria = CategoriaAmeaca.outroGolpe;
  bool _enviando = false;
  bool _lendoPrint = false;
  String? _erro;

  static final _categorias = CategoriaAmeaca.values
      .where((c) => c != CategoriaAmeaca.semIndicios)
      .toList();

  @override
  void dispose() {
    _link.dispose();
    _titulo.dispose();
    _relato.dispose();
    super.dispose();
  }

  Future<void> _colar() async {
    String? texto;
    try {
      texto = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    } catch (_) {
      texto = null;
    }
    if (!mounted) return;
    setState(() {
      if (texto == null || texto.isEmpty) {
        _erro =
            'Nenhum link copiado. Na conversa, toque e segure o link, '
            'escolha "Copiar" e volte aqui.';
      } else {
        _link.text = texto;
        _erro = null;
      }
    });
  }

  /// Lê o texto do print no aparelho e já o deixa mascarado no campo, para a
  /// pessoa revisar antes de publicar. A imagem é descartada por
  /// [CapturaImagem] ao fim da leitura, com sucesso ou falha.
  Future<void> _escolherPrint() async {
    setState(() {
      _lendoPrint = true;
      _erro = null;
    });
    String? textoPublicoDoPrint;
    String? erro;
    try {
      final lido = await widget.captura.processar(
        (imagem) => widget.reconhecedor.reconhecer(imagem),
      );
      if (lido != null) {
        textoPublicoDoPrint = textoPublico(lido);
        if (textoPublicoDoPrint.isEmpty) {
          erro = 'Não encontramos texto nesse print. Tente outro.';
        }
      }
    } catch (_) {
      // Sem expor a exceção: ela pode trazer o nome original do arquivo.
      erro = 'Não foi possível ler o print. Tente de novo.';
    }
    if (!mounted) return;
    setState(() {
      _lendoPrint = false;
      _erro = erro;
      if (erro == null && textoPublicoDoPrint != null) {
        _relato.text = textoPublicoDoPrint.length > tamanhoMaximoRelato
            ? textoPublicoDoPrint.substring(0, tamanhoMaximoRelato)
            : textoPublicoDoPrint;
      }
    });
  }

  Future<void> _publicar() async {
    final PreparacaoReporte preparacao;
    try {
      preparacao = prepararReporte(
        tipo: _tipo,
        titulo: _titulo.text,
        relato: _relato.text,
        categoria: _categoria,
        link: _link.text,
      );
    } catch (_) {
      setState(() => _erro = 'Não foi possível preparar o reporte.');
      return;
    }
    switch (preparacao) {
      case ReporteRecusado(:final motivo):
        setState(() => _erro = motivo.mensagem);
        return;
      case ReportePronto(:final reporte):
        setState(() {
          _enviando = true;
          _erro = null;
        });
        ResultadoPublicacao resultado;
        try {
          resultado = await _repositorio.publicar(reporte);
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _enviando = false;
            _erro =
                'Não foi possível enviar o reporte agora. Confira a conexão '
                'e tente de novo.';
          });
          return;
        }
        if (!mounted) return;
        _link.clear();
        _titulo.clear();
        _relato.clear();
        setState(() => _enviando = false);
        await _mostrarResultado(resultado);
        if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _mostrarResultado(ResultadoPublicacao resultado) {
    final (titulo, texto) = switch (resultado) {
      ResultadoPublicacao.publicado => (
        'Obrigado!',
        'Seu reporte foi publicado na comunidade e aguarda revisão da '
            'equipe.',
      ),
      ResultadoPublicacao.incidenciaRegistrada => (
        'Obrigado!',
        'Esse link já tinha sido reportado. Contamos o seu como mais um caso.',
      ),
      ResultadoPublicacao.jaRegistradoPorVoce => (
        'Você já reportou este link',
        'Cada conta conta uma vez por link.',
      ),
      ResultadoPublicacao.emRevisao => (
        'Link em revisão',
        'Esse link já foi reportado e está em revisão pela equipe.',
      ),
    };
    return showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        key: const Key('reportar_resultado'),
        title: Text(titulo),
        content: Text(texto),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _enviando || _lendoPrint;
    final rotuloRelato = switch (_tipo) {
      TipoReporte.link => 'O que dizia a mensagem (opcional)',
      TipoReporte.relato => 'O que aconteceu',
      TipoReporte.print => 'Texto do print (revise antes de publicar)',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar golpe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ReportarGolpePage.avisoPublico,
                key: const Key('reportar_aviso'),
                style: TextStyle(color: context.cores.textoSecundario),
              ),
              const SizedBox(height: 20),
              SegmentedButton<TipoReporte>(
                key: const Key('reportar_tipo'),
                segments: [
                  for (final tipo in TipoReporte.values)
                    ButtonSegment(
                      value: tipo,
                      label: Text(tipo.nome),
                      // Sem galeria nem OCR embarcado na web.
                      enabled: !(kIsWeb && tipo == TipoReporte.print),
                    ),
                ],
                selected: {_tipo},
                showSelectedIcon: false,
                onSelectionChanged: ocupado
                    ? null
                    : (selecao) => setState(() {
                        _tipo = selecao.first;
                        _erro = null;
                      }),
              ),
              const SizedBox(height: 20),
              if (_tipo == TipoReporte.link) ...[
                TextField(
                  key: const Key('reportar_link'),
                  controller: _link,
                  enabled: !ocupado,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Link suspeito',
                    hintText: 'https://...',
                    border: const OutlineInputBorder(),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        key: const Key('reportar_colar'),
                        onPressed: ocupado ? null : _colar,
                        child: const Text('Colar'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_tipo == TipoReporte.print) ...[
                OutlinedButton.icon(
                  key: const Key('reportar_escolher_print'),
                  onPressed: ocupado ? null : _escolherPrint,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Escolher print'),
                ),
                if (_lendoPrint) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: 16),
              ],
              TextField(
                key: const Key('reportar_titulo'),
                controller: _titulo,
                enabled: !ocupado,
                maxLength: tamanhoMaximoTitulo,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex.: Falso parente pedindo Pix',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CategoriaAmeaca>(
                key: const Key('reportar_categoria'),
                initialValue: _categoria,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de golpe',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final categoria in _categorias)
                    DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.nome),
                    ),
                ],
                onChanged: ocupado
                    ? null
                    : (categoria) =>
                          setState(() => _categoria = categoria ?? _categoria),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('reportar_relato'),
                controller: _relato,
                enabled: !ocupado,
                minLines: 3,
                maxLines: 8,
                maxLength: tamanhoMaximoRelato,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: rotuloRelato,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_erro case final erro?) ...[
                const SizedBox(height: 8),
                Text(
                  erro,
                  key: const Key('reportar_erro'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('reportar_publicar'),
                onPressed: ocupado ? null : _publicar,
                child: _enviando
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publicar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
