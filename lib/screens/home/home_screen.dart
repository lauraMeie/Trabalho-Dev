import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_card.dart';
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
              color: AppColors.primary,
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

              MenuCard(
                icon: Icons.groups_outlined,
                title: 'Turmas',
                subtitle: 'Gerencie suas turmas e alunos',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.turmas),
              ),
              const SizedBox(height: AppSpacing.sm),
              MenuCard(
                icon: Icons.quiz_outlined,
                title: 'Banco de Questões',
                subtitle: 'Cadastre e organize questões',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.bancoQuestoes),
              ),
              const SizedBox(height: AppSpacing.sm),
              MenuCard(
                icon: Icons.edit_document,
                title: 'Criar Prova',
                subtitle: 'Monte uma nova avaliação',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.criarProva),
              ),
              const SizedBox(height: AppSpacing.sm),
              MenuCard(
                icon: Icons.fact_check_outlined,
                title: 'Corrigir Prova',
                subtitle: 'Correção automatizada das provas',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.corrigirProva),
              ),
              const SizedBox(height: AppSpacing.sm),
                            MenuCard(
                icon: Icons.bar_chart_outlined,
                title: 'Relatórios',
                subtitle: 'Acompanhe os resultados',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.relatorios),
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