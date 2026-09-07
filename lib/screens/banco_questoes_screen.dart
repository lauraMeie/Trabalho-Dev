import 'package:flutter/material.dart';

import '../data/question_bank.dart';
import '../models/question.dart';
import '../utils/exam_generator.dart';

/// Tela "Banco de Questões": lista as questões cadastradas, permite
/// criar uma nova questão (mock, sem persistência real na N1) e mostra
/// uma prévia de como fica uma prova gerada com alternativas embaralhadas.
class BancoQuestoesScreen extends StatefulWidget {
  const BancoQuestoesScreen({super.key});

  @override
  State<BancoQuestoesScreen> createState() => _BancoQuestoesScreenState();
}

class _BancoQuestoesScreenState extends State<BancoQuestoesScreen> {
  // Cópia local (mock) do banco de questões. Como a N1 não tem
  // persistência real, as questões criadas aqui existem só na sessão.
  late List<Question> _questoes;

  @override
  void initState() {
    super.initState();
    _questoes = List<Question>.from(questionBank);
  }

  void _abrirFormularioNovaQuestao() {
    final subjectController = TextEditingController();
    final statementController = TextEditingController();
    final alternativeControllers = List.generate(5, (_) => TextEditingController());
    int correctIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova questão'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(labelText: 'Matéria'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: statementController,
                      decoration: const InputDecoration(labelText: 'Enunciado'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    const Text('Alternativas (toque no círculo da correta):'),
                    for (int i = 0; i < 5; i++)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              correctIndex == i
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                            onPressed: () {
                              setDialogState(() => correctIndex = i);
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: alternativeControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Alternativa ${String.fromCharCode(65 + i)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final novaQuestao = Question(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      subject: subjectController.text.trim().isEmpty
                          ? 'Geral'
                          : subjectController.text.trim(),
                      statement: statementController.text.trim(),
                      alternatives: alternativeControllers.map((c) => c.text.trim()).toList(),
                      correctIndex: correctIndex,
                    );
                    setState(() => _questoes.add(novaQuestao));
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _visualizarProvaGerada() {
    final provaGerada = ExamGenerator.gerarProva(quantidade: 5);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prévia de prova gerada'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provaGerada.length,
            itemBuilder: (context, index) {
              final questao = provaGerada[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${questao.statement}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (int i = 0; i < questao.alternatives.length; i++)
                      Text('${String.fromCharCode(65 + i)}) ${questao.alternatives[i]}'),
                    Text(
                      'Gabarito: ${questao.correctLetter}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco de Questões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Ver exemplo de prova gerada',
            onPressed: _visualizarProvaGerada,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _questoes.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final questao = _questoes[index];
          return ExpansionTile(
            title: Text(questao.statement),
            subtitle: Text(questao.subject),
            children: [
              for (int i = 0; i < questao.alternatives.length; i++)
                ListTile(
                  dense: true,
                  leading: Text(String.fromCharCode(65 + i)),
                  title: Text(questao.alternatives[i]),
                  trailing: i == questao.correctIndex
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioNovaQuestao,
        icon: const Icon(Icons.add),
        label: const Text('Criar questão'),
      ),
    );
  }
}
