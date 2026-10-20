import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/question.dart';
import '../utils/firestore_errors.dart';

/// Acesso ao Banco de Questões no Firestore (coleção `questoes`).
///
/// Estrutura de cada documento (ID = id da questão):
///   subject      (string)  matéria
///   statement    (string)  enunciado
///   alternatives (array)   5 strings
///   correctIndex (number)  0 a 4
///   criadoEm / atualizadoEm (timestamp do servidor)
class QuestionRepository {
  QuestionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String nomeColecao = 'questoes';

  CollectionReference<Map<String, dynamic>> get _colecao =>
      _firestore.collection(nomeColecao);

  /// Fica "ouvindo" o banco: sempre que alguém cria, edita ou exclui
  /// uma questão, a lista é emitida de novo automaticamente.
  Stream<List<Question>> observar() {
    return _colecao.snapshots().map(_converter);
  }

  /// Busca todas as questões uma única vez (usado na tela Criar Prova).
  Future<List<Question>> buscarTodas() async {
    final snapshot = await _colecao.get();
    return _converter(snapshot);
  }

  Future<void> adicionar(Question questao) {
    return _colecao.add({
      ...questao.toMap(),
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    }).timeout(tempoLimiteGravacao);
  }

  Future<void> atualizar(Question questao) {
    return _colecao.doc(questao.id).update({
      ...questao.toMap(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    }).timeout(tempoLimiteGravacao);
  }

  Future<void> remover(String id) {
    return _colecao.doc(id).delete().timeout(tempoLimiteGravacao);
  }

  /// Copia o banco fictício da N1 (50 questões) para o Firestore.
  /// Usa o id original (q001...) como ID do documento, então rodar duas
  /// vezes não duplica nada.
  Future<void> importarQuestoes(List<Question> questoes) {
    final batch = _firestore.batch();
    for (final questao in questoes) {
      batch.set(_colecao.doc(questao.id), {
        ...questao.toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    }
    return batch.commit().timeout(tempoLimiteGravacao);
  }

  /// Converte os documentos em [Question], ignorando (e registrando no
  /// log) qualquer documento mal formatado, para que UMA questão ruim
  /// não derrube a lista inteira.
  List<Question> _converter(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final questoes = <Question>[];
    for (final doc in snapshot.docs) {
      try {
        questoes.add(Question.fromMap(doc.id, doc.data()));
      } on FormatException catch (e) {
        debugPrint('Questão ignorada: ${e.message}');
      }
    }
    questoes.sort((a, b) {
      final porMateria = a.subject.compareTo(b.subject);
      return porMateria != 0 ? porMateria : a.statement.compareTo(b.statement);
    });
    return questoes;
  }
}
