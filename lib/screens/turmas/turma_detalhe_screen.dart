import 'package:flutter/material.dart';

import '../../data/turmas_repository.dart';
import '../../models/aluno.dart';
import '../../models/turma.dart';
import '../../theme/app_theme.dart';
import '../../utils/busca_utils.dart';
import '../../utils/firestore_errors.dart';
import 'cadastro_aluno_screen.dart';
import 'campo_busca.dart';

/// Tela de alunos de uma turma (N2 — dados reais do Firestore), com CRUD completo.
class TurmaDetalheScreen extends StatefulWidget {
  final Turma turma;

  const TurmaDetalheScreen({super.key, required this.turma});

  @override
  State<TurmaDetalheScreen> createState() => _TurmaDetalheScreenState();
}

class _TurmaDetalheScreenState extends State<TurmaDetalheScreen> {
  final _repo = TurmasRepository();
  final _buscaController = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String get _turmaId => widget.turma.id!;

  void _abrirCadastroAluno([Aluno? aluno]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CadastroAlunoScreen(turmaId: _turmaId, alunoParaEditar: aluno),
      ),
    );
  }

  Future<void> _excluirAluno(Aluno aluno) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text(
          'Tem certeza que deseja excluir "${aluno.nome}" desta turma?',
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
    if (confirmar != true || aluno.id == null) return;

    try {
      await _repo.excluirAluno(_turmaId, aluno.id!);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(mensagemDeErro(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.turma.nome)),
      body: StreamBuilder<List<Aluno>>(
        stream: _repo.alunosStream(_turmaId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  mensagemDeErro(snapshot.error!),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alunos = snapshot.data!;
          if (alunos.isEmpty) {
            return const Center(
              child: Text('Nenhum aluno cadastrado nesta turma ainda.'),
            );
          }

          final visiveis = BuscaUtils.filtrarAlunos(alunos, _busca);
          return Column(
            children: [
              CampoBusca(
                controller: _buscaController,
                hint: 'Buscar por nome ou matrícula',
                onChanged: (valor) => setState(() => _busca = valor),
              ),
              Expanded(
                child: visiveis.isEmpty
                    ? const Center(child: Text('Nenhum aluno encontrado.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: visiveis.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final aluno = visiveis[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                              ),
                              title: Text(aluno.nome),
                              subtitle: Text('Matrícula: ${aluno.matricula}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (valor) {
                                  if (valor == 'editar') {
                                    _abrirCadastroAluno(aluno);
                                  }
                                  if (valor == 'excluir') {
                                    _excluirAluno(aluno);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'excluir',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirCadastroAluno(),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Adicionar aluno'),
      ),
    );
  }
}
