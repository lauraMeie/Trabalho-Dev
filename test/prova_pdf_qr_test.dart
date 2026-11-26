import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/prova_gerada.dart';
import 'package:trabalho/utils/exam_generator.dart';
import 'package:trabalho/utils/prova_pdf.dart';

void main() {
  test('gera PDF com QR Code de identificação da versão individual', () async {
    final prova = ProvaGerada(
      nome: 'Prova de teste',
      turmaNome: 'Turma A',
      mesmaProvaParaTodos: true,
      embaralhouQuestoes: false,
      embaralhouAlternativas: false,
      colunas: 1,
      tamanhoFonte: 14,
      provas: [
        ProvaDoAluno(
          aluno: 'Aluno Teste',
          matricula: '123',
          questoes: [
            GeneratedQuestion(
              originalId: 'q1',
              subject: 'Matemática',
              statement: 'Quanto é 1 + 1?',
              alternatives: ['1', '2', '3', '4', '5'],
              correctIndex: 1,
            ),
          ],
        ),
      ],
    );

    final bytes = await ProvaPdf.gerar(prova, provaId: 'PROVA-TESTE');

    expect(bytes, isNotEmpty);
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
  });
}
