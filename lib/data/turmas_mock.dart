import '../models/aluno.dart';
import '../models/turma.dart';

/// Dados fictícios (mock) usados na N1, enquanto não há banco de dados real.
final List<Turma> turmasMock = [
  Turma('3º Ano A - ADS', [
    Aluno('Ana Souza', '2024001'),
    Aluno('Bruno Lima', '2024002'),
    Aluno('Carla Menezes', '2024003'),
  ]),
  Turma('3º Ano B - ADS', [
    Aluno('Diego Torres', '2024010'),
    Aluno('Elaine Rocha', '2024011'),
  ]),
  Turma('2º Ano A - ADS', [
    Aluno('Felipe Nunes', '2024020'),
  ]),
];
