import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/correction_simulator.dart';
import 'leitura_prova_mock_screen.dart';

/// Tela de "escaneamento" do QR Code da folha de respostas (RF05/RF06).
/// Nesta fase N1 não há câmera real: o professor toca em um botão que
/// simula a leitura e identifica aluno/turma/prova com dados fictícios.
class QrCodeMockScreen extends StatefulWidget {
  const QrCodeMockScreen({super.key});

  @override
  State<QrCodeMockScreen> createState() => _QrCodeMockScreenState();
}

class _QrCodeMockScreenState extends State<QrCodeMockScreen> {
  bool _escaneando = false;

  Future<void> _simularEscaneamento() async {
    setState(() => _escaneando = true);

    await Future.delayed(const Duration(milliseconds: 900));
    final identificacao = CorrectionSimulator.simularEscaneamentoQrCode();

    if (!mounted) return;

    setState(() => _escaneando = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.corrigirProvaLeitura),
        builder: (_) => LeituraProvaMockScreen(identificacao: identificacao),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              alignment: Alignment.center,
              child: _escaneando
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : const Icon(
                      Icons.qr_code_scanner,
                      size: 96,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _escaneando
                  ? 'Lendo QR Code...'
                  : 'Aponte a câmera para o QR Code da folha de respostas',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tela mock (N1) — a leitura do QR Code é simulada, sem uso '
              'real da câmera.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _escaneando ? null : _simularEscaneamento,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Simular escaneamento'),
            ),
          ],
        ),
      ),
    );
  }
}
