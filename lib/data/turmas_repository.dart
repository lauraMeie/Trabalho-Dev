import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/aluno.dart';
import '../models/resumo_turmas.dart';
import '../models/turma.dart';
import '../utils/firestore_errors.dart';
import '../utils/texto_utils.dart';

/// Acesso ao Firestore para Turmas e Alunos (N2).
///
/// Estrutura no banco:
///   turmas/{turmaId}                 -> { nome, quantidadeAlunos }
///   turmas/{turmaId}/alunos/{id}     -> { nome, matricula }
class TurmasRepository {
  TurmasRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _turmas =>
      _db.collection('turmas');

  CollectionReference<Map<String, dynamic>> _alunos(String turmaId) =>
      _turmas.doc(turmaId).collection('alunos');

  // ---------------------------------------------------------------- TURMAS

  /// Lista de turmas em tempo real (atualiza sozinha quando o banco muda).
  Stream<List<Turma>> turmasStream() {
    return _turmas
        .orderBy('nome')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Turma.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Leitura única das turmas (útil para outras telas, ex.: criar prova).
  Future<List<Turma>> listarTurmas() async {
    final snap = await _turmas.orderBy('nome').get();
    return snap.docs.map((d) => Turma.fromMap(d.id, d.data())).toList();
  }

  /// Totais (nº de turmas e de alunos) em tempo real.
  ///
  /// Uso na Tela Inicial:
  /// ```dart
  /// StreamBuilder<ResumoTurmas>(
  ///   stream: TurmasRepository().resumoStream(),
  ///   builder: (context, snapshot) {
  ///     final resumo = snapshot.data;
  ///     return StatBadge(
  ///       value: resumo == null ? '-' : '${resumo.totalTurmas}',
  ///       label: 'Turmas',
  ///     );
  ///   },
  /// )
  /// ```
  Stream<ResumoTurmas> resumoStream() {
    return turmasStream().map(ResumoTurmas.deTurmas);
  }

  Future<void> criarTurma(String nome) async {
    await _turmas
        .add({'nome': nome, 'quantidadeAlunos': 0})
        .timeout(tempoLimiteGravacao);
  }

  Future<void> atualizarTurma(String turmaId, String nome) async {
    await _turmas
        .doc(turmaId)
        .update({'nome': nome})
        .timeout(tempoLimiteGravacao);
  }

  /// Exclui a turma e todos os alunos dela (o Firestore não apaga
  /// subcoleções automaticamente).
  ///
  /// A turma entra por último na lista de exclusões. Para turmas com menos
  /// de 400 alunos tudo é apagado em UM único lote: ou apaga tudo, ou nada.
  Future<void> excluirTurma(String turmaId) async {
    final alunos = (await _alunos(turmaId).get()).docs;
    final referencias = <DocumentReference<Map<String, dynamic>>>[
      ...alunos.map((doc) => doc.reference),
      _turmas.doc(turmaId),
    ];
    for (var i = 0; i < referencias.length; i += 400) {
      final batch = _db.batch();
      for (final ref in referencias.skip(i).take(400)) {
        batch.delete(ref);
      }
      await batch.commit().timeout(tempoLimiteGravacao);
    }
  }

  /// `true` se já existe OUTRA turma com o mesmo nome (ignora acento,
  /// maiúsculas e espaços extras). Em edição, passe o id da própria turma
  /// em [ignorarTurmaId] para ela não ser comparada consigo mesma.
  Future<bool> existeTurmaComNome(String nome, {String? ignorarTurmaId}) async {
    final chave = TextoUtils.chaveDeComparacao(nome);
    final snap = await _turmas.get();
    return snap.docs.any(
      (doc) =>
          doc.id != ignorarTurmaId &&
          TextoUtils.chaveDeComparacao(doc.data()['nome'] as String? ?? '') ==
              chave,
    );
  }

  // ---------------------------------------------------------------- ALUNOS

  /// Alunos de uma turma em tempo real.
  Stream<List<Aluno>> alunosStream(String turmaId) {
    return _alunos(turmaId)
        .orderBy('nome')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Aluno.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Cria o aluno e soma 1 no contador da turma, tudo de uma vez (batch).
  Future<void> criarAluno(String turmaId, Aluno aluno) async {
    final batch = _db.batch();
    batch.set(_alunos(turmaId).doc(), aluno.toMap());
    batch.update(_turmas.doc(turmaId), {
      'quantidadeAlunos': FieldValue.increment(1),
    });
    await batch.commit().timeout(tempoLimiteGravacao);
  }

  Future<void> atualizarAluno(String turmaId, Aluno aluno) async {
    await _alunos(turmaId)
        .doc(aluno.id)
        .update(aluno.toMap())
        .timeout(tempoLimiteGravacao);
  }

  /// Alunos de uma turma, lidos uma única vez e em ordem alfabética.
  /// Útil para outros módulos (ex.: gerar uma prova para cada aluno).
  Future<List<Aluno>> alunosDaTurma(String turmaId) async {
    final snap = await _alunos(turmaId).orderBy('nome').get();
    return snap.docs.map((d) => Aluno.fromMap(d.id, d.data())).toList();
  }

  /// `true` se já existe OUTRO aluno com a mesma matrícula NESTA turma.
  /// Em edição, passe o id do próprio aluno em [ignorarAlunoId].
  Future<bool> existeAlunoComMatricula(
    String turmaId,
    String matricula, {
    String? ignorarAlunoId,
  }) async {
    final chave = TextoUtils.chaveDeComparacao(matricula);
    final snap = await _alunos(turmaId).get();
    return snap.docs.any(
      (doc) =>
          doc.id != ignorarAlunoId &&
          TextoUtils.chaveDeComparacao(
                doc.data()['matricula']?.toString() ?? '',
              ) ==
              chave,
    );
  }

  /// Exclui o aluno e subtrai 1 do contador da turma.
  Future<void> excluirAluno(String turmaId, String alunoId) async {
    final batch = _db.batch();
    batch.delete(_alunos(turmaId).doc(alunoId));
    batch.update(_turmas.doc(turmaId), {
      'quantidadeAlunos': FieldValue.increment(-1),
    });
    await batch.commit().timeout(tempoLimiteGravacao);
  }
}
