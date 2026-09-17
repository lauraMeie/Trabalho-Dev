import 'package:flutter/material.dart';
import '../../models/turma.dart';
import '../../theme/app_theme.dart';

/// Tela de cadastro/edição de turma (MOCK — N1).
/// Se `turmaParaEditar` for informado, a tela entra em modo de edição.
class CadastroTurmaScreen extends StatefulWidget {
  final Turma? turmaParaEditar;

  const CadastroTurmaScreen({super.key, this.turmaParaEditar});

  @override
  State<CadastroTurmaScreen> createState() => _CadastroTurmaScreenState();
}

class _CadastroTurmaScreenState extends State<CadastroTurmaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;

  bool get _editando => widget.turmaParaEditar != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.turmaParaEditar?.nome ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      if (_editando) {
        // edição: altera o objeto existente e avisa a tela anterior pra atualizar
        widget.turmaParaEditar!.nome = _nomeController.text.trim();
        Navigator.of(context).pop(true);
      } else {
        // criação: devolve uma turma nova
        final turma = Turma(_nomeController.text.trim(), []);
        Navigator.of(context).pop(turma);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar turma' : 'Cadastrar turma')),
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
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Informe o nome da turma' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _salvar,
                child: Text(_editando ? 'Salvar alterações' : 'Salvar'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Text(
                  'Tela mock (N1) — turma fica só em memória, ainda sem banco de dados',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
