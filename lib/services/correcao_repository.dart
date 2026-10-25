import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/exam_generator.dart';
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
class CorrecaoRepository {
  CorrecaoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Tempo máximo esperando o Firestore responder uma LEITURA. Sem
  /// internet, o Firestore pode ficar pendente em vez de dar erro.
  static const Duration _tempoLimiteLeitura = Duration(seconds: 10);

  CollectionReference<Map<String, dynamic>> get _provas =>
      _firestore.collection('provas');

  /// Busca a prova (e o gabarito) identificados por um QR Code já
  /// decodificado. Lança [ProvaNaoEncontradaException] se a prova ou a
  /// versão individual dela não existir mais.
  Future<ProvaParaCorrigir> buscarProvaDoAluno(QrProvaPayload payload) async {
    final docPrincipal =
        await _provas.doc(payload.provaId).get().timeout(_tempoLimiteLeitura);
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

  /// Usado só como auxílio de teste: a tela de Criar Prova (RF05, de outro
  /// colega do grupo) ainda não imprime o QR Code na folha de respostas,
  /// então aqui pegamos a prova mais recente já salva no banco para gerar
  /// um QR Code de demonstração e validar a leitura pela câmera ponta a
  /// ponta.
  Future<QrProvaPayload?> buscarQrDeTeste() async {
    final maisRecente = await _provas
        .orderBy('criadaEm', descending: true)
        .limit(1)
        .get()
        .timeout(_tempoLimiteLeitura);
    if (maisRecente.docs.isEmpty) return null;

    final provaId = maisRecente.docs.first.id;
    final individuais = await _provas
        .doc(provaId)
        .collection('individuais')
        .limit(1)
        .get()
        .timeout(_tempoLimiteLeitura);
    if (individuais.docs.isEmpty) return null;

    return QrProvaPayload(
      provaId: provaId,
      individualId: individuais.docs.first.id,
    );
  }
}
