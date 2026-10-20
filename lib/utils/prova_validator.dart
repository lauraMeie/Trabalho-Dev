import '../models/turma.dart';

/// Resultado da validação da configuração da prova. Cada campo é `null`
/// quando está OK, ou a mensagem (em português) do problema encontrado.
class ProvaValidationResult {
  final String? erroQuestoes;
  final String? erroNome;
  final String? erroTurma;
  final String? erroAlunos;

  const ProvaValidationResult({
    this.erroQuestoes,
    this.erroNome,
    this.erroTurma,
    this.erroAlunos,
  });

  bool get valido =>
      erroQuestoes == null &&
      erroNome == null &&
      erroTurma == null &&
      erroAlunos == null;
}

/// Regras para poder gerar uma prova: título, turma e questões.
class ProvaValidator {
  ProvaValidator._();

  static const int tamanhoMaximoNome = 80;

  static ProvaValidationResult validar({
    required String nome,
    required Turma? turma,
    required int quantidadeQuestoes,
    required bool mesmaProvaParaTodos,
  }) {
    final nomeLimpo = nome.trim();

    String? erroNome;
    if (nomeLimpo.isEmpty) {
      erroNome = 'Informe o nome da prova.';
    } else if (nomeLimpo.length > tamanhoMaximoNome) {
      erroNome = 'O nome pode ter no máximo $tamanhoMaximoNome caracteres.';
    }

    final erroTurma = turma == null ? 'Selecione a turma da prova.' : null;

    final erroQuestoes = quantidadeQuestoes <= 0
        ? 'Selecione pelo menos uma questão.'
        : null;

    String? erroAlunos;
    if (turma != null && !mesmaProvaParaTodos && turma.alunos.isEmpty) {
      erroAlunos = 'Esta turma não tem alunos cadastrados. Cadastre alunos '
          'ou escolha "Mesma prova para todos os alunos".';
    }

    return ProvaValidationResult(
      erroQuestoes: erroQuestoes,
      erroNome: erroNome,
      erroTurma: erroTurma,
      erroAlunos: erroAlunos,
    );
  }
}
