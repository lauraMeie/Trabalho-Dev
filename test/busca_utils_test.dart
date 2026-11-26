import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/aluno.dart';
import 'package:trabalho/models/turma.dart';
import 'package:trabalho/utils/busca_utils.dart';

void main() {
  final turmas = [
    Turma('3º Ano A - ADS', []),
    Turma('3º Ano B - ADS', []),
    Turma('Programação Móvel', []),
  ];
  final alunos = [
    Aluno('João da Silva', '2024001'),
    Aluno('Ana Souza', '2024002'),
    Aluno('Maria Joana', 'RA-77'),
  ];

  group('filtrarTurmas', () {
    test('consulta vazia devolve todas', () {
      expect(BuscaUtils.filtrarTurmas(turmas, '  '), hasLength(3));
    });

    test('ignora maiúsculas e acento', () {
      final achadas = BuscaUtils.filtrarTurmas(turmas, 'programacao movel');
      expect(achadas, hasLength(1));
      expect(achadas.first.nome, 'Programação Móvel');
    });

    test('acha por parte do nome', () {
      expect(BuscaUtils.filtrarTurmas(turmas, 'ano b'), hasLength(1));
      expect(BuscaUtils.filtrarTurmas(turmas, 'ads'), hasLength(2));
    });

    test('sem resultado devolve lista vazia', () {
      expect(BuscaUtils.filtrarTurmas(turmas, 'zzz'), isEmpty);
    });
  });

  group('filtrarAlunos', () {
    test('consulta vazia devolve todos', () {
      expect(BuscaUtils.filtrarAlunos(alunos, ''), hasLength(3));
    });

    test('acha pelo nome sem acento', () {
      final achados = BuscaUtils.filtrarAlunos(alunos, 'joao');
      expect(achados, hasLength(1));
      expect(achados.first.nome, 'João da Silva');
    });

    test('acha pela matrícula', () {
      final achados = BuscaUtils.filtrarAlunos(alunos, '2024002');
      expect(achados, hasLength(1));
      expect(achados.first.nome, 'Ana Souza');
      expect(BuscaUtils.filtrarAlunos(alunos, 'ra-77'), hasLength(1));
    });

    test('nome e matrícula contam: "jo" acha João e Joana', () {
      expect(BuscaUtils.filtrarAlunos(alunos, 'jo'), hasLength(2));
    });
  });
}
