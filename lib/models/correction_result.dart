/// Representa a correção de UMA questão dentro de uma prova corrigida:
/// guarda as alternativas na mesma ordem embaralhada usada na prova
/// (para poder mostrar o texto marcado e o texto correto depois),
/// qual era o índice correto e qual índice o aluno marcou (null = em branco).
class RespostaCorrigida {
  final String questaoId;
  final String materia;
  final String enunciado;
  final List<String> alternativas;
  final int indiceCorreto;
  final int? indiceMarcado;

  const RespostaCorrigida({
    required this.questaoId,
    required this.materia,
    required this.enunciado,
    required this.alternativas,
    required this.indiceCorreto,
    required this.indiceMarcado,
  });

  bool get emBranco => indiceMarcado == null;
  bool get correta => indiceMarcado == indiceCorreto;

  String get textoCorreto => alternativas[indiceCorreto];
  String? get textoMarcado =>
      indiceMarcado == null ? null : alternativas[indiceMarcado!];
}

/// Resultado completo da correção automatizada de uma prova (RF07/RF08):
/// identifica aluno/turma/prova e traz a lista de respostas já corrigidas.
class ResultadoCorrecao {
  final String id;
  final String aluno;
  final String turma;
  final String provaId;
  final DateTime corrigidoEm;
  final List<RespostaCorrigida> respostas;

  const ResultadoCorrecao({
    required this.id,
    required this.aluno,
    required this.turma,
    required this.provaId,
    required this.corrigidoEm,
    required this.respostas,
  });

  int get totalQuestoes => respostas.length;
  int get acertos => respostas.where((r) => r.correta).length;
  int get emBranco => respostas.where((r) => r.emBranco).length;
  int get erros => totalQuestoes - acertos - emBranco;

  /// Nota de 0 a 10, proporcional ao número de acertos.
  double get nota => totalQuestoes == 0 ? 0 : (acertos / totalQuestoes) * 10;
}
