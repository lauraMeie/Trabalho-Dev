import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/mock_screen_scaffold.dart';

class CriarProvaScreen extends StatelessWidget {
  const CriarProvaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      title: 'Criar Prova',
      icon: Icons.edit_document,
      description:
          'Aqui o professor vai montar/gerar automaticamente uma nova prova.',
      nextLabel: 'Ir para Corrigir Prova',
      onNext: () => Navigator.of(context).pushNamed(AppRoutes.corrigirProva),
    );
  }
}