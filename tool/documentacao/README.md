# Sincronização dos .docx acadêmicos

Os textos dos documentos acadêmicos vivem em `docs/*.md`, que são a fonte (CLAUDE.md, seção 7). Os `.docx` entregues à faculdade ficam em `docs/DOCS/`, fora do git. Estes scripts levam o texto dos `.md` aos `.docx` como **alterações controladas** do Word, mantendo a formatação, para a equipe revisar e aceitar no próprio Word.

Usados em 2026-11-17 (ver `docs/ROADMAP.md`, "Atualização da documentação"). Só a biblioteca padrão do Python; a conferência em PDF usa o Microsoft Word instalado.

| Script | O que faz |
| --- | --- |
| `sincronizar_docx.py` | Compara o `.docx` com o `.md`, parágrafo a parágrafo (e célula a célula nas tabelas), e grava um novo `.docx` com as diferenças como alterações controladas. Parágrafos novos copiam o estilo de um parágrafo do mesmo tipo. Gera um relatório do que mudou. |
| `trocar_imagens.py` | Troca imagens do `.docx` (por exemplo, os diagramas do UML) como alteração controlada: a antiga riscada, a nova inserida. |
| `docx_texto.py` | Extrai o texto de cada `.docx` (ignora o que está apagado em alterações controladas). |
| `comparar.py` | Compara esse texto com os `.md` e lista o que difere. Com as alterações aceitas, o resultado esperado é zero. |
| `docx_para_pdf.ps1` | Abre cada `.docx` no Word (confirma que o arquivo está íntegro) e exporta PDF com as alterações visíveis. |
| `aceito_pdf.ps1` | Exporta páginas de uma cópia com todas as alterações aceitas, só para conferir o resultado final. |
| `mermaid-config.json` | Configuração usada para gerar as imagens de `docs/diagramas/`. |

## Passo a passo

```bash
python -I tool/documentacao/sincronizar_docx.py docs/DOCS/Requisitos_de_Software_Phize_corrigido.docx docs/requisitos.md docs/DOCS/Requisitos_de_Software_Phize_atualizado.docx --relatorio relatorio.txt
```

```bash
python -I tool/documentacao/docx_texto.py docs/DOCS pasta_txt
```

```bash
python -I tool/documentacao/comparar.py pasta_txt . diferencas.txt
```

O `comparar.py` espera os nomes de arquivo da tabela `PARES` dentro dele; ajuste se os `.docx` mudarem de nome.

Limites conhecidos: parágrafos com tabulação, quebra de linha ou desenho não são reescritos (o relatório marca "MANUAL" para conferir à mão), e uma tabela com linhas a mais ou a menos que o `.md` também fica para conferência manual.
