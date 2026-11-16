import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prova_gerada.dart';
import '../utils/exam_generator.dart';

/// Consulta e edicao de provas; independente do repositorio de salvamento.
/// Nao altera o arquivo prova_repository.dart do projeto original.
class ProvaConsultaRepository {
  ProvaConsultaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String nomeColecao = 'provas';
  static const String nomeSubcolecao = 'individuais';
  static const int _limitePorBatch = 450;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> listar() async {
    final resultado = await _firestore.collection(nomeColecao).get()
        .timeout(const Duration(seconds: 15));
    final documentos = resultado.docs.toList();
    documentos.sort((a, b) {
      final da = a.data()['criadaEm'];
      final db = b.data()['criadaEm'];
      if (da is Timestamp && db is Timestamp) return db.compareTo(da);
      return 0;
    });
    return documentos;
  }

  Future<ProvaGerada> buscar(String id) async {
    final referencia = _firestore.collection(nomeColecao).doc(id);
    final principal = await referencia.get().timeout(const Duration(seconds: 15));
    if (!principal.exists) throw StateError('Prova não encontrada.');
    final dados = principal.data()!;
    final individuais = await referencia.collection(nomeSubcolecao).get()
        .timeout(const Duration(seconds: 15));
    final documentos = individuais.docs.toList()..sort((a,b) => a.id.compareTo(b.id));
    return ProvaGerada(
      nome: dados['nome'] as String? ?? '',
      turmaNome: dados['turmaNome'] as String? ?? '',
      mesmaProvaParaTodos: dados['mesmaProvaParaTodos'] as bool? ?? true,
      embaralhouQuestoes: dados['embaralhouQuestoes'] as bool? ?? false,
      embaralhouAlternativas: dados['embaralhouAlternativas'] as bool? ?? false,
      colunas: (dados['colunas'] as num?)?.toInt() ?? 1,
      tamanhoFonte: (dados['tamanhoFonte'] as num?)?.toDouble() ?? 14,
      provas: documentos.map((doc) {
        final mapa = doc.data();
        return ProvaDoAluno(
          aluno: mapa['aluno'] as String?,
          matricula: mapa['matricula'] as String?,
          questoes: (mapa['questoes'] as List? ?? const [])
              .map((q) => GeneratedQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
              .toList(),
        );
      }).toList(),
    );
  }

  /// Atualiza o conteúdo sem trocar os IDs individuais (usados pelo QR Code).
  /// Não permite alterar a quantidade de provas individuais.
  Future<void> atualizar(String id, ProvaGerada prova) async {
    final referencia = _firestore.collection(nomeColecao).doc(id);
    final existentes = await referencia.collection(nomeSubcolecao).get()
        .timeout(const Duration(seconds: 15));
    final documentos = existentes.docs.toList()..sort((a,b) => a.id.compareTo(b.id));
    if (documentos.length != prova.provas.length) {
      throw StateError('Não é possível alterar a quantidade de provas individuais.');
    }
    final operacoes = <void Function(WriteBatch)>[
      (batch) => batch.update(referencia, prova.toMapPrincipal()),
      for (var i = 0; i < documentos.length; i++)
        (batch) => batch.update(documentos[i].reference, prova.provas[i].toMap()),
    ];
    for (var inicio = 0; inicio < operacoes.length; inicio += _limitePorBatch) {
      final fim = inicio + _limitePorBatch > operacoes.length
          ? operacoes.length : inicio + _limitePorBatch;
      final batch = _firestore.batch();
      for (final operacao in operacoes.sublist(inicio, fim)) { operacao(batch); }
      await batch.commit().timeout(const Duration(seconds: 15));
    }
  }

}
