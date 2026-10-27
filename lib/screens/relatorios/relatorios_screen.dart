import 'package:flutter/material.dart';

import '../../data/relatorios_calculos.dart';
import '../../models/correction_result.dart';
import '../../routes/app_routes.dart';
import '../../services/correcao_repository.dart';
import '../../services/excel_export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/firestore_errors.dart';
import '../../widgets/grafico_desempenho.dart';
import '../../widgets/stat_badge.dart';
import '../correcao/qrcode_screen.dart';

/// Tela de Relatórios (RF09) e Estatísticas por questão (RF11), a partir
/// das provas já corrigidas e salvas no Firestore (coleção `correcoes`).
class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final _correcaoRepository = CorrecaoRepository();

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<List<ResultadoCorrecao>>(
        stream: _correcaoRepository.observarResultados(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EstadoErro(
              mensagem: mensagemDeErro(snapshot.error!),
              onTentarNovamente: () => setState(() {}),
            );
          }

          final resultados = snapshot.data ?? const [];
          return resultados.isEmpty
              ? _EstadoVazio(context: context)
              : _ConteudoRelatorios(resultados: resultados);
        },
      ),
    );
  }
}

class _ConteudoRelatorios extends StatelessWidget {
  final List<ResultadoCorrecao> resultados;

  const _ConteudoRelatorios({required this.resultados});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _BotaoExportarExcel(resultados: resultados),
        ),
        const SizedBox(height: AppSpacing.sm),
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
                  value: RelatoriosCalculos.mediaGeral(resultados)
                      .toStringAsFixed(1),
                  label: 'Média\ngeral',
                ),
                StatBadge(
                  value: '${RelatoriosCalculos.totalTurmasDistintas(resultados)}',
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
              dados: RelatoriosCalculos.desempenhoPorMateria(resultados),
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
        ...RelatoriosCalculos.estatisticasPorQuestao(resultados).map(
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
                builder: (_) => const QrCodeScreen(),
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

class _BotaoExportarExcel extends StatefulWidget {
  final List<ResultadoCorrecao> resultados;

  const _BotaoExportarExcel({required this.resultados});

  @override
  State<_BotaoExportarExcel> createState() => _BotaoExportarExcelState();
}

class _BotaoExportarExcelState extends State<_BotaoExportarExcel> {
  bool _exportando = false;

  Future<void> _exportar() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exportando = true);
    try {
      final caminho = await ExcelExportService.exportar(widget.resultados);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            caminho == null
                ? 'Planilha baixada com sucesso.'
                : 'Planilha salva em: $caminho',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar a planilha. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _exportando ? null : _exportar,
      icon: _exportando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.table_chart_outlined),
      label: Text(_exportando ? 'Gerando...' : 'Exportar para Excel'),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const _EstadoErro({required this.mensagem, required this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: AppSpacing.md),
          Text(
            mensagem,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onTentarNovamente,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
