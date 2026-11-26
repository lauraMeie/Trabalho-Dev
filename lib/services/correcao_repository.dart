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

/// Monta o ID fixo do documento de correção na coleção `correcoes`, para
/// que corrigir de novo a mesma folha de respostas substitua a correção
/// anterior em vez de criar outra.
///
/// - Prova individual (o aluno veio da própria prova): `provaId_individualId`.
/// - Mesma prova para todos (o professor digita o nome do aluno):
///   `provaId_individualId_nome-normalizado`, onde o nome fica em
///   minúsculas, sem acentos, com espaços trocados por "-" e só [a-z0-9-].
String idDaCorrecao({
  required String provaId,
  required String individualId,
  String? alunoDigitado,
}) {
  final base = '${provaId}_$individualId';
  if (alunoDigitado == null) return base;
  return '${base}_${normalizarNomeParaId(alunoDigitado)}';
}

/// Letras acentuadas e, na mesma posição, a letra sem acento.
const String _comAcento = 'áàâãäåéèêëíìîïóòôõöúùûüçñýÿ';
const String _semAcento = 'aaaaaaeeeeiiiiooooouuuucnyy';

/// Normaliza um nome para uso em ID: minúsculas, sem acentos, espaços
/// (inclusive repetidos ou nas pontas) viram um único "-" e qualquer outro
/// caractere fora de [a-z0-9-] é descartado.
String normalizarNomeParaId(String nome) {
  final semAcento = nome.toLowerCase().split('').map((c) {
    final i = _comAcento.indexOf(c);
    return i < 0 ? c : _semAcento[i];
  }).join();
  return semAcento
      .trim()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9-]'), '')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
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

  /// ID fixo da correção de [prova] (ver [idDaCorrecao]). Na "mesma prova
  /// para todos" (`prova.aluno == null`), usa o nome digitado [aluno].
  static String idDaCorrecaoDe(ProvaParaCorrigir prova, String aluno) {
    return idDaCorrecao(
      provaId: prova.provaId,
      individualId: prova.individualId,
      alunoDigitado: prova.aluno == null ? aluno : null,
    );
  }

  /// Busca a correção já salva com o ID [id] pelo professor logado.
  /// Devolve null se ainda não existir.
  ///
  /// Usa consulta filtrada por `uid` (em vez de `doc(id).get()`) para
  /// continuar valendo a regra de que cada professor só lê as próprias
  /// correções, mesmo quando o documento ainda não existe.
  Future<ResultadoCorrecao?> buscarCorrecaoExistente(String id) async {
    final snapshot = await _correcoes
        .where('uid', isEqualTo: _uid)
        .where(FieldPath.documentId, isEqualTo: id)
        .limit(1)
        .get()
        .timeout(_tempoLimiteLeitura);
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ResultadoCorrecao.fromMap(doc.id, doc.data());
  }

  /// Salva o resultado de UMA correção no Firestore (RF08) com ID fixo
  /// (ver [idDaCorrecao]): corrigir de novo a mesma folha substitui a
  /// correção anterior em vez de duplicá-la. [prova] é a prova lida pelo QR
  /// Code, usada para montar o ID. Devolve o mesmo resultado já com o ID do
  /// documento. A correção é gravada com o `uid` do professor logado.
  Future<ResultadoCorrecao> salvarResultado(
    ResultadoCorrecao resultado, {
    required ProvaParaCorrigir prova,
  }) async {
    final id = idDaCorrecaoDe(prova, resultado.aluno);
    final dados = {...resultado.toMap(), 'uid': _uid};
    await _correcoes.doc(id).set(dados).timeout(tempoLimiteGravacao);
    return ResultadoCorrecao.fromMap(id, dados);
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
