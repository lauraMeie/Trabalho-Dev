import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../utils/question_validator.dart';

/// Abre o formulário de questão. Se [questao] for informada, o formulário
/// abre em modo EDIÇÃO (já preenchido); senão, em modo CRIAÇÃO.
///
/// Devolve a [Question] preenchida (já validada) quando o professor toca em
/// Salvar, ou `null` se cancelar. Quem chama é que grava no Firestore.
/// Em modo criação o `id` da questão devolvida é vazio ('').
Future<Question?> mostrarFormularioQuestao(
  BuildContext context, {
  Question? questao,
}) {
  return showDialog<Question>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _QuestionFormDialog(questao: questao),
  );
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({this.questao});

  final Question? questao;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _materiaController;
  late final TextEditingController _enunciadoController;
  late final List<TextEditingController> _alternativasControllers;
  int? _indiceCorreto;

  bool get _editando => widget.questao != null;

  @override
  void initState() {
    super.initState();
    final q = widget.questao;
    _materiaController = TextEditingController(text: q?.subject ?? '');
    _enunciadoController = TextEditingController(text: q?.statement ?? '');
    _alternativasControllers = List.generate(
      Question.quantidadeAlternativas,
      (i) => TextEditingController(text: q?.alternatives[i] ?? ''),
    );
    _indiceCorreto = q?.correctIndex; // null ao criar: professor precisa marcar
  }

  @override
  void dispose() {
    _materiaController.dispose();
    _enunciadoController.dispose();
    for (final c in _alternativasControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Textos de todas as alternativas, menos a de posição [indice].
  List<String> _outrasAlternativas(int indice) {
    return [
      for (int i = 0; i < _alternativasControllers.length; i++)
        if (i != indice) _alternativasControllers[i].text,
    ];
  }

  void _salvar() {
    // validate() roda TODOS os validators e mostra os erros nos campos.
    if (!_formKey.currentState!.validate()) return;

    final resultado = Question(
      id: widget.questao?.id ?? '',
      subject: _materiaController.text.trim(),
      statement: _enunciadoController.text.trim(),
      alternatives:
          _alternativasControllers.map((c) => c.text.trim()).toList(),
      correctIndex: _indiceCorreto!,
    );
    Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar questão' : 'Nova questão'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _materiaController,
                  decoration: const InputDecoration(labelText: 'Matéria'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: QuestionValidator.materia,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _enunciadoController,
                  decoration: const InputDecoration(labelText: 'Enunciado'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: QuestionValidator.enunciado,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 12),
                const Text('Alternativas (toque no círculo da correta):'),
                // O FormField<int> faz a escolha da alternativa correta
                // participar da validação do Form.
                FormField<int>(
                  initialValue: _indiceCorreto,
                  validator: (_) =>
                      QuestionValidator.alternativaCorreta(_indiceCorreto),
                  builder: (campo) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < _alternativasControllers.length; i++)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                tooltip: 'Marcar como correta',
                                icon: Icon(
                                  _indiceCorreto == i
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                ),
                                onPressed: () {
                                  setState(() => _indiceCorreto = i);
                                  campo.didChange(i);
                                },
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _alternativasControllers[i],
                                  decoration: InputDecoration(
                                    labelText:
                                        'Alternativa ${String.fromCharCode(65 + i)}',
                                  ),
                                  validator: (v) => QuestionValidator.alternativa(
                                    v,
                                    outras: _outrasAlternativas(i),
                                  ),
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                              ),
                            ],
                          ),
                        if (campo.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              campo.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
