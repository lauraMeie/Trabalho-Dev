import '../models/aluno.dart';
import '../models/turma.dart';
import 'texto_utils.dart';

/// Filtros de busca das listas de turmas e alunos.
///
/// A busca ignora acento, maiúsculas e espaços extras: digitar "joao" acha
/// "João da Silva". Texto vazio devolve a lista completa.
class BuscaUtils {
  BuscaUtils._();

  static List<Turma> filtrarTurmas(List<Turma> turmas, String consulta) {
    final chave = TextoUtils.chaveDeComparacao(consulta);
    if (chave.isEmpty) return turmas;
    return turmas
        .where((t) => TextoUtils.chaveDeComparacao(t.nome).contains(chave))
        .toList();
  }

  /// Procura no nome E na matrícula do aluno.
  static List<Aluno> filtrarAlunos(List<Aluno> alunos, String consulta) {
    final chave = TextoUtils.chaveDeComparacao(consulta);
    if (chave.isEmpty) return alunos;
    return alunos
        .where(
          (a) =>
              TextoUtils.chaveDeComparacao(a.nome).contains(chave) ||
              TextoUtils.chaveDeComparacao(a.matricula).contains(chave),
        )
        .toList();
  }
}
