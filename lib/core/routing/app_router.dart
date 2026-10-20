import 'package:flutter/material.dart';

import '../../features/analise/data/analise_texto_client_http.dart';
import '../../features/analise/data/rdap_client_http.dart';
import '../../features/analise/data/reconhecedor_texto_mlkit.dart';
import '../../features/analise/data/reputacao_dominio_client_http.dart';
import '../../features/analise/data/seletor_imagem_galeria.dart';
import '../../features/analise/domain/analisador_link.dart';
import '../../features/analise/domain/analisador_print.dart';
import '../../features/analise/domain/analise_texto_client.dart';
import '../../features/analise/domain/captura_imagem.dart';
import '../../features/analise/domain/consulta_idade_dominio.dart';
import '../../features/analise/domain/consulta_reputacao_dominio.dart';
import '../../features/analise/domain/rdap_client.dart';
import '../../features/analise/domain/reconhecedor_texto.dart';
import '../../features/analise/domain/reputacao_dominio_client.dart';
import '../../features/analise/domain/resultado_analise_link.dart';
import '../../features/analise/domain/resultado_analise_print.dart';
import '../../features/analise/domain/seletor_imagem.dart';
import '../../features/analise/presentation/pages/analisar_link_page.dart';
import '../../features/analise/presentation/pages/analisar_print_page.dart';
import '../../features/analise/presentation/pages/dashboard_page.dart';
import '../../features/analise/presentation/pages/historico_page.dart';
import '../../features/analise/presentation/pages/resultado_analise_page.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
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
  }) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(authRepository: authRepository),
        );
      case AppRoutes.cadastro:
        return MaterialPageRoute(
          builder: (_) => CadastroPage(authRepository: authRepository),
        );
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case AppRoutes.historico:
        return MaterialPageRoute(builder: (_) => const HistoricoPage());
      case AppRoutes.analisarLink:
        return MaterialPageRoute(
          builder: (_) => AnalisarLinkPage(
            analisadorLink: AnalisadorLink(
              ConsultaIdadeDominio(rdapClient ?? RdapClientHttp()),
              ConsultaReputacaoDominio(
                reputacaoClient ??
                    ReputacaoDominioClientHttp.comFirebaseAuth(),
              ),
            ),
          ),
        );
      case AppRoutes.analisarPrint:
        return MaterialPageRoute(
          builder: (_) => AnalisarPrintPage(
            analisadorPrint: AnalisadorPrint(
              reconhecedor: reconhecedorTexto ?? ReconhecedorTextoMlKit(),
              cliente:
                  analiseTextoClient ??
                  AnaliseTextoClientHttp.comFirebaseAuth(),
            ),
            captura: CapturaImagem(seletorImagem ?? SeletorImagemGaleria()),
            authRepository: authRepository,
          ),
        );
      case AppRoutes.resultado:
        return MaterialPageRoute(
          builder: (_) => switch (settings.arguments) {
            final AnalisePrintConcluida resultado => ResultadoAnalisePage.print(
              resultado: resultado,
            ),
            final resultado => ResultadoAnalisePage(
              resultado: resultado as ResultadoAnaliseLink,
            ),
          },
        );
      default:
        return MaterialPageRoute(
          builder: (_) => LoginPage(authRepository: authRepository),
        );
    }
  }
}
