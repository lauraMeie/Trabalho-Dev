import 'dart:math';

import '../models/correction_result.dart';
import 'exam_generator.dart';

/// Identificação de aluno/turma/prova obtida a partir da leitura do QR Code
/// (mock nesta fase N1 — RF05/RF06: sem câmera real, sem QR de verdade).
class IdentificacaoProva {
  final String aluno;
  final String turma;
  final String provaId;

  const IdentificacaoProva({
    required this.aluno,
    required this.turma,
    required this.provaId,
  });
}

/// Simula, com dados fictícios, as etapas de leitura do QR Code e de
/// leitura/correção das respostas marcadas em uma folha de respostas
/// (RF06/RF07/RF08), sem depender de câmera, OCR ou banco de dados real.
class CorrectionSimulator {
  CorrectionSimulator._();

  static final Random _random = Random();

  static const List<String> _alunosMock = [
    'Ana Beatriz Souza',
    'Bruno Costa Lima',
    'Carla Mendes',
    'Diego Ferreira',
    'Elaine Rocha',
    'Felipe Almeida',
    'Gabriela Nunes',
    'Henrique Duarte',
    'Isabela Martins',
    'João Pedro Ramos',
  ];

  static const List<String> _turmasMock = ['3º Ano A', '3º Ano B', '2º Ano C'];

  /// Simula o escaneamento do QR Code presente na folha de respostas,
  /// "descobrindo" de forma fictícia qual aluno/turma/prova está sendo lida.
  static IdentificacaoProva simularEscaneamentoQrCode() {
    final aluno = _alunosMock[_random.nextInt(_alunosMock.length)];
    final turma = _turmasMock[_random.nextInt(_turmasMock.length)];
    final provaId = 'PROVA-${1000 + _random.nextInt(9000)}';
    return IdentificacaoProva(aluno: aluno, turma: turma, provaId: provaId);
  }

  /// Simula a leitura das alternativas marcadas pelo aluno e já corrige a
  /// prova, comparando com o gabarito gerado por [ExamGenerator].
  static ResultadoCorrecao simularLeituraRespostas({
    required IdentificacaoProva identificacao,
    int quantidadeQuestoes = 10,
  }) {
    final questoes = ExamGenerator.gerarProva(quantidade: quantidadeQuestoes);

    final respostas = questoes.map((questao) {
      final indiceMarcado = _sortearRespostaAluno(questao);
      return RespostaCorrigida(
        questaoId: questao.originalId,
        materia: questao.subject,
        enunciado: questao.statement,
        alternativas: questao.alternatives,
        indiceCorreto: questao.correctIndex,
        indiceMarcado: indiceMarcado,
      );
    }).toList();

    return ResultadoCorrecao(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch}',
      aluno: identificacao.aluno,
      turma: identificacao.turma,
      provaId: identificacao.provaId,
      corrigidoEm: DateTime.now(),
      respostas: respostas,
    );
  }

  /// Sorteia uma resposta fictícia para o aluno: a maior parte das vezes
  /// acerta, às vezes erra e, ocasionalmente, deixa a questão em branco —
  /// só para o resultado da correção não parecer artificial demais.
  static int? _sortearRespostaAluno(GeneratedQuestion questao) {
    final sorteio = _random.nextDouble();

    if (sorteio < 0.08) {
      return null; // em branco
    }
    if (sorteio < 0.78) {
      return questao.correctIndex; // acertou
    }

    final indicesErrados = List<int>.generate(
      questao.alternatives.length,
      (i) => i,
    )..remove(questao.correctIndex);
    return indicesErrados[_random.nextInt(indicesErrados.length)];
  }
}
