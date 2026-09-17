import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gráfico de barras horizontais simples (sem dependências externas)
/// mostrando o percentual de acerto por matéria (RF11).
class GraficoDesempenho extends StatelessWidget {
  /// Matéria -> percentual de acerto (0.0 a 1.0).
  final Map<String, double> dados;

  const GraficoDesempenho({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) return const SizedBox.shrink();

    final entradas = dados.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entradas
          .map((entrada) => _BarraMateria(
                materia: entrada.key,
                percentual: entrada.value,
              ))
          .toList(),
    );
  }
}

class _BarraMateria extends StatelessWidget {
  final String materia;
  final double percentual;

  const _BarraMateria({required this.materia, required this.percentual});

  @override
  Widget build(BuildContext context) {
    final percentualClamped = percentual.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                materia,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                '${(percentualClamped * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 10,
                      width: constraints.maxWidth,
                      color: AppColors.border,
                    ),
                    Container(
                      height: 10,
                      width: constraints.maxWidth * percentualClamped,
                      color: AppColors.primary,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
