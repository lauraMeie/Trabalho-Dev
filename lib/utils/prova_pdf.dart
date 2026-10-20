import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/prova_gerada.dart';
import 'exam_generator.dart';

/// Monta o PDF da prova para impressão: cabeçalho, identificação do
/// aluno e questões (RF14: respeita colunas e tamanho da fonte).
///
/// É Dart puro (sem rede nem plataforma), por isso dá para testar.
/// Se a prova for individualizada, cada aluno ganha suas próprias
/// páginas, já com nome e matrícula preenchidos.
class ProvaPdf {
  ProvaPdf._();

  static Future<Uint8List> gerar(
    ProvaGerada prova, {
    pw.ThemeData? tema,
  }) async {
    if (prova.provas.isEmpty) {
      throw ArgumentError('A prova não tem nenhuma versão para imprimir.');
    }

    final documento = pw.Document(
      title: prova.nome,
      author: 'ProvaLab',
      theme: tema,
    );

    for (final versao in prova.provas) {
      documento.addPage(_paginas(prova, versao));
    }

    return documento.save();
  }

  static pw.MultiPage _paginas(ProvaGerada prova, ProvaDoAluno versao) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (contexto) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${contexto.pageNumber} de ${contexto.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
      build: (contexto) => [
        _cabecalho(prova, versao),
        pw.SizedBox(height: 18),
        ..._questoes(prova, versao),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Cabeçalho + identificação
  // ---------------------------------------------------------------------
  static pw.Widget _cabecalho(ProvaGerada prova, ProvaDoAluno versao) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          prova.nome,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Turma: ${prova.turmaNome}',
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                children: [
                  _campo('Aluno', valor: versao.aluno, flex: 3),
                  pw.SizedBox(width: 12),
                  _campo('Matrícula', valor: versao.matricula, flex: 2),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  _campo('Data', flex: 2),
                  pw.SizedBox(width: 12),
                  _campo('Nota', flex: 1),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Marque apenas uma alternativa por questão.',
          style: pw.TextStyle(
            fontSize: 9,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  /// Campo "Rótulo: ________". Se [valor] vier preenchido, mostra o
  /// texto em cima da linha; senão deixa a linha em branco.
  static pw.Widget _campo(String rotulo, {String? valor, int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('$rotulo: ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Container(
              height: 16,
              alignment: pw.Alignment.bottomLeft,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.6),
                ),
              ),
              child: valor != null && valor.trim().isNotEmpty
                  ? pw.Text(valor, style: const pw.TextStyle(fontSize: 11))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Questões
  // ---------------------------------------------------------------------
  static List<pw.Widget> _questoes(ProvaGerada prova, ProvaDoAluno versao) {
    final blocos = <pw.Widget>[
      for (int i = 0; i < versao.questoes.length; i++)
        _bloco(i + 1, versao.questoes[i], prova.tamanhoFonte),
    ];

    if (prova.colunas <= 1) {
      return [
        for (final bloco in blocos)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 14),
            child: bloco,
          ),
      ];
    }

    // 2 colunas: cada linha tem duas questões lado a lado (1 e 2, 3 e 4...).
    // Assim a linha inteira pula para a próxima página quando não cabe.
    final linhas = <pw.Widget>[];
    for (int i = 0; i < blocos.length; i += 2) {
      final temPar = i + 1 < blocos.length;
      linhas.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: blocos[i]),
              pw.SizedBox(width: 18),
              pw.Expanded(child: temPar ? blocos[i + 1] : pw.SizedBox()),
            ],
          ),
        ),
      );
    }
    return linhas;
  }

  /// Uma questão. Fica dentro de um Container para não ser cortada no
  /// meio entre duas páginas.
  static pw.Widget _bloco(
    int numero,
    GeneratedQuestion questao,
    double tamanhoFonte,
  ) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$numero. ${questao.statement}',
            style: pw.TextStyle(
              fontSize: tamanhoFonte,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          for (int i = 0; i < questao.alternatives.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
              child: pw.Text(
                '${String.fromCharCode(65 + i)}) ${questao.alternatives[i]}',
                style: pw.TextStyle(fontSize: tamanhoFonte - 1),
              ),
            ),
        ],
      ),
    );
  }
}
