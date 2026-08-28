import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/mock_screen_scaffold.dart';

class CorrigirProvaScreen extends StatelessWidget {
  const CorrigirProvaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      title: 'Corrigir Prova',
      icon: Icons.fact_check_outlined,
      description:
          'Aqui o professor vai corrigir as provas aplicadas de forma automatizada.',
      nextLabel: 'Ver Relatórios',
      onNext: () => Navigator.of(context).pushNamed(AppRoutes.relatorios),
    );
  }
}