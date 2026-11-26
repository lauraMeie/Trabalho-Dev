import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/aluno.dart';
import 'package:trabalho/models/turma.dart';

void main() {
  group('Aluno', () {
    test('toMap guarda nome e matrícula, sem o id', () {
      final aluno = Aluno('Ana Souza', '2024001', id: 'a1');
      expect(aluno.toMap(), {'nome': 'Ana Souza', 'matricula': '2024001'});
    });

    test('fromMap preenche id, nome e matrícula', () {
      final aluno = Aluno.fromMap('a1', {
        'nome': 'Ana Souza',
        'matricula': '2024001',
      });
      expect(aluno.id, 'a1');
      expect(aluno.nome, 'Ana Souza');
      expect(aluno.matricula, '2024001');
    });

    test('fromMap usa texto vazio quando faltam campos', () {
      final aluno = Aluno.fromMap('a2', {});
      expect(aluno.id, 'a2');
      expect(aluno.nome, '');
      expect(aluno.matricula, '');
    });
  });

  group('Turma', () {
    test('toMap guarda só o nome (o contador é cuidado pelo repositório)', () {
      expect(Turma('3º Ano A', []).toMap(), {'nome': '3º Ano A'});
    });

    test('fromMap lê id, nome e quantidadeAlunos', () {
      final turma = Turma.fromMap('t1', {
        'nome': '3º Ano A',
        'quantidadeAlunos': 12,
      });
      expect(turma.id, 't1');
      expect(turma.nome, '3º Ano A');
      expect(turma.totalAlunos, 12);
      expect(turma.quantidadeAlunos, 12);
      expect(turma.alunos, isEmpty);
    });

    test('fromMap aceita número decimal e usa 0 quando o campo não existe', () {
      expect(
        Turma.fromMap('t1', {'quantidadeAlunos': 7.0}).quantidadeAlunos,
        7,
      );

      final vazia = Turma.fromMap('t2', {});
      expect(vazia.nome, '');
      expect(vazia.quantidadeAlunos, 0);
    });

    test(
      'quantidadeAlunos usa o tamanho da lista quando não há total (mock)',
      () {
        final turma = Turma('2º Ano B', [Aluno('A', '1'), Aluno('B', '2')]);
        expect(turma.quantidadeAlunos, 2);
      },
    );

    test('totalAlunos tem prioridade sobre o tamanho da lista', () {
      final turma = Turma('2º Ano B', [Aluno('A', '1')], totalAlunos: 5);
      expect(turma.quantidadeAlunos, 5);
    });
  });
}
