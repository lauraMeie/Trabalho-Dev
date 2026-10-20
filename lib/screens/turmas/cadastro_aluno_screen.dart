import 'package:flutter/material.dart';
import '../../data/turmas_repository.dart';
import '../../models/aluno.dart';
import '../../theme/app_theme.dart';

/// Tela de cadastro/edição de aluno (N2 — grava no Firestore).
/// Se `alunoParaEditar` for informado, a tela entra em modo de edição.
class CadastroAlunoScreen extends StatefulWidget {
  final String turmaId;
  final Aluno? alunoParaEditar;

  const CadastroAlunoScreen({
    super.key,
    required this.turmaId,
    this.alunoParaEditar,
  });

  @override
  State<CadastroAlunoScreen> createState() => _CadastroAlunoScreenState();
}

class _CadastroAlunoScreenState extends State<CadastroAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TurmasRepository();
  late final TextEditingController _nomeController;
  late final TextEditingController _matriculaController;
  bool _salvando = false;

  bool get _editando => widget.alunoParaEditar != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.alunoParaEditar?.nome ?? '',
    );
    _matriculaController = TextEditingController(
      text: widget.alunoParaEditar?.matricula ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final nome = _nomeController.text.trim();
    final matricula = _matriculaController.text.trim();
    setState(() => _salvando = true);

    try {
      if (_editando) {
        final original = widget.alunoParaEditar!;
        await _repo.atualizarAluno(
          widget.turmaId,
          Aluno(nome, matricula, id: original.id),
        );
      } else {
        await _repo.criarAluno(widget.turmaId, Aluno(nome, matricula));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o aluno: $e')),
      );
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar aluno' : 'Cadastrar aluno'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do aluno',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  labelText: 'Matrícula',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe a matrícula'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editando ? 'Salvar alterações' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
