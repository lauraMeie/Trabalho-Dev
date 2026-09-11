import 'package:flutter/material.dart';
import '../../models/turma.dart';
import '../../theme/app_theme.dart';
import 'cadastro_aluno_screen.dart';

/// Tela de lista de alunos de uma turma (MOCK — N1).
class TurmaDetalheScreen extends StatefulWidget {
  final Turma turma;

  const TurmaDetalheScreen({super.key, required this.turma});

  @override
  State<TurmaDetalheScreen> createState() => _TurmaDetalheScreenState();
}

class _TurmaDetalheScreenState extends State<TurmaDetalheScreen> {
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
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final novoAluno = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CadastroAlunoScreen()),
          );
          if (novoAluno != null) {
            setState(() {
              widget.turma.alunos.add(novoAluno);
            });
          }
        },
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Adicionar aluno'),
      ),
    );
  }
}
