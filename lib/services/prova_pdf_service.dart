import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/prova_gerada.dart';
import '../utils/prova_pdf.dart';

/// Gera o PDF da prova e entrega ao usuário (imprimir ou baixar).
class ProvaPdfService {
  ProvaPdfService._();

  /// Abre a visualização/impressão do PDF.
  static Future<void> imprimir(ProvaGerada prova) async {
    final bytes = await _gerarBytes(prova);
    await Printing.layoutPdf(
      name: _nomeArquivo(prova),
      onLayout: (_) async => bytes,
    );
  }

  /// Baixa/compartilha o PDF como arquivo.
  static Future<void> baixar(ProvaGerada prova) async {
    final bytes = await _gerarBytes(prova);
    await Printing.sharePdf(bytes: bytes, filename: _nomeArquivo(prova));
  }

  static Future<Uint8List> _gerarBytes(ProvaGerada prova) async {
    final tema = await _carregarTema();
    return ProvaPdf.gerar(prova, tema: tema);
  }

  /// Usa a fonte Roboto (baixada na hora) para os acentos e símbolos
  /// saírem corretos. Sem internet, cai na fonte padrão do PDF, que
  /// ainda atende o português.
  static Future<pw.ThemeData> _carregarTema() async {
    try {
      final normal = await PdfGoogleFonts.robotoRegular()
          .timeout(const Duration(seconds: 8));
      final negrito = await PdfGoogleFonts.robotoBold()
          .timeout(const Duration(seconds: 8));
      final italico = await PdfGoogleFonts.robotoItalic()
          .timeout(const Duration(seconds: 8));
      return pw.ThemeData.withFont(
        base: normal,
        bold: negrito,
        italic: italico,
      );
    } catch (erro) {
      debugPrint('Fonte Roboto indisponível, usando a padrão: $erro');
      return pw.ThemeData.base();
    }
  }

  static String _nomeArquivo(ProvaGerada prova) {
    var base = prova.nome.trim().toLowerCase();
    const acentos = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };
    acentos.forEach((de, para) => base = base.replaceAll(de, para));
    base = base
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${base.isEmpty ? 'prova' : base}.pdf';
  }
}
