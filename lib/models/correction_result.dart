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

  Map<String, dynamic> toMap() {
    return {
      'questaoId': questaoId,
      'materia': materia,
      'enunciado': enunciado,
      'alternativas': alternativas,
      'indiceCorreto': indiceCorreto,
      'indiceMarcado': indiceMarcado,
    };
  }

  factory RespostaCorrigida.fromMap(Map<String, dynamic> map) {
    return RespostaCorrigida(
      questaoId: map['questaoId'] as String? ?? '',
      materia: map['materia'] as String? ?? '',
      enunciado: map['enunciado'] as String? ?? '',
      alternativas: List<String>.from(map['alternativas'] as List? ?? const []),
      indiceCorreto: (map['indiceCorreto'] as num?)?.toInt() ?? 0,
      indiceMarcado: (map['indiceMarcado'] as num?)?.toInt(),
    );
  }
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

  /// Formato salvo no Firestore (coleção `correcoes`). O `id` NÃO entra no
  /// mapa: quem identifica o documento é o ID dele no Firestore (ver
  /// [fromMap]), igual ao padrão usado em Turma/Question.
  Map<String, dynamic> toMap() {
    return {
      'aluno': aluno,
      'turma': turma,
      'provaId': provaId,
      'corrigidoEm': corrigidoEm.toIso8601String(),
      'respostas': respostas.map((r) => r.toMap()).toList(),
    };
  }

  factory ResultadoCorrecao.fromMap(String id, Map<String, dynamic> map) {
    final corrigidoEmRaw = map['corrigidoEm'];
    final corrigidoEm = corrigidoEmRaw is String
        ? DateTime.tryParse(corrigidoEmRaw) ?? DateTime.now()
        : DateTime.now();

    return ResultadoCorrecao(
      id: id,
      aluno: map['aluno'] as String? ?? '',
      turma: map['turma'] as String? ?? '',
      provaId: map['provaId'] as String? ?? '',
      corrigidoEm: corrigidoEm,
      respostas: (map['respostas'] as List? ?? const [])
          .whereType<Map>()
          .map((r) => RespostaCorrigida.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }
}
