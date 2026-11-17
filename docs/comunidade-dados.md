# Dados da comunidade no Firestore

Fase 10, etapa 10.1 (2026-11-16). Modelo de dados da comunidade (RF05, RF06, RF08, RF11, RF12, RF15, RF16) e o que as regras de `firestore.rules` garantem. Os requisitos prevalecem sobre este documento (`docs/requisitos.md`); a arquitetura, seções 5.5 e 5.7, traz os princípios.

## Coleções

| Caminho | Quem lê | Quem grava | Conteúdo |
| --- | --- | --- | --- |
| `reportes/{id}` | conta logada; oculto, só moderação | autor (criar, editar, excluir), qualquer conta (contadores +1), moderação (status, excluir) | reporte público, **sem autor** e **sem link em texto puro** |
| `reportes/{id}/curtidas/{uid}` | a própria conta | a própria conta, junto com o +1 | `criadoEm` |
| `reportes/{id}/denuncias/{uid}` | a própria conta e a moderação | a própria conta, junto com o +1 | `motivo`, `criadoEm` |
| `users/{uid}/reportes/{id}` | o dono | o dono, junto com o reporte | autoria (`criadoEm`) |
| `users/{uid}/incidencias/{id}` | o dono | o dono, junto com o +1 | "também recebi este golpe" (`criadoEm`) |
| `moderadores/{uid}` | o próprio moderador | **ninguém pelo app**: só a equipe, pelo console | marca de moderação (RF11) |
| `ameacas/{hash}` | conta logada | moderação | hash de ameaça validada, sem autor (`validadoEm`) |

## Reporte público (`reportes/{id}`)

| Campo | Regra |
| --- | --- |
| `tipo` | `link`, `print` ou `relato` |
| `titulo` | 3 a 80 caracteres, já mascarado no aparelho |
| `relato` | até 1.000 caracteres, já mascarado; obrigatório em `print` e `relato` (no print, é o texto extraído; a imagem nunca é gravada) |
| `categoria` | uma das 7 categorias de golpe de `docs/categorias-ameaca.md` (sem `sem_indicios`) |
| `hashLink` | só em `link`: SHA-256 do endereço normalizado (64 caracteres hexadecimais). O identificador do documento é a própria hash |
| `palavras` | até 20 palavras para a pesquisa (RF15) |
| `curtidas`, `denuncias`, `incidencias` | nascem em 0, 0 e 1; só sobem de 1 em 1 |
| `status` | nasce `pendente`; só a moderação muda para `aprovado` ou `oculto` |
| `criadoEm`, `editadoEm` | hora do servidor |

Nenhum outro campo é aceito: não há onde gravar autor, link em texto puro ou imagem.

## O que as regras garantem

- **Anonimato:** a autoria fica só em `users/{uid}/reportes`, que nenhuma outra conta lê. O reporte e a autoria são gravados juntos: um não existe sem o outro na criação.
- **Um reporte por link:** a hash é o identificador, então o segundo reporte do mesmo link é recusado. No app, ele vira incidência (+1), como pede o UC05.
- **Um voto, uma denúncia e uma incidência por conta:** cada +1 exige criar, na mesma gravação, a marca da conta (curtida, denúncia ou incidência). A marca não pode ser criada de novo, e o contador nunca sobe mais de 1.
- **Edição (RF16):** só o autor, só título, relato e palavras. Categoria, tipo, link e status não mudam.
- **Exclusão (RF16):** o autor exclui o reporte e a autoria juntos. Apagar só a autoria dissocia o autor e mantém o reporte (exclusão de conta com reporte validado, RF12).
- **Moderação (RF11):** só contas em `moderadores` mudam o status, leem ocultos e excluem reportes de outras contas. Ninguém se torna moderador pelo app.
- **Feed:** reporte oculto não é lido por conta comum; por isso, as consultas do feed filtram o status (`pendente` e `aprovado`), e uma consulta sem esse filtro é recusada inteira. "Em alta" ordena por `curtidas` e depois `criadoEm`; "Mais recentes", por `criadoEm` (índices compostos em `firestore.indexes.json`; etapa 10.3, `lib/features/comunidade/data/feed_repository_firestore.dart`). Ler um reporte que ainda não existe é permitido: é assim que o app confere se o link já foi reportado antes de publicar.
- **Hashes validadas (RF12):** `ameacas/{hash}` só guarda a data de validação e continua lá depois da exclusão do reporte de origem.

## O que fica para as próximas etapas

- **Ocultação automática com 3 denúncias (RF11):** feita por função acionada pela gravação da denúncia, na etapa 10.4. As regras já guardam o contador.
- **Mascaramento, normalização e hash:** feitos no aparelho (etapa 10.2, `lib/features/comunidade/domain/preparacao_reporte.dart`); as regras não leem o conteúdo, só o formato. A hash é o SHA-256 do domínio normalizado.
- **Recusa de domínio oficial (RF05):** feita no aparelho (etapa 10.2).

## Como rodar os testes das regras

Com o emulador do Firestore ligado (porta 8085, ver `docs/emulador-local.md`):

```bash
cd functions && npm run test:regras
```

Os testes (`functions/test/regrasComunidade.test.ts`) usam o projeto `demo-phize-regras`, separado do app, e só conteúdo fictício. Não fazem parte do `npm test`, que roda sem emulador.
