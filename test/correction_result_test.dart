import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/correction_result.dart';

RespostaCorrigida _resposta({
  required int indiceCorreto,
  required int? indiceMarcado,
}) {
  return RespostaCorrigida(
    questaoId: 'q1',
    materia: 'Matemática',
    enunciado: 'Quanto é 2 + 2?',
    alternativas: const ['2', '3', '4', '5', '6'],
    indiceCorreto: indiceCorreto,
    indiceMarcado: indiceMarcado,
  );
}

void main() {
  group('RespostaCorrigida', () {
    test('emBranco é true quando indiceMarcado é null', () {
      final resposta = _resposta(indiceCorreto: 2, indiceMarcado: null);
      expect(resposta.emBranco, isTrue);
      expect(resposta.correta, isFalse);
    });

    test('correta é true quando indiceMarcado == indiceCorreto', () {
      final resposta = _resposta(indiceCorreto: 2, indiceMarcado: 2);
      expect(resposta.correta, isTrue);
      expect(resposta.emBranco, isFalse);
    });

    test('correta é false quando indiceMarcado difere de indiceCorreto', () {
      final resposta = _resposta(indiceCorreto: 2, indiceMarcado: 0);
      expect(resposta.correta, isFalse);
      expect(resposta.emBranco, isFalse);
    });

    test('textoCorreto retorna a alternativa no indiceCorreto', () {
      final resposta = _resposta(indiceCorreto: 2, indiceMarcado: 0);
      expect(resposta.textoCorreto, '4');
    });

    test('textoMarcado é null quando em branco, e o texto certo quando marcado', () {
      final emBranco = _resposta(indiceCorreto: 2, indiceMarcado: null);
      expect(emBranco.textoMarcado, isNull);

      final marcada = _resposta(indiceCorreto: 2, indiceMarcado: 1);
      expect(marcada.textoMarcado, '3');
    });
  });

  group('ResultadoCorrecao', () {
    ResultadoCorrecao construir(List<RespostaCorrigida> respostas) {
      return ResultadoCorrecao(
        id: 'r1',
        aluno: 'Aluno Teste',
        turma: '1º Ano A',
        provaId: 'PROVA-0001',
        corrigidoEm: DateTime(2026, 1, 1),
        respostas: respostas,
      );
    }

    test('nota é 10 quando o aluno acerta todas as questões', () {
      final resultado = construir(List.generate(
        5,
        (_) => _resposta(indiceCorreto: 2, indiceMarcado: 2),
      ));

      expect(resultado.acertos, 5);
      expect(resultado.erros, 0);
      expect(resultado.emBranco, 0);
      expect(resultado.nota, 10.0);
    });

    test('nota é 0 quando o aluno erra todas as questões', () {
      final resultado = construir(List.generate(
        5,
        (_) => _resposta(indiceCorreto: 2, indiceMarcado: 0),
      ));

      expect(resultado.acertos, 0);
      expect(resultado.erros, 5);
      expect(resultado.nota, 0.0);
    });

    test('nota é proporcional aos acertos, com acertos/erros/em branco corretos', () {
      final resultado = construir([
        _resposta(indiceCorreto: 0, indiceMarcado: 0), // acerto
        _resposta(indiceCorreto: 0, indiceMarcado: 1), // erro
        _resposta(indiceCorreto: 0, indiceMarcado: null), // em branco
        _resposta(indiceCorreto: 0, indiceMarcado: 0), // acerto
      ]);

      expect(resultado.totalQuestoes, 4);
      expect(resultado.acertos, 2);
      expect(resultado.erros, 1);
      expect(resultado.emBranco, 1);
      expect(resultado.nota, 5.0); // 2/4 * 10
    });

    test('nota é 0 quando não há nenhuma questão (evita divisão por zero)', () {
      final resultado = construir(const []);

      expect(resultado.totalQuestoes, 0);
      expect(resultado.nota, 0.0);
    });
  });
}
