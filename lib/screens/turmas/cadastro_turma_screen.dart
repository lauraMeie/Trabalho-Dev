import 'package:flutter/material.dart';
import '../../data/turmas_repository.dart';
import '../../models/turma.dart';
import '../../theme/app_theme.dart';

/// Tela de cadastro/edição de turma (N2 — grava no Firestore).
/// Se `turmaParaEditar` for informado, a tela entra em modo de edição.
class CadastroTurmaScreen extends StatefulWidget {
  final Turma? turmaParaEditar;

  const CadastroTurmaScreen({super.key, this.turmaParaEditar});

  @override
  State<CadastroTurmaScreen> createState() => _CadastroTurmaScreenState();
}

class _CadastroTurmaScreenState extends State<CadastroTurmaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TurmasRepository();
  late final TextEditingController _nomeController;
  bool _salvando = false;

  bool get _editando => widget.turmaParaEditar != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.turmaParaEditar?.nome ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final nome = _nomeController.text.trim();
    setState(() => _salvando = true);

    try {
      if (_editando) {
        await _repo.atualizarTurma(widget.turmaParaEditar!.id!, nome);
      } else {
        await _repo.criarTurma(nome);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a turma: $e')),
      );
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar turma' : 'Cadastrar turma'),
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
                  labelText: 'Nome da turma',
                  hintText: 'Ex.: 3º Ano C - ADS',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe o nome da turma'
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
