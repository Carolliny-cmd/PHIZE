# Gerador de prints fictícios

Ferramenta auxiliar para a validação manual da trilha de análise de print (UC04). Não faz parte do aplicativo.

Nesta fase, o RNF07 veda enviar conversas reais ao provedor de LLM. Por isso, os prints de teste são inventados: pessoas, instituições, CPF e telefone. O CPF tem dígitos verificadores válidos, mas não pertence a ninguém conhecido.

## Cenários

| Arquivo | Cenário | Sinais esperados (RF07) |
| --- | --- | --- |
| `phize-print-1-falso-parente.png` | Falso parente que alega troca de número | Alegação de troca de contato, pedido financeiro, indução de urgência |
| `phize-print-2-falsa-central.png` | Falsa central de segurança bancária | Alegação de troca de contato ("novo canal oficial"), solicitação de dados pessoais, ameaça |
| `phize-print-3-conversa-comum.png` | Conversa cotidiana | Nenhum |
| `phize-print-4-dados-estruturados.png` | CPF e celular no texto | Nenhum; valida o mascaramento (`[CPF]` e `[TELEFONE]`) |

Os pesos e as faixas esperadas saem de `docs/score-calibracao.md`, a fonte única desses valores. Enquanto não houver base de conhecimento (Fase 7), toda análise de print é tratada como verificação incompleta, e a faixa verde fica impedida.

## Gerar as imagens

1. Abra `index.html` direto no navegador (duplo clique). Não precisa de servidor, build nem internet.
2. Em cada cenário, clique em **Baixar PNG**. A imagem sai com 1080 px de largura, a resolução típica de um print de celular.

As conversas são desenhadas em `<canvas>`, com fonte grande e alto contraste, sem ícones nem emojis, para que o OCR leia só o texto. Para mudar um cenário, edite o bloco JSON `id="dados"` em `index.html`. O texto alterado continua obrigatoriamente fictício.

## Colocar na galeria do emulador Android

Opção 1: arraste os arquivos PNG para a janela do emulador. Eles vão para a pasta `Download` e aparecem na galeria.

Opção 2, por linha de comando, com o emulador ligado:

```
adb push phize-print-1-falso-parente.png /sdcard/Pictures/
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/phize-print-1-falso-parente.png
```

Se a imagem não aparecer na galeria, reinicie o emulador para forçar a indexação.

No app, use **Analisar print** e escolha a imagem na galeria.

## Sobre o cenário 4

O app não exibe o texto mascarado. No fluxo real, a confirmação do mascaramento é indireta: a análise segue adiante, porque a segunda verificação de volume passa, e a explicação não reproduz o CPF nem o telefone. O comportamento exato da rotina é coberto pelos testes de `mascaramento_local.dart`.
