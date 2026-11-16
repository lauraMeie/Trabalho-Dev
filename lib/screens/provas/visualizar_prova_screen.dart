import 'package:flutter/material.dart';
import '../../models/prova_gerada.dart';
import '../../services/prova_consulta_repository.dart';
import '../../utils/exam_generator.dart';

class VisualizarProvaScreen extends StatefulWidget {
  final String provaId;
  const VisualizarProvaScreen({super.key, required this.provaId});
  @override
  State<VisualizarProvaScreen> createState() => _VisualizarProvaScreenState();
}

class _VisualizarProvaScreenState extends State<VisualizarProvaScreen> {
  final _repository = ProvaConsultaRepository();
  late Future<ProvaGerada> _future;
  @override
  void initState() { super.initState(); _recarregar(); }
  void _recarregar() { _future = _repository.buscar(widget.provaId); }

  Future<void> _editar(ProvaGerada prova) async {
    final nome = TextEditingController(text: prova.nome);
    final turma = TextEditingController(text: prova.turmaNome);
    var colunas = prova.colunas;
    var fonte = prova.tamanhoFonte;
    final resultado = await showDialog<ProvaGerada>(context: context, builder: (context) =>
      StatefulBuilder(builder: (context, atualizarDialogo) => AlertDialog(
        title: const Text('Editar prova'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
          TextField(controller: turma, decoration: const InputDecoration(labelText: 'Nome da turma')),
          DropdownButtonFormField<int>(initialValue: colunas, decoration: const InputDecoration(labelText: 'Colunas'),
            items: [1, 2].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
            onChanged: (v) { if (v != null) atualizarDialogo(() => colunas = v); }),
          Text('Tamanho da fonte: ${fonte.toStringAsFixed(0)}'),
          Slider(value: fonte.clamp(10, 24).toDouble(), min: 10, max: 24, divisions: 14,
            onChanged: (v) => atualizarDialogo(() => fonte = v)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (nome.text.trim().isEmpty || turma.text.trim().isEmpty) return;
            Navigator.pop(context, ProvaGerada(
              nome: nome.text.trim(), turmaNome: turma.text.trim(),
              mesmaProvaParaTodos: prova.mesmaProvaParaTodos,
              embaralhouQuestoes: prova.embaralhouQuestoes,
              embaralhouAlternativas: prova.embaralhouAlternativas,
              colunas: colunas, tamanhoFonte: fonte, provas: prova.provas));
          }, child: const Text('Salvar')),
        ],
      )));
    nome.dispose(); turma.dispose();
    if (resultado == null || !mounted) return;
    try {
      await _repository.atualizar(widget.provaId, resultado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prova atualizada.')));
      setState(_recarregar);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  Future<void> _editarQuestao(ProvaGerada prova, int versao, int indice) async {
    final original = prova.provas[versao].questoes[indice];
    final enunciado = TextEditingController(text: original.statement);
    final alternativas = original.alternatives.map((a) => TextEditingController(text: a)).toList();
    var correta = original.correctIndex;
    final nova = await showDialog<GeneratedQuestion>(context: context,
      builder: (context) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
        title: const Text('Editar questão'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: enunciado, maxLines: 3, decoration: const InputDecoration(labelText: 'Enunciado')),
          for (var i = 0; i < alternativas.length; i++)
            TextField(controller: alternativas[i], decoration: InputDecoration(labelText: 'Alternativa ${String.fromCharCode(65 + i)}')),
          DropdownButtonFormField<int>(initialValue: correta,
            decoration: const InputDecoration(labelText: 'Alternativa correta'),
            items: List.generate(alternativas.length, (i) => DropdownMenuItem(
              value: i, child: Text(String.fromCharCode(65 + i)))),
            onChanged: (v) { if (v != null) refresh(() => correta = v); }),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (enunciado.text.trim().isEmpty || alternativas.any((a) => a.text.trim().isEmpty)) return;
            Navigator.pop(context, GeneratedQuestion(
              originalId: original.originalId, subject: original.subject,
              statement: enunciado.text.trim(),
              alternatives: alternativas.map((a) => a.text.trim()).toList(),
              correctIndex: correta));
          }, child: const Text('Salvar')),
        ],
      )));
    enunciado.dispose();
    for (final a in alternativas) { a.dispose(); }
    if (nova == null || !mounted) return;
    final versoes = <ProvaDoAluno>[];
    for (var i = 0; i < prova.provas.length; i++) {
      final atual = prova.provas[i];
      final questoes = List<GeneratedQuestion>.from(atual.questoes);
      if (i == versao) questoes[indice] = nova;
      versoes.add(ProvaDoAluno(aluno: atual.aluno, matricula: atual.matricula, questoes: questoes));
    }
    final alterada = ProvaGerada(nome: prova.nome, turmaNome: prova.turmaNome,
      mesmaProvaParaTodos: prova.mesmaProvaParaTodos,
      embaralhouQuestoes: prova.embaralhouQuestoes,
      embaralhouAlternativas: prova.embaralhouAlternativas,
      colunas: prova.colunas, tamanhoFonte: prova.tamanhoFonte, provas: versoes);
    try {
      await _repository.atualizar(widget.provaId, alterada);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Questão atualizada.')));
      setState(_recarregar);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar questão: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Visualizar Prova')),
    body: FutureBuilder<ProvaGerada>(future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
      final prova = snapshot.data!;
      return ListView(padding: const EdgeInsets.all(16), children: [
        Text(prova.nome, style: Theme.of(context).textTheme.headlineSmall),
        Text('Turma: ${prova.turmaNome}'),
        Text('${prova.provas.length} versão(ões) da prova'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () => _editar(prova), icon: const Icon(Icons.edit),
          label: const Text('Editar dados e layout')),
        const SizedBox(height: 12),
        for (var i = 0; i < prova.provas.length; i++) ...[
          ExpansionTile(title: Text(prova.provas[i].aluno ?? 'Prova única'),
            subtitle: Text('${prova.provas[i].questoes.length} questões'),
            children: [for (var j = 0; j < prova.provas[i].questoes.length; j++)
              _QuestaoCard(indice: j + 1, questao: prova.provas[i].questoes[j],
                onEditar: () => _editarQuestao(prova, i, j))]),
        ],
      ]);
    }),
  );
}

class _QuestaoCard extends StatelessWidget {
  final int indice;
  final GeneratedQuestion questao;
  final VoidCallback onEditar;
  const _QuestaoCard({required this.indice, required this.questao, required this.onEditar});
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$indice. ${questao.statement}', style: const TextStyle(fontWeight: FontWeight.bold)),
        for (var i = 0; i < questao.alternatives.length; i++)
          Text('${String.fromCharCode(65 + i)}) ${questao.alternatives[i]}'),
        Text('Gabarito: ${questao.correctLetter}'),
        TextButton.icon(onPressed: onEditar, icon: const Icon(Icons.edit), label: const Text('Editar questão')),
      ]),
  ));
}
