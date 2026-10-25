import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;

import '../models/correction_result.dart';
import 'excel_export/save_bytes_stub.dart'
    if (dart.library.io) 'excel_export/save_bytes_io.dart' as plataforma;

/// Exporta os resultados das provas corrigidas em uma planilha Excel
/// (RF10/RNF05).
///
/// No Flutter Web, gerar a planilha já dispara o download pelo navegador
/// (comportamento do próprio pacote `excel`). Em Android/iOS/desktop, o
/// arquivo é salvo nos documentos do app e o caminho é devolvido.
class ExcelExportService {
  ExcelExportService._();

  static const String _nomeAba = 'Resultados';

  /// Gera e salva/baixa a planilha. Devolve o caminho do arquivo salvo
  /// (fora da Web) ou `null` quando o download já foi disparado (Web).
  static Future<String?> exportar(List<ResultadoCorrecao> resultados) async {
    final excel = xlsx.Excel.createExcel();
    final sheet = excel[_nomeAba];
    excel.delete('Sheet1');

    sheet.appendRow([
      xlsx.TextCellValue('Aluno'),
      xlsx.TextCellValue('Turma'),
      xlsx.TextCellValue('Prova'),
      xlsx.TextCellValue('Nota'),
      xlsx.TextCellValue('Acertos'),
      xlsx.TextCellValue('Erros'),
      xlsx.TextCellValue('Em branco'),
      xlsx.TextCellValue('Corrigido em'),
    ]);

    for (final resultado in resultados) {
      sheet.appendRow([
        xlsx.TextCellValue(resultado.aluno),
        xlsx.TextCellValue(resultado.turma),
        xlsx.TextCellValue(resultado.provaId),
        xlsx.DoubleCellValue(resultado.nota),
        xlsx.IntCellValue(resultado.acertos),
        xlsx.IntCellValue(resultado.erros),
        xlsx.IntCellValue(resultado.emBranco),
        xlsx.TextCellValue(_formatarData(resultado.corrigidoEm)),
      ]);
    }

    final nomeArquivo =
        'resultados-provas-${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final bytes = excel.save(fileName: nomeArquivo);
    if (bytes == null) {
      throw Exception('Não foi possível gerar a planilha.');
    }

    return plataforma.salvarBytesLocalmente(
      Uint8List.fromList(bytes),
      nomeArquivo,
    );
  }

  static String _formatarData(DateTime data) {
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');
    return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
        '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
  }
}
