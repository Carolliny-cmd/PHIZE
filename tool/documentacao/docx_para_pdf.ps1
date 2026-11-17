param([string[]]$Arquivos)
# Abre cada .docx no Word (só leitura, sem reparo silencioso) e exporta PDF
# com as alterações controladas visíveis. Erro de abertura = arquivo inválido.
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
  foreach ($arq in $Arquivos) {
    $pdf = [System.IO.Path]::ChangeExtension($arq, '.pdf')
    try {
      $doc = $word.Documents.Open($arq, $false, $true, $false, '', '', $true, '', '', 0, 0, $false, $false, 0, $true)
      $revisoes = $doc.Revisions.Count
      $doc.ActiveWindow.View.RevisionsFilter.Markup = 2
      $doc.ExportAsFixedFormat($pdf, 17, $false, 0, 0, 1, 1, 7)
      $paginas = $doc.ComputeStatistics(2)
      $doc.Close($false)
      "OK  $([System.IO.Path]::GetFileName($arq)): $revisoes revisões, $paginas páginas"
    } catch {
      "ERRO $([System.IO.Path]::GetFileName($arq)): $($_.Exception.Message)"
    }
  }
} finally {
  $word.Quit()
}
