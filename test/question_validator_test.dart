import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/utils/question_validator.dart';

void main() {
  group('matéria', () {
    test('vazia é inválida', () => expect(QuestionValidator.materia('  '), isNotNull));
    test('muito curta é inválida', () => expect(QuestionValidator.materia('ab'), isNotNull));
    test('normal é válida', () => expect(QuestionValidator.materia('Física'), isNull));
  });

  group('enunciado', () {
    test('vazio é inválido', () => expect(QuestionValidator.enunciado(''), isNotNull));
    test('curto demais é inválido', () => expect(QuestionValidator.enunciado('Oi?'), isNotNull));
    test('longo demais é inválido', () {
      expect(QuestionValidator.enunciado('a' * 501), isNotNull);
    });
    test('normal é válido', () {
      expect(QuestionValidator.enunciado('Quanto é 7 x 8?'), isNull);
    });
  });

  group('alternativa', () {
    test('vazia é inválida', () => expect(QuestionValidator.alternativa(' '), isNotNull));
    test('repetida (ignorando maiúsculas e espaços) é inválida', () {
      expect(
        QuestionValidator.alternativa(' Sol ', outras: ['lua', 'sol']),
        isNotNull,
      );
    });
    test('diferente das outras é válida', () {
      expect(QuestionValidator.alternativa('Sol', outras: ['Lua', 'Marte']), isNull);
    });
  });

  group('alternativa correta', () {
    test('null é inválido', () => expect(QuestionValidator.alternativaCorreta(null), isNotNull));
    test('fora de 0..4 é inválido', () => expect(QuestionValidator.alternativaCorreta(5), isNotNull));
    test('0 a 4 é válido', () {
      for (int i = 0; i < 5; i++) {
        expect(QuestionValidator.alternativaCorreta(i), isNull);
      }
    });
  });
}
