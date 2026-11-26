import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/correction_result.dart';
import 'package:trabalho/services/excel_export/planilha_relatorio.dart';
import 'package:trabalho/services/excel_export_service.dart';

/// Correção com gabarito sempre "A" (índice 0); [marcacoes] são os índices
/// marcados pelo aluno (null = em branco).
ResultadoCorrecao _resultado({
  required String aluno,
  String matricula = '',
  String turma = '3º Ano A',
  String provaId = 'p1',
  String provaNome = 'Prova 1',
  required List<int?> marcacoes,
  DateTime? corrigidoEm,
}) {
  return ResultadoCorrecao(
    id: '$aluno-$provaId-${corrigidoEm?.millisecondsSinceEpoch}',
    aluno: aluno,
    matricula: matricula,
    turma: turma,
    provaId: provaId,
    provaNome: provaNome,
    corrigidoEm: corrigidoEm ?? DateTime(2026, 3, 1),
    respostas: [
      for (var i = 0; i < marcacoes.length; i++)
        RespostaCorrigida(
          questaoId: 'q$i',
          materia: 'Matemática',
          enunciado: 'Enunciado $i',
          alternativas: const ['a', 'b', 'c', 'd', 'e'],
          indiceCorreto: 0,
          indiceMarcado: marcacoes[i],
        ),
    ],
  );
}

