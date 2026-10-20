import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/question.dart';
import 'package:trabalho/utils/exam_generator.dart';

void main() {
  final questoes = List.generate(
    8,
    (i) => Question(
      id: 'q$i',
      subject: 'Teste',
      statement: 'Enunciado número $i',
      alternatives: ['a$i', 'b$i', 'c$i', 'd$i', 'e$i'],
      correctIndex: i % 5,
    ),
  );

  test('sem embaralhar mantém ordem e gabarito originais', () {
    final prova = ExamGenerator.gerarDeQuestoes(questoes);
    expect(prova.map((q) => q.originalId), questoes.map((q) => q.id));
    for (int i = 0; i < prova.length; i++) {
      expect(prova[i].alternatives, questoes[i].alternatives);
      expect(prova[i].correctIndex, questoes[i].correctIndex);
    }
  });

  test('embaralhar alternativas mantém o gabarito apontando pro texto certo', () {
    for (int tentativa = 0; tentativa < 20; tentativa++) {
      final prova = ExamGenerator.gerarDeQuestoes(
        questoes,
        embaralharAlternativas: true,
      );
      for (int i = 0; i < prova.length; i++) {
        final original = questoes[i];
        expect(
          prova[i].alternatives[prova[i].correctIndex],
          original.alternatives[original.correctIndex],
        );
      }
    }
  });

  test('embaralhar questões mantém as mesmas questões, sem perder nem repetir', () {
    final prova = ExamGenerator.gerarDeQuestoes(
      questoes,
      embaralharQuestoes: true,
    );
    expect(prova.length, questoes.length);
    expect(
      prova.map((q) => q.originalId).toSet(),
      questoes.map((q) => q.id).toSet(),
    );
  });

  test('toMap guarda o gabarito em letra', () {
    final mapa = ExamGenerator.gerarDeQuestoes(questoes).first.toMap();
    expect(mapa['originalId'], 'q0');
    expect(mapa['correctLetter'], 'A');
    expect((mapa['alternatives'] as List).length, 5);
  });
}
