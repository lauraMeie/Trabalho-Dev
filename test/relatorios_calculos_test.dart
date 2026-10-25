import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/data/relatorios_calculos.dart';
import 'package:trabalho/models/correction_result.dart';

ResultadoCorrecao _resultado({
  required String aluno,
  required String turma,
  required List<int?> marcacoes,
}) {
  return ResultadoCorrecao(
    id: 'id-$aluno',
    aluno: aluno,
    turma: turma,
    provaId: 'prova-1',
    corrigidoEm: DateTime(2026, 1, 1),
    respostas: [
      for (var i = 0; i < marcacoes.length; i++)
        RespostaCorrigida(
          questaoId: 'q$i',
          materia: i.isEven ? 'Matemática' : 'Português',
          enunciado: 'Enunciado $i',
          alternativas: const ['A', 'B', 'C', 'D', 'E'],
          indiceCorreto: 0,
          indiceMarcado: marcacoes[i],
        ),
    ],
  );
}

void main() {
  group('RelatoriosCalculos.mediaGeral', () {
    test('é 0 quando não há resultados', () {
      expect(RelatoriosCalculos.mediaGeral(const []), 0);
    });

    test('é a média aritmética das notas', () {
      final resultados = [
        _resultado(aluno: 'A', turma: 'T1', marcacoes: [0, 0]), // nota 10
        _resultado(aluno: 'B', turma: 'T1', marcacoes: [1, 1]), // nota 0
      ];
      expect(RelatoriosCalculos.mediaGeral(resultados), 5.0);
    });
  });

  group('RelatoriosCalculos.totalTurmasDistintas', () {
    test('conta turmas sem repetir', () {
      final resultados = [
        _resultado(aluno: 'A', turma: 'T1', marcacoes: [0]),
        _resultado(aluno: 'B', turma: 'T1', marcacoes: [0]),
        _resultado(aluno: 'C', turma: 'T2', marcacoes: [0]),
      ];
      expect(RelatoriosCalculos.totalTurmasDistintas(resultados), 2);
    });
  });

  group('RelatoriosCalculos.desempenhoPorMateria', () {
    test('calcula o percentual de acerto por matéria', () {
      final resultados = [
        _resultado(aluno: 'A', turma: 'T1', marcacoes: [0, 1]),
      ];
      final desempenho = RelatoriosCalculos.desempenhoPorMateria(resultados);
      expect(desempenho['Matemática'], 1.0); // questão 0: acertou
      expect(desempenho['Português'], 0.0); // questão 1: errou
    });
  });

  group('RelatoriosCalculos.estatisticasPorQuestao', () {
    test('nunca tem mais acertos do que respostas', () {
      final resultados = [
        _resultado(aluno: 'A', turma: 'T1', marcacoes: [0, null]),
        _resultado(aluno: 'B', turma: 'T1', marcacoes: [1, 0]),
      ];
      for (final estatistica
          in RelatoriosCalculos.estatisticasPorQuestao(resultados)) {
        expect(estatistica.acertos, lessThanOrEqualTo(estatistica.totalRespostas));
      }
    });
  });
}
