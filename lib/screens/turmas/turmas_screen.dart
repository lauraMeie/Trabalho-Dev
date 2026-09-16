import 'package:flutter/material.dart';
import '../../data/turmas_mock.dart';
import '../../models/turma.dart';
import '../../theme/app_theme.dart';
import 'cadastro_turma_screen.dart';
import 'turma_detalhe_screen.dart';

/// Tela de lista de turmas (MOCK — N1), com CRUD completo de turmas.
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

  Future<void> _abrirCadastroTurma() async {
    final novaTurma = await Navigator.of(context).push<Turma>(
      MaterialPageRoute(builder: (_) => const CadastroTurmaScreen()),
    );
    if (novaTurma != null) {
      setState(() => _turmas.add(novaTurma));
    }
  }

  Future<void> _editarTurma(Turma turma) async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CadastroTurmaScreen(turmaParaEditar: turma)),
    );
    if (alterou == true) setState(() {});
  }

  Future<void> _excluirTurma(Turma turma) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir turma'),
        content: Text('Tem certeza que deseja excluir "${turma.nome}" e todos os seus alunos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar == true) {
      setState(() => _turmas.remove(turma));
    }
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
                    trailing: PopupMenuButton<String>(
                      onSelected: (valor) {
                        if (valor == 'editar') _editarTurma(turma);
                        if (valor == 'excluir') _excluirTurma(turma);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TurmaDetalheScreen(turma: turma)),
                      );
                      setState(() {}); // atualiza a contagem de alunos ao voltar
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCadastroTurma,
        icon: const Icon(Icons.add),
        label: const Text('Nova turma'),
      ),
    );
  }
}
