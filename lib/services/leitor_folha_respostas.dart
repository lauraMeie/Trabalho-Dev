import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../utils/folha_respostas_layout.dart';

/// O que foi lido em uma questão da folha de respostas.
class LeituraQuestao {
  /// Índice da questão na prova (0 = questão 1).
  final int indiceQuestao;

  /// Índice da alternativa marcada (0 = A), ou null se a questão estiver
  /// em branco ou com mais de uma bolinha preenchida.
  final int? marcada;

  /// Mais de uma bolinha preenchida: o professor precisa conferir.
  final bool duplaMarcacao;

  /// Quanto cada bolinha (A–E) está preenchida, de 0 (vazia) a 1.
  final List<double> preenchimento;

  const LeituraQuestao({
    required this.indiceQuestao,
    required this.marcada,
    required this.duplaMarcacao,
    required this.preenchimento,
  });

  bool get emBranco => marcada == null && !duplaMarcacao;
}

class LeituraFolha {
  final List<LeituraQuestao> questoes;

  const LeituraFolha(this.questoes);

  int get marcadas => questoes.where((q) => q.marcada != null).length;
  int get emBranco => questoes.where((q) => q.emBranco).length;
  int get duplas => questoes.where((q) => q.duplaMarcacao).length;
}

/// A foto não permitiu localizar a folha de respostas.
class FolhaNaoEncontradaException implements Exception {
  final String mensagem;

  const FolhaNaoEncontradaException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Pedido de leitura, para rodar fora da thread da interface (compute).
class PedidoLeituraFolha {
  final Uint8List bytesImagem;
  final int totalQuestoes;
  final int folha;

  const PedidoLeituraFolha({
    required this.bytesImagem,
    required this.totalQuestoes,
    this.folha = 0,
  });
}

LeituraFolha lerFolhaRespostas(PedidoLeituraFolha pedido) =>
    LeitorFolhaRespostas.ler(
      pedido.bytesImagem,
      totalQuestoes: pedido.totalQuestoes,
      folha: pedido.folha,
    );

/// Lê, a partir de uma foto, as alternativas marcadas na folha de
/// respostas gerada por FolhaRespostasPdf (RF10).
///
/// 1. Localiza os 4 quadrados pretos dos cantos (os 4 maiores blocos
///    escuros, sólidos e convexos da foto).
/// 2. Usa a marca de orientação para saber como a folha está girada.
/// 3. Calcula a homografia folha → foto, que corrige perspectiva e
///    inclinação.
/// 4. Em cada bolinha, compara o tom do miolo com o papel ao redor.
class LeitorFolhaRespostas {
  LeitorFolhaRespostas._();

  /// Fotos maiores são reduzidas: acelera e não perde precisão.
  static const int ladoMaximo = 1400;

  /// A partir de quanto uma bolinha é considerada preenchida.
  static const double limiarMarcada = 0.25;

  /// Se a 2ª bolinha mais escura chegar a esta fração da 1ª, é dupla
  /// marcação.
  static const double proporcaoDupla = 0.65;

  static LeituraFolha ler(
    Uint8List bytesImagem, {
    required int totalQuestoes,
    int folha = 0,
  }) {
    img.Image? imagem;
    try {
      imagem = img.decodeImage(bytesImagem);
    } catch (_) {
      // O pacote image lança erros variados para arquivos corrompidos.
    }
    if (imagem == null) {
      throw const FolhaNaoEncontradaException(
        'Não foi possível abrir a imagem. Tente tirar a foto de novo.',
      );
    }
    return lerImagem(imagem, totalQuestoes: totalQuestoes, folha: folha);
  }

  static LeituraFolha lerImagem(
    img.Image imagem, {
    required int totalQuestoes,
    int folha = 0,
  }) {
    final cinza = _ImagemCinza.de(_preparar(imagem));
    final cantos = _encontrarMarcadores(cinza);
    final homografia = _orientar(cinza, cantos);

    const centroDaFolha = Ponto(
      FolhaRespostasLayout.largura / 2,
      FolhaRespostasLayout.altura / 2,
    );
    final raioEmPixels = homografia
        .aplicar(
          centroDaFolha + const Ponto(FolhaRespostasLayout.raioBolinha, 0),
        )
        .distancia(homografia.aplicar(centroDaFolha));
    if (raioEmPixels < 2.5) {
      throw const FolhaNaoEncontradaException(
        'A folha ficou muito pequena na foto. Aproxime a câmera.',
      );
    }

    final questoes = FolhaRespostasLayout.questoesDaFolha(totalQuestoes, folha);
    return LeituraFolha([
      for (final questao in questoes)
        _decidir(questao.indiceQuestao, [
          for (final centro in questao.bolinhas)
            _preenchimento(
              cinza,
              homografia,
              centro,
              FolhaRespostasLayout.raioBolinha,
            ),
        ]),
    ]);
  }

