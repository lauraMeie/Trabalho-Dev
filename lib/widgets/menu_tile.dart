import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

/// Item de menu em formato de cartão horizontal: ilustração (ou
/// ícone, como fallback) à esquerda, título/subtítulo ao centro e
/// um indicador de navegação (chevron) à direita.
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Caminho de uma ilustração (SVG) para exibir no lugar do ícone.
  /// Se não for informado, o [icon] continua sendo usado normalmente
  /// (compatibilidade com tiles que ainda não têm ilustração própria).
  final String? imageAsset;

  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Illustration(icon: icon, imageAsset: imageAsset),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color:
                                    AppColors.textPrimary.withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary.withValues(alpha: 0.55),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final IconData icon;
  final String? imageAsset;

  const _Illustration({required this.icon, required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    const double size = 68;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: imageAsset != null
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                imageAsset!,
                fit: BoxFit.contain,
              ),
            )
          : Icon(icon, color: AppColors.primary, size: 26),
    );
  }
}