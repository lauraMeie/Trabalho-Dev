import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/aluno.dart';
import '../models/turma.dart';

/// Leitura das turmas (e dos alunos de cada uma) no Firestore, usada pela
/// tela Criar Prova.
///
/// Estrutura esperada (coleção `turmas`):
///   turmas/{id}  ->  nome (string)
///                    alunos (array de {nome, matricula})   <- formato 1
///   turmas/{id}/alunos/{id} -> nome, matricula              <- formato 2
///
/// Aceita os DOIS formatos de alunos, porque a tela de Turmas (tarefa do
/// Nicolas) pode salvar de qualquer um dos jeitos.
class TurmaLeituraRepository {
  TurmaLeituraRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String nomeColecao = 'turmas';
  static const String nomeSubcolecaoAlunos = 'alunos';

  Future<List<Turma>> buscarTodas() async {
    final snapshot = await _firestore.collection(nomeColecao).get();

    final turmas = await Future.wait(
      snapshot.docs.map((doc) async {
        final nome = (doc.data()['nome'] as String?)?.trim() ?? '';
        if (nome.isEmpty) {
          debugPrint('Turma ${doc.id} ignorada: sem nome.');
          return null;
        }
        return Turma(nome, await _lerAlunos(doc));
      }),
    );

    return turmas.whereType<Turma>().toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  Future<List<Aluno>> _lerAlunos(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final embutidos = doc.data()['alunos'];
    if (embutidos is List) {
      return embutidos
          .whereType<Map>()
          .map(_alunoDeMapa)
          .whereType<Aluno>()
          .toList();
    }

    final sub = await doc.reference.collection(nomeSubcolecaoAlunos).get();
    return sub.docs
        .map((d) => _alunoDeMapa(d.data()))
        .whereType<Aluno>()
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  Aluno? _alunoDeMapa(Map<dynamic, dynamic> mapa) {
    final nome = (mapa['nome'] as String?)?.trim() ?? '';
    if (nome.isEmpty) return null;
    final matricula = (mapa['matricula'] ?? '').toString().trim();
    return Aluno(nome, matricula);
  }
}
