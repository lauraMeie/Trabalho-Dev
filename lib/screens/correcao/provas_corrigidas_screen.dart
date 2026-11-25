import 'package:flutter/material.dart';

import '../../models/correction_result.dart';
import '../../routes/app_routes.dart';
import '../../services/correcao_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/firestore_errors.dart';
import 'resultado_correcao_screen.dart';

/// Lista todas as provas já corrigidas pelo professor logado (RF-13),
/// lidas em tempo real do Firestore. Tocar numa correção abre o resultado
/// detalhado dela.
class ProvasCorrigidasScreen extends StatefulWidget {
  /// Correções a exibir. Se não for informado, usa
  /// [CorrecaoRepository.observarResultados] (permite testar sem Firebase).
  final Stream<List<ResultadoCorrecao>>? resultados;

  const ProvasCorrigidasScreen({super.key, this.resultados});

  @override
  State<ProvasCorrigidasScreen> createState() => _ProvasCorrigidasScreenState();
}

class _ProvasCorrigidasScreenState extends State<ProvasCorrigidasScreen> {
  late final Stream<List<ResultadoCorrecao>> _resultados =
      widget.resultados ?? CorrecaoRepository().observarResultados();

  /// Turma selecionada no filtro (null = todas).
  String? _turmaFiltro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provas corrigidas')),
      body: StreamBuilder<List<ResultadoCorrecao>>(
        stream: _resultados,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MensagemCentral(
              icone: Icons.error_outline,
              texto: mensagemDeErro(snapshot.error!),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!;
          if (todos.isEmpty) {
            return const _MensagemCentral(
              icone: Icons.inbox_outlined,
              texto:
                  'Nenhuma prova corrigida ainda.\n'
                  'As correções aparecem aqui assim que forem salvas.',
            );
          }

          final turmas = todos.map((r) => r.turma).toSet().toList()..sort();
          final turmaFiltro = turmas.contains(_turmaFiltro)
              ? _turmaFiltro
              : null;
          final filtrados = turmaFiltro == null
              ? todos
              : todos.where((r) => r.turma == turmaFiltro).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (turmas.length > 1) ...[
                DropdownButtonFormField<String?>(
                  initialValue: turmaFiltro,
                  decoration: const InputDecoration(labelText: 'Turma'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas as turmas'),
                    ),
                    ...turmas.map(
                      (t) =>
                          DropdownMenuItem<String?>(value: t, child: Text(t)),
                    ),
                  ],
                  onChanged: (valor) => setState(() => _turmaFiltro = valor),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                '${filtrados.length} '
                '${filtrados.length == 1 ? 'prova corrigida' : 'provas corrigidas'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...filtrados.map(
                (resultado) => ResultadoCorrecaoTile(
                  resultado: resultado,
                  mostrarData: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Abre o resultado detalhado de uma correção já salva.
void abrirResultadoCorrecao(BuildContext context, ResultadoCorrecao resultado) {
  Navigator.of(context).push(
    MaterialPageRoute(
      settings: const RouteSettings(name: AppRoutes.corrigirProvaResultado),
      builder: (_) => ResultadoCorrecaoScreen(resultado: resultado),
    ),
  );
}

/// Formata a data no padrão brasileiro (dd/mm/aaaa hh:mm).
String formatarDataCorrecao(DateTime data) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
      '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}

/// Item de lista de uma correção: aluno, turma, data e nota. Tocar abre o
/// resultado detalhado.
class ResultadoCorrecaoTile extends StatelessWidget {
  final ResultadoCorrecao resultado;
  final bool mostrarData;

  const ResultadoCorrecaoTile({
    super.key,
    required this.resultado,
    this.mostrarData = false,
  });

  @override
  Widget build(BuildContext context) {
    final aluno = resultado.aluno.isEmpty ? '(sem nome)' : resultado.aluno;
    final detalhes = [
      resultado.turma,
      '${resultado.acertos}/${resultado.totalQuestoes} acertos',
      if (mostrarData) formatarDataCorrecao(resultado.corrigidoEm),
    ].where((t) => t.isNotEmpty).join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => abrirResultadoCorrecao(context, resultado),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          foregroundColor: AppColors.primary,
          child: Text(resultado.nota.toStringAsFixed(0)),
        ),
        title: Text(aluno),
        subtitle: Text(detalhes),
        trailing: Text(
          resultado.nota.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _MensagemCentral extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _MensagemCentral({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
