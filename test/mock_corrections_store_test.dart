import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/data/mock_corrections_store.dart';
import 'package:trabalho/models/correction_result.dart';

// MockCorrectionsStore é um singleton com estado estático compartilhado
// entre os testes deste arquivo (já nasce com 3 resultados de exemplo).
// Por isso os testes abaixo verificam relações/deltas (o que muda a
// cada chamada), em vez de valores absolutos fixos.

RespostaCorrigida _resposta({required bool correta}) {
  return RespostaCorrigida(
    questaoId: 'q-teste',
    materia: 'Matemática',
    enunciado: 'Quanto é 2 + 2?',
    alternativas: const ['2', '3', '4', '5', '6'],
    indiceCorreto: 2,
    indiceMarcado: correta ? 2 : 0,
  );
}

ResultadoCorrecao _resultado(String aluno, String turma, {int acertos = 5, int total = 5}) {
  final respostas = [
    ...List.generate(acertos, (_) => _resposta(correta: true)),
    ...List.generate(total - acertos, (_) => _resposta(correta: false)),
  ];
  return ResultadoCorrecao(
    id: 'res-$aluno',
    aluno: aluno,
    turma: turma,
    provaId: 'PROVA-TESTE',
    corrigidoEm: DateTime(2026, 1, 1),
    respostas: respostas,
  );
}

void main() {
  test('resultados nunca vem vazio (já nasce com resultados de exemplo)', () {
    expect(MockCorrectionsStore.resultados, isNotEmpty);
  });

  test('vazio reflete corretamente se a lista de resultados está vazia', () {
    expect(MockCorrectionsStore.vazio, MockCorrectionsStore.resultados.isEmpty);
  });

  test('resultados é uma lista imutável (não pode ser alterada por fora)', () {
    expect(
      () => MockCorrectionsStore.resultados.add(_resultado('X', 'Y')),
      throwsUnsupportedError,
    );
  });

  test('adicionar insere o novo resultado no topo da lista', () {
    final antes = MockCorrectionsStore.resultados.length;
    final novo = _resultado('Aluno Novo Teste', '9º Ano Z');

    MockCorrectionsStore.adicionar(novo);

    expect(MockCorrectionsStore.resultados.length, antes + 1);
    expect(MockCorrectionsStore.resultados.first, same(novo));
  });

  test('mediaGeral é a média aritmética das notas de todos os resultados', () {
    final resultados = MockCorrectionsStore.resultados;
    final somaEsperada = resultados.fold<double>(0, (soma, r) => soma + r.nota);
    final mediaEsperada = somaEsperada / resultados.length;

    expect(MockCorrectionsStore.mediaGeral, closeTo(mediaEsperada, 0.0001));
  });

  test('totalTurmasDistintas conta as turmas sem repetir', () {
    final turmasEsperadas =
        MockCorrectionsStore.resultados.map((r) => r.turma).toSet().length;

    expect(MockCorrectionsStore.totalTurmasDistintas, turmasEsperadas);
  });

  test('estatisticasPorQuestao inclui a questão recém adicionada', () {
    final resultado = _resultado('Aluno Estatistica', '1º Ano Estat');
    MockCorrectionsStore.adicionar(resultado);

    final estatisticas = MockCorrectionsStore.estatisticasPorQuestao();
    final estatisticaDaQuestao =
        estatisticas.where((e) => e.questaoId == 'q-teste').toList();

    expect(estatisticaDaQuestao, isNotEmpty);
  });

  test('estatística de uma questão nunca tem mais acertos do que respostas', () {
    for (final estatistica in MockCorrectionsStore.estatisticasPorQuestao()) {
      expect(estatistica.acertos, lessThanOrEqualTo(estatistica.totalRespostas));
      expect(estatistica.percentualAcerto, inInclusiveRange(0.0, 1.0));
    }
  });
}
