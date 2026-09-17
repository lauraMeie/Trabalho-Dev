import 'package:flutter/material.dart';

import '../../data/mock_corrections_store.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/grafico_desempenho.dart';
import '../../widgets/stat_badge.dart';
import '../correcao/qrcode_mock_screen.dart';

/// Tela de Relatórios (RF09) e Estatísticas por questão (RF11), a partir
/// das provas já corrigidas na sessão atual (mock, sem persistência real).
class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resultados = MockCorrectionsStore.resultados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            tooltip: 'Voltar para a Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.settings.name == AppRoutes.home),
          ),
        ],
      ),
      body: resultados.isEmpty
          ? _EstadoVazio(context: context)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatBadge(
                          value: '${resultados.length}',
                          label: 'Provas\ncorrigidas',
                        ),
                        StatBadge(
                          value: MockCorrectionsStore.mediaGeral
                              .toStringAsFixed(1),
                          label: 'Média\ngeral',
                        ),
                        StatBadge(
                          value: '${MockCorrectionsStore.totalTurmasDistintas}',
                          label: 'Turmas',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Desempenho por matéria',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: GraficoDesempenho(
                      dados: MockCorrectionsStore.desempenhoPorMateria(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Provas corrigidas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...resultados.map(
                  (resultado) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        foregroundColor: AppColors.primary,
                        child: Text(resultado.nota.toStringAsFixed(0)),
                      ),
                      title: Text(resultado.aluno),
                      subtitle: Text(
                        '${resultado.turma} · ${resultado.provaId} · '
                        '${resultado.acertos}/${resultado.totalQuestoes} acertos',
                      ),
                      trailing: Text(
                        resultado.nota.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Estatística por questão',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Alternativa mais marcada pelos alunos em cada questão já '
                  'corrigida.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...MockCorrectionsStore.estatisticasPorQuestao().map(
                  (estatistica) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${estatistica.materia} · ${estatistica.enunciado}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Mais marcada: '
                            '${estatistica.alternativaMaisMarcada?.key ?? '-'} '
                            '(${estatistica.alternativaMaisMarcada?.value ?? 0}x)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Acerto: '
                            '${(estatistica.percentualAcerto * 100).toStringAsFixed(0)}% '
                            'de ${estatistica.totalRespostas} resposta(s)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final BuildContext context;

  const _EstadoVazio({required this.context});

  @override
  Widget build(BuildContext _) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 72, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Nenhuma prova corrigida ainda',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Corrija uma prova para ver aqui os resultados e as '
            'estatísticas por questão.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(
                  name: AppRoutes.corrigirProvaQrCode,
                ),
                builder: (_) => const QrCodeMockScreen(),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Corrigir uma prova'),
          ),
        ],
      ),
    );
  }
}
