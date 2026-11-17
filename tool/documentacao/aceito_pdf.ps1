param([string]$Arquivo, [int]$De, [int]$Ate, [string]$Saida)
# Só para conferência: abre uma cópia, aceita todas as alterações e exporta
# as páginas [De, Ate]. Não grava nada no .docx.
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
  $doc = $word.Documents.Open($Arquivo, $false, $true)
  $doc.Revisions.AcceptAll()
  "páginas depois de aceitar: $($doc.ComputeStatistics(2))"
  $doc.ExportAsFixedFormat($Saida, 17, $false, 0, 3, $De, $Ate, 0)
  $doc.Close($false)
} finally {
  $word.Quit()
}
