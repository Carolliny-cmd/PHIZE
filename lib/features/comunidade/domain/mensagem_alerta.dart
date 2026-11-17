import 'novo_reporte.dart';
import 'reporte_comunidade.dart';

/// Mensagem padronizada para compartilhar um alerta fora do app (RF09): o
/// aviso de segurança, os detalhes da ameaça e a identidade do Phize. Usa só
/// o que já é público no feed (título e relato mascarados, sem link).
String mensagemDoAlerta(ReporteComunidade reporte) {
  final linhas = <String>[
    'Alerta de golpe (Phize)',
    '',
    reporte.titulo,
    'Tipo: ${reporte.categoria.nome}',
  ];
  final relato = reporte.relato.trim();
  if (relato.isNotEmpty) {
    linhas.addAll(['', relato]);
  }
  if (reporte.tipo == TipoReporte.link) {
    linhas.addAll([
      '',
      'Reporte de link suspeito. O Phize não mostra o endereço.',
    ]);
  }
  linhas.add('');
  linhas.add(
    reporte.incidencias == 1
        ? '1 pessoa relatou este golpe na comunidade do Phize.'
        : '${reporte.incidencias} pessoas relataram este golpe na comunidade '
              'do Phize.',
  );
  if (reporte.status == StatusReporte.pendente) {
    linhas.add('Relato da comunidade, ainda não revisado pela equipe.');
  }
  linhas.addAll([
    '',
    'Na dúvida, não clique em links, não passe códigos nem faça pagamentos. '
        'Confirme direto com a instituição, pelos canais oficiais.',
    '',
    'Enviado pelo Phize, app de prevenção a golpes.',
  ]);
  return linhas.join('\n');
}
