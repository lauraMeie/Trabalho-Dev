import 'package:flutter/material.dart';
import '../../data/turmas_repository.dart';
import '../../models/turma.dart';
import '../../theme/app_theme.dart';
import 'cadastro_turma_screen.dart';
import 'turma_detalhe_screen.dart';

/// Tela de lista de turmas (N2 — dados reais do Firestore), com CRUD completo.
class TurmasScreen extends StatefulWidget {
  const TurmasScreen({super.key});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  final _repo = TurmasRepository();

  void _abrirCadastroTurma([Turma? turma]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CadastroTurmaScreen(turmaParaEditar: turma),
      ),
    );
  }

  Future<void> _excluirTurma(Turma turma) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir turma'),
        content: Text(
          'Tem certeza que deseja excluir "${turma.nome}" e todos os seus alunos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || turma.id == null) return;

    try {
      await _repo.excluirTurma(turma.id!);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível excluir a turma: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turmas')),
      body: StreamBuilder<List<Turma>>(
        stream: _repo.turmasStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Erro ao carregar as turmas: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final turmas = snapshot.data!;
          if (turmas.isEmpty) {
            return const Center(child: Text('Nenhuma turma cadastrada ainda.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: turmas.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final turma = turmas[index];
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
                    child: const Icon(
                      Icons.groups_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    turma.nome,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text('${turma.quantidadeAlunos} aluno(s)'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (valor) {
                      if (valor == 'editar') _abrirCadastroTurma(turma);
                      if (valor == 'excluir') _excluirTurma(turma);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TurmaDetalheScreen(turma: turma),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirCadastroTurma(),
        icon: const Icon(Icons.add),
        label: const Text('Nova turma'),
      ),
    );
  }
}
