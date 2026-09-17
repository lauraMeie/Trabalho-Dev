import '../models/correction_result.dart';
import '../utils/correction_simulator.dart';

/// Estatística agregada de UMA questão, considerando todas as correções já
/// feitas na sessão: quantas vezes cada alternativa foi marcada (RF11).
class EstatisticaQuestao {
  final String questaoId;
  final String materia;
  final String enunciado;
  final String textoCorreto;

  final Map<String, int> _contagemPorAlternativa = {};
  int totalRespostas = 0;

  EstatisticaQuestao({
    required this.questaoId,
    required this.materia,
    required this.enunciado,
    required this.textoCorreto,
  });

  void registrarResposta(String? textoMarcado) {
    totalRespostas++;
    final chave = textoMarcado ?? '(em branco)';
    _contagemPorAlternativa[chave] = (_contagemPorAlternativa[chave] ?? 0) + 1;
  }

  /// Alternativa (texto) mais marcada pelos alunos e quantas vezes.
  MapEntry<String, int>? get alternativaMaisMarcada {
    if (_contagemPorAlternativa.isEmpty) return null;
    return _contagemPorAlternativa.entries
        .reduce((a, b) => a.value >= b.value ? a : b);
  }

  int get acertos => _contagemPorAlternativa[textoCorreto] ?? 0;
  double get percentualAcerto =>
      totalRespostas == 0 ? 0 : acertos / totalRespostas;
}

/// "Banco de dados" fictício, em memória, das provas já corrigidas na
/// sessão atual (fase N1 — sem persistência real, ver README).
///
/// Começa com alguns resultados de exemplo já corrigidos, para a tela de
/// Relatórios não começar vazia, e recebe novos resultados conforme o
/// professor usa o fluxo de correção (QR Code mock → leitura mock).
class MockCorrectionsStore {
  MockCorrectionsStore._();

  static final List<ResultadoCorrecao> _resultados = _seed();

  static List<ResultadoCorrecao> get resultados =>
      List.unmodifiable(_resultados);

  static bool get vazio => _resultados.isEmpty;

  static void adicionar(ResultadoCorrecao resultado) {
    _resultados.insert(0, resultado);
  }

  static double get mediaGeral {
    if (_resultados.isEmpty) return 0;
    final soma = _resultados.fold<double>(0, (acc, r) => acc + r.nota);
    return soma / _resultados.length;
  }

  static int get totalTurmasDistintas =>
      _resultados.map((r) => r.turma).toSet().length;

  /// Estatística por questão (RF11), juntando os dados de todas as provas
  /// corrigidas até agora — cada questão é identificada pelo id original
  /// dela no banco de questões.
  static List<EstatisticaQuestao> estatisticasPorQuestao() {
    final Map<String, EstatisticaQuestao> mapa = {};

    for (final resultado in _resultados) {
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
  /// todas as respostas de todas as provas já corrigidas na sessão.
  static Map<String, double> desempenhoPorMateria() {
    final Map<String, int> acertosPorMateria = {};
    final Map<String, int> totalPorMateria = {};

    for (final resultado in _resultados) {
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

  static List<ResultadoCorrecao> _seed() {
    return List.generate(3, (_) {
      final identificacao = CorrectionSimulator.simularEscaneamentoQrCode();
      return CorrectionSimulator.simularLeituraRespostas(
        identificacao: identificacao,
      );
    });
  }
}
