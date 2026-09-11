import 'aluno.dart';

class Turma {
  final String nome;
  final List<Aluno> alunos;

  Turma(this.nome, this.alunos);

  int get quantidadeAlunos => alunos.length;
}
