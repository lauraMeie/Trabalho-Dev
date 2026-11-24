import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trabalho/services/leitor_folha_respostas.dart';
import 'package:trabalho/utils/folha_respostas_layout.dart';

const _pagina = [
  Ponto(0, 0),
  Ponto(FolhaRespostasLayout.larguraPagina, 0),
  Ponto(FolhaRespostasLayout.larguraPagina, FolhaRespostasLayout.alturaPagina),
  Ponto(0, FolhaRespostasLayout.alturaPagina),
];

typedef _Desenho = int? Function(double x, double y);

class _Item {
  final double x0, y0, x1, y1;
  final _Desenho tom;

  const _Item(this.x0, this.y0, this.x1, this.y1, this.tom);
}

/// "Fotografa" a folha: desenha a página (em pontos de PDF) projetada no
/// quadrilátero [cantosNaFoto] (cantos da página: sup. esq., sup. dir.,
/// inf. dir., inf. esq.), com luz desigual e ruído, e devolve o JPEG.
Uint8List _foto({
  required int totalQuestoes,
  required Map<int, List<int>> marcas,
  required List<Ponto> cantosNaFoto,
  int folha = 0,
  int largura = 1000,
  int altura = 1400,
  bool imprimirMarcadores = true,
}) {
  final paraFoto = Homografia.calcular(_pagina, cantosNaFoto)!;
  final paraPagina = Homografia.calcular(cantosNaFoto, _pagina)!;
  final tons = List<int>.filled(largura * altura, 0);

  for (var v = 0; v < altura; v++) {
    for (var u = 0; u < largura; u++) {
      final p = paraPagina.aplicar(Ponto(u + 0.5, v + 0.5));
      final dentro =
          p.x >= 0 &&
          p.y >= 0 &&
          p.x <= FolhaRespostasLayout.larguraPagina &&
          p.y <= FolhaRespostasLayout.alturaPagina;
      tons[v * largura + u] = dentro ? 235 : 150;
    }
  }

  final itens = <_Item>[];
  void quadrado(Ponto c, double lado, int tom) {
    final p = FolhaRespostasLayout.naPagina(c);
    itens.add(
      _Item(
        p.x - lado / 2,
        p.y - lado / 2,
        p.x + lado / 2,
        p.y + lado / 2,
        (_, _) => tom,
      ),
    );
  }

  if (imprimirMarcadores) {
    for (final m in FolhaRespostasLayout.marcadores) {
      quadrado(m, FolhaRespostasLayout.ladoMarcador, 20);
    }
    quadrado(
      FolhaRespostasLayout.marcaOrientacao,
      FolhaRespostasLayout.ladoMarcaOrientacao,
      20,
    );
  }

  // Imitação do QR Code e de linhas de texto no cabeçalho.
  final aleatorio = math.Random(7);
  for (var i = 0; i < 28; i++) {
    for (var j = 0; j < 28; j++) {
      if (aleatorio.nextBool()) {
        itens.add(
          _Item(
            470 + i * 3.0,
            36 + j * 3.0,
            473 + i * 3.0,
            39 + j * 3.0,
            (_, _) => 25,
          ),
        );
      }
    }
  }
  for (var linha = 0; linha < 6; linha++) {
    for (var letra = 0; letra < 40; letra++) {
      final x = 40 + letra * 9.0;
      final y = 44 + linha * 18.0;
      itens.add(_Item(x, y, x + 6, y + 9, (_, _) => 40));
    }
  }

  const raio = FolhaRespostasLayout.raioBolinha;
  for (final questao in FolhaRespostasLayout.questoesDaFolha(
    totalQuestoes,
    folha,
  )) {
    final marcadas = marcas[questao.indiceQuestao] ?? const [];
    for (final (j, centro) in questao.bolinhas.indexed) {
      final c = FolhaRespostasLayout.naPagina(centro);
      final cheia = marcadas.contains(j);
      itens.add(
        _Item(c.x - raio - 1, c.y - raio - 1, c.x + raio + 1, c.y + raio + 1, (
          x,
          y,
        ) {
          final d = math.sqrt(math.pow(x - c.x, 2) + math.pow(y - c.y, 2));
          if (cheia && d <= raio - 0.5) return 70;
          if ((d - raio).abs() <= 0.45) return 30;
          return null;
        }),
      );
    }
  }

  for (final item in itens) {
    final cantos = [
      paraFoto.aplicar(Ponto(item.x0, item.y0)),
      paraFoto.aplicar(Ponto(item.x1, item.y0)),
      paraFoto.aplicar(Ponto(item.x1, item.y1)),
      paraFoto.aplicar(Ponto(item.x0, item.y1)),
    ];
    final u0 = math.max(0, cantos.map((p) => p.x).reduce(math.min).floor());
    final u1 = math.min(
      largura - 1,
      cantos.map((p) => p.x).reduce(math.max).ceil(),
    );
    final v0 = math.max(0, cantos.map((p) => p.y).reduce(math.min).floor());
    final v1 = math.min(
      altura - 1,
      cantos.map((p) => p.y).reduce(math.max).ceil(),
    );
    for (var v = v0; v <= v1; v++) {
      for (var u = u0; u <= u1; u++) {
        final p = paraPagina.aplicar(Ponto(u + 0.5, v + 0.5));
        if (p.x < item.x0 || p.x > item.x1 || p.y < item.y0 || p.y > item.y1) {
          continue;
        }
        final tom = item.tom(p.x, p.y);
        if (tom != null) tons[v * largura + u] = tom;
      }
    }
  }

  final ruido = math.Random(42);
  final foto = img.Image(width: largura, height: altura);
  for (var v = 0; v < altura; v++) {
    for (var u = 0; u < largura; u++) {
      final luz = 0.7 + 0.35 * u / largura; // sombra do lado esquerdo
      final valor = (tons[v * largura + u] * luz + ruido.nextInt(17) - 8)
          .round()
          .clamp(0, 255);
      foto.setPixelRgb(u, v, valor, valor, (valor * 0.95).round());
    }
  }
  return img.encodeJpg(foto, quality: 85);
}

List<int?> _respostas(LeituraFolha leitura) =>
    leitura.questoes.map((q) => q.marcada).toList();

void main() {
  const deFrente = [
    Ponto(60, 80),
    Ponto(940, 80),
    Ponto(940, 1325),
    Ponto(60, 1325),
  ];
  const emPerspectiva = [
    Ponto(120, 60),
    Ponto(900, 140),
    Ponto(960, 1360),
    Ponto(40, 1250),
  ];

  group('LeitorFolhaRespostas', () {
    test('lê as alternativas marcadas numa foto de frente', () {
      final bytes = _foto(
        totalQuestoes: 10,
        marcas: {
          0: [1],
          1: [0],
          2: [4],
          3: [2],
          5: [3],
          6: [1],
          9: [0],
        },
        cantosNaFoto: deFrente,
      );

      final leitura = LeitorFolhaRespostas.ler(bytes, totalQuestoes: 10);

      expect(_respostas(leitura), [1, 0, 4, 2, null, 3, 1, null, null, 0]);
      expect(leitura.marcadas, 7);
      expect(leitura.emBranco, 3);
      expect(leitura.duplas, 0);
    });

    test('corrige perspectiva, inclinação e luz desigual', () {
      final marcas = {
        for (var i = 0; i < 45; i++)
          if (i % 7 != 3) i: [(i * 3) % 5],
      };
      final bytes = _foto(
        totalQuestoes: 45,
        marcas: marcas,
        cantosNaFoto: emPerspectiva,
      );

      final leitura = LeitorFolhaRespostas.ler(bytes, totalQuestoes: 45);

      expect(_respostas(leitura), [
        for (var i = 0; i < 45; i++) i % 7 != 3 ? (i * 3) % 5 : null,
      ]);
    });

    test('entende a folha fotografada de cabeça para baixo', () {
      final girada = [
        emPerspectiva[2],
        emPerspectiva[3],
        emPerspectiva[0],
        emPerspectiva[1],
      ];
      final bytes = _foto(
        totalQuestoes: 8,
        marcas: {
          0: [0],
          1: [1],
          2: [2],
          3: [3],
          4: [4],
          7: [2],
        },
        cantosNaFoto: girada,
      );

      final leitura = LeitorFolhaRespostas.ler(bytes, totalQuestoes: 8);

      expect(_respostas(leitura), [0, 1, 2, 3, 4, null, null, 2]);
    });

    test('aponta dupla marcação em vez de escolher uma alternativa', () {
      final bytes = _foto(
        totalQuestoes: 3,
        marcas: {
          0: [1, 3],
          1: [2],
        },
        cantosNaFoto: deFrente,
      );

      final leitura = LeitorFolhaRespostas.ler(bytes, totalQuestoes: 3);

      expect(leitura.questoes[0].marcada, isNull);
      expect(leitura.questoes[0].duplaMarcacao, isTrue);
      expect(leitura.questoes[1].marcada, 2);
      expect(leitura.questoes[2].emBranco, isTrue);
    });

    test('lê a segunda folha de uma prova com mais de 60 questões', () {
      final bytes = _foto(
        totalQuestoes: 70,
        folha: 1,
        marcas: {
          60: [4],
          61: [3],
          69: [0],
        },
        cantosNaFoto: deFrente,
      );

      final leitura = LeitorFolhaRespostas.ler(
        bytes,
        totalQuestoes: 70,
        folha: 1,
      );

      expect(leitura.questoes.map((q) => q.indiceQuestao), [
        for (var i = 60; i < 70; i++) i,
      ]);
      expect(leitura.questoes.first.marcada, 4);
      expect(leitura.questoes[1].marcada, 3);
      expect(leitura.questoes.last.marcada, 0);
    });

    test('lê a foto de uma folha impressa pelo app e preenchida à caneta', () {
      // Página real do PDF (ProvaPdf), marcada com caneta azul, com um "X"
      // fraco na questão 2 (não conta) e dupla marcação na questão 10,
      // fotografada inclinada e com sombra.
      final bytes = File(
        'test/fixtures/folha_respostas_foto.jpg',
      ).readAsBytesSync();

      final leitura = LeitorFolhaRespostas.ler(bytes, totalQuestoes: 25);

      final lido = leitura.questoes
          .map(
            (q) => q.duplaMarcacao
                ? '*'
                : q.marcada == null
                ? '-'
                : 'ABCDE'[q.marcada!],
          )
          .join();
      expect(lido, 'BDAC-BDAC*BDA-EBDACEBD-CE');
    });

    test('avisa quando a foto não tem a folha de respostas', () {
      final bytes = _foto(
        totalQuestoes: 5,
        marcas: const {},
        cantosNaFoto: deFrente,
        imprimirMarcadores: false,
      );

      expect(
        () => LeitorFolhaRespostas.ler(bytes, totalQuestoes: 5),
        throwsA(isA<FolhaNaoEncontradaException>()),
      );
    });

    test('avisa quando os bytes não são uma imagem', () {
      expect(
        () => LeitorFolhaRespostas.ler(
          img.encodeJpg(img.Image(width: 1, height: 1)).sublist(0, 4),
          totalQuestoes: 5,
        ),
        throwsA(isA<FolhaNaoEncontradaException>()),
      );
    });
  });

  group('FolhaRespostasLayout', () {
    test('divide as questões em folhas de 60', () {
      expect(FolhaRespostasLayout.totalFolhas(1), 1);
      expect(FolhaRespostasLayout.totalFolhas(60), 1);
      expect(FolhaRespostasLayout.totalFolhas(61), 2);
      expect(
        FolhaRespostasLayout.questoesDaFolha(61, 1).single.indiceQuestao,
        60,
      );
    });

    test('todas as bolinhas ficam dentro da área de leitura, longe dos '
        'marcadores', () {
      const folga =
          FolhaRespostasLayout.ladoMarcador / 2 +
          FolhaRespostasLayout.raioBolinha;
      for (final questao in FolhaRespostasLayout.questoesDaFolha(60, 0)) {
        for (final b in questao.bolinhas) {
          expect(b.x, inInclusiveRange(0, FolhaRespostasLayout.largura));
          expect(b.y, inInclusiveRange(0, FolhaRespostasLayout.altura));
          for (final m in FolhaRespostasLayout.marcadores) {
            expect(b.distancia(m), greaterThan(folga));
          }
        }
      }
    });
  });
}
