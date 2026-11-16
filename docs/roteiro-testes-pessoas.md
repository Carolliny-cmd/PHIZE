# Roteiro dos testes com pessoas

Fase 9, item 5 do `docs/ROADMAP.md`. Versão 1.2 (2026-11-16), proposta para revisão da equipe.

## 1. Objetivo

Observar pessoas do público do Phize, principalmente idosos e pessoas com pouca familiaridade digital (persona Dona Neuza, `docs/requisitos.md`, seção 4), usando o app sem ajuda, para responder:

| Pergunta | Requisito |
| --- | --- |
| A pessoa consegue analisar um link e um print sozinha? | RF03, RF04 |
| A pessoa entende o resultado: o número, a cor e o rótulo da faixa? Entende que verde não quer dizer "seguro"? | RF07 |
| A pessoa sabe o que fazer depois de ver o resultado? | RF07 ("O que fazer agora") |
| O tutorial da primeira vez ajuda ou atrapalha? | RF13 |
| A pessoa consegue mandar um print direto da galeria para o Phize? | RF10 |
| A pessoa encontra o histórico e consegue aumentar a letra? | RF14 |
| A espera da análise parece longa demais? | RNF03 |

O teste avalia o app, não a pessoa. Não há resposta certa ou errada.

## 2. Participantes

- **Quantidade:** de 5 a 8 pessoas. Com 5, já aparecem a maior parte dos problemas de uso.
- **Perfis:**
  - pelo menos 3 com 60 anos ou mais, ou que usem o celular só para conversar e fazer ligações (Dona Neuza);
  - pelo menos 1 que receba muitas mensagens de desconhecidos no trabalho (persona Ana);
  - se possível, 1 que costume ajudar a família com o celular (persona Ricardo).
- **Critérios:** usar WhatsApp ou SMS no dia a dia; aceitar participar depois de ouvir o termo de consentimento (seção 3).
- **Não participam:** membros da equipe e pessoas que já viram o app.

## 3. Ética e privacidade

- **Só conteúdo fictício.** O Phize usa a versão gratuita do Gemini, e o Google pode usar o texto enviado (RNF07, limitação de escopo acadêmico). Por isso, **o participante não usa o próprio celular nem as próprias conversas**. Todos os prints e links vêm da seção 5 deste roteiro.
- **Consentimento antes de começar**, lido em voz alta e assinado. Modelo na seção 9.
- **O que é anotado:** só o que a pessoa faz e diz sobre o app, sem nome. Cada participante recebe um código (P1, P2...). Idade e perfil vão em faixas (ex.: 60 a 69 anos).
- **Gravação:** preferencialmente nenhuma. Se a equipe precisar, só da tela do celular de teste e com autorização marcada no termo. Nada de rosto ou voz.
- **A pessoa pode parar a qualquer momento**, sem precisar explicar.
- **Comitê de ética (decisão da equipe, 2026-11-16):** não foi possível consultar a instituição sobre a necessidade de aprovação de comitê de ética em pesquisa (CEP). Os testes seguem enquadrados como **avaliação de usabilidade do app, realizada como atividade do projeto acadêmico**, buscando o perfil das atividades dispensadas pela Resolução CNS 510/2016:
  - o objetivo é melhorar o Phize, não produzir conhecimento sobre os participantes;
  - nenhum dado que identifique a pessoa é coletado (códigos, faixas de idade, sem gravação de rosto ou voz);
  - risco mínimo: conteúdo fictício, celular da equipe, nenhum tema sensível, liberdade de parar a qualquer momento;
  - termo de consentimento mantido, mesmo sem exigência formal;
  - os resultados ficam restritos ao trabalho acadêmico.

  **No relatório**, descrever assim: "avaliação de usabilidade com participantes voluntários, realizada como atividade do projeto acadêmico, sem coleta de dados pessoais, com termo de consentimento e uso exclusivo de conteúdo fictício". Não apresentar como pesquisa científica com seres humanos nem divulgar os resultados fora do trabalho.

  **Risco aceito:** a instituição pode entender depois que a aprovação era necessária. Os cuidados acima reduzem esse risco, mas não o eliminam. Para reduzir ainda mais, a equipe pode recrutar os participantes no próprio convívio (familiares e conhecidos), com o mesmo roteiro.

