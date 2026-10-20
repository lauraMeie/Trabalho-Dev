import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/question.dart';

void main() {
  const questao = Question(
    id: 'abc',
    subject: 'Matemática',
    statement: 'Quanto é 7 x 8?',
    alternatives: ['54', '56', '58', '64', '49'],
    correctIndex: 1,
  );

  test('toMap não inclui o id e fromMap devolve a mesma questão', () {
    final mapa = questao.toMap();
    expect(mapa.containsKey('id'), isFalse);

    final volta = Question.fromMap('abc', mapa);
    expect(volta.id, 'abc');
    expect(volta.subject, 'Matemática');
    expect(volta.statement, 'Quanto é 7 x 8?');
    expect(volta.alternatives, ['54', '56', '58', '64', '49']);
    expect(volta.correctIndex, 1);
    expect(volta.correctLetter, 'B');
  });

  test('fromMap rejeita documento com menos de 5 alternativas', () {
    final mapa = questao.toMap()..['alternatives'] = ['1', '2', '3'];
    expect(() => Question.fromMap('x', mapa), throwsFormatException);
  });

  test('fromMap rejeita correctIndex fora de 0..4', () {
    final mapa = questao.toMap()..['correctIndex'] = 5;
    expect(() => Question.fromMap('x', mapa), throwsFormatException);
  });

  test('fromMap rejeita enunciado vazio', () {
    final mapa = questao.toMap()..['statement'] = '   ';
    expect(() => Question.fromMap('x', mapa), throwsFormatException);
  });

  test('fromMap usa "Geral" quando a matéria está vazia', () {
    final mapa = questao.toMap()..['subject'] = '';
    expect(Question.fromMap('x', mapa).subject, 'Geral');
  });

  test('copyWith mantém o id e troca só o que foi pedido', () {
    final nova = questao.copyWith(statement: 'Novo enunciado aqui');
    expect(nova.id, 'abc');
    expect(nova.statement, 'Novo enunciado aqui');
    expect(nova.subject, 'Matemática');
  });
}
