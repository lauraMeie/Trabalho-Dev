import 'package:flutter/material.dart';
import '../../models/aluno.dart';
import '../../models/turma.dart';
import '../../theme/app_theme.dart';
import 'cadastro_aluno_screen.dart';

/// Tela de lista de alunos de uma turma (MOCK — N1), com CRUD completo de alunos.
class TurmaDetalheScreen extends StatefulWidget {
  final Turma turma;

  const TurmaDetalheScreen({super.key, required this.turma});

  @override
  State<TurmaDetalheScreen> createState() => _TurmaDetalheScreenState();
}

class _TurmaDetalheScreenState extends State<TurmaDetalheScreen> {
  Future<void> _adicionarAluno() async {
    final novoAluno = await Navigator.of(context).push<Aluno>(
      MaterialPageRoute(builder: (_) => const CadastroAlunoScreen()),
    );
    if (novoAluno != null) {
      setState(() => widget.turma.alunos.add(novoAluno));
    }
  }

  Future<void> _editarAluno(Aluno aluno) async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CadastroAlunoScreen(alunoParaEditar: aluno)),
    );
    if (alterou == true) setState(() {});
  }

  Future<void> _excluirAluno(Aluno aluno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text('Tem certeza que deseja excluir "${aluno.nome}" desta turma?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar == true) {
      setState(() => widget.turma.alunos.remove(aluno));
    }
  }

  @override
  Widget build(BuildContext context) {
    final alunos = widget.turma.alunos;
    return Scaffold(
      appBar: AppBar(title: Text(widget.turma.nome)),
      body: alunos.isEmpty
          ? const Center(child: Text('Nenhum aluno cadastrado nesta turma ainda.'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: alunos.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final aluno = alunos[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.primary),
                    title: Text(aluno.nome),
                    subtitle: Text('Matrícula: ${aluno.matricula}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (valor) {
                        if (valor == 'editar') _editarAluno(aluno);
                        if (valor == 'excluir') _excluirAluno(aluno);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarAluno,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Adicionar aluno'),
      ),
    );
  }
}
