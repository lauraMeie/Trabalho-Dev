/// Aluno de uma turma.
/// No Firestore fica em: turmas/{turmaId}/alunos/{alunoId}
class Aluno {
  /// ID do documento no Firestore (null enquanto o aluno ainda não foi salvo).
  final String? id;
  String nome;
  String matricula;

  Aluno(this.nome, this.matricula, {this.id});

  /// Converte o documento do Firestore em um objeto Aluno.
  factory Aluno.fromMap(String id, Map<String, dynamic> map) {
    return Aluno(
      map['nome'] as String? ?? '',
      map['matricula'] as String? ?? '',
      id: id,
    );
  }

  /// Converte o Aluno em um Map para gravar no Firestore.
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'matricula': matricula};
  }
}
