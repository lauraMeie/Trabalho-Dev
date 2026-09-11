import 'package:flutter/material.dart';
import '../../data/turmas_mock.dart';
import '../../models/turma.dart';
import '../../theme/app_theme.dart';
import 'turma_detalhe_screen.dart';

/// Tela de lista de turmas (MOCK — N1).
/// Mostra as turmas fictícias e navega para o detalhe de cada uma.
class TurmasScreen extends StatefulWidget {
  const TurmasScreen({super.key});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  late List<Turma> _turmas;

  @override
  void initState() {
    super.initState();
    _turmas = turmasMock;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turmas')),
      body: _turmas.isEmpty
          ? const Center(child: Text('Nenhuma turma cadastrada ainda.'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _turmas.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final turma = _turmas[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: const Icon(Icons.groups_outlined, color: AppColors.primary),
                    ),
                    title: Text(turma.nome, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text('${turma.quantidadeAlunos} aluno(s)'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TurmaDetalheScreen(turma: turma),
                        ),
                      );
                      setState(() {}); // atualiza a contagem de alunos ao voltar
                    },
                  ),
                );
              },
            ),
    );
  }
}
