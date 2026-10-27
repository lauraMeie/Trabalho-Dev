import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho/services/qr_prova_codec.dart';

void main() {
  group('QrProvaCodec.codificar', () {
    test('gera o payload no formato esperado', () {
      final codigo = QrProvaCodec.codificar('ABC123', '0000');
      expect(codigo, 'provalab://prova/ABC123/0000');
    });
  });

  group('QrProvaCodec.decodificar', () {
    test('decodifica um payload válido corretamente', () {
      final payload =
          QrProvaCodec.decodificar('provalab://prova/ABC123/0001');
      expect(payload, isNotNull);
      expect(payload!.provaId, 'ABC123');
      expect(payload.individualId, '0001');
    });

    test('é o inverso de codificar (round-trip)', () {
      final codigo = QrProvaCodec.codificar('xyz-999', '0003');
      final payload = QrProvaCodec.decodificar(codigo);
      expect(payload!.provaId, 'xyz-999');
      expect(payload.individualId, '0003');
    });

    test('retorna null para texto nulo', () {
      expect(QrProvaCodec.decodificar(null), isNull);
    });

    test('retorna null para QR Code de outro app (prefixo diferente)', () {
      expect(QrProvaCodec.decodificar('https://outroapp.com/123'), isNull);
    });

    test('retorna null quando falta o individualId', () {
      expect(QrProvaCodec.decodificar('provalab://prova/ABC123'), isNull);
    });

    test('retorna null quando o provaId está vazio', () {
      expect(QrProvaCodec.decodificar('provalab://prova//0000'), isNull);
    });

    test('ignora espaços em branco nas pontas', () {
      final payload =
          QrProvaCodec.decodificar('  provalab://prova/ABC123/0000  ');
      expect(payload, isNotNull);
      expect(payload!.provaId, 'ABC123');
    });
  });
}
