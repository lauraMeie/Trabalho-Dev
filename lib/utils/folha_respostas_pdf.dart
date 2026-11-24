import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'folha_respostas_layout.dart';

/// Folha de respostas para leitura pela câmera (RF10): marcadores pretos
/// nos cantos, bolinhas A–E por questão e o mesmo QR Code da prova.
///
/// Tudo é posicionado de forma absoluta a partir de FolhaRespostasLayout,
/// a mesma geometria usada pelo LeitorFolhaRespostas.
class FolhaRespostasPdf {
  FolhaRespostasPdf._();

  static const _tinta = PdfColors.black;
  static const _cinza = PdfColors.grey700;

  static List<pw.Page> paginas({
    required String nomeProva,
    required String turma,
    required String? aluno,
    required String? matricula,
    required int totalQuestoes,
    required String payloadQr,
  }) {
    final total = FolhaRespostasLayout.totalFolhas(totalQuestoes);
    return [
      for (var folha = 0; folha < total; folha++)
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Stack(
            children: [
              ..._cabecalho(
                nomeProva: nomeProva,
                turma: turma,
                aluno: aluno,
                matricula: matricula,
                payloadQr: payloadQr,
                folha: folha,
                totalFolhas: total,
              ),
              ..._areaDeLeitura(totalQuestoes, folha),
            ],
          ),
        ),
    ];
  }

  static List<pw.Widget> _cabecalho({
    required String nomeProva,
    required String turma,
    required String? aluno,
    required String? matricula,
    required String payloadQr,
    required int folha,
    required int totalFolhas,
  }) {
    final titulo = totalFolhas > 1
        ? 'FOLHA DE RESPOSTAS (${folha + 1} de $totalFolhas)'
        : 'FOLHA DE RESPOSTAS';
    final alunoTexto = (aluno ?? '').trim().isEmpty
        ? 'Aluno: ________________________________'
        : 'Aluno: $aluno';
    final matriculaTexto = (matricula ?? '').trim().isEmpty
        ? 'Matrícula: ______________'
        : 'Matrícula: $matricula';

    return [
      pw.Positioned(
        left: 40,
        top: 40,
        child: pw.SizedBox(
          width: 400,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(nomeProva, style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Turma: $turma', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 8),
              pw.Text(alunoTexto, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text(matriculaTexto, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 10),
              pw.Text(
                'Preencha totalmente a bolinha da alternativa escolhida, com '
                'caneta preta ou azul. Marque só uma por questão e não '
                'rasure. Não escreva perto dos quadrados pretos.',
                style: const pw.TextStyle(fontSize: 8.5, color: _cinza),
              ),
            ],
          ),
        ),
      ),
      pw.Positioned(
        left: 470,
        top: 36,
        child: pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(
            errorCorrectLevel: pw.BarcodeQRCorrectionLevel.high,
          ),
          data: payloadQr,
          width: 84,
          height: 84,
        ),
      ),
    ];
  }

  static List<pw.Widget> _areaDeLeitura(int totalQuestoes, int folha) {
    const lado = FolhaRespostasLayout.ladoMarcador;
    const ladoOrientacao = FolhaRespostasLayout.ladoMarcaOrientacao;
    const raio = FolhaRespostasLayout.raioBolinha;
    final questoes = FolhaRespostasLayout.questoesDaFolha(totalQuestoes, folha);
    final colunas = FolhaRespostasLayout.colunasUsadas(totalQuestoes, folha);

    return [
      for (final marcador in FolhaRespostasLayout.marcadores)
        _quadrado(marcador, lado),
      _quadrado(FolhaRespostasLayout.marcaOrientacao, ladoOrientacao),
      for (var coluna = 0; coluna < colunas; coluna++)
        for (final (j, centro) in FolhaRespostasLayout.letrasDaColuna(
          coluna,
        ).indexed)
          _textoCentralizado(
            String.fromCharCode(65 + j),
            centro,
            pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
      for (final questao in questoes) ...[
        _rotulo('${questao.indiceQuestao + 1}.', questao.rotulo),
        for (final centro in questao.bolinhas)
          _posicionado(
            centro,
            raio * 2,
            raio * 2,
            pw.Container(
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: _tinta, width: 0.8),
              ),
            ),
          ),
      ],
    ];
  }

  static pw.Widget _quadrado(Ponto centro, double lado) =>
      _posicionado(centro, lado, lado, pw.Container(color: _tinta));

  static pw.Widget _textoCentralizado(
    String texto,
    Ponto centro,
    pw.TextStyle estilo,
  ) {
    return _posicionado(
      centro,
      20,
      12,
      pw.Center(child: pw.Text(texto, style: estilo)),
    );
  }

  /// Número da questão, alinhado à direita em [fim].
  static pw.Widget _rotulo(String texto, Ponto fim) {
    final pagina = FolhaRespostasLayout.naPagina(fim);
    return pw.Positioned(
      left: pagina.x - 30,
      top: pagina.y - 6,
      child: pw.SizedBox(
        width: 30,
        height: 12,
        child: pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(texto, style: const pw.TextStyle(fontSize: 9)),
        ),
      ),
    );
  }

  static pw.Widget _posicionado(
    Ponto centro,
    double largura,
    double altura,
    pw.Widget filho,
  ) {
    final pagina = FolhaRespostasLayout.naPagina(centro);
    return pw.Positioned(
      left: pagina.x - largura / 2,
      top: pagina.y - altura / 2,
      child: pw.SizedBox(width: largura, height: altura, child: filho),
    );
  }
}
