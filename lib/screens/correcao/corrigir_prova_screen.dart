import 'package:flutter/material.dart';

import '../../models/correction_result.dart';
import '../../routes/app_routes.dart';
import '../../services/correcao_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/firestore_errors.dart';
import 'provas_corrigidas_screen.dart';
import 'qrcode_screen.dart';

/// Ponto de partida do fluxo de correção (RF06/RF07): explica os passos e
/// permite iniciar uma nova correção (escaneando o QR Code real da folha
/// de respostas) ou ver as últimas provas já corrigidas.
class CorrigirProvaScreen extends StatelessWidget {
  const CorrigirProvaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrigir Prova'),
        actions: [
          IconButton(
            tooltip: 'Voltar para a Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.of(
              context,
            ).popUntil((route) => route.settings.name == AppRoutes.home),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Icon(Icons.fact_check_outlined, size: 64, color: AppColors.primary),
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
                    descricao: 'Identifica a prova e o aluno pela câmera.',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _EtapaFluxo(
                    numero: '2',
                    titulo: 'Leitura das respostas',
                    descricao: 'Fotografe a folha e o app lê as marcações.',
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
                builder: (_) => const QrCodeScreen(),
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
          const SizedBox(height: AppSpacing.xl),
          _UltimasCorrecoes(repositorio: CorrecaoRepository()),
        ],
      ),
    );
  }
}

class _UltimasCorrecoes extends StatelessWidget {
  final CorrecaoRepository repositorio;

  const _UltimasCorrecoes({required this.repositorio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Últimas correções',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.provasCorrigidas),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<List<ResultadoCorrecao>>(
          stream: repositorio.observarResultados(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                mensagemDeErro(snapshot.error!),
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final ultimasCorrecoes = snapshot.data!.take(3).toList();
            if (ultimasCorrecoes.isEmpty) {
              return Text(
                'Nenhuma prova corrigida ainda.',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            return Column(
              children: ultimasCorrecoes
                  .map(
                    (resultado) => ResultadoCorrecaoTile(resultado: resultado),
                  )
                  .toList(),
            );
          },
        ),
      ],
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