## 4. Preparação técnica (antes de cada dia de teste)

As Cloud Functions só rodam no emulador local (decisão de 2026-11-12), então o celular de teste fica ligado ao computador da equipe.

**Na máquina da equipe** (comandos em `docs/emulador-local.md`):

1. Subir os emuladores de Functions, Auth e Firestore.
2. **Aquecer as Functions:** `bash tool/emuladores/aquecer_functions.sh`. Sem isso, a primeira análise de link mostra a lista do Google como "verificação não concluída".
3. Conferir que `functions/.env.local` tem as chaves do Safe Browsing e do Gemini (sem abrir o arquivo na frente do participante).

**No celular de teste:**

4. Usar um celular Android físico, de tela média ou grande, ligado por cabo. O emulador no computador não serve para este público.
5. Instalar o build de debug com `127.0.0.1` nas três variáveis e ligar o redirecionamento de portas: `adb reverse tcp:9099 tcp:9099`, `adb reverse tcp:8085 tcp:8085` e `adb reverse tcp:5001 tcp:5001` (`docs/emulador-local.md`, "HTTP sem TLS para o emulador").
6. Colocar na galeria os prints da seção 5 e apagar qualquer outra imagem.
7. Deixar no app de notas do celular as mensagens com os links da seção 5.
8. **Para cada participante, criar uma conta nova** (ex.: `p1@teste.phize`, com senha de teste anotada só na ficha da equipe). Conta nova garante que o tutorial e o aviso de privacidade aparecem como na primeira vez.
9. Voltar o tamanho da letra para "Normal" e o tema para "Igual ao do celular".
10. Fazer o **ensaio** (seção 8) no primeiro dia, antes do primeiro participante.

## 5. Materiais fictícios

**Prints** (gerados por `tools/gerador-prints/index.html`, botão "Baixar PNG"):

| Print | Cenário | Resultado esperado |
| --- | --- | --- |
| `phize-print-1-falso-parente.png` | falso parente com número novo pedindo Pix | vermelho, golpe do falso parente |
| `phize-print-2-falsa-central.png` | falsa central do banco pedindo dados | vermelho ou amarelo |
| `phize-print-3-conversa-comum.png` | conversa do dia a dia | verde, "Não encontramos sinais de golpe" |
| `phize-print-4-dados-estruturados.png` | conversa com CPF e celular | verde ou amarelo; CPF e telefone não aparecem na explicação |

**Mensagens com link** (no app de notas do celular de teste):

| Mensagem | Resultado esperado |
| --- | --- |
| "Sua encomenda está retida. Regularize em http://testsafebrowsing.appspot.com/s/phishing.html" | vermelho: endereço de teste oficial do Google, sempre apontado como perigoso |
| "Consulte o rastreio em https://www.correios.com.br" | verde (confirmado no ensaio) |

Os resultados esperados foram confirmados no ensaio de 2026-11-16 (seção 11). Links oficiais no formato `www.gov.br/...` não servem como exemplo de verde: dão amarelo por verificação incompleta.

## 6. Sessão (cerca de 40 minutos)

**Papéis:** um moderador, que conversa com a pessoa, e um observador, que anota na ficha (seção 7). O moderador não explica o app nem aponta botões. Se a pessoa travar por mais de 2 minutos, ele pode dar uma dica, e a tarefa conta como "com ajuda".

### Abertura (5 min)

> "Obrigado por vir. Estamos testando um aplicativo que ajuda a descobrir se uma mensagem é golpe. Quem está sendo testado é o aplicativo, não você: se algo ficar difícil, a culpa é dele, e é isso que queremos descobrir. Vou pedir algumas tarefas. Fale em voz alta o que estiver pensando, mesmo que pareça bobo. Nada aqui é conversa de verdade: todas as mensagens foram inventadas por nós."

Ler o termo de consentimento e colher a assinatura.

Perguntas iniciais (anotar em faixas):
- Que celular você usa? Usa WhatsApp todo dia?
- Já recebeu mensagem de golpe? O que fez?

### Tarefas

Entregar o celular já logado na conta do participante, na tela de Início. Ler cada tarefa em voz alta, uma por vez.

