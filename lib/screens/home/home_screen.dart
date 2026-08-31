import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_tile.dart';
import '../../widgets/stat_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
      ),
            body: SafeArea(
        child: Column(
          children: [
                          Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Bem vindo!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Hora de gerenciar suas avaliações de forma simples e rápida.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                            Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: Color(0xFF2E2545), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      StatBadge(value: '3', label: 'Turmas'),
                      StatBadge(value: '120', label: 'Alunos'),
                      StatBadge(value: '15', label: 'Provas'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'Menu principal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),

                            GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.9,
                children: [
                                    MenuTile(
                    icon: Icons.groups_outlined,
                    title: 'Turmas',
                    subtitle: 'Gerencie suas turmas e alunos',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.turmas),
                  ),
                  MenuTile(
                    icon: Icons.quiz_outlined,
                    title: 'Banco de Questões',
                    subtitle: 'Cadastre e organize questões',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.bancoQuestoes),
                  ),
                  MenuTile(
                    icon: Icons.edit_document,
                    title: 'Criar Prova',
                    subtitle: 'Monte uma nova avaliação',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.criarProva),
                  ),
                  MenuTile(
                    icon: Icons.fact_check_outlined,
                    title: 'Corrigir Prova',
                    subtitle: 'Correção automatizada das provas',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.corrigirProva),
                  ),
                  MenuTile(
                    icon: Icons.bar_chart_outlined,
                    title: 'Relatórios',
                    subtitle: 'Acompanhe os resultados',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.relatorios),
                  ),
                ],
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}