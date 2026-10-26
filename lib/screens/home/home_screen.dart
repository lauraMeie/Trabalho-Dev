import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/menu_tile.dart';
import '../../widgets/stat_badge.dart';
import '../../widgets/side_nav_bar.dart';
import '../../widgets/background_texture.dart';
import '../../services/stats_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _breakpoint = 800;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _breakpoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
              }
            },
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
                      const Expanded(child: _HomeContent()),
                    ],
                  )
                : const _HomeContent(),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      child: Column(
        children: [
          ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                isNarrow ? AppSpacing.md : AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl + AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem vindo!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Hora de gerenciar suas avaliações de forma simples e rápida.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    child: _StatsRow(),
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
                    final narrowGrid = gridConstraints.maxWidth < 420;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 1,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: narrowGrid ? 3.1 : 4.6,
                      children: [
                        MenuTile(
                          icon: Icons.groups_outlined,
                          title: 'Turmas',
                          subtitle: 'Gerencie suas turmas e alunos',
                          imageAsset: 'assets/images/icon_turmas.svg',
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.turmas),
                        ),
                        MenuTile(
                          icon: Icons.quiz_outlined,
                          title: 'Banco de Questões',
                          subtitle: 'Cadastre e organize questões',
                          imageAsset: 'assets/images/icon_banco_questoes.svg',
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.bancoQuestoes),
                        ),
                        MenuTile(
                          icon: Icons.edit_document,
                          title: 'Criar Prova',
                          subtitle: 'Monte uma nova avaliação',
                          imageAsset: 'assets/images/icon_criar_prova.svg',
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.criarProva),
                        ),
                        MenuTile(
                          icon: Icons.fact_check_outlined,
                          title: 'Corrigir Prova',
                          subtitle: 'Correção automatizada das provas',
                          imageAsset: 'assets/images/icon_corrigir_prova.svg',
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

class _StatsRow extends StatefulWidget {
  const _StatsRow();

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  late final Stream<Stats> _stream = StatsService.stream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Stats>(
      stream: _stream,
      builder: (context, snapshot) {
        final s = snapshot.data;
        String n(int? v) => v == null ? '-' : '$v';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StatBadge(value: n(s?.turmas), label: 'Turmas'),
            StatBadge(value: n(s?.alunos), label: 'Alunos'),
            StatBadge(value: n(s?.provas), label: 'Provas'),
          ],
        );
      },
    );
  }
}

class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}