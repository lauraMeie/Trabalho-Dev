import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/models/correction_result.dart';

void main() {
  group('RespostaCorrigida.toMap/fromMap', () {
    test('round-trip preserva todos os campos', () {
      const original = RespostaCorrigida(
        questaoId: 'q01',
        materia: 'Matemática',
        enunciado: 'Quanto é 2 + 2?',
        alternativas: ['3', '4', '5'],
        indiceCorreto: 1,
        indiceMarcado: 1,
      );

      final reconstruida = RespostaCorrigida.fromMap(original.toMap());

      expect(reconstruida.questaoId, original.questaoId);
      expect(reconstruida.materia, original.materia);
      expect(reconstruida.enunciado, original.enunciado);
      expect(reconstruida.alternativas, original.alternativas);
      expect(reconstruida.indiceCorreto, original.indiceCorreto);
      expect(reconstruida.indiceMarcado, original.indiceMarcado);
      expect(reconstruida.correta, isTrue);
    });

    test('indiceMarcado nulo (em branco) é preservado', () {
      const original = RespostaCorrigida(
        questaoId: 'q02',
        materia: 'História',
        enunciado: 'Enunciado',
        alternativas: ['A', 'B'],
        indiceCorreto: 0,
        indiceMarcado: null,
      );

      final reconstruida = RespostaCorrigida.fromMap(original.toMap());
      expect(reconstruida.indiceMarcado, isNull);
      expect(reconstruida.emBranco, isTrue);
    });
  });

  group('ResultadoCorrecao.toMap/fromMap', () {
    test('round-trip preserva aluno, turma, prova, data e respostas', () {
      final original = ResultadoCorrecao(
        id: 'ignorado-no-toMap',
        aluno: 'Ana Souza',
        turma: '3º Ano A',
        provaId: 'PROVA-123',
        corrigidoEm: DateTime(2026, 10, 20, 14, 30),
        respostas: const [
          RespostaCorrigida(
            questaoId: 'q01',
            materia: 'Matemática',
            enunciado: 'Enunciado',
            alternativas: ['A', 'B'],
            indiceCorreto: 0,
            indiceMarcado: 0,
          ),
        ],
      );

      final mapa = original.toMap();
      expect(mapa.containsKey('id'), isFalse);

      final reconstruido = ResultadoCorrecao.fromMap('doc-real-123', mapa);

      expect(reconstruido.id, 'doc-real-123');
      expect(reconstruido.aluno, original.aluno);
      expect(reconstruido.turma, original.turma);
      expect(reconstruido.provaId, original.provaId);
      expect(reconstruido.corrigidoEm, original.corrigidoEm);
      expect(reconstruido.respostas.length, 1);
      expect(reconstruido.acertos, original.acertos);
      expect(reconstruido.nota, original.nota);
    });
  });
}
