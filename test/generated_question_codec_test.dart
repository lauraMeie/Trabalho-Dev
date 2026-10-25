import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/utils/exam_generator.dart';

void main() {
  group('GeneratedQuestion.toMap/fromMap', () {
    test('fromMap reconstrói exatamente o que toMap salvou (round-trip)', () {
      final original = GeneratedQuestion(
        originalId: 'q007',
        subject: 'Matemática',
        statement: 'Quanto é 7 x 8?',
        alternatives: const ['54', '56', '58', '60', '62'],
        correctIndex: 1,
      );

      final reconstruida = GeneratedQuestion.fromMap(original.toMap());

      expect(reconstruida.originalId, original.originalId);
      expect(reconstruida.subject, original.subject);
      expect(reconstruida.statement, original.statement);
      expect(reconstruida.alternatives, original.alternatives);
      expect(reconstruida.correctIndex, original.correctIndex);
      expect(reconstruida.correctLetter, original.correctLetter);
    });

    test('fromMap não quebra com campos ausentes (documento incompleto)', () {
      final questao = GeneratedQuestion.fromMap(const {});

      expect(questao.originalId, '');
      expect(questao.subject, '');
      expect(questao.statement, '');
      expect(questao.alternatives, isEmpty);
      expect(questao.correctIndex, 0);
    });
  });
}
