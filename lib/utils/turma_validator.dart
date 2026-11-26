import 'texto_utils.dart';

/// Regras de validação do formulário de turma.
///
/// Cada método devolve `null` quando o valor é válido, ou a mensagem de
/// erro que aparece embaixo do campo (mesmo formato do `validator` do
/// `TextFormField`).
class TurmaValidator {
  TurmaValidator._();

  static const int nomeMinimo = 3;
  static const int nomeMaximo = 60;

  /// Mensagem usada quando já existe OUTRA turma com o mesmo nome.
  static const String erroNomeRepetido = 'Já existe uma turma com esse nome.';

  static String? nome(String? valor) {
    final texto = TextoUtils.normalizarEspacos(valor ?? '');
    if (texto.isEmpty) return 'Informe o nome da turma.';
    if (texto.length < nomeMinimo) {
      return 'O nome precisa ter ao menos $nomeMinimo caracteres.';
    }
    if (texto.length > nomeMaximo) {
      return 'O nome pode ter no máximo $nomeMaximo caracteres.';
    }
    return null;
  }
}

/// Regras de validação do formulário de aluno.
class AlunoValidator {
  AlunoValidator._();

  static const int nomeMinimo = 3;
  static const int nomeMaximo = 80;
  static const int matriculaMinima = 3;
  static const int matriculaMaxima = 20;

  /// Mensagem usada quando a matrícula já existe NA MESMA turma.
  static const String erroMatriculaRepetida =
      'Já existe um aluno com essa matrícula nesta turma.';

  static final RegExp _matriculaValida = RegExp(r'^[A-Za-z0-9._-]+$');

  static String? nome(String? valor) {
    final texto = TextoUtils.normalizarEspacos(valor ?? '');
    if (texto.isEmpty) return 'Informe o nome do aluno.';
    if (texto.length < nomeMinimo) {
      return 'O nome precisa ter ao menos $nomeMinimo caracteres.';
    }
    if (texto.length > nomeMaximo) {
      return 'O nome pode ter no máximo $nomeMaximo caracteres.';
    }
    if (texto.contains(RegExp(r'\d'))) {
      return 'O nome não pode ter números.';
    }
    return null;
  }

  static String? matricula(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Informe a matrícula.';
    if (texto.contains(RegExp(r'\s'))) {
      return 'A matrícula não pode ter espaços.';
    }
    if (!_matriculaValida.hasMatch(texto)) {
      return 'Use só letras, números, ponto, hífen ou sublinhado.';
    }
    if (texto.length < matriculaMinima) {
      return 'A matrícula precisa ter ao menos $matriculaMinima caracteres.';
    }
    if (texto.length > matriculaMaxima) {
      return 'A matrícula pode ter no máximo $matriculaMaxima caracteres.';
    }
    return null;
  }
}