  static img.Image _preparar(img.Image original) {
    var imagem = img.bakeOrientation(original);
    final maior = math.max(imagem.width, imagem.height);
    if (maior > ladoMaximo) {
      imagem = imagem.width >= imagem.height
          ? img.copyResize(imagem, width: ladoMaximo)
          : img.copyResize(imagem, height: ladoMaximo);
    }
    return imagem;
  }

  static LeituraQuestao _decidir(int indice, List<double> preenchimento) {
    final ordem = List.generate(preenchimento.length, (i) => i)
      ..sort((a, b) => preenchimento[b].compareTo(preenchimento[a]));
    final maior = preenchimento[ordem[0]];
    final segundo = preenchimento[ordem[1]];

    if (maior < limiarMarcada) {
      return LeituraQuestao(
        indiceQuestao: indice,
        marcada: null,
        duplaMarcacao: false,
        preenchimento: preenchimento,
      );
    }
    final dupla = segundo >= limiarMarcada && segundo >= maior * proporcaoDupla;
    return LeituraQuestao(
      indiceQuestao: indice,
      marcada: dupla ? null : ordem[0],
      duplaMarcacao: dupla,
      preenchimento: preenchimento,
    );
  }

  // -------------------------------------------------------------------
  // Marcadores
  // -------------------------------------------------------------------

  static List<Ponto> _encontrarMarcadores(_ImagemCinza cinza) {
    final escuro = cinza.limiarAdaptativo();
    final candidatos =
        _componentes(
            cinza.largura,
            cinza.altura,
            escuro,
          ).where((c) => c.pareceQuadradoSolido).toList()
          ..sort((a, b) => b.area.compareTo(a.area));

    if (candidatos.length < 4) {
      throw const FolhaNaoEncontradaException(
        'Não encontrei os 4 quadrados pretos dos cantos. Enquadre a folha '
        'inteira, com boa luz e sobre um fundo claro.',
      );
    }

    final marcadores = candidatos.take(4).toList();
    if (marcadores.last.area < marcadores.first.area * 0.3) {
      throw const FolhaNaoEncontradaException(
        'Os quadrados dos cantos não ficaram nítidos. Fotografe a folha de '
        'frente, sem sombra sobre os cantos.',
      );
    }

    final centros = marcadores.map((m) => m.centro).toList();
    final cx = centros.map((p) => p.x).reduce((a, b) => a + b) / 4;
    final cy = centros.map((p) => p.y).reduce((a, b) => a + b) / 4;
    // Ordem horária na imagem (y cresce para baixo), igual à ordem dos
    // marcadores no layout.
    centros.sort(
      (a, b) => math
          .atan2(a.y - cy, a.x - cx)
          .compareTo(math.atan2(b.y - cy, b.x - cx)),
    );
    return centros;
  }

  /// Testa os 4 giros possíveis e fica com o que encontra a marca de
  /// orientação escura no lugar certo.
  static Homografia _orientar(_ImagemCinza cinza, List<Ponto> cantos) {
    Homografia? melhor;
    var melhorNota = -1.0;
    for (var giro = 0; giro < 4; giro++) {
      final destino = [for (var i = 0; i < 4; i++) cantos[(i + giro) % 4]];
      final h = Homografia.calcular(FolhaRespostasLayout.marcadores, destino);
      if (h == null) continue;
      final nota = _preenchimento(
        cinza,
        h,
        FolhaRespostasLayout.marcaOrientacao,
        FolhaRespostasLayout.ladoMarcaOrientacao / 2,
      );
      if (nota > melhorNota) {
        melhorNota = nota;
        melhor = h;
      }
    }
    if (melhor == null || melhorNota < 0.3) {
      throw const FolhaNaoEncontradaException(
        'Não reconheci esta folha de respostas. Use a folha impressa pelo '
        'app e fotografe a página inteira.',
      );
    }
    return melhor;
  }

  /// 0 = miolo tão claro quanto o papel ao redor; 1 = miolo preto.
  static double _preenchimento(
    _ImagemCinza cinza,
    Homografia h,
    Ponto centro,
    double raio,
  ) {
    final c = h.aplicar(centro);
    final rx = h.aplicar(centro + Ponto(raio, 0)).distancia(c);
    final ry = h.aplicar(centro + Ponto(0, raio)).distancia(c);
    final r = (rx + ry) / 2;
    if (r < 1.5) return 0;

    final raioMiolo = r * 0.6;
    final anelInterno = r * 1.35;
    final anelExterno = r * 1.9;
    var somaMiolo = 0;
    var qtdMiolo = 0;
    final anel = <int>[];

    final x0 = (c.x - anelExterno).floor();
    final x1 = (c.x + anelExterno).ceil();
    final y0 = (c.y - anelExterno).floor();
    final y1 = (c.y + anelExterno).ceil();
    for (var y = y0; y <= y1; y++) {
      if (y < 0 || y >= cinza.altura) continue;
      for (var x = x0; x <= x1; x++) {
        if (x < 0 || x >= cinza.largura) continue;
        final d = math.sqrt((x - c.x) * (x - c.x) + (y - c.y) * (y - c.y));
        final tom = cinza.tom(x, y);
        if (d <= raioMiolo) {
          somaMiolo += tom;
          qtdMiolo++;
        } else if (d >= anelInterno && d <= anelExterno) {
          anel.add(tom);
        }
      }
    }
    if (qtdMiolo == 0 || anel.isEmpty) return 0;

    anel.sort();
    final papel = anel[anel.length ~/ 2];
    if (papel == 0) return 0;
    final miolo = somaMiolo / qtdMiolo;
    return ((papel - miolo) / papel).clamp(0.0, 1.0);
  }

