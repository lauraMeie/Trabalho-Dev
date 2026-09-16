import 'package:flutter/material.dart';

import '../../models/correction_result.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_badge.dart';
import 'qrcode_mock_screen.dart';

/// Mostra o resultado da correção automatizada de uma prova (RF08):
/// nota, quantidade de acertos/erros/em branco e o detalhe de cada questão.
class ResultadoCorrecaoScreen extends StatelessWidget {
  final ResultadoCorrecao resultado;

  const ResultadoCorrecaoScreen({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        actions: [
          IconButton(
            tooltip: 'Voltar para a Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.settings.name == AppRoutes.home),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Text(
                    resultado.aluno,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${resultado.turma} · ${resultado.provaId}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    resultado.nota.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Nota final (0 a 10)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatBadge(
                        value: '${resultado.acertos}',
                        label: 'Acertos',
                      ),
                      StatBadge(value: '${resultado.erros}', label: 'Erros'),
                      StatBadge(
                        value: '${resultado.emBranco}',
                        label: 'Em branco',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Detalhe das questões',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...resultado.respostas.asMap().entries.map(
                (entry) => _QuestaoResultadoCard(
                  numero: entry.key + 1,
                  resposta: entry.value,
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                settings:
                    const RouteSettings(name: AppRoutes.corrigirProvaQrCode),
                builder: (_) => const QrCodeMockScreen(),
              ),
              (route) => route.settings.name == AppRoutes.corrigirProva ||
                  route.settings.name == AppRoutes.home,
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Corrigir outra prova'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil(
              AppRoutes.relatorios,
              (route) => route.settings.name == AppRoutes.home,
            ),
            icon: const Icon(Icons.bar_chart_outlined),
            label: const Text('Ver relatórios'),
          ),
        ],
      ),
    );
  }
}

class _QuestaoResultadoCard extends StatelessWidget {
  final int numero;
  final RespostaCorrigida resposta;

  const _QuestaoResultadoCard({required this.numero, required this.resposta});

  @override
  Widget build(BuildContext context) {
    final Color corStatus = resposta.correta
        ? AppColors.success
        : resposta.emBranco
            ? AppColors.textSecondary
            : Colors.redAccent;

    final IconData iconeStatus = resposta.correta
        ? Icons.check_circle
        : resposta.emBranco
            ? Icons.remove_circle_outline
            : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconeStatus, color: corStatus),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Questão $numero · ${resposta.materia}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(resposta.enunciado,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              resposta.emBranco
                  ? 'Resposta do aluno: em branco'
                  : 'Resposta do aluno: ${resposta.textoMarcado}',
              style: TextStyle(color: corStatus, fontWeight: FontWeight.w600),
            ),
            if (!resposta.correta)
              Text(
                'Resposta correta: ${resposta.textoCorreto}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