| # | Tarefa (como falar) | O que observar | Sucesso |
| --- | --- | --- | --- |
| T1 | "Você recebeu esta mensagem com um link (mostrar a nota da encomenda). Use o aplicativo para saber se é golpe." | Abre "Analisar link"? Vê o tutorial até o fim, pula ou se perde? Consegue copiar e colar? | Chega ao resultado do link |
| T2 | "O que o aplicativo está dizendo? O que você faria agora?" | Lê a cor, o número ou o rótulo? Lê "O que fazer agora"? | Diz que é perigoso e que não deve abrir ou pagar |
| T3 | "Agora você recebeu esta conversa (mostrar o print 1 na galeria). Veja se é golpe." | Acha "Analisar print"? Entende o aviso de privacidade? Escolhe a imagem certa? Como reage à espera? | Chega ao resultado do print |
| T4 | "Por que o aplicativo acha isso? Quais partes da mensagem chamaram atenção?" | Encontra os sinais e as frases destacadas? | Cita pelo menos um motivo mostrado na tela |
| T5 | "Esta outra conversa (print 3), é golpe?" | Interpreta o verde. Diz "é seguro"? | Diz que não encontrou sinais, sem afirmar que é seguro |
| T6 | "Abra a galeria, escolha o print 2 e mande para o Phize sem abrir o aplicativo antes." | Usa o botão compartilhar e escolhe o Phize? | Resultado aberto a partir da galeria |
| T7 | "Onde você veria as análises que fez hoje?" | Encontra a aba Histórico? | Abre o histórico |
| T8 | "A letra está boa para você? Se quiser maior, tente aumentar no aplicativo." | Encontra Perfil e Tamanho da letra? | Muda o tamanho da letra |

Depois da T5, perguntar: "Quando a tela fica verde, o que isso quer dizer para você?" (verifica o entendimento de que verde não garante segurança).

### Encerramento (10 min)

1. Questionário SUS (seção 7.2), lido em voz alta se a pessoa preferir.
2. Perguntas abertas:
   - "O que foi mais fácil? E o mais difícil?"
   - "Você usaria esse aplicativo quando recebesse uma mensagem estranha? Por quê?"
   - "A explicação do tutorial ajudou? Teria pulado?"
   - "Mudaria alguma palavra que estava na tela?"
3. Agradecer. Lembrar que as mensagens eram inventadas e que nada da conversa foi guardado.

Depois que a pessoa sair: excluir a conta de teste dela pelo próprio app (Perfil, "Excluir minha conta") e conferir que o histórico sumiu.

## 7. Coleta

### 7.1 Ficha de observação (uma por participante)

| Campo | Conteúdo |
| --- | --- |
| Código | P1, P2... |
| Faixa de idade e perfil | ex.: 60 a 69, Dona Neuza |
| Para cada tarefa (T1 a T8) | **sem ajuda / com ajuda / não concluiu**; tempo aproximado; onde travou; frases ditas em voz alta (sem dados pessoais) |
| Entendimento do verde (depois da T5) | resposta da pessoa |
| Tutorial | viu até o fim / pulou / se perdeu |
| Erros do app | qualquer erro, tela travada ou resultado inesperado, com o horário |

### 7.2 Questionário SUS (System Usability Scale)

Cada frase com nota de 1 (discordo totalmente) a 5 (concordo totalmente):

1. Eu usaria este aplicativo com frequência.
2. Achei o aplicativo mais complicado do que precisava.
3. Achei o aplicativo fácil de usar.
4. Eu precisaria de ajuda de outra pessoa para usar este aplicativo.
5. As partes do aplicativo funcionam bem juntas.
6. Achei coisas sem sentido ou fora do lugar no aplicativo.
7. Acho que a maioria das pessoas aprenderia a usar este aplicativo rapidamente.
8. Achei o aplicativo cansativo de usar.
9. Me senti confiante usando o aplicativo.
10. Precisei aprender muitas coisas antes de conseguir usar o aplicativo.

Cálculo: nas frases ímpares, nota menos 1; nas pares, 5 menos a nota; somar e multiplicar por 2,5. O resultado vai de 0 a 100; acima de 68 costuma ser considerado acima da média.

## 8. Ensaio

Antes do primeiro participante, um membro da equipe faz a sessão inteira no celular de teste, como se fosse participante:

