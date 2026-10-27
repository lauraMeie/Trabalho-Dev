import '../models/correction_result.dart';
import 'mock_corrections_store.dart' show EstatisticaQuestao;

/// Cálculos agregados para a tela de Relatórios (RF09/RF11), a partir de
/// uma lista real de correções (lidas do Firestore via CorrecaoRepository).
///
/// São funções puras — não dependem de nenhum estado global — para serem
/// fáceis de testar e reaproveitar.
class RelatoriosCalculos {
  RelatoriosCalculos._();

  static double mediaGeral(List<ResultadoCorrecao> resultados) {
    if (resultados.isEmpty) return 0;
    final soma = resultados.fold<double>(0, (acc, r) => acc + r.nota);
    return soma / resultados.length;
  }

  static int totalTurmasDistintas(List<ResultadoCorrecao> resultados) =>
      resultados.map((r) => r.turma).toSet().length;

  /// Estatística por questão (RF11), juntando os dados de todas as provas
  /// corrigidas — cada questão é identificada pelo id original dela no
  /// banco de questões.
  static List<EstatisticaQuestao> estatisticasPorQuestao(
    List<ResultadoCorrecao> resultados,
  ) {
    final Map<String, EstatisticaQuestao> mapa = {};

    for (final resultado in resultados) {
      for (final resposta in resultado.respostas) {
        final estatistica = mapa.putIfAbsent(
          resposta.questaoId,
          () => EstatisticaQuestao(
            questaoId: resposta.questaoId,
            materia: resposta.materia,
            enunciado: resposta.enunciado,
            textoCorreto: resposta.textoCorreto,
          ),
        );
        estatistica.registrarResposta(resposta.textoMarcado);
      }
    }

    return mapa.values.toList();
  }

  /// Percentual de acerto (0.0 a 1.0) agrupado por matéria, considerando
  /// todas as respostas de todas as provas corrigidas.
  static Map<String, double> desempenhoPorMateria(
    List<ResultadoCorrecao> resultados,
  ) {
    final Map<String, int> acertosPorMateria = {};
    final Map<String, int> totalPorMateria = {};

    for (final resultado in resultados) {
      for (final resposta in resultado.respostas) {
        totalPorMateria[resposta.materia] =
            (totalPorMateria[resposta.materia] ?? 0) + 1;
        if (resposta.correta) {
          acertosPorMateria[resposta.materia] =
              (acertosPorMateria[resposta.materia] ?? 0) + 1;
        }
      }
    }

    return {
      for (final materia in totalPorMateria.keys)
        materia: (acertosPorMateria[materia] ?? 0) / totalPorMateria[materia]!,
    };
  }
}
