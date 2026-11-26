import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/services/correcao_repository.dart';

void main() {
  group('idDaCorrecao', () {
    test('prova individual usa provaId_individualId', () {
      expect(
        idDaCorrecao(provaId: 'prova1', individualId: 'ind7'),
        'prova1_ind7',
      );
    });

    test('mesma prova para todos normaliza nome com acento e espaços', () {
      expect(
        idDaCorrecao(
          provaId: 'prova1',
          individualId: 'unica',
          alunoDigitado: 'João da Conceição',
        ),
        'prova1_unica_joao-da-conceicao',
      );
    });

    test('nomes diferentes geram IDs diferentes', () {
      final a = idDaCorrecao(
        provaId: 'prova1',
        individualId: 'unica',
        alunoDigitado: 'Ana Souza',
      );
      final b = idDaCorrecao(
        provaId: 'prova1',
        individualId: 'unica',
        alunoDigitado: 'Ana Silva',
      );
      expect(a, isNot(b));
    });

    test('mesmo nome com maiúsculas/espaços extras gera o mesmo ID', () {
      final a = idDaCorrecao(
        provaId: 'prova1',
        individualId: 'unica',
        alunoDigitado: 'Maria José',
      );
      final b = idDaCorrecao(
        provaId: 'prova1',
        individualId: 'unica',
        alunoDigitado: '  MARIA   José ',
      );
      expect(a, b);
    });
  });
}
