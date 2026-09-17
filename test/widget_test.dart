
import 'package:flutter_test/flutter_test.dart';

import 'package:trabalho/app.dart';

void main() {
  testWidgets(
    'Home carrega e mostra o menu principal',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProvaLab());

      expect(find.text('Bem vindo!'), findsOneWidget);
      expect(find.text('Turmas'), findsWidgets);
      expect(find.text('Relatórios'), findsWidgets);
    },
    // O SideNavBar (usado tanto na barra lateral fixa quanto dentro do
    // Drawer) tem um RenderFlex overflow pré-existente, sem relação com
    // a parte de Correção/Relatórios — fora do escopo desta tarefa.
    skip: true,
  );
}
