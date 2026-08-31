import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/mock_screen_scaffold.dart';

class BancoQuestoesScreen extends StatelessWidget {
  const BancoQuestoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      title: 'Banco de Questões',
      icon: Icons.quiz_outlined,
      description:
          'Aqui o professor vai cadastrar e organizar as questões usadas nas provas.',
      nextLabel: 'Ir para Criar Prova',
      onNext: () => Navigator.of(context).pushNamed(AppRoutes.criarProva),
    );
  }
}