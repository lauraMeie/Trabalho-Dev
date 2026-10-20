/// Regras de validação do formulário de questão (criar/editar).
///
/// Cada método devolve `null` quando o valor é válido, ou a mensagem de
/// erro que aparece embaixo do campo — o mesmo formato que o `validator`
/// do `TextFormField` espera.
class QuestionValidator {
  QuestionValidator._();

  static const int tamanhoMinimoEnunciado = 10;
  static const int tamanhoMaximoEnunciado = 500;
  static const int tamanhoMaximoAlternativa = 200;

  static String? materia(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe a matéria.';
    if (texto.length < 3) return 'A matéria precisa ter ao menos 3 letras.';
    return null;
  }

  static String? enunciado(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o enunciado da questão.';
    if (texto.length < tamanhoMinimoEnunciado) {
      return 'O enunciado precisa ter ao menos $tamanhoMinimoEnunciado '
          'caracteres.';
    }
    if (texto.length > tamanhoMaximoEnunciado) {
      return 'O enunciado pode ter no máximo $tamanhoMaximoEnunciado '
          'caracteres.';
    }
    return null;
  }

  /// [outras] são os textos das OUTRAS alternativas, para impedir duas
  /// alternativas iguais (o aluno não conseguiria diferenciá-las).
  static String? alternativa(String? valor, {Iterable<String> outras = const []}) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Preencha esta alternativa.';
    if (texto.length > tamanhoMaximoAlternativa) {
      return 'Máximo de $tamanhoMaximoAlternativa caracteres.';
    }
    final repetida = outras.any(
      (o) => o.trim().toLowerCase() == texto.toLowerCase(),
    );
    if (repetida) return 'Já existe outra alternativa igual a esta.';
    return null;
  }

  /// Garante que exista SEMPRE uma alternativa marcada como correta.
  static String? alternativaCorreta(int? indice) {
    if (indice == null || indice < 0 || indice > 4) {
      return 'Marque qual alternativa é a correta.';
    }
    return null;
  }
}
