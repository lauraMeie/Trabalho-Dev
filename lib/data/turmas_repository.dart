import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/aluno.dart';
import '../models/turma.dart';

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
    return _turmas.orderBy('nome').snapshots().map(
          (snap) =>
              snap.docs.map((d) => Turma.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Leitura única das turmas (útil para outras telas, ex.: criar prova).
  Future<List<Turma>> listarTurmas() async {
    final snap = await _turmas.orderBy('nome').get();
    return snap.docs.map((d) => Turma.fromMap(d.id, d.data())).toList();
  }

  Future<void> criarTurma(String nome) async {
    await _turmas.add({'nome': nome, 'quantidadeAlunos': 0});
  }

  Future<void> atualizarTurma(String turmaId, String nome) async {
    await _turmas.doc(turmaId).update({'nome': nome});
  }

  /// Exclui a turma e todos os alunos dela (o Firestore não apaga
  /// subcoleções automaticamente).
  Future<void> excluirTurma(String turmaId) async {
    final alunos = (await _alunos(turmaId).get()).docs;
    for (var i = 0; i < alunos.length; i += 400) {
      final batch = _db.batch();
      for (final doc in alunos.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _turmas.doc(turmaId).delete();
  }

  // ---------------------------------------------------------------- ALUNOS

  /// Alunos de uma turma em tempo real.
  Stream<List<Aluno>> alunosStream(String turmaId) {
    return _alunos(turmaId).orderBy('nome').snapshots().map(
          (snap) =>
              snap.docs.map((d) => Aluno.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Cria o aluno e soma 1 no contador da turma, tudo de uma vez (batch).
  Future<void> criarAluno(String turmaId, Aluno aluno) async {
    final batch = _db.batch();
    batch.set(_alunos(turmaId).doc(), aluno.toMap());
    batch.update(
      _turmas.doc(turmaId),
      {'quantidadeAlunos': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  Future<void> atualizarAluno(String turmaId, Aluno aluno) async {
    await _alunos(turmaId).doc(aluno.id).update(aluno.toMap());
  }

  /// Exclui o aluno e subtrai 1 do contador da turma.
  Future<void> excluirAluno(String turmaId, String alunoId) async {
    final batch = _db.batch();
    batch.delete(_alunos(turmaId).doc(alunoId));
    batch.update(
      _turmas.doc(turmaId),
      {'quantidadeAlunos': FieldValue.increment(-1)},
    );
    await batch.commit();
  }
}
