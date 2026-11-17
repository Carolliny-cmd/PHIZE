# Diagramas UML do Phize

Fonte dos diagramas de `docs/uml.md` (e do `.docx` do UML), em Mermaid. As imagens `.png` desta pasta são geradas a partir dos `.mmd` e são as que estão no `.docx`.

| Arquivo | Diagrama | Seção do UML |
| --- | --- | --- |
| `01-casos-de-uso.mmd` | Casos de uso | 2.1 |
| `02-sequencia-analise.mmd` | Sequência: análise de ameaças (print ou link) | 2.2, item 1 |
| `03-sequencia-cadastro.mmd` | Sequência: cadastro do usuário | 2.2, item 2 |
| `04-sequencia-reportes.mmd` | Sequência: gerenciamento de reportes (CRUD) | 2.2, item 3 |
| `05-classes.mmd` | Classes: entidades e modelos de dados | 2.3 |

Os diagramas seguem os documentos (`docs/requisitos.md`, `docs/casos-de-uso.md`, `docs/arquitetura.md`, `docs/comunidade-dados.md`) e o código. Ao mudar o sistema, mude o `.mmd` e gere a imagem de novo.

## Como gerar as imagens

Sem instalar nada: cole o conteúdo do `.mmd` em <https://mermaid.live> e exporte em PNG.

Ou, no computador, com o [mermaid-cli](https://github.com/mermaid-js/mermaid-cli) instalado numa pasta fora do projeto (pode usar o Microsoft Edge no lugar do Chromium):

```bash
mmdc -i docs/diagramas/05-classes.mmd -o docs/diagramas/05-classes.png -c tool/documentacao/mermaid-config.json -b white -s 2
```

Para usar o Edge, passe também `-p` com um arquivo `puppeteer.json` contendo `{"executablePath": "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", "headless": "shell"}`.

Para trocar as imagens no `.docx` do UML como alteração controlada, ver `tool/documentacao/README.md`.
