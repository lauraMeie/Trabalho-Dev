import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/correcao_repository.dart';
import '../../services/qr_prova_codec.dart';
import '../../theme/app_theme.dart';
import 'leitura_prova_screen.dart';

/// Tela de escaneamento do QR Code da folha de respostas (RF05/RF06).
///
/// Usa a câmera real do dispositivo (pacote mobile_scanner) para ler o QR
/// Code impresso na folha e, a partir dele, identificar a prova/gabarito
/// reais salvos no Firestore (ver CorrecaoRepository).
class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final CorrecaoRepository _repositorio = CorrecaoRepository();
  final _codigoManualController = TextEditingController();

  bool _processando = false;
  String? _erro;
  bool _mostrarEntradaManual = false;

  @override
  void dispose() {
    _controller.dispose();
    _codigoManualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture captura) {
    if (_processando) return;
    final valor = captura.barcodes.isEmpty
        ? null
        : captura.barcodes.first.rawValue;
    if (valor == null) return;
    _processarCodigo(valor);
  }

  Future<void> _processarCodigo(String codigo) async {
    final payload = QrProvaCodec.decodificar(codigo);
    if (payload == null) {
      setState(() => _erro =
          'Esse QR Code não é de uma folha de respostas do Provas App.');
      return;
    }

    setState(() {
      _processando = true;
      _erro = null;
    });
    unawaited(_controller.stop());

    try {
      final prova = await _repositorio.buscarProvaDoAluno(payload);
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.corrigirProvaLeitura),
          builder: (_) => LeituraProvaScreen(prova: prova),
        ),
      );
    } on ProvaNaoEncontradaException {
      if (!mounted) return;
      setState(() {
        _erro = 'Essa prova não existe mais no banco de dados (talvez já '
            'tenha sido excluída).';
        _processando = false;
      });
      unawaited(_controller.start());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível buscar a prova. Verifique sua conexão '
            'e tente novamente.';
        _processando = false;
      });
      unawaited(_controller.start());
    }
  }

  Future<void> _mostrarQrDeTeste() async {
    final messenger = ScaffoldMessenger.of(context);
    final payload = await _repositorio.buscarQrDeTeste();
    if (!mounted) return;

    if (payload == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhuma prova foi gerada ainda em "Criar Prova" — gere uma '
            'prova primeiro para ter um QR Code para testar.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QR Code de teste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aponte a câmera de outro dispositivo (ou a sua, trocando de '
              'tela) para este código, só para testar a leitura.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            QrImageView(data: payload.codificar(), size: 200),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: SizedBox(
                height: 280,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) => _SemCameraAviso(
                        onUsarCodigoManual: () =>
                            setState(() => _mostrarEntradaManual = true),
                      ),
                    ),
                    if (_processando)
                      Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _processando
                  ? 'Buscando a prova...'
                  : 'Aponte a câmera para o QR Code da folha de respostas',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (_erro != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _erro!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _mostrarEntradaManual = !_mostrarEntradaManual),
              icon: const Icon(Icons.keyboard_outlined),
              label: Text(
                _mostrarEntradaManual
                    ? 'Ocultar código manual'
                    : 'Não consegue usar a câmera? Informe o código manualmente',
              ),
            ),
            if (_mostrarEntradaManual) ...[
              TextField(
                controller: _codigoManualController,
                decoration: const InputDecoration(
                  labelText: 'Código do QR Code',
                  hintText: 'provalab://prova/...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: _processando
                    ? null
                    : () => _processarCodigo(_codigoManualController.text),
                child: const Text('Buscar prova'),
              ),
            ],
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _mostrarQrDeTeste,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Ver QR Code de teste'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemCameraAviso extends StatelessWidget {
  final VoidCallback onUsarCodigoManual;

  const _SemCameraAviso({required this.onUsarCodigoManual});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_outlined,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Não foi possível acessar a câmera. Verifique a permissão do '
            'app ou informe o código manualmente abaixo.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

