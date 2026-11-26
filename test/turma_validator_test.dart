import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/utils/texto_utils.dart';
import 'package:trabalho/utils/turma_validator.dart';

void main() {
  group('TextoUtils', () {
    test('normalizarEspacos tira espaços das pontas e do meio', () {
      expect(TextoUtils.normalizarEspacos('  3º   Ano  A '), '3º Ano A');
    });

    test('chaveDeComparacao ignora acento, maiúsculas e espaços extras', () {
      expect(
        TextoUtils.chaveDeComparacao(' João  da SILVA '),
        TextoUtils.chaveDeComparacao('joao da silva'),
      );
      expect(TextoUtils.chaveDeComparacao('Ação'), 'acao');
    });

    test('textos diferentes têm chaves diferentes', () {
      final a = TextoUtils.chaveDeComparacao('3º Ano A');
      final b = TextoUtils.chaveDeComparacao('3º Ano B');
      expect(a == b, isFalse);
    });
  });

  group('TurmaValidator.nome', () {
    test('vazio ou só espaços é inválido', () {
      expect(TurmaValidator.nome(null), isNotNull);
      expect(TurmaValidator.nome('   '), isNotNull);
    });

    test('curto demais é inválido', () {
      expect(TurmaValidator.nome('A1'), isNotNull);
    });

    test('longo demais é inválido', () {
      expect(TurmaValidator.nome('a' * 61), isNotNull);
    });

    test('nome normal é válido', () {
      expect(TurmaValidator.nome('3º Ano C - ADS'), isNull);
    });
  });

  group('AlunoValidator.nome', () {
    test('vazio é inválido', () {
      expect(AlunoValidator.nome(''), isNotNull);
    });

    test('com números é inválido', () {
      expect(AlunoValidator.nome('Ana 2'), isNotNull);
    });

    test('nome normal é válido', () {
      expect(AlunoValidator.nome('Ana Souza'), isNull);
      expect(AlunoValidator.nome('  João   da Silva '), isNull);
    });

    test('longo demais é inválido', () {
      expect(AlunoValidator.nome('a' * 81), isNotNull);
    });
  });

  group('AlunoValidator.matricula', () {
    test('vazia é inválida', () {
      expect(AlunoValidator.matricula(' '), isNotNull);
    });

    test('com espaço no meio é inválida', () {
      expect(AlunoValidator.matricula('20 24'), isNotNull);
    });

    test('com símbolo estranho é inválida', () {
      expect(AlunoValidator.matricula('2024@01'), isNotNull);
    });

    test('muito curta ou muito longa é inválida', () {
      expect(AlunoValidator.matricula('12'), isNotNull);
      expect(AlunoValidator.matricula('1' * 21), isNotNull);
    });

    test('números, letras, ponto, hífen e sublinhado são válidos', () {
      expect(AlunoValidator.matricula('2024001'), isNull);
      expect(AlunoValidator.matricula('RA-2024.01_A'), isNull);
    });
  });
}