- confirma os resultados esperados da seção 5;
- mede o tempo de cada tarefa e o total;
- confere a preparação técnica da seção 4 (principalmente o aquecimento e o `adb reverse`);
- ajusta as falas do roteiro que soarem estranhas.

O ensaio não entra nos resultados.

## 9. Modelo do termo de consentimento

> Você está sendo convidado(a) a testar o Phize, um aplicativo em desenvolvimento como projeto acadêmico, que ajuda a identificar mensagens de golpe.
>
> Durante cerca de 40 minutos, você usará um celular da equipe para fazer algumas tarefas, falando em voz alta o que pensa. Todas as mensagens usadas foram inventadas pela equipe: você não usará seu celular nem suas conversas.
>
> Anotaremos o que você faz no aplicativo e suas opiniões sobre ele, sem seu nome. Os resultados serão usados apenas no trabalho acadêmico, de forma que você não possa ser identificado(a).
>
> ( ) Autorizo a gravação da tela do celular de teste. Não haverá gravação do meu rosto nem da minha voz.
>
> Sua participação é voluntária. Você pode parar a qualquer momento, sem precisar dar motivo.
>
> Nome: ______________________ Assinatura: ______________________ Data: ___/___/______

O termo assinado fica com a equipe, separado das fichas de observação, para que o nome não fique junto das anotações.

## 10. Análise e registro

- Para cada tarefa, contar quantos concluíram sem ajuda, com ajuda e não concluíram.
- **Metas de referência:** pelo menos 4 de 5 participantes concluem T1 e T3 sem ajuda; pelo menos 4 de 5 interpretam corretamente o vermelho (T2) e o verde (T5).
- Calcular a média e a variação do SUS.
- Listar os problemas encontrados por gravidade: **impede a tarefa**, **atrasa ou confunde** e **detalhe**.
- Registrar o resultado em `docs/resultados-testes-pessoas.md`, só com códigos de participante e faixas, nunca com nome, telefone ou conversa.
- Os problemas que exigirem mudança no app viram itens do `docs/ROADMAP.md`.

## 11. Registro do ensaio (2026-11-16)

Feito no emulador Android (sistema em inglês), com os emuladores do Firebase aquecidos e uma conta nova. As tarefas foram executadas pela IA, com acompanhamento da equipe pelas capturas de tela; por isso, o tempo de cada tarefa não representa um participante.

**Resultados esperados confirmados:**

| Material | Resultado no ensaio |
| --- | --- |
| Print 1 (falso parente) | 100, vermelho; golpe do falso parente citado pelo nome |
| Print 2 (falsa central), compartilhado da galeria | 100, vermelho |
| Print 3 (conversa comum) | 0, verde |
| Print 4 (CPF e celular) | 0, verde; CPF e celular não aparecem na explicação |
| Link da encomenda (endereço de teste do Google) | 70, vermelho |
| Link do gov.br | **amarelo**, e não verde: o RDAP não informa data de registro para o próprio `gov.br`, e verificação incompleta impede o verde (RF07). Trocado pelo link dos Correios, que deu 0, verde |

**Ajustes feitos neste roteiro:** o link do verde passou a ser o dos Correios (seção 5); no emulador, as mensagens com link foram enviadas como SMS (`adb emu sms send`), o que é mais realista que o app de notas.

**O que observar nas sessões, a partir do ensaio:**
- No app de mensagens, **um toque no link abre o navegador**. Se o participante abrir, o moderador anota e pede para voltar; não é preciso impedir antes.
- O balão "Colar" do Android é pequeno e aparece no canto do campo.
- O seletor de fotos mostra miniaturas cortadas e exige confirmar a escolha; o moderador mostra antes qual print usar.
- O botão "Entendi e concordo" do aviso de privacidade fica abaixo da dobra.
- Depois de um resultado, a volta ao Início pode exigir vários toques em "voltar" (as telas de resultado não têm a barra inferior).
- No celular dos participantes, deixar o sistema em português.

## Registro de versões

| Versão | Data | Alteração |
| --- | --- | --- |
| 1.0 | 2026-11-16 | Primeira versão, proposta para revisão da equipe. |
| 1.1 | 2026-11-16 | Enquadramento sem consulta ao comitê de ética (seção 3); gravação preferencialmente nenhuma. |
| 1.2 | 2026-11-16 | Registro do ensaio (seção 11); link do verde trocado pelo dos Correios. |
