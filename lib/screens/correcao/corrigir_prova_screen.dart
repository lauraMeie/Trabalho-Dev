import 'package:flutter/material.dart';

import '../../data/mock_corrections_store.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import 'qrcode_mock_screen.dart';

/// Ponto de partida do fluxo de correção (RF06/RF07): explica os passos e
/// permite iniciar uma nova correção (escaneando o QR Code da folha de
/// respostas, de forma simulada) ou ver as últimas provas já corrigidas.
class CorrigirProvaScreen extends StatelessWidget {
  const CorrigirProvaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ultimasCorrecoes = MockCorrectionsStore.resultados.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrigir Prova'),
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
          Icon(Icons.fact_check_outlined,
              size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Correção automatizada',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Escaneie o QR Code da folha de respostas para identificar a '
            'prova e o aluno, e deixe o app ler e corrigir as respostas '
            'automaticamente.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _EtapaFluxo(
                    numero: '1',
                    titulo: 'Escanear QR Code',
                    descricao: 'Identifica o aluno e a prova (mock).',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _EtapaFluxo(
                    numero: '2',
                    titulo: 'Leitura das respostas',
                    descricao: 'App lê as alternativas marcadas (mock).',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _EtapaFluxo(
                    numero: '3',
                    titulo: 'Resultado',
                    descricao: 'Nota e acertos/erros calculados na hora.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
            label: const Text('Iniciar nova correção'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.relatorios),
            icon: const Icon(Icons.bar_chart_outlined),
            label: const Text('Ver relatórios'),
          ),
          if (ultimasCorrecoes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Últimas correções',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...ultimasCorrecoes.map(
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
                    '${resultado.turma} · ${resultado.acertos}/${resultado.totalQuestoes} acertos',
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
          ],
        ],
      ),
    );
  }
}

class _EtapaFluxo extends StatelessWidget {
  final String numero;
  final String titulo;
  final String descricao;

  const _EtapaFluxo({
    required this.numero,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Text(numero, style: const TextStyle(fontSize: 13)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
              Text(descricao, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
