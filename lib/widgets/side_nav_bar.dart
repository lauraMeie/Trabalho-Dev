import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

/// Barra lateral de navegação, usada na Home (como painel fixo em
/// telas largas, ou dentro de um Drawer em telas estreitas).
class SideNavBar extends StatelessWidget {
  const SideNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('ProvaLab',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Início',
            selected: true,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          _NavItem(
            icon: Icons.groups_outlined,
            label: 'Turmas',
            onTap: () {
              Navigator.of(context).maybePop();
              Navigator.of(context).pushNamed(AppRoutes.turmas);
            },
          ),
          _NavItem(
            icon: Icons.quiz_outlined,
            label: 'Banco de Questões',
            onTap: () {
              Navigator.of(context).maybePop();
              Navigator.of(context).pushNamed(AppRoutes.bancoQuestoes);
            },
          ),
          _NavItem(
            icon: Icons.edit_document,
            label: 'Criar Prova',
            onTap: () {
              Navigator.of(context).maybePop();
              Navigator.of(context).pushNamed(AppRoutes.criarProva);
            },
          ),
          _NavItem(
            icon: Icons.fact_check_outlined,
            label: 'Corrigir Prova',
            onTap: () {
              Navigator.of(context).maybePop();
              Navigator.of(context).pushNamed(AppRoutes.corrigirProva);
            },
          ),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            label: 'Relatórios',
            onTap: () {
              Navigator.of(context).maybePop();
              Navigator.of(context).pushNamed(AppRoutes.relatorios);
            },
          ),
          const Spacer(),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          _NavItem(
            icon: Icons.logout,
            label: 'Sair da conta',
            iconColor: Colors.red.shade400,
            textColor: Colors.red.shade400,
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ??
        (selected ? AppColors.primary : AppColors.textSecondary);
    final effectiveTextColor = textColor ??
        (selected ? AppColors.primary : AppColors.textPrimary);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 20, color: effectiveIconColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}