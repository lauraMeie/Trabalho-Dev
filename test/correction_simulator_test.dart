import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/utils/correction_simulator.dart';

void main() {
  group('CorrectionSimulator.simularEscaneamentoQrCode', () {
    test('sempre retorna aluno, turma e provaId não vazios', () {
      for (var i = 0; i < 20; i++) {
        final identificacao = CorrectionSimulator.simularEscaneamentoQrCode();

        expect(identificacao.aluno, isNotEmpty);
        expect(identificacao.turma, isNotEmpty);
        expect(identificacao.provaId, startsWith('PROVA-'));
      }
    });
  });

  group('CorrectionSimulator.simularLeituraRespostas', () {
    final identificacao = CorrectionSimulator.simularEscaneamentoQrCode();

    test('gera exatamente a quantidade de questões pedida', () {
      final resultado = CorrectionSimulator.simularLeituraRespostas(
        identificacao: identificacao,
        quantidadeQuestoes: 7,
      );

      expect(resultado.totalQuestoes, 7);
      expect(resultado.respostas.length, 7);
    });

    test('usa quantidade padrão de 10 questões quando não especificado', () {
      final resultado = CorrectionSimulator.simularLeituraRespostas(
        identificacao: identificacao,
      );

      expect(resultado.totalQuestoes, 10);
    });

    test('acertos + erros + em branco é sempre igual ao total de questões', () {
      for (var i = 0; i < 10; i++) {
        final resultado = CorrectionSimulator.simularLeituraRespostas(
          identificacao: identificacao,
          quantidadeQuestoes: 10,
        );

        expect(
          resultado.acertos + resultado.erros + resultado.emBranco,
          resultado.totalQuestoes,
        );
      }
    });

    test('nota calculada bate com a fórmula acertos/total * 10', () {
      final resultado = CorrectionSimulator.simularLeituraRespostas(
        identificacao: identificacao,
        quantidadeQuestoes: 10,
      );

      final notaEsperada = (resultado.acertos / resultado.totalQuestoes) * 10;
      expect(resultado.nota, notaEsperada);
    });

    test('mantém a identificação (aluno/turma/prova) recebida', () {
      final resultado = CorrectionSimulator.simularLeituraRespostas(
        identificacao: identificacao,
      );

      expect(resultado.aluno, identificacao.aluno);
      expect(resultado.turma, identificacao.turma);
      expect(resultado.provaId, identificacao.provaId);
    });

    test('cada resposta corrigida referencia uma alternativa válida da questão', () {
      final resultado = CorrectionSimulator.simularLeituraRespostas(
        identificacao: identificacao,
      );

      for (final resposta in resultado.respostas) {
        expect(resposta.indiceCorreto, inInclusiveRange(0, resposta.alternativas.length - 1));
        if (!resposta.emBranco) {
          expect(resposta.indiceMarcado, inInclusiveRange(0, resposta.alternativas.length - 1));
        }
      }
    });
  });
}
