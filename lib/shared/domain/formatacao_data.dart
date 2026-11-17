/// Data no formato dd/mm/aaaa, usada no histórico e na comunidade.
String formatarData(DateTime data) {
  return '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';
}
