import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_tile.dart';
import '../../widgets/stat_badge.dart';
import '../../widgets/side_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Largura mínima de tela a partir da qual mostramos a barra lateral fixa.
  static const double _breakpoint = 800;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _breakpoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.login),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Entrar'),
          ),
        ],
      ),
      
      drawer: isWide ? null : const Drawer(width: 260, child: SideNavBar()),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  const SideNavBar(),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(child: _HomeContent(context: context)),
                ],
              )
            : _HomeContent(context: context),
      ),
    );
  }
}

/// Conteúdo principal da Home (faixa de boas-vindas, estatísticas e
/// grade de menu). Reaproveitado tanto no layout largo (com barra
/// lateral) quanto no layout estreito (celular, sem barra).
class _HomeContent extends StatelessWidget {
  final BuildContext context;

  const _HomeContent({required this.context});

    @override
  Widget build(BuildContext _) {
    final isNarrow = MediaQuery.of(context).size.width < 800;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: isNarrow ? AppSpacing.xs : AppSpacing.sm,
          ),
          margin: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Círculo decorativo, ao fundo, canto superior esquerdo.
              Positioned(
                left: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Grade de pontinhos decorativa, canto inferior direito.
              const Positioned(
                right: 8,
                bottom: 8,
                child: _DotsGrid(),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('👋', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem vindo!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Hora de gerenciar suas avaliações de forma simples e rápida.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
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
                    side: const BorderSide(
                        color: AppColors.border, width: 1.5),
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
                LayoutBuilder(
                  builder: (context, gridConstraints) {
                    final isNarrow = gridConstraints.maxWidth < 420;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isNarrow ? 2 : 3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: isNarrow ? 1.0 : 0.9,
                      children: [
                        MenuTile(
                          icon: Icons.groups_outlined,
                          title: 'Turmas',
                          subtitle: 'Gerencie suas turmas e alunos',
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.turmas),
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
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.criarProva),
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
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.relatorios),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pequena grade de pontinhos decorativos, usada no fundo da faixa
/// de boas-vindas.
class _DotsGrid extends StatelessWidget {
  const _DotsGrid();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: 16,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}