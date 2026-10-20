import 'aluno.dart';

/// Turma do professor.
/// No Firestore fica em: turmas/{turmaId}
class Turma {
  /// ID do documento no Firestore (null para turmas só em memória/mock).
  final String? id;
  String nome;

  /// Lista de alunos em memória. Usada pelos dados mock; com o Firestore os
  /// alunos são lidos da subcoleção "alunos" (ver TurmasRepository).
  final List<Aluno> alunos;

  /// Total de alunos guardado no documento da turma (campo "quantidadeAlunos").
  final int? totalAlunos;

  Turma(this.nome, this.alunos, {this.id, this.totalAlunos});

  /// Mantém compatibilidade com o código que já usava a lista mock.
  int get quantidadeAlunos => totalAlunos ?? alunos.length;

  /// Converte o documento do Firestore em um objeto Turma.
  factory Turma.fromMap(String id, Map<String, dynamic> map) {
    return Turma(
      map['nome'] as String? ?? '',
      [],
      id: id,
      totalAlunos: (map['quantidadeAlunos'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converte a Turma em um Map para gravar no Firestore.
  Map<String, dynamic> toMap() {
    return {'nome': nome};
  }
}
