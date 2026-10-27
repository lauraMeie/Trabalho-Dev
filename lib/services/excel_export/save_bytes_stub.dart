import 'dart:typed_data';

/// No Flutter Web o download já é disparado pelo próprio pacote `excel`
/// (Excel.save()), então aqui não há nada a fazer.
Future<String?> salvarBytesLocalmente(Uint8List bytes, String nomeArquivo) async {
  return null;
}
