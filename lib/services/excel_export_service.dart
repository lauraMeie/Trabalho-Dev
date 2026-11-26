import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:excel/excel.dart' as xlsx;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

import '../models/correction_result.dart';
import 'excel_export/planilha_relatorio.dart';
import 'excel_export/save_bytes_stub.dart'
    if (dart.library.io) 'excel_export/save_bytes_io.dart'
    as plataforma;

/// Exporta os resultados das provas corrigidas em uma planilha Excel
/// (RF-15/RF-16): abas "Resumo", uma por turma (alunos × provas, com
/// média) e "Respostas" (alternativa marcada em cada questão).
///
/// No Flutter Web, gerar a planilha já dispara o download pelo navegador
/// (comportamento do próprio pacote `excel`). Em Android/iOS/desktop, o
/// arquivo é salvo nos documentos do app e pode ser compartilhado com
/// [compartilhar].
class ExcelExportService {
  ExcelExportService._();

  static const String _mimeXlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// Aba que o pacote `excel` cria sozinho em `Excel.createExcel()`.
  static const String _abaPadrao = 'Sheet1';

  /// Formato das células de nota: 1 casa decimal.
  static const xlsx.NumFormat _formatoNota = xlsx.CustomNumericNumFormat(
    formatCode: '0.0',
  );

  /// Monta a planilha (sem salvar) a partir dos resultados.
  static xlsx.Excel montarExcel(List<ResultadoCorrecao> resultados) {
    final excel = xlsx.Excel.createExcel();
    final tabelas = PlanilhaRelatorio.montarTabelas(resultados);

    for (final tabela in tabelas) {
      _preencherAba(excel[tabela.nome], tabela);
    }
    if (!tabelas.any((t) => t.nome == _abaPadrao)) {
      excel.delete(_abaPadrao);
    }
    excel.setDefaultSheet(PlanilhaRelatorio.nomeAbaResumo);
    return excel;
  }

  /// Bytes do arquivo .xlsx, sem disparar download (útil para testes).
  static Uint8List gerarBytes(List<ResultadoCorrecao> resultados) {
    final bytes = montarExcel(resultados).encode();
    if (bytes == null) {
      throw Exception('Não foi possível gerar a planilha.');
    }
    return Uint8List.fromList(bytes);
  }

  /// Gera e salva/baixa a planilha. Devolve o caminho do arquivo salvo
  /// (fora da Web) ou `null` quando o download já foi disparado (Web).
  static Future<String?> exportar(List<ResultadoCorrecao> resultados) async {
    final excel = montarExcel(resultados);
    final nomeArquivo =
        'resultados-provas-${DateTime.now().millisecondsSinceEpoch}.xlsx';

    // Na Web, save() já baixa o arquivo; fora dela só gera os bytes.
    final bytes = kIsWeb ? excel.save(fileName: nomeArquivo) : excel.encode();
    if (bytes == null) {
      throw Exception('Não foi possível gerar a planilha.');
    }

    return plataforma.salvarBytesLocalmente(
      Uint8List.fromList(bytes),
      nomeArquivo,
    );
  }

  /// Abre a janela de compartilhamento do sistema com a planilha salva em
  /// [caminho] (para salvar no Drive, enviar por WhatsApp/e-mail etc.).
  /// [origem] é a posição do botão, exigida pelo iPad.
  static Future<ShareResultStatus> compartilhar(
    String caminho, {
    Rect? origem,
  }) async {
    final resultado = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(caminho, mimeType: _mimeXlsx)],
        subject: 'Notas das provas',
        sharePositionOrigin: origem,
      ),
    );
    return resultado.status;
  }

  static void _preencherAba(xlsx.Sheet sheet, TabelaPlanilha tabela) {
    final estiloCabecalho = xlsx.CellStyle(bold: true);
    final estiloNota = xlsx.CellStyle(numberFormat: _formatoNota);

    for (var col = 0; col < tabela.cabecalho.length; col++) {
      sheet.updateCell(
        xlsx.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        xlsx.TextCellValue(tabela.cabecalho[col]),
        cellStyle: estiloCabecalho,
      );
    }

    for (var lin = 0; lin < tabela.linhas.length; lin++) {
      final linha = tabela.linhas[lin];
      for (var col = 0; col < linha.length; col++) {
        final valor = _valorCelula(linha[col]);
        if (valor == null) continue;
        sheet.updateCell(
          xlsx.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: lin + 1),
          valor,
          cellStyle:
              tabela.colunasDeNota.contains(col) &&
                  valor is xlsx.DoubleCellValue
              ? estiloNota
              : null,
        );
      }
    }
  }

  static xlsx.CellValue? _valorCelula(Object? valor) {
    return switch (valor) {
      null => null,
      final int v => xlsx.IntCellValue(v),
      final double v => xlsx.DoubleCellValue(v),
      _ => xlsx.TextCellValue(valor.toString()),
    };
  }
}
