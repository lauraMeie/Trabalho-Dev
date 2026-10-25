import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Salva a planilha gerada nos documentos do app (Android/iOS/desktop) e
/// devolve o caminho do arquivo salvo.
Future<String?> salvarBytesLocalmente(Uint8List bytes, String nomeArquivo) async {
  final diretorio = await getApplicationDocumentsDirectory();
  final arquivo = File('${diretorio.path}/$nomeArquivo');
  await arquivo.writeAsBytes(bytes);
  return arquivo.path;
}