void main() {
  group('Aba por turma', () {
    test('alunos × provas, com célula vazia para prova não feita e média', () {
      final resultados = [
        // Bruno: Prova 1 = 10, Prova 2 = 5
        _resultado(
          aluno: 'Bruno',
          matricula: '002',
          marcacoes: [0, 0],
          corrigidoEm: DateTime(2026, 3, 1),
        ),
        _resultado(
          aluno: 'Bruno',
          matricula: '002',
          provaId: 'p2',
          provaNome: 'Prova 2',
          marcacoes: [0, 1],
          corrigidoEm: DateTime(2026, 3, 10),
        ),
        // Ana: só fez a Prova 1 (2 de 3 = 6,666...)
        _resultado(
          aluno: 'Ana',
          matricula: '001',
          marcacoes: [0, 0, 1],
          corrigidoEm: DateTime(2026, 3, 2),
        ),
      ];

      final abas = PlanilhaRelatorio.montarAbasPorTurma(resultados);
      expect(abas, hasLength(1));
      final aba = abas.single;

      expect(aba.nome, '3º Ano A');
      expect(aba.cabecalho, [
        'Aluno',
        'Matrícula',
        'Prova 1',
        'Prova 2',
        'Média',
      ]);
      expect(aba.linhas, [
        ['Ana', '001', 6.7, null, 6.7],
        ['Bruno', '002', 10.0, 5.0, 7.5],
      ]);
      expect(aba.colunasDeNota, {2, 3, 4});
    });

    test('usa a correção mais recente quando há duplicidade', () {
      final resultados = [
        _resultado(
          aluno: 'Ana',
          matricula: '001',
          marcacoes: [1, 1],
          corrigidoEm: DateTime(2026, 3, 1),
        ),
        _resultado(
          aluno: 'Ana Souza',
          matricula: '001',
          marcacoes: [0, 0],
          corrigidoEm: DateTime(2026, 3, 5),
        ),
        _resultado(
          aluno: 'Ana',
          matricula: '001',
          marcacoes: [0, 1],
          corrigidoEm: DateTime(2026, 3, 3),
        ),
      ];

      final aba = PlanilhaRelatorio.montarAbasPorTurma(resultados).single;
      expect(aba.linhas, [
        ['Ana Souza', '001', 10.0, 10.0],
      ]);
    });

    test('sem matrícula, o aluno é identificado pelo nome', () {
      final resultados = [
        _resultado(aluno: 'Carla', marcacoes: [0]),
        _resultado(
          aluno: 'carla ',
          provaId: 'p2',
          provaNome: 'Prova 2',
          marcacoes: [1],
          corrigidoEm: DateTime(2026, 3, 2),
        ),
        _resultado(aluno: 'Davi', marcacoes: [1]),
      ];

      final aba = PlanilhaRelatorio.montarAbasPorTurma(resultados).single;
      expect(aba.linhas, [
        ['carla ', '', 10.0, 0.0, 5.0],
        ['Davi', '', 0.0, null, 0.0],
      ]);
    });

    test('cria uma aba por turma, em ordem alfabética', () {
      final resultados = [
        _resultado(aluno: 'A', turma: 'Turma B', marcacoes: [0]),
        _resultado(aluno: 'B', turma: 'Turma A', marcacoes: [0]),
      ];

      final nomes = PlanilhaRelatorio.montarAbasPorTurma(
        resultados,
      ).map((a) => a.nome).toList();
      expect(nomes, ['Turma A', 'Turma B']);
    });
  });

  group('Aba Respostas', () {
    test('mostra letra marcada com ✓, ✗ ou — e completa até o maior Q', () {
      final resultados = [
        _resultado(aluno: 'Ana', matricula: '001', marcacoes: [0, 1, null]),
        _resultado(aluno: 'Bruno', matricula: '002', marcacoes: [0]),
      ];

      final aba = PlanilhaRelatorio.montarRespostas(resultados);
      expect(aba.nome, 'Respostas');
      expect(aba.cabecalho, [
        'Aluno',
        'Matrícula',
        'Turma',
        'Prova',
        'Nota',
        'Q1',
        'Q2',
        'Q3',
      ]);
      expect(aba.linhas, [
        ['Ana', '001', '3º Ano A', 'Prova 1', 3.3, 'A ✓', 'B ✗', '—'],
        ['Bruno', '002', '3º Ano A', 'Prova 1', 10.0, 'A ✓', null, null],
      ]);
    });
  });

  group('Aba Resumo', () {
    test('ordena por turma e aluno e arredonda a nota', () {
      final resultados = [
        _resultado(aluno: 'Zeca', turma: 'B', marcacoes: [0]),
        _resultado(aluno: 'Bia', turma: 'A', marcacoes: [0, 0, 1]),
        _resultado(aluno: 'Álvaro', turma: 'B', marcacoes: [1]),
      ];

      final aba = PlanilhaRelatorio.montarResumo(resultados);
      expect(aba.cabecalho.first, 'Aluno');
      expect(aba.cabecalho.last, 'Corrigido em');
      expect(aba.linhas.map((l) => l[0]), ['Bia', 'Álvaro', 'Zeca']);
      expect(aba.linhas.first[4], 6.7);
      expect(aba.linhas.first[8], '01/03/2026 00:00');
    });
  });

  group('Nome de aba', () {
    test('remove caracteres proibidos', () {
      expect(
        PlanilhaRelatorio.sanitizarNomeAba('3º [A]: *manhã?/tarde\\'),
        '3º A manhãtarde',
      );
    });

    test('limita a 31 caracteres', () {
      final nome = PlanilhaRelatorio.sanitizarNomeAba(
        'Turma de Matemática Avançada do Terceiro Ano',
      );
      expect(nome.length, lessThanOrEqualTo(31));
      expect(nome, 'Turma de Matemática Avançada do');
    });

    test('nome vazio depois de limpar vira "Turma"', () {
      expect(PlanilhaRelatorio.sanitizarNomeAba('[]?*'), 'Turma');
    });

    test('acrescenta número quando o nome se repete, sem passar de 31', () {
      final usados = <String>{'resumo', 'respostas'};
      final longo = 'X' * 40;

      expect(PlanilhaRelatorio.nomeUnicoDeAba('Turma/A', usados), 'TurmaA');
      expect(PlanilhaRelatorio.nomeUnicoDeAba('Turma:A', usados), 'TurmaA 2');
      expect(PlanilhaRelatorio.nomeUnicoDeAba('Resumo', usados), 'Resumo 2');

      final primeiro = PlanilhaRelatorio.nomeUnicoDeAba(longo, usados);
      final segundo = PlanilhaRelatorio.nomeUnicoDeAba(longo, usados);
      expect(primeiro, 'X' * 31);
      expect(segundo, '${'X' * 29} 2');
      expect(segundo.length, 31);
    });

    test('turmas com nomes que colidem depois de limpar ganham número', () {
      final resultados = [
        _resultado(aluno: 'A', turma: 'Turma/1', marcacoes: [0]),
        _resultado(aluno: 'B', turma: 'Turma:1', marcacoes: [0]),
      ];

      final nomes = PlanilhaRelatorio.montarAbasPorTurma(
        resultados,
      ).map((a) => a.nome).toList();
      expect(nomes, ['Turma1', 'Turma1 2']);
    });
  });

  group('Arquivo .xlsx', () {
    test('gera os bytes e as abas esperadas podem ser lidas de volta', () {
      final resultados = [
        _resultado(aluno: 'Ana', matricula: '001', marcacoes: [0, 0, 1]),
        _resultado(
          aluno: 'Bruno',
          turma: 'Turma: [Noite]',
          marcacoes: [null, 0],
        ),
      ];

      final bytes = ExcelExportService.gerarBytes(resultados);
      final lido = xlsx.Excel.decodeBytes(bytes);

      expect(lido.tables.keys.toList(), [
        'Resumo',
        '3º Ano A',
        'Turma Noite',
        'Respostas',
      ]);

      final turma = lido.tables['3º Ano A']!;
      expect(turma.row(0).map((c) => c?.value.toString()).toList(), [
        'Aluno',
        'Matrícula',
        'Prova 1',
        'Média',
      ]);
      expect(turma.row(1)[2]?.value, xlsx.DoubleCellValue(6.7));
      expect(turma.row(1)[3]?.value, xlsx.DoubleCellValue(6.7));

      final respostas = lido.tables['Respostas']!;
      expect(respostas.row(2)[5]?.value, xlsx.TextCellValue('—'));
    });
  });
}
