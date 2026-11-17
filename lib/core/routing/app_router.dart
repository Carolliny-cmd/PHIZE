import 'package:flutter/material.dart';

import '../../features/analise/data/analise_texto_client_http.dart';
import '../../features/analise/data/rdap_client_http.dart';
import '../../shared/data/reconhecedor_texto_mlkit.dart';
import '../../features/analise/data/reputacao_dominio_client_http.dart';
import '../../shared/data/seletor_imagem_galeria.dart';
import '../../features/analise/domain/analisador_link.dart';
import '../../features/analise/domain/analisador_print.dart';
import '../../features/analise/domain/analise_risco.dart';
import '../../features/analise/domain/analise_texto_client.dart';
import '../../features/analise/domain/caixa_compartilhamento.dart';
import '../../shared/domain/captura_imagem.dart';
import '../../features/analise/domain/consentimento_repository.dart';
import '../../features/analise/domain/consulta_idade_dominio.dart';
import '../../features/analise/domain/consulta_reputacao_dominio.dart';
import '../../features/analise/domain/historico_repository.dart';
import '../../features/analise/domain/rdap_client.dart';
import '../../shared/domain/reconhecedor_texto.dart';
import '../../features/analise/domain/reputacao_dominio_client.dart';
import '../../features/analise/domain/resultado_analise_link.dart';
import '../../features/analise/domain/resultado_analise_print.dart';
import '../../shared/domain/seletor_imagem.dart';
import '../../features/analise/domain/tutorial_repository.dart';
import '../../features/analise/presentation/pages/analisar_link_page.dart';
import '../../features/analise/presentation/pages/analisar_print_page.dart';
import '../../features/analise/presentation/pages/analise_compartilhada_page.dart';
import '../../features/analise/presentation/pages/dashboard_page.dart';
import '../../features/analise/presentation/pages/detalhe_historico_page.dart';
import '../../features/analise/presentation/pages/historico_page.dart';
import '../../features/analise/presentation/pages/resultado_analise_page.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/comunidade/domain/compartilhador_texto.dart';
import '../../features/comunidade/domain/feed_repository.dart';
import '../../features/comunidade/domain/meus_reportes_repository.dart';
import '../../features/comunidade/domain/moderacao_repository.dart';
import '../../features/comunidade/domain/reporte_comunidade.dart';
import '../../features/comunidade/domain/reporte_repository.dart';
import '../../features/comunidade/presentation/pages/comunidade_page.dart';
import '../../features/comunidade/presentation/pages/detalhe_reporte_page.dart';
import '../../features/comunidade/presentation/pages/editar_reporte_page.dart';
import '../../features/comunidade/presentation/pages/meus_reportes_page.dart';
import '../../features/comunidade/presentation/pages/moderacao_page.dart';
import '../../features/comunidade/presentation/pages/pesquisa_comunidade_page.dart';
import '../../features/comunidade/presentation/pages/reportar_golpe_page.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/conta/domain/compartilhador_arquivo.dart';
import '../../features/conta/domain/conta_repository.dart';
import '../../features/conta/presentation/pages/exclusao_pendente_page.dart';
import '../../features/conta/presentation/pages/perfil_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<void> onGenerateRoute(
    RouteSettings settings, {
    AuthRepository? authRepository,
    RdapClient? rdapClient,
    ReputacaoDominioClient? reputacaoClient,
    SeletorImagem? seletorImagem,
    ReconhecedorTexto? reconhecedorTexto,
    AnaliseTextoClient? analiseTextoClient,
    HistoricoRepository? historicoRepository,
    ContaRepository? contaRepository,
    CompartilhadorArquivo? compartilhador,
    CaixaCompartilhamento? caixaCompartilhamento,
    ConsentimentoRepository? consentimentoRepository,
    TutorialRepository? tutorialRepository,
    ReporteRepository? reporteRepository,
    FeedRepository? feedRepository,
    CompartilhadorTexto? compartilhadorTexto,
    ModeracaoRepository? moderacaoRepository,
    MeusReportesRepository? meusReportesRepository,
  }) {
    final caixa = caixaCompartilhamento ?? CaixaCompartilhamento.instancia;

    AnalisadorLink criarAnalisadorLink() => AnalisadorLink(
      ConsultaIdadeDominio(rdapClient ?? RdapClientHttp()),
      ConsultaReputacaoDominio(
        reputacaoClient ?? ReputacaoDominioClientHttp.comFirebaseAuth(),
      ),
    );

    AnalisadorPrint criarAnalisadorPrint() => AnalisadorPrint(
      reconhecedor: reconhecedorTexto ?? ReconhecedorTextoMlKit(),
      cliente: analiseTextoClient ?? AnaliseTextoClientHttp.comFirebaseAuth(),
    );

    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(
            authRepository: authRepository,
            contaRepository: contaRepository,
            caixaCompartilhamento: caixa,
          ),
        );
      case AppRoutes.cadastro:
        return MaterialPageRoute(
          builder: (_) => CadastroPage(
            authRepository: authRepository,
            caixaCompartilhamento: caixa,
          ),
        );
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case AppRoutes.historico:
        return MaterialPageRoute(
          builder: (_) =>
              HistoricoPage(historicoRepository: historicoRepository),
        );
      case AppRoutes.detalheHistorico:
        return MaterialPageRoute(
          builder: (_) =>
              DetalheHistoricoPage(analise: settings.arguments as AnaliseRisco),
        );
      case AppRoutes.analisarLink:
        return MaterialPageRoute(
          builder: (_) => AnalisarLinkPage(
            analisadorLink: criarAnalisadorLink(),
            historicoRepository: historicoRepository,
            tutorialRepository: tutorialRepository,
          ),
        );
      case AppRoutes.analisarPrint:
        return MaterialPageRoute(
          builder: (_) => AnalisarPrintPage(
            analisadorPrint: criarAnalisadorPrint(),
            captura: CapturaImagem(seletorImagem ?? SeletorImagemGaleria()),
            authRepository: authRepository,
            historicoRepository: historicoRepository,
            consentimentoRepository: consentimentoRepository,
            tutorialRepository: tutorialRepository,
          ),
        );
      case AppRoutes.analiseCompartilhada:
        return MaterialPageRoute(
          builder: (_) => AnaliseCompartilhadaPage(
            caixa: caixa,
            analisadorPrint: criarAnalisadorPrint(),
            analisadorLink: criarAnalisadorLink(),
            historicoRepository: historicoRepository,
            authRepository: authRepository,
            consentimentoRepository: consentimentoRepository,
          ),
        );
      case AppRoutes.perfil:
        return MaterialPageRoute(
          builder: (_) => PerfilPage(
            contaRepository: contaRepository,
            historicoRepository: historicoRepository,
            compartilhador: compartilhador,
            authRepository: authRepository,
            consentimentoRepository: consentimentoRepository,
            tutorialRepository: tutorialRepository,
            meusReportesRepository: meusReportesRepository,
          ),
        );
      case AppRoutes.comunidade:
        return MaterialPageRoute(
          builder: (_) => ComunidadePage(
            repositorio: feedRepository,
            moderacao: moderacaoRepository,
          ),
        );
      case AppRoutes.detalheReporte:
        return MaterialPageRoute(
          builder: (_) => DetalheReportePage(
            reporte: settings.arguments as ReporteComunidade,
            repositorio: feedRepository,
            compartilhador: compartilhadorTexto,
          ),
        );
      case AppRoutes.pesquisaComunidade:
        return MaterialPageRoute(
          builder: (_) => PesquisaComunidadePage(repositorio: feedRepository),
        );
      case AppRoutes.meusReportes:
        return MaterialPageRoute(
          builder: (_) => MeusReportesPage(repositorio: meusReportesRepository),
        );
      case AppRoutes.editarReporte:
        return MaterialPageRoute<bool>(
          builder: (_) => EditarReportePage(
            reporte: settings.arguments as ReporteComunidade,
            repositorio: meusReportesRepository,
          ),
        );
      case AppRoutes.moderacao:
        return MaterialPageRoute(
          builder: (_) => ModeracaoPage(repositorio: moderacaoRepository),
        );
      case AppRoutes.reportarGolpe:
        return MaterialPageRoute(
          builder: (_) => ReportarGolpePage(
            captura: CapturaImagem(seletorImagem ?? SeletorImagemGaleria()),
            reconhecedor: reconhecedorTexto ?? ReconhecedorTextoMlKit(),
            repositorio: reporteRepository,
          ),
        );
      case AppRoutes.exclusaoPendente:
        return MaterialPageRoute(
          builder: (_) => ExclusaoPendentePage(
            contaRepository: contaRepository,
            authRepository: authRepository,
          ),
        );
      case AppRoutes.resultado:
        return MaterialPageRoute(
          builder: (_) => switch (settings.arguments) {
            final AnalisePrintConcluida resultado => ResultadoAnalisePage.print(
              resultado: resultado,
              tutorialRepository: tutorialRepository,
            ),
            final resultado => ResultadoAnalisePage(
              resultado: resultado as ResultadoAnaliseLink,
              tutorialRepository: tutorialRepository,
            ),
          },
        );
      default:
        return MaterialPageRoute(
          builder: (_) => LoginPage(
            authRepository: authRepository,
            contaRepository: contaRepository,
            caixaCompartilhamento: caixa,
          ),
        );
    }
  }
}
