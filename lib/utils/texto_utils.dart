/// Funções de texto usadas para validar e comparar nomes e matrículas.
class TextoUtils {
  TextoUtils._();

  /// Tira os espaços das pontas e troca vários espaços seguidos por um só.
  static String normalizarEspacos(String texto) {
    return texto.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Texto "comparável": minúsculo, sem acento e com espaços normalizados.
  /// Serve para saber se "3º Ano A" e "3º ano  a" são a mesma turma.
  static String chaveDeComparacao(String texto) {
    final buffer = StringBuffer();
    for (final letra in normalizarEspacos(texto).toLowerCase().split('')) {
      buffer.write(_semAcento[letra] ?? letra);
    }
    return buffer.toString();
  }

  static const Map<String, String> _semAcento = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
}
