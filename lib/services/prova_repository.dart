import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prova_gerada.dart';
import '../utils/firestore_errors.dart';

/// Salva as provas geradas no Firestore.
///
/// Estrutura:
///   provas/{provaId}                    -> dados gerais (nome, turma, layout...)
///   provas/{provaId}/individuais/{n}    -> uma prova por aluno (ou uma só,
///                                          se for "mesma prova para todos"),
///                                          com as questões JÁ embaralhadas
///                                          e o gabarito.
class ProvaRepository {
  ProvaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String nomeColecao = 'provas';
  static const String nomeSubcolecao = 'individuais';

  // O Firestore aceita no máximo 500 operações por batch.
  static const int _limitePorBatch = 450;

  /// Salva a prova e devolve o ID do documento criado.
  Future<String> salvar(ProvaGerada prova) async {
    final docPrincipal = _firestore.collection(nomeColecao).doc();
    final subcolecao = docPrincipal.collection(nomeSubcolecao);

    final operacoes = <void Function(WriteBatch)>[
      (batch) => batch.set(docPrincipal, {
            ...prova.toMapPrincipal(),
            'criadaEm': FieldValue.serverTimestamp(),
          }),
      for (int i = 0; i < prova.provas.length; i++)
        (batch) => batch.set(
              subcolecao.doc(i.toString().padLeft(4, '0')),
              prova.provas[i].toMap(),
            ),
    ];

    for (int inicio = 0; inicio < operacoes.length; inicio += _limitePorBatch) {
      final fim = inicio + _limitePorBatch > operacoes.length
          ? operacoes.length
          : inicio + _limitePorBatch;
      final batch = _firestore.batch();
      for (final operacao in operacoes.sublist(inicio, fim)) {
        operacao(batch);
      }
      await batch.commit().timeout(tempoLimiteGravacao);
    }

    return docPrincipal.id;
  }
}