  static List<_Componente> _componentes(
    int largura,
    int altura,
    Uint8List escuro,
  ) {
    final visitado = Uint8List(largura * altura);
    final pilha = Int32List(largura * altura);
    final componentes = <_Componente>[];

    bool ehEscuro(int x, int y) =>
        x >= 0 &&
        y >= 0 &&
        x < largura &&
        y < altura &&
        escuro[y * largura + x] == 1;

    for (var inicio = 0; inicio < escuro.length; inicio++) {
      if (escuro[inicio] == 0 || visitado[inicio] == 1) continue;
      final comp = _Componente();
      var topo = 0;
      pilha[topo++] = inicio;
      visitado[inicio] = 1;

      while (topo > 0) {
        final i = pilha[--topo];
        final x = i % largura;
        final y = i ~/ largura;
        comp.adicionar(x, y);
        if (x == 0 || y == 0 || x == largura - 1 || y == altura - 1) {
          comp.tocaBorda = true;
        }
        for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nx = x + dx;
          final ny = y + dy;
          if (!ehEscuro(nx, ny)) {
            comp.arestas++;
            continue;
          }
          final j = ny * largura + nx;
          if (visitado[j] == 0) {
            visitado[j] = 1;
            pilha[topo++] = j;
          }
        }
      }
      componentes.add(comp);
    }
    return componentes;
  }
}

class _Componente {
  int area = 0;
  int arestas = 0;
  int minX = 1 << 30, minY = 1 << 30, maxX = -1, maxY = -1;
  double somaX = 0, somaY = 0;
  bool tocaBorda = false;

  void adicionar(int x, int y) {
    area++;
    somaX += x;
    somaY += y;
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }

  int get largura => maxX - minX + 1;
  int get altura => maxY - minY + 1;
  Ponto get centro => Ponto(somaX / area, somaY / area);

  /// Um quadrado cheio (mesmo girado ou em perspectiva) é convexo: o
  /// contorno dele soma 2 × (largura + altura) da caixa. Letras, QR Code
  /// e rabiscos têm contorno bem maior e ficam de fora.
  bool get pareceQuadradoSolido {
    if (tocaBorda || area < 40) return false;
    final proporcao = largura / altura;
    if (proporcao < 0.5 || proporcao > 2) return false;
    if (area / (largura * altura) < 0.45) return false;
    return arestas <= 2 * (largura + altura) * 1.35;
  }
}

class _ImagemCinza {
  final int largura;
  final int altura;
  final Uint8List _tons;

  _ImagemCinza(this.largura, this.altura, this._tons);

  factory _ImagemCinza.de(img.Image imagem) {
    final fonte = imagem.numChannels < 3 || imagem.hasPalette
        ? imagem.convert(numChannels: 3)
        : imagem;
    final tons = Uint8List(fonte.width * fonte.height);
    final maximo = fonte.maxChannelValue.toDouble();
    var i = 0;
    for (final p in fonte) {
      final l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) / maximo * 255;
      tons[i++] = l.round().clamp(0, 255);
    }
    return _ImagemCinza(fonte.width, fonte.height, tons);
  }

  int tom(int x, int y) => _tons[y * largura + x];

  /// Pixel escuro = bem mais escuro que a média da vizinhança. Funciona
  /// mesmo com luz desigual na foto (sombra de um lado, por exemplo).
  Uint8List limiarAdaptativo() {
    final w = largura;
    final h = altura;
    final integral = Float64List((w + 1) * (h + 1));
    for (var y = 0; y < h; y++) {
      var somaLinha = 0.0;
      for (var x = 0; x < w; x++) {
        somaLinha += _tons[y * w + x];
        integral[(y + 1) * (w + 1) + x + 1] =
            integral[y * (w + 1) + x + 1] + somaLinha;
      }
    }

    final raio = math.max(8, math.min(w, h) ~/ 14);
    final escuro = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final ya = math.max(0, y - raio);
      final yb = math.min(h, y + raio + 1);
      for (var x = 0; x < w; x++) {
        final xa = math.max(0, x - raio);
        final xb = math.min(w, x + raio + 1);
        final soma =
            integral[yb * (w + 1) + xb] -
            integral[ya * (w + 1) + xb] -
            integral[yb * (w + 1) + xa] +
            integral[ya * (w + 1) + xa];
        final media = soma / ((xb - xa) * (yb - ya));
        if (_tons[y * w + x] < media * 0.7) escuro[y * w + x] = 1;
      }
    }
    return escuro;
  }
}
