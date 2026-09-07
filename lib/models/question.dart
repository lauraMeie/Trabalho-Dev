/// Representa uma questão de múltipla escolha do Banco de Questões.
///
/// Cada questão tem sempre 5 alternativas (A a E), seguindo o padrão
/// do gabarito usado nas provas (ver folha de respostas do modelo N1).
class Question {
  final String id;
  final String subject; // Ex: "Matemática", "Português"...
  final String statement; // Enunciado da questão
  final List<String> alternatives; // Sempre 5 alternativas
  final int correctIndex; // Índice (0 a 4) da alternativa correta

  const Question({
    required this.id,
    required this.subject,
    required this.statement,
    required this.alternatives,
    required this.correctIndex,
  })  : assert(alternatives.length == 5,
            'Cada questão deve ter exatamente 5 alternativas'),
        assert(correctIndex >= 0 && correctIndex < 5,
            'correctIndex deve estar entre 0 e 4');

  /// Retorna a letra da alternativa correta (A, B, C, D ou E)
  String get correctLetter => String.fromCharCode(65 + correctIndex);
}
