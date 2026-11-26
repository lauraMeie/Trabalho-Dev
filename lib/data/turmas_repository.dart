import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/aluno.dart';
import '../models/resumo_turmas.dart';
import '../models/turma.dart';
import '../utils/firestore_errors.dart';
import '../utils/texto_utils.dart';

/// Erro lançado quando já existe outro aluno com a mesma matrícula na turma.
class MatriculaDuplicadaException implements Exception {
  final String matricula;
  const MatriculaDuplicadaException(this.matricula);

  @override
  String toString() =>
      'Já existe um aluno com a matrícula "$matricula" nesta turma.';
}

/// Erro lançado quando a matrícula está vazia.
class MatriculaVaziaException implements Exception {
  const MatriculaVaziaException();

  @override
  String toString() => 'Informe a matrícula do aluno.';
}

/// Acesso ao Firestore para Turmas e Alunos (N2).
///
/// Estrutura no banco:
///   turmas/{turmaId}                 -> { nome, quantidadeAlunos, uid }
///   turmas/{turmaId}/alunos/{id}     -> { nome, matricula }
class TurmasRepository {
  TurmasRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _turmas =>
      _db.collection('turmas');

  CollectionReference<Map<String, dynamic>> _alunos(String turmaId) =>
      _turmas.doc(turmaId).collection('alunos');

  /// Identificador do professor logado (cada professor só vê as suas turmas).
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ---------------------------------------------------------------- TURMAS

  /// Lista de turmas do professor logado, em tempo real.
  /// A ordenação é feita aqui no app (assim não precisa de índice no banco).
  Stream<List<Turma>> turmasStream() {
    return _turmas.where('uid', isEqualTo: _uid).snapshots().map((snap) {
      final lista = snap.docs
          .map((d) => Turma.fromMap(d.id, d.data()))
          .toList();
      lista.sort((a, b) => a.nome.compareTo(b.nome));
      return lista;
    });
  }

  /// Leitura única das turmas (útil para outras telas, ex.: criar prova).
  Future<List<Turma>> listarTurmas() async {
    final snap = await _turmas.where('uid', isEqualTo: _uid).get();
    final lista = snap.docs.map((d) => Turma.fromMap(d.id, d.data())).toList();
    lista.sort((a, b) => a.nome.compareTo(b.nome));
    return lista;
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
        .add({'nome': nome, 'quantidadeAlunos': 0, 'uid': _uid})
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

  /// `true` se o professor logado já tem OUTRA turma com o mesmo nome
  /// (ignora acento, maiúsculas e espaços extras). Em edição, passe o id da
  /// própria turma em [ignorarTurmaId] para ela não ser comparada consigo mesma.
  Future<bool> existeTurmaComNome(String nome, {String? ignorarTurmaId}) async {
    final chave = TextoUtils.chaveDeComparacao(nome);
    final snap = await _turmas.where('uid', isEqualTo: _uid).get();
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
    return _alunos(turmaId).orderBy('nome').snapshots().map(
      (snap) => snap.docs.map((d) => Aluno.fromMap(d.id, d.data())).toList(),
    );
  }

  /// Diz se já existe aluno com essa matrícula na turma.
  /// Em edição, passe [ignorarAlunoId] para não comparar o aluno com ele mesmo.
  Future<bool> matriculaJaExiste(
    String turmaId,
    String matricula, {
    String? ignorarAlunoId,
  }) async {
    final snap = await _alunos(
      turmaId,
    ).where('matricula', isEqualTo: matricula.trim()).get();
    return snap.docs.any((d) => d.id != ignorarAlunoId);
  }

  /// Valida a matrícula (obrigatória e única na turma) e devolve os dados
  /// do aluno já com a matrícula sem espaços nas pontas.
  Future<Map<String, dynamic>> _dadosValidados(
    String turmaId,
    Aluno aluno, {
    String? ignorarAlunoId,
  }) async {
    final matricula = aluno.matricula.trim();
    if (matricula.isEmpty) throw const MatriculaVaziaException();

    if (await matriculaJaExiste(
      turmaId,
      matricula,
      ignorarAlunoId: ignorarAlunoId,
    )) {
      throw MatriculaDuplicadaException(matricula);
    }
    return {...aluno.toMap(), 'matricula': matricula};
  }

  /// Cria o aluno e soma 1 no contador da turma, tudo de uma vez (batch).
  /// Lança [MatriculaDuplicadaException] se a matrícula já existir na turma.
  Future<void> criarAluno(String turmaId, Aluno aluno) async {
    final dados = await _dadosValidados(turmaId, aluno);

    final batch = _db.batch();
    batch.set(_alunos(turmaId).doc(), dados);
    batch.update(_turmas.doc(turmaId), {
      'quantidadeAlunos': FieldValue.increment(1),
    });
    await batch.commit().timeout(tempoLimiteGravacao);
  }

  /// Lança [MatriculaDuplicadaException] se outro aluno da turma já usa
  /// a matrícula informada.
  Future<void> atualizarAluno(String turmaId, Aluno aluno) async {
    final dados = await _dadosValidados(
      turmaId,
      aluno,
      ignorarAlunoId: aluno.id,
    );
    await _alunos(
      turmaId,
    ).doc(aluno.id).update(dados).timeout(tempoLimiteGravacao);
  }

  /// Alunos de uma turma, lidos uma única vez e em ordem alfabética.
  /// Útil para outros módulos (ex.: gerar uma prova para cada aluno).
  Future<List<Aluno>> alunosDaTurma(String turmaId) async {
    final snap = await _alunos(turmaId).orderBy('nome').get();
    return snap.docs.map((d) => Aluno.fromMap(d.id, d.data())).toList();
  }

  /// `true` se já existe OUTRO aluno com a mesma matrícula NESTA turma,
  /// ignorando maiúsculas e acento. É a checagem usada pela tela de cadastro
  /// para mostrar o erro embaixo do campo (o repositório ainda confere de novo
  /// ao gravar, com [matriculaJaExiste]).
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