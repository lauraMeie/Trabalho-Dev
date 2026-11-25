import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/correction_result.dart';
import '../utils/exam_generator.dart';
import '../utils/firestore_errors.dart';
import 'qr_prova_codec.dart';

/// Prova de um aluno específico, lida de volta do Firestore a partir da
/// identificação obtida pelo QR Code (RF06): já traz as questões na mesma
/// ordem/embaralhamento salvos quando a prova foi gerada, para a correção
/// comparar com o gabarito real.
class ProvaParaCorrigir {
  final String provaId;
  final String individualId;
  final String provaNome;
  final String turmaNome;
  final String? aluno;
  final String? matricula;
  final List<GeneratedQuestion> questoes;

  const ProvaParaCorrigir({
    required this.provaId,
    required this.individualId,
    required this.provaNome,
    required this.turmaNome,
    required this.aluno,
    required this.matricula,
    required this.questoes,
  });
}

/// Exceção lançada quando o QR Code é válido, mas a prova que ele aponta
/// não existe mais no banco (ex.: foi excluída).
class ProvaNaoEncontradaException implements Exception {
  const ProvaNaoEncontradaException();
}

/// Acesso ao Firestore para a etapa de leitura/correção de provas (RF06/RF07).
///
/// Lê a prova gerada pela tela Criar Prova (coleção `provas`, ver
/// ProvaRepository) a partir do ID identificado no QR Code da folha de
/// respostas.
///
/// Cada professor só enxerga as próprias provas e correções: os documentos
/// guardam o campo `uid` do dono e as consultas filtram por ele.
class CorrecaoRepository {
  CorrecaoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Tempo máximo esperando o Firestore responder uma LEITURA. Sem
  /// internet, o Firestore pode ficar pendente em vez de dar erro.
  static const Duration _tempoLimiteLeitura = Duration(seconds: 10);

  /// UID do professor logado.
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _provas =>
      _firestore.collection('provas');

  /// Correções já realizadas (RF09/RF11), uma por folha de respostas lida.
  static const String nomeColecaoCorrecoes = 'correcoes';

  CollectionReference<Map<String, dynamic>> get _correcoes =>
      _firestore.collection(nomeColecaoCorrecoes);

  /// Converte um campo de data (String ISO ou Timestamp) em texto
  /// comparável, para ordenar no app sem precisar de índice composto.
  String _dataComoTexto(dynamic valor) {
    if (valor is Timestamp) return valor.toDate().toIso8601String();
    return valor?.toString() ?? '';
  }

  /// Busca a prova (e o gabarito) identificados por um QR Code já
  /// decodificado. Lança [ProvaNaoEncontradaException] se a prova ou a
  /// versão individual dela não existir mais.
  ///
  /// As regras do Firestore recusam a leitura de provas de outro professor
  /// (vira FirebaseException com code 'permission-denied').
  Future<ProvaParaCorrigir> buscarProvaDoAluno(QrProvaPayload payload) async {
    final docPrincipal = await _provas
        .doc(payload.provaId)
        .get()
        .timeout(_tempoLimiteLeitura);
    if (!docPrincipal.exists) throw const ProvaNaoEncontradaException();

    final docIndividual = await _provas
        .doc(payload.provaId)
        .collection('individuais')
        .doc(payload.individualId)
        .get()
        .timeout(_tempoLimiteLeitura);
    if (!docIndividual.exists) throw const ProvaNaoEncontradaException();

    final principal = docPrincipal.data()!;
    final individual = docIndividual.data()!;

    final questoes = (individual['questoes'] as List? ?? const [])
        .whereType<Map>()
        .map((q) => GeneratedQuestion.fromMap(Map<String, dynamic>.from(q)))
        .toList();

    return ProvaParaCorrigir(
      provaId: payload.provaId,
      individualId: payload.individualId,
      provaNome: principal['nome'] as String? ?? '(sem nome)',
      turmaNome: principal['turmaNome'] as String? ?? '(sem turma)',
      aluno: individual['aluno'] as String?,
      matricula: individual['matricula'] as String?,
      questoes: questoes,
    );
  }

  // ------------------------------------------------------------ CORREÇÕES

  /// Salva o resultado de UMA correção no Firestore (RF08) e devolve o
  /// mesmo resultado já com o ID definitivo do documento salvo.
  /// A correção é gravada com o `uid` do professor logado.
  Future<ResultadoCorrecao> salvarResultado(ResultadoCorrecao resultado) async {
    final dados = {...resultado.toMap(), 'uid': _uid};
    final doc = await _correcoes.add(dados).timeout(tempoLimiteGravacao);
    return ResultadoCorrecao.fromMap(doc.id, dados);
  }

  /// Fica "ouvindo" as correções do professor logado: a tela de Relatórios
  /// atualiza sozinha sempre que uma nova prova é corrigida, sem precisar
  /// recarregar. Mais recentes primeiro.
  Stream<List<ResultadoCorrecao>> observarResultados() {
    return _correcoes.where('uid', isEqualTo: _uid).snapshots().map((snapshot) {
      final docs = snapshot.docs.toList()
        ..sort(
          (a, b) => _dataComoTexto(
            b.data()['corrigidoEm'],
          ).compareTo(_dataComoTexto(a.data()['corrigidoEm'])),
        );
      return docs
          .map((doc) => ResultadoCorrecao.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
