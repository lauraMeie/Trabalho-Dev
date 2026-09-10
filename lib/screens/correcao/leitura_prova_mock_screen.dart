import 'package:flutter/material.dart';

import '../../data/mock_corrections_store.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/correction_simulator.dart';
import 'resultado_correcao_screen.dart';

/// Tela de leitura das respostas marcadas na folha de respostas (RF07).
/// Nesta fase N1 a leitura é simulada: o app já sabe quem é o aluno/turma
/// (identificado na etapa anterior) e, ao tocar em "Iniciar leitura",
/// gera e corrige uma prova fictícia.
class LeituraProvaMockScreen extends StatefulWidget {
  final IdentificacaoProva identificacao;

  const LeituraProvaMockScreen({super.key, required this.identificacao});

  @override
  State<LeituraProvaMockScreen> createState() =>
      _LeituraProvaMockScreenState();
}

class _LeituraProvaMockScreenState extends State<LeituraProvaMockScreen> {
  bool _lendo = false;

  Future<void> _iniciarLeitura() async {
    setState(() => _lendo = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    final resultado = CorrectionSimulator.simularLeituraRespostas(
      identificacao: widget.identificacao,
    );
    MockCorrectionsStore.adicionar(resultado);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.corrigirProvaResultado),
        builder: (_) => ResultadoCorrecaoScreen(resultado: resultado),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final identificacao = widget.identificacao;

    return Scaffold(
      appBar: AppBar(title: const Text('Leitura da Prova')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.qr_code_2, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'QR Code identificado',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoLinha(label: 'Aluno', valor: identificacao.aluno),
                    _InfoLinha(label: 'Turma', valor: identificacao.turma),
                    _InfoLinha(label: 'Prova', valor: identificacao.provaId),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 72,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_lendo) ...[
                    const LinearProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Lendo alternativas marcadas...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else
                    Text(
                      'Pronto para ler as respostas marcadas na folha '
                      '(mock).',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _lendo ? null : _iniciarLeitura,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar leitura das respostas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoLinha({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              valor,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
