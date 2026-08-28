import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/turmas/turmas_screen.dart';
import 'screens/questoes/banco_questoes_screen.dart';
import 'screens/provas/criar_prova_screen.dart';
import 'screens/correcao/corrigir_prova_screen.dart';
import 'screens/relatorios/relatorios_screen.dart';

class ProvasApp extends StatelessWidget {
  const ProvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provas App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.turmas: (context) => const TurmasScreen(),
        AppRoutes.bancoQuestoes: (context) => const BancoQuestoesScreen(),
        AppRoutes.criarProva: (context) => const CriarProvaScreen(),
        AppRoutes.corrigirProva: (context) => const CorrigirProvaScreen(),
        AppRoutes.relatorios: (context) => const RelatoriosScreen(),
      },
    );
  }
}