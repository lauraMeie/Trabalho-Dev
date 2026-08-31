import 'package:flutter/material.dart';
import '../../widgets/mock_screen_scaffold.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MockScreenScaffold(
      title: 'Relatórios',
      icon: Icons.bar_chart_outlined,
      description:
          'Aqui o professor vai visualizar os resultados e relatórios das provas corrigidas.',
    );
  }
}