import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/resumo_turmas.dart';
import 'package:trabalho/models/turma.dart';

void main() {
  test('sem turmas, os totais são zero', () {
    final resumo = ResumoTurmas.deTurmas([]);
    expect(resumo.totalTurmas, 0);
    expect(resumo.totalAlunos, 0);
  });

  test('soma turmas e alunos usando o contador do banco', () {
    final resumo = ResumoTurmas.deTurmas([
      Turma('3º Ano A', [], totalAlunos: 30),
      Turma('3º Ano B', [], totalAlunos: 25),
      Turma('2º Ano A', [], totalAlunos: 0),
    ]);
    expect(resumo.totalTurmas, 3);
    expect(resumo.totalAlunos, 55);
  });

  test('contador negativo (dado inconsistente) conta como zero', () {
    final resumo = ResumoTurmas.deTurmas([
      Turma('3º Ano A', [], totalAlunos: -2),
      Turma('3º Ano B', [], totalAlunos: 10),
    ]);
    expect(resumo.totalAlunos, 10);
  });
}
