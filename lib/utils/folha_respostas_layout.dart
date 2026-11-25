import 'dart:math' as math;

/// Ponto 2D simples (coordenadas em pontos de PDF ou em pixels).
class Ponto {
  final double x;
  final double y;

  const Ponto(this.x, this.y);

  Ponto operator +(Ponto outro) => Ponto(x + outro.x, y + outro.y);

  double distancia(Ponto outro) =>
      math.sqrt(math.pow(x - outro.x, 2) + math.pow(y - outro.y, 2));

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Posição das 5 bolinhas (A a E) de uma questão na folha de respostas.
class BolinhasDaQuestao {
  /// Índice da questão na prova (0 = questão 1).
  final int indiceQuestao;

  /// Centro do rótulo "1.", "2."... (alinhado à direita neste ponto).
  final Ponto rotulo;

  /// Centros das bolinhas A, B, C, D e E.
  final List<Ponto> bolinhas;

  const BolinhasDaQuestao({
    required this.indiceQuestao,
    required this.rotulo,
    required this.bolinhas,
  });
}

/// Geometria da folha de respostas, compartilhada entre quem DESENHA a
/// folha (FolhaRespostasPdf) e quem a LÊ pela câmera
/// (LeitorFolhaRespostas). Se um lado mudar sem o outro, a leitura erra
/// de bolinha — por isso tudo fica aqui, num lugar só.
///
/// Coordenadas da "área de leitura" em pontos de PDF, com origem no
/// centro do marcador superior esquerdo: x cresce para a direita e y
/// para baixo. Os 4 marcadores (quadrados pretos) ficam nos cantos
/// (0,0), (largura,0), (largura,altura) e (0,altura).
class FolhaRespostasLayout {
  FolhaRespostasLayout._();

  static const int alternativas = 5;
  static const int questoesPorColuna = 20;
  static const int colunasPorFolha = 3;
  static const int questoesPorFolha = questoesPorColuna * colunasPorFolha;

  /// Página A4 em pontos.
  static const double larguraPagina = 595.28;
  static const double alturaPagina = 841.89;

  /// Onde fica, na página, o centro do marcador superior esquerdo.
  static const Ponto origemNaPagina = Ponto(50, 215);

  static const double largura = 495;
  static const double altura = 585;
  static const double ladoMarcador = 22;

  /// Quadradinho menor ao lado do marcador superior esquerdo, que só
  /// existe nesse canto: serve para descobrir se a foto está de
  /// cabeça para baixo ou deitada.
  static const Ponto marcaOrientacao = Ponto(36, 0);
  static const double ladoMarcaOrientacao = 9;

  static const double raioBolinha = 7;
  static const double espacoEntreBolinhas = 24;
  static const double alturaLinha = 26;
  static const double larguraColuna = 160;
  static const double inicioColunas = 22;
  static const double primeiraLinha = 45;
  static const double linhaDasLetras = 20;

  /// Distância do rótulo "N." até a bolinha A.
  static const double deslocamentoPrimeiraBolinha = 40;

  static const List<Ponto> marcadores = [
    Ponto(0, 0),
    Ponto(largura, 0),
    Ponto(largura, altura),
    Ponto(0, altura),
  ];

  static int totalFolhas(int totalQuestoes) =>
      totalQuestoes <= 0 ? 1 : (totalQuestoes / questoesPorFolha).ceil();

  /// Questões que aparecem na folha [folha] (0 = primeira folha).
  static List<BolinhasDaQuestao> questoesDaFolha(int totalQuestoes, int folha) {
    final inicio = folha * questoesPorFolha;
    final fim = math.min(inicio + questoesPorFolha, totalQuestoes);
    return [
      for (var indice = inicio; indice < fim; indice++)
        _posicao(indice, indice - inicio),
    ];
  }

  /// Centro da letra (A–E) do cabeçalho de cada coluna usada na folha.
  static List<Ponto> letrasDaColuna(int coluna) => [
    for (var j = 0; j < alternativas; j++)
      Ponto(_xBolinha(coluna, j), linhaDasLetras),
  ];

  static int colunasUsadas(int totalQuestoes, int folha) {
    final naFolha = questoesDaFolha(totalQuestoes, folha).length;
    return math.max(1, (naFolha / questoesPorColuna).ceil());
  }

  static Ponto naPagina(Ponto p) => p + origemNaPagina;

  static double _xBolinha(int coluna, int alternativa) =>
      inicioColunas +
      coluna * larguraColuna +
      deslocamentoPrimeiraBolinha +
      alternativa * espacoEntreBolinhas;

  static BolinhasDaQuestao _posicao(int indiceQuestao, int posicaoNaFolha) {
    final coluna = posicaoNaFolha ~/ questoesPorColuna;
    final linha = posicaoNaFolha % questoesPorColuna;
    final y = primeiraLinha + linha * alturaLinha;
    return BolinhasDaQuestao(
      indiceQuestao: indiceQuestao,
      rotulo: Ponto(inicioColunas + coluna * larguraColuna + 22, y),
      bolinhas: [
        for (var j = 0; j < alternativas; j++) Ponto(_xBolinha(coluna, j), y),
      ],
    );
  }
}

/// Transformação projetiva (perspectiva) entre dois planos, a partir de
/// 4 pares de pontos.
class Homografia {
  final List<double> _h;

  Homografia(this._h);

  static Homografia? calcular(List<Ponto> origem, List<Ponto> destino) {
    final a = List.generate(8, (_) => List<double>.filled(9, 0));
    for (var i = 0; i < 4; i++) {
      final x = origem[i].x, y = origem[i].y;
      final u = destino[i].x, v = destino[i].y;
      a[2 * i] = [x, y, 1, 0, 0, 0, -x * u, -y * u, u];
      a[2 * i + 1] = [0, 0, 0, x, y, 1, -x * v, -y * v, v];
    }

    for (var col = 0; col < 8; col++) {
      var pivo = col;
      for (var lin = col + 1; lin < 8; lin++) {
        if (a[lin][col].abs() > a[pivo][col].abs()) pivo = lin;
      }
      if (a[pivo][col].abs() < 1e-9) return null;
      final troca = a[col];
      a[col] = a[pivo];
      a[pivo] = troca;
      for (var lin = 0; lin < 8; lin++) {
        if (lin == col) continue;
        final fator = a[lin][col] / a[col][col];
        for (var k = col; k < 9; k++) {
          a[lin][k] -= fator * a[col][k];
        }
      }
    }
    return Homografia([for (var i = 0; i < 8; i++) a[i][8] / a[i][i]]);
  }

  Ponto aplicar(Ponto p) {
    final w = _h[6] * p.x + _h[7] * p.y + 1;
    return Ponto(
      (_h[0] * p.x + _h[1] * p.y + _h[2]) / w,
      (_h[3] * p.x + _h[4] * p.y + _h[5]) / w,
    );
  }
}
