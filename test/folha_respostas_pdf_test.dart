import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/prova_gerada.dart';
import 'package:trabalho/utils/exam_generator.dart';
import 'package:trabalho/utils/folha_respostas_pdf.dart';
import 'package:trabalho/utils/prova_pdf.dart';

List<GeneratedQuestion> _questoes(int quantidade) => [
  for (var i = 0; i < quantidade; i++)
    GeneratedQuestion(
      originalId: 'q$i',
      subject: 'Matemática',
      statement: 'Quanto é $i + 1?',
      alternatives: ['1', '2', '3', '4', '5'],
      correctIndex: i % 5,
    ),
];

int _totalPaginas(List<int> pdf) {
  final contagem = RegExp(r'/Count (\d+)').firstMatch(latin1.decode(pdf));
  return int.parse(contagem!.group(1)!);
}

void main() {
  test('cada aluno recebe uma folha de respostas depois da prova', () async {
    final prova = ProvaGerada(
      nome: 'Prova',
      turmaNome: 'Turma A',
      mesmaProvaParaTodos: false,
      embaralhouQuestoes: true,
      embaralhouAlternativas: true,
      colunas: 1,
      tamanhoFonte: 12,
      provas: [
        ProvaDoAluno(aluno: 'Ana', matricula: '1', questoes: _questoes(3)),
        ProvaDoAluno(aluno: 'Bruno', matricula: '2', questoes: _questoes(3)),
      ],
    );

    final bytes = await ProvaPdf.gerar(prova, provaId: 'PROVA-1');

    // 1 página de questões + 1 folha de respostas, para cada aluno.
    expect(_totalPaginas(bytes), 4);
  });

  test('provas com mais de 60 questões ganham mais de uma folha', () {
    List<Object> paginas(int questoes) => FolhaRespostasPdf.paginas(
      nomeProva: 'Prova',
      turma: 'Turma A',
      aluno: null,
      matricula: null,
      totalQuestoes: questoes,
      payloadQr: 'provalab://prova/X/0000',
    );

    expect(paginas(60), hasLength(1));
    expect(paginas(61), hasLength(2));
  });
}
