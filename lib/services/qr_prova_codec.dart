/// Formato do QR Code impresso na folha de respostas: identifica, de forma
/// compacta, qual prova (e qual versão individual dela) aquela folha é.
///
/// Exemplo: `provalab://prova/AbC123XyZ/0000`
///   - `AbC123XyZ` é o ID do documento em `provas/{provaId}` no Firestore;
///   - `0000` é o ID do documento em `provas/{provaId}/individuais/{id}`
///     (ver ProvaRepository/ProvaGerada). Para "mesma prova para todos" só
///     existe a versão `0000`; para prova individualizada, cada aluno tem
///     a sua.
class QrProvaPayload {
  final String provaId;
  final String individualId;

  const QrProvaPayload({required this.provaId, required this.individualId});

  String codificar() => 'provalab://prova/$provaId/$individualId';

  @override
  String toString() => codificar();
}

/// Codifica/decodifica o payload do QR Code da folha de respostas (RF05/RF06).
class QrProvaCodec {
  QrProvaCodec._();

  static const String _prefixo = 'provalab://prova/';

  static String codificar(String provaId, String individualId) {
    return QrProvaPayload(provaId: provaId, individualId: individualId)
        .codificar();
  }

  /// Decodifica o texto lido pela câmera. Devolve `null` se o QR Code não
  /// for de uma folha de respostas do Provas App (ex.: QR de outro app).
  static QrProvaPayload? decodificar(String? texto) {
    if (texto == null) return null;
    final valor = texto.trim();
    if (!valor.startsWith(_prefixo)) return null;

    final partes = valor.substring(_prefixo.length).split('/');
    if (partes.length != 2) return null;

    final provaId = partes[0].trim();
    final individualId = partes[1].trim();
    if (provaId.isEmpty || individualId.isEmpty) return null;

    return QrProvaPayload(provaId: provaId, individualId: individualId);
  }
}
