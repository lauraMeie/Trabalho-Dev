import '../models/prova_config.dart';

/// Dados fictícios para a Fase N1 (sem persistência real).
/// Servem para popular a tela de Criar Prova sem depender de banco de dados.
///
/// Usa o model [Question] definido em lib/models/question.dart (Banco de Questões).
/// Atenção: nesse model toda questão tem sempre 5 alternativas (A a E).
///
/// As turmas NÃO são definidas aqui: usamos a lista oficial `turmasMock`
/// de lib/data/turmas_mock.dart, para não ter dois bancos de turmas
/// diferentes no app.

final List<Question> mockQuestoes = [
  const Question(
    id: 'q1',
    subject: 'Matemática',
    statement: 'Qual é o resultado de 7 x 8?',
    alternatives: ['54', '56', '58', '64', '72'],
    correctIndex: 1,
  ),
  const Question(
    id: 'q2',
    subject: 'Matemática',
    statement: 'Qual é a raiz quadrada de 144?',
    alternatives: ['10', '11', '12', '13', '14'],
    correctIndex: 2,
  ),
  const Question(
    id: 'q3',
    subject: 'Matemática',
    statement: 'Resolvendo a equação 2x + 5 = 17, qual é o valor de x?',
    alternatives: ['4', '5', '6', '7', '8'],
    correctIndex: 2,
  ),
  const Question(
    id: 'q4',
    subject: 'Ciências',
    statement: 'Qual é o principal gás responsável pelo efeito estufa?',
    alternatives: [
      'Oxigênio',
      'Gás carbônico',
      'Nitrogênio',
      'Hidrogênio',
      'Hélio',
    ],
    correctIndex: 1,
  ),
  const Question(
    id: 'q5',
    subject: 'Ciências',
    statement: 'Qual organela é responsável pela respiração celular?',
    alternatives: [
      'Ribossomo',
      'Mitocôndria',
      'Núcleo',
      'Lisossomo',
      'Complexo de Golgi',
    ],
    correctIndex: 1,
  ),
  const Question(
    id: 'q6',
    subject: 'Geografia',
    statement: 'Qual é o maior bioma brasileiro em extensão territorial?',
    alternatives: [
      'Cerrado',
      'Caatinga',
      'Amazônia',
      'Mata Atlântica',
      'Pampa',
    ],
    correctIndex: 2,
  ),
  const Question(
    id: 'q7',
    subject: 'Geografia',
    statement: 'Qual desses países faz fronteira com o Brasil?',
    alternatives: ['Chile', 'Panamá', 'Peru', 'México', 'Costa Rica'],
    correctIndex: 2,
  ),
  const Question(
    id: 'q8',
    subject: 'Matemática',
    statement: 'Qual é o valor de π (pi) aproximado com duas casas decimais?',
    alternatives: ['3,41', '3,14', '3,12', '3,16', '3,18'],
    correctIndex: 1,
  ),
];
