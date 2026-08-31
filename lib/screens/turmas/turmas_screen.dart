import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/mock_screen_scaffold.dart';

class TurmasScreen extends StatelessWidget {
  const TurmasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      title: 'Turmas',
      icon: Icons.groups_outlined,
      description:
          'Aqui o professor vai gerenciar as turmas cadastradas e seus alunos.',
      nextLabel: 'Ir para Banco de Questões',
      onNext: () => Navigator.of(context).pushNamed(AppRoutes.bancoQuestoes),
    );
  }
}