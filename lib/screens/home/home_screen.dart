import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_tile.dart';
import '../../widgets/stat_badge.dart';
import '../../widgets/side_nav_bar.dart';
import '../../widgets/background_texture.dart';

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
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackgroundTexture()),
          SafeArea(
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
        ],
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

    return SingleChildScrollView(
      child: Column(
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
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_outlined,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ProvaLab',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
        Padding(
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
                    crossAxisCount: 1,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: isNarrow ? 2.6 : 4.2,
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
      ],
      ),
    );
  }
}