// Reexporta Question para quem importar só este arquivo já ter acesso
// ao model, sem precisar de dois imports.
export 'question.dart';

/// Representa uma turma (usada aqui só para vincular a prova a uma turma;
/// o cadastro completo de turmas fica a cargo da tela "Turmas").
class Turma {
  final String id;
  final String nome;
  final int numAlunos;

  const Turma({
    required this.id,
    required this.nome,
    required this.numAlunos,
  });
}

/// Configuração escolhida pelo professor ao montar a prova.
class ConfiguracaoProva {
  String nome;
  Turma? turma;
  bool mesmaProvaParaTodos; // RF04
  bool embaralharQuestoes; // RF03
  bool embaralharAlternativas; // RF03
  int colunas; // parte de "editar layout" (RF14)
  double tamanhoFonte; // parte de "editar layout" (RF14)

  ConfiguracaoProva({
    this.nome = '',
    this.turma,
    this.mesmaProvaParaTodos = true,
    this.embaralharQuestoes = false,
    this.embaralharAlternativas = false,
    this.colunas = 1,
    this.tamanhoFonte = 14,
  });
}
