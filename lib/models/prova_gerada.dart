import '../utils/exam_generator.dart';

/// Prova de UM aluno (ou a prova única, quando a turma toda faz a mesma).
class ProvaDoAluno {
  /// null quando é "mesma prova para todos".
  final String? aluno;
  final String? matricula;
  final List<GeneratedQuestion> questoes;

  const ProvaDoAluno({
    this.aluno,
    this.matricula,
    required this.questoes,
  });

  /// Gabarito em letras na ordem da prova, ex.: ['B', 'D', 'A'].
  List<String> get gabarito => questoes.map((q) => q.correctLetter).toList();

  Map<String, dynamic> toMap() {
    return {
      'aluno': aluno,
      'matricula': matricula,
      'questoes': questoes.map((q) => q.toMap()).toList(),
      'gabarito': gabarito,
    };
  }
}

/// Prova gerada e pronta para ser salva no Firestore (coleção `provas`).
class ProvaGerada {
  final String nome;
  final String turmaNome;
  final bool mesmaProvaParaTodos;
  final bool embaralhouQuestoes;
  final bool embaralhouAlternativas;
  final int colunas;
  final double tamanhoFonte;
  final List<ProvaDoAluno> provas;

  const ProvaGerada({
    required this.nome,
    required this.turmaNome,
    required this.mesmaProvaParaTodos,
    required this.embaralhouQuestoes,
    required this.embaralhouAlternativas,
    required this.colunas,
    required this.tamanhoFonte,
    required this.provas,
  });

  /// Dados do documento principal (sem as provas individuais, que vão
  /// para a subcoleção `individuais` para não estourar o limite de 1 MB
  /// do Firestore em turmas grandes).
  Map<String, dynamic> toMapPrincipal() {
    return {
      'nome': nome,
      'turmaNome': turmaNome,
      'mesmaProvaParaTodos': mesmaProvaParaTodos,
      'embaralhouQuestoes': embaralhouQuestoes,
      'embaralhouAlternativas': embaralhouAlternativas,
      'colunas': colunas,
      'tamanhoFonte': tamanhoFonte,
      'totalProvas': provas.length,
      'totalQuestoes': provas.isEmpty ? 0 : provas.first.questoes.length,
    };
  }
}
