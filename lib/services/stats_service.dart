import 'dart:async';

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

  /// Atualiza em tempo real sempre que turmas, alunos ou provas
  /// do professor logado mudarem.
  static Stream<Stats> stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const Stats(0, 0, 0));

    late final StreamController<Stats> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? turmasSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? provasSub;
    final alunosSubs =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final alunosPorTurma = <String, int>{};

    var turmas = 0;
    var provas = 0;
    var turmasPronto = false;
    var provasPronto = false;

    void emitir() {
      // Só emite depois que turmas e provas chegaram pela primeira vez,
      // para não piscar "0" na tela.
      if (controller.isClosed || !turmasPronto || !provasPronto) return;
      final alunos = alunosPorTurma.values.fold<int>(0, (a, b) => a + b);
      controller.add(Stats(turmas, alunos, provas));
    }

    Future<void> cancelarTudo() async {
      await turmasSub?.cancel();
      await provasSub?.cancel();
      for (final sub in alunosSubs.values) {
        await sub.cancel();
      }
      alunosSubs.clear();
      alunosPorTurma.clear();
    }

    controller = StreamController<Stats>(
      onListen: () {
        // Turmas (e, para cada turma, a contagem de alunos)
        turmasSub = _db
            .collection('turmas')
            .where('uid', isEqualTo: uid)
            .snapshots()
            .listen((snap) {
          turmas = snap.docs.length;
          turmasPronto = true;

          // Para de ouvir turmas que foram removidas.
          final idsAtuais = snap.docs.map((d) => d.id).toSet();
          final removidas =
              alunosSubs.keys.where((id) => !idsAtuais.contains(id)).toList();
          for (final id in removidas) {
            alunosSubs.remove(id)?.cancel();
            alunosPorTurma.remove(id);
          }

          // Começa a ouvir os alunos de turmas novas.
          for (final turma in snap.docs) {
            if (alunosSubs.containsKey(turma.id)) continue;
            alunosSubs[turma.id] = turma.reference
                .collection('alunos')
                .snapshots()
                .listen((alunosSnap) {
              alunosPorTurma[turma.id] = alunosSnap.docs.length;
              emitir();
            }, onError: (Object e) {
              // Turma apagada ou sem permissão: ignora o erro dela.
              alunosPorTurma.remove(turma.id);
              emitir();
            });
          }

          emitir();
        }, onError: controller.addError);

        // Provas do professor
        provasSub = _db
            .collection('provas')
            .where('uid', isEqualTo: uid)
            .snapshots()
            .listen((snap) {
          provas = snap.docs.length;
          provasPronto = true;
          emitir();
        }, onError: controller.addError);
      },
      onCancel: cancelarTudo,
    );

    return controller.stream;
  }
}