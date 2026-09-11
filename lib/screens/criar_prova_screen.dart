import 'package:flutter/material.dart';

import '../data/mock_questoes.dart';
import '../models/prova_config.dart';
import '../models/question.dart';

/// Tela "Criar Prova" (Fase N1 - dados mock, sem persistência real).
///
/// Cobre os requisitos:
/// - RF01: montar a prova a partir do banco de questões
/// - RF03: randomizar ordem das questões e alternativas
/// - RF04: escolher mesma prova para todos ou provas diferentes por aluno
/// - RF14: editar o layout da prova gerada
///
/// Organizada em 4 etapas (Stepper): selecionar questões, configurar
/// prova, embaralhamento e tela da prova (preview final).
///
/// Usa o model [Question] (lib/question.dart) do Banco de Questões, onde
/// toda questão tem sempre 5 alternativas (A a E).
class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  int _etapaAtual = 0;

  final Set<String> _questoesSelecionadasIds = {};
  String? _filtroDisciplina;

  final ConfiguracaoProva _config = ConfiguracaoProva();
  final _nomeProvaController = TextEditingController();

  List<Question> get _questoesFiltradas {
    if (_filtroDisciplina == null) return mockQuestoes;
    return mockQuestoes
        .where((q) => q.subject == _filtroDisciplina)
        .toList();
  }

  List<Question> get _questoesSelecionadas {
    final selecionadas = mockQuestoes
        .where((q) => _questoesSelecionadasIds.contains(q.id))
        .toList();
    if (_config.embaralharQuestoes) {
      selecionadas.shuffle();
    }
    return selecionadas;
  }

  @override
  void dispose() {
    _nomeProvaController.dispose();
    super.dispose();
  }

  bool _podeAvancar(int etapa) {
    switch (etapa) {
      case 0:
        return _questoesSelecionadasIds.isNotEmpty;
      case 1:
        return _nomeProvaController.text.trim().isNotEmpty &&
            _config.turma != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Prova'),
      ),
      body: Stepper(
        currentStep: _etapaAtual,
        onStepTapped: (step) {
          // Só permite pular para uma etapa se as anteriores estiverem OK.
          if (step <= _etapaAtual || _podeAvancar(_etapaAtual)) {
            setState(() => _etapaAtual = step);
          }
        },
        onStepContinue: () {
          if (!_podeAvancar(_etapaAtual)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complete esta etapa antes de continuar.'),
              ),
            );
            return;
          }
          if (_etapaAtual < 3) {
            setState(() => _etapaAtual += 1);
          }
        },
        onStepCancel: () {
          if (_etapaAtual > 0) {
            setState(() => _etapaAtual -= 1);
          }
        },
        controlsBuilder: (context, details) {
          final ultimaEtapa = _etapaAtual == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (!ultimaEtapa)
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continuar'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _mostrarProvaGerada(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Gerar Prova'),
                  ),
                const SizedBox(width: 12),
                if (_etapaAtual > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Voltar'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Selecionar questões'),
            isActive: _etapaAtual >= 0,
            state: _etapaAtual > 0 ? StepState.complete : StepState.indexed,
            content: _buildSelecaoQuestoes(colorScheme),
          ),
          Step(
            title: const Text('Configurar prova'),
            isActive: _etapaAtual >= 1,
            state: _etapaAtual > 1 ? StepState.complete : StepState.indexed,
            content: _buildConfiguracaoProva(),
          ),
          Step(
            title: const Text('Embaralhamento'),
            isActive: _etapaAtual >= 2,
            state: _etapaAtual > 2 ? StepState.complete : StepState.indexed,
            content: _buildEmbaralhamento(),
          ),
          Step(
            title: const Text('Tela da prova'),
            isActive: _etapaAtual >= 3,
            content: _buildPreviewProva(colorScheme),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Etapa 1: Selecionar questões (RF01, RF02 - usa o banco de questões)
  // ---------------------------------------------------------------------
  Widget _buildSelecaoQuestoes(ColorScheme colorScheme) {
    final disciplinas = mockQuestoes.map((q) => q.subject).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_questoesSelecionadasIds.length} questão(ões) selecionada(s)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: _filtroDisciplina == null,
              onSelected: (_) => setState(() => _filtroDisciplina = null),
            ),
            ...disciplinas.map(
              (d) => ChoiceChip(
                label: Text(d),
                selected: _filtroDisciplina == d,
                onSelected: (_) => setState(() => _filtroDisciplina = d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questoesFiltradas.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final questao = _questoesFiltradas[index];
            final selecionada = _questoesSelecionadasIds.contains(questao.id);
            return CheckboxListTile(
              value: selecionada,
              contentPadding: EdgeInsets.zero,
              title: Text(
                questao.statement,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(questao.subject),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _questoesSelecionadasIds.add(questao.id);
                  } else {
                    _questoesSelecionadasIds.remove(questao.id);
                  }
                });
              },
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Etapa 2: Configurar prova (RF04 - individual x mesma prova)
  // ---------------------------------------------------------------------
  Widget _buildConfiguracaoProva() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nomeProvaController,
          decoration: const InputDecoration(
            labelText: 'Nome da prova',
            hintText: 'Ex: Avaliação Bimestral - Matemática',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Turma>(
          initialValue: _config.turma,
          decoration: const InputDecoration(
            labelText: 'Turma',
            border: OutlineInputBorder(),
          ),
          items: mockTurmas
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text('${t.nome} (${t.numAlunos} alunos)'),
                ),
              )
              .toList(),
          onChanged: (turma) => setState(() => _config.turma = turma),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mesma prova para todos os alunos'),
                  subtitle: const Text(
                      'Todos recebem as mesmas questões e alternativas'),
                  value: true,
                  groupValue: _config.mesmaProvaParaTodos,
                  onChanged: (v) =>
                      setState(() => _config.mesmaProvaParaTodos = v!),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Provas individualizadas por aluno'),
                  subtitle: const Text(
                      'Cada aluno recebe uma prova identificável e única'),
                  value: false,
                  groupValue: _config.mesmaProvaParaTodos,
                  onChanged: (v) =>
                      setState(() => _config.mesmaProvaParaTodos = v!),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Etapa 3: Embaralhamento (RF03)
  // ---------------------------------------------------------------------
  Widget _buildEmbaralhamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Embaralhar ordem das questões'),
          subtitle: const Text(
              'Cada prova gerada terá as questões em uma ordem diferente'),
          value: _config.embaralharQuestoes,
          onChanged: (v) => setState(() => _config.embaralharQuestoes = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Embaralhar ordem das alternativas'),
          subtitle: const Text(
              'As alternativas (A a E) mudam de posição entre provas'),
          value: _config.embaralharAlternativas,
          onChanged: (v) =>
              setState(() => _config.embaralharAlternativas = v),
        ),
        if (!_config.mesmaProvaParaTodos)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Como você escolheu provas individualizadas, o embaralhamento '
              'será aplicado de forma independente para cada aluno.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Etapa 4: Tela da prova / preview (RF14 - editar layout)
  // ---------------------------------------------------------------------
  Widget _buildPreviewProva(ColorScheme colorScheme) {
    final questoes = _questoesSelecionadas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout da prova',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Colunas:'),
            const SizedBox(width: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
              ],
              selected: {_config.colunas},
              onSelectionChanged: (v) =>
                  setState(() => _config.colunas = v.first),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Tamanho da fonte:'),
            Expanded(
              child: Slider(
                value: _config.tamanhoFonte,
                min: 10,
                max: 20,
                divisions: 10,
                label: _config.tamanhoFonte.toStringAsFixed(0),
                onChanged: (v) => setState(() => _config.tamanhoFonte = v),
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nomeProvaController.text.isEmpty
                    ? '(nome da prova)'
                    : _nomeProvaController.text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _config.turma?.nome ?? '(turma não selecionada)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                _config.mesmaProvaParaTodos
                    ? 'Mesma prova para todos'
                    : 'Prova individualizada por aluno',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questoes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _config.colunas,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  childAspectRatio: _config.colunas == 1 ? 3.4 : 1.8,
                ),
                itemBuilder: (context, index) {
                  final questao = questoes[index];
                  final alternativas = List<String>.from(
                    questao.alternatives,
                  );
                  if (_config.embaralharAlternativas) {
                    alternativas.shuffle();
                  }
                  return _QuestaoPreview(
                    numero: index + 1,
                    questao: questao,
                    alternativas: alternativas,
                    tamanhoFonte: _config.tamanhoFonte,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarProvaGerada(BuildContext context) {
    if (_questoesSelecionadasIds.isEmpty ||
        _nomeProvaController.text.trim().isEmpty ||
        _config.turma == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todas as etapas antes de gerar a prova.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prova gerada (mock)'),
        content: Text(
          'A prova "${_nomeProvaController.text}" foi gerada com '
          '${_questoesSelecionadasIds.length} questões para a turma '
          '${_config.turma!.nome}.\n\n'
          'Nesta fase (N1) a geração é apenas ilustrativa — a folha de '
          'respostas com QR code e a persistência real ficam para as '
          'próximas fases do projeto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }
}

/// Card individual de uma questão dentro do preview da prova.
class _QuestaoPreview extends StatelessWidget {
  final int numero;
  final Question questao;
  final List<String> alternativas;
  final double tamanhoFonte;

  const _QuestaoPreview({
    required this.numero,
    required this.questao,
    required this.alternativas,
    required this.tamanhoFonte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$numero. ${questao.statement}',
              style: TextStyle(
                fontSize: tamanhoFonte,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...alternativas.asMap().entries.map(
                  (e) => Text(
                    '${String.fromCharCode(65 + e.key)}) ${e.value}',
                    style: TextStyle(fontSize: tamanhoFonte - 1),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
