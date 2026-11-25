import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/correction_result.dart';
import 'package:trabalho/screens/correcao/provas_corrigidas_screen.dart';
import 'package:trabalho/screens/correcao/resultado_correcao_screen.dart';

ResultadoCorrecao _resultado({
  required String id,
  required String aluno,
  required String turma,
  required int acertos,
}) {
  return ResultadoCorrecao(
    id: id,
    aluno: aluno,
    turma: turma,
    provaId: 'prova-1',
    corrigidoEm: DateTime(2026, 11, 20, 9, 5),
    respostas: List.generate(
      4,
      (i) => RespostaCorrigida(
        questaoId: 'q$i',
        materia: 'Matemática',
        enunciado: 'Questão $i',
        alternativas: const ['A', 'B', 'C', 'D'],
        indiceCorreto: 0,
        indiceMarcado: i < acertos ? 0 : 1,
      ),
    ),
  );
}

Widget _app(Stream<List<ResultadoCorrecao>> resultados) {
  return MaterialApp(home: ProvasCorrigidasScreen(resultados: resultados));
}

void main() {
  final ana = _resultado(id: '1', aluno: 'Ana', turma: '3A', acertos: 4);
  final bruno = _resultado(id: '2', aluno: 'Bruno', turma: '3B', acertos: 2);

  testWidgets('mostra carregamento enquanto o stream não emite', (
    tester,
  ) async {
    final controller = StreamController<List<ResultadoCorrecao>>();
    addTearDown(controller.close);

    await tester.pumpWidget(_app(controller.stream));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('lista vazia mostra mensagem clara', (tester) async {
    await tester.pumpWidget(_app(Stream.value(const [])));
    await tester.pump();

    expect(
      find.textContaining('Nenhuma prova corrigida ainda'),
      findsOneWidget,
    );
  });

  testWidgets('erro mostra mensagem amigável', (tester) async {
    await tester.pumpWidget(
      _app(
        Stream.error(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('não tem permissão'), findsOneWidget);
  });

  testWidgets('lista as correções com aluno, turma, data e nota', (
    tester,
  ) async {
    await tester.pumpWidget(_app(Stream.value([ana, bruno])));
    await tester.pump();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('3A · 4/4 acertos · 20/11/2026 09:05'), findsOneWidget);
    expect(find.text('10.0'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('2 provas corrigidas'), findsOneWidget);
  });

  testWidgets('filtro por turma mostra só a turma escolhida', (tester) async {
    await tester.pumpWidget(_app(Stream.value([ana, bruno])));
    await tester.pump();

    await tester.tap(find.text('Todas as turmas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3B').last);
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsNothing);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('1 prova corrigida'), findsOneWidget);
  });

  testWidgets('tocar numa correção abre o resultado dela', (tester) async {
    await tester.pumpWidget(_app(Stream.value([ana, bruno])));
    await tester.pump();

    await tester.tap(find.text('Bruno'));
    await tester.pumpAndSettle();

    final tela = tester.widget<ResultadoCorrecaoScreen>(
      find.byType(ResultadoCorrecaoScreen),
    );
    expect(tela.resultado.id, '2');
    expect(find.text('Detalhe das questões'), findsOneWidget);
  });
}
