
import 'dart:math';

import '../data/question_bank.dart';
import '../models/question.dart';

/// Uma questão já pronta para ser usada em uma prova gerada: veio do
/// banco de questões, mas com a ORDEM das alternativas embaralhada.
class GeneratedQuestion {
  final String originalId;
  final String subject;
  final String statement;
  final List<String> alternatives; // já embaralhadas
  final int correctIndex; // índice correto DEPOIS do embaralhamento

  GeneratedQuestion({
    required this.originalId,
    required this.subject,
    required this.statement,
    required this.alternatives,
    required this.correctIndex,
  });

  /// Letra da alternativa correta (A a E) já considerando o novo embaralhamento
  String get correctLetter => String.fromCharCode(65 + correctIndex);
}

/// Responsável por "puxar" questões do banco e montar uma prova,
/// conforme pedido: cada vez que uma questão é usada, o app pega uma
/// questão do banco e embaralha a ordem das alternativas.
class ExamGenerator {
  static final Random _random = Random();

  /// Gera uma prova com [quantidade] questões escolhidas aleatoriamente
  /// do banco (sem repetir nenhuma questão), cada uma com as
  /// alternativas em uma ordem embaralhada.
  static List<GeneratedQuestion> gerarProva({int quantidade = 10}) {
    final total = questionBank.length;
    final qtd = quantidade > total ? total : quantidade;

    final bancoEmbaralhado = List<Question>.from(questionBank)..shuffle(_random);
    final selecionadas = bancoEmbaralhado.take(qtd).toList();

    return selecionadas.map(_embaralharAlternativas).toList();
  }

  /// Gera uma prova diferente para cada aluno da lista (RF04/RF13):
  /// cada aluno recebe uma seleção e uma ordem de alternativas próprias.
  static Map<String, List<GeneratedQuestion>> gerarProvasPorAluno({
    required List<String> alunos,
    int quantidadeQuestoes = 10,
  }) {
    final Map<String, List<GeneratedQuestion>> provas = {};
    for (final aluno in alunos) {
      provas[aluno] = gerarProva(quantidade: quantidadeQuestoes);
    }
    return provas;
  }

  /// Embaralha as alternativas de uma questão, recalculando qual é o
  /// novo índice da alternativa correta.
  static GeneratedQuestion _embaralharAlternativas(Question questao) {
    final indices = List<int>.generate(questao.alternatives.length, (i) => i)
      ..shuffle(_random);

    final novasAlternativas = indices.map((i) => questao.alternatives[i]).toList();
    final novoIndiceCorreto = indices.indexOf(questao.correctIndex);

    return GeneratedQuestion(
      originalId: questao.id,
      subject: questao.subject,
      statement: questao.statement,
      alternatives: novasAlternativas,
      correctIndex: novoIndiceCorreto,
    );
  }
}
