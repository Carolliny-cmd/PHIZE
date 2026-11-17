import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/domain/formatacao_data.dart';
import '../../../../shared/widgets/phize_bottom_nav.dart';
import '../../data/historico_repository_firestore.dart';
import '../../domain/analise_risco.dart';
import '../../domain/faixa_risco.dart';
import '../../domain/historico_repository.dart';
import '../../domain/resultado_analise_print.dart';
import '../../domain/rotulos_risco.dart';
import '../widgets/aviso_card.dart';

String nomeTipoEntrada(TipoEntrada tipo) => switch (tipo) {
  TipoEntrada.link => 'Link',
  TipoEntrada.imagem => 'Print',
};

/// Histórico de análises (UC06): lista cronológica apenas com o resultado de
/// cada análise, nunca o conteúdo original (RNF01, RNF07).
class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key, this.historicoRepository});

  final HistoricoRepository? historicoRepository;

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  // Resolvido só quando usado: criar o repositório real exige o Firebase
  // inicializado.
  late final HistoricoRepository _repositorio =
      widget.historicoRepository ?? HistoricoRepositoryFirestore();
  late Future<List<AnaliseRisco>> _analises = _repositorio.listar();

  void _tentarDeNovo() {
    setState(() {
      _analises = _repositorio.listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Análises')),
      body: FutureBuilder<List<AnaliseRisco>>(
        future: _analises,
        builder: (context, carga) {
          if (carga.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final analises = carga.data;
          if (carga.hasError || analises == null) {
            return _FalhaCarga(aoTentarDeNovo: _tentarDeNovo);
          }
          if (analises.isEmpty) return const _HistoricoVazio();
          return _ListaAnalises(analises: analises);
        },
      ),
      bottomNavigationBar: const PhizeBottomNav(currentIndex: 2),
    );
  }
}

class _ListaAnalises extends StatelessWidget {
  const _ListaAnalises({required this.analises});

  final List<AnaliseRisco> analises;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: analises.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == analises.length) {
          return const AvisoCard(
            key: Key('historico_aviso_permanente'),
            texto: RotulosRisco.avisoPermanente,
          );
        }
        final analise = analises[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: analise.faixa.corTexto,
              child: Text(
                '${analise.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(analise.faixa.rotulo),
            subtitle: Text(
              '${nomeTipoEntrada(analise.tipoEntrada)} · '
              '${formatarData(analise.data)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.detalheHistorico, arguments: analise),
          ),
        );
      },
    );
  }
}

class _HistoricoVazio extends StatelessWidget {
  const _HistoricoVazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Você ainda não fez nenhuma análise. Quando receber uma '
              'mensagem ou link suspeito, analise aqui no Phize e o resultado '
              'aparece nesta tela.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.dashboard),
              child: const Text('Fazer minha primeira análise'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FalhaCarga extends StatelessWidget {
  const _FalhaCarga({required this.aoTentarDeNovo});

  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível carregar seu histórico. Verifique sua '
              'conexão e tente novamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: aoTentarDeNovo,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
