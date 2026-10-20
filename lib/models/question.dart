/// Representa uma questão de múltipla escolha do Banco de Questões.
///
/// Cada questão tem sempre 5 alternativas (A a E), seguindo o padrão
/// do gabarito usado nas provas (ver folha de respostas do modelo N1).
///
/// Na N2 as questões ficam salvas no Firestore (coleção `questoes`).
/// O [id] é o ID do documento e NÃO é gravado dentro dele — por isso
/// [toMap] não inclui o id e [fromMap] recebe o id separado.
class Question {
  static const int quantidadeAlternativas = 5;

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
  }) : assert(correctIndex >= 0 && correctIndex < 5,
            'correctIndex deve estar entre 0 e 4');

  /// Retorna a letra da alternativa correta (A, B, C, D ou E)
  String get correctLetter => String.fromCharCode(65 + correctIndex);

  /// Converte a questão para o formato salvo no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'statement': statement,
      'alternatives': alternatives,
      'correctIndex': correctIndex,
    };
  }

  /// Cria uma questão a partir de um documento do Firestore.
  ///
  /// Lança [FormatException] se o documento estiver incompleto ou
  /// inválido (ex.: menos de 5 alternativas) — quem chama decide o que
  /// fazer (o repositório ignora documentos inválidos).
  factory Question.fromMap(String id, Map<String, dynamic> map) {
    final rawAlternatives = map['alternatives'];
    if (rawAlternatives is! List ||
        rawAlternatives.length != quantidadeAlternativas) {
      throw FormatException(
        'Questão $id precisa ter $quantidadeAlternativas alternativas.',
      );
    }

    final rawCorrect = map['correctIndex'];
    if (rawCorrect is! num ||
        rawCorrect < 0 ||
        rawCorrect >= quantidadeAlternativas) {
      throw FormatException('Questão $id tem correctIndex inválido.');
    }

    final statement = (map['statement'] as String?)?.trim() ?? '';
    if (statement.isEmpty) {
      throw FormatException('Questão $id está sem enunciado.');
    }

    final subject = (map['subject'] as String?)?.trim() ?? '';

    return Question(
      id: id,
      subject: subject.isEmpty ? 'Geral' : subject,
      statement: statement,
      alternatives: rawAlternatives.map((e) => e.toString()).toList(),
      correctIndex: rawCorrect.toInt(),
    );
  }

  Question copyWith({
    String? subject,
    String? statement,
    List<String>? alternatives,
    int? correctIndex,
  }) {
    return Question(
      id: id,
      subject: subject ?? this.subject,
      statement: statement ?? this.statement,
      alternatives: alternatives ?? this.alternatives,
      correctIndex: correctIndex ?? this.correctIndex,
    );
  }
}
