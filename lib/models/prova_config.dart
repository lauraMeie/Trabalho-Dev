
import 'turma.dart';

export 'question.dart';
export 'turma.dart';


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
