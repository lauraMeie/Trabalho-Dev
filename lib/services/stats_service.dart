import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Stats {
  final int turmas;
  final int alunos;
  final int provas;
  const Stats(this.turmas, this.alunos, this.provas);
}

class StatsService {
  static final _db = FirebaseFirestore.instance;

  /// Atualiza sempre que as turmas do usuário mudam.
  static Stream<Stats> stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const Stats(0, 0, 0));

    return _db
        .collection('turmas')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
      // Alunos: soma dos alunos de cada turma
      int alunos = 0;
      for (final turma in snap.docs) {
        final c = await turma.reference.collection('alunos').count().get();
        alunos += c.count ?? 0;
      }

      // Provas
      final provasSnap = await _db.collection('provas').count().get();

      return Stats(snap.docs.length, alunos, provasSnap.count ?? 0);
    });
  }
}