import 'package:phize/features/analise/domain/consentimento_repository.dart';

class FakeConsentimentoRepository implements ConsentimentoRepository {
  FakeConsentimentoRepository({this.aceitou = true});

  bool aceitou;

  @override
  Future<bool> aceito() async => aceitou;

  @override
  Future<void> aceitar() async => aceitou = true;

  @override
  Future<void> revogar() async => aceitou = false;
}
