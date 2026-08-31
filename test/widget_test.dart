
import 'package:flutter_test/flutter_test.dart';

import 'package:trabalho/app.dart';

void main() {
  testWidgets('Home carrega e mostra o menu principal', (WidgetTester tester) async {
    await tester.pumpWidget(const ProvasApp());

    expect(find.text('Olá, Professor!'), findsOneWidget);
    expect(find.text('Turmas'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);
  });
}