import 'turma.dart';

/// Totais das turmas do professor, para a Tela Inicial e outros módulos.
class ResumoTurmas {
  const ResumoTurmas({required this.totalTurmas, required this.totalAlunos});

  final int totalTurmas;
  final int totalAlunos;

  /// Soma os totais a partir da lista de turmas. Contador negativo (dado
  /// inconsistente no banco) conta como zero.
  factory ResumoTurmas.deTurmas(Iterable<Turma> turmas) {
    var turmasContadas = 0;
    var alunos = 0;
    for (final turma in turmas) {
      turmasContadas++;
      final quantidade = turma.quantidadeAlunos;
      if (quantidade > 0) alunos += quantidade;
    }
    return ResumoTurmas(totalTurmas: turmasContadas, totalAlunos: alunos);
  }
}
