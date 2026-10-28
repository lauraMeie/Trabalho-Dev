/// Estatística agregada de UMA questão, considerando todas as correções
/// já feitas: quantas vezes cada alternativa foi marcada (RF11).
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