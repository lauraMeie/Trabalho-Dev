import 'package:flutter/material.dart';

import '../../data/turmas_mock.dart';
import '../../models/prova_config.dart';
import '../../models/prova_gerada.dart';
import '../../services/prova_repository.dart';
import '../../services/question_repository.dart';
import '../../utils/exam_generator.dart';
import '../../utils/firestore_errors.dart';


class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  int _etapaAtual = 0;

  final QuestionRepository _questionRepository = QuestionRepository();
  final ProvaRepository _provaRepository = ProvaRepository();

  // Questões vindas do Firestore (Banco de Questões).
  List<Question> _bancoQuestoes = const [];
  bool _carregandoQuestoes = true;
  String? _erroQuestoes;

  bool _salvando = false;

  // Prova que o professor está vendo na etapa 4. É gerada UMA vez ao
  // entrar na etapa (e não a cada rebuild), para que o que aparece na
  // tela seja exatamente o que será salvo.
  List<GeneratedQuestion> _previewQuestoes = const [];

  final Set<String> _questoesSelecionadasIds = {};
  String? _filtroDisciplina;

  final ConfiguracaoProva _config = ConfiguracaoProva();
  final _nomeProvaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarQuestoes();
  }

  Future<void> _carregarQuestoes() async {
    setState(() {
      _carregandoQuestoes = true;
      _erroQuestoes = null;
    });
    try {
      final questoes = await _questionRepository.buscarTodas();
      if (!mounted) return;
      setState(() {
        _bancoQuestoes = questoes;
        _carregandoQuestoes = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erroQuestoes = mensagemDeErro(erro);
        _carregandoQuestoes = false;
      });
    }
  }

  List<Question> get _questoesFiltradas {
    if (_filtroDisciplina == null) return _bancoQuestoes;
    return _bancoQuestoes
        .where((q) => q.subject == _filtroDisciplina)
        .toList();
  }

  List<Question> get _questoesSelecionadas {
    return _bancoQuestoes
        .where((q) => _questoesSelecionadasIds.contains(q.id))
        .toList();
  }

  /// Gera a prova mostrada na etapa 4, aplicando o embaralhamento
  /// escolhido na etapa 3 (RF03).
  void _gerarPreview() {
    _previewQuestoes = ExamGenerator.gerarDeQuestoes(
      _questoesSelecionadas,
      embaralharQuestoes: _config.embaralharQuestoes,
      embaralharAlternativas: _config.embaralharAlternativas,
    );
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
            setState(() {
              _etapaAtual = step;
              if (step == 3) _gerarPreview();
            });
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
            setState(() {
              _etapaAtual += 1;
              if (_etapaAtual == 3) _gerarPreview();
            });
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
                    onPressed:
                        _salvando ? null : () => _gerarESalvarProva(context),
                    icon: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_salvando ? 'Salvando...' : 'Gerar Prova'),
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
    if (_carregandoQuestoes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_erroQuestoes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_erroQuestoes!),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _carregarQuestoes,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    if (_bancoQuestoes.isEmpty) {
      return const Text(
        'O Banco de Questões está vazio. Cadastre questões no Banco de '
        'Questões antes de criar uma prova.',
      );
    }

    final disciplinas =
        _bancoQuestoes.map((q) => q.subject).toSet().toList()..sort();

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
          separatorBuilder: (_, _) => const Divider(height: 1),
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
          items: turmasMock
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text('${t.nome} (${t.quantidadeAlunos} alunos)'),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _config.mesmaProvaParaTodos
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: const Text('Mesma prova para todos os alunos'),
                  subtitle: const Text(
                      'Todos recebem as mesmas questões e alternativas'),
                  onTap: () =>
                      setState(() => _config.mesmaProvaParaTodos = true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    !_config.mesmaProvaParaTodos
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: const Text('Provas individualizadas por aluno'),
                  subtitle: const Text(
                      'Cada aluno recebe uma prova identificável e única'),
                  onTap: () =>
                      setState(() => _config.mesmaProvaParaTodos = false),
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
    final questoes = _previewQuestoes;

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
                  return _QuestaoPreview(
                    numero: index + 1,
                    questao: questao,
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

  /// Monta a prova (a mesma para todos ou uma por aluno), salva no
  /// Firestore e só então avisa o professor.
  Future<void> _gerarESalvarProva(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_questoesSelecionadasIds.isEmpty ||
        _nomeProvaController.text.trim().isEmpty ||
        _config.turma == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Preencha todas as etapas antes de gerar a prova.'),
        ),
      );
      return;
    }

    final turma = _config.turma!;
    final selecionadas = _questoesSelecionadas;

    // Mesma prova para todos: salva exatamente o que está no preview.
    // Individualizada: gera uma prova própria (embaralhamento
    // independente) para cada aluno da turma (RF04/RF13).
    final List<ProvaDoAluno> provas;
    if (_config.mesmaProvaParaTodos) {
      provas = [ProvaDoAluno(questoes: _previewQuestoes)];
    } else {
      if (turma.alunos.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'A turma não tem alunos para gerar provas individualizadas.',
            ),
          ),
        );
        return;
      }
      provas = [
        for (final aluno in turma.alunos)
          ProvaDoAluno(
            aluno: aluno.nome,
            matricula: aluno.matricula,
            questoes: ExamGenerator.gerarDeQuestoes(
              selecionadas,
              embaralharQuestoes: _config.embaralharQuestoes,
              embaralharAlternativas: _config.embaralharAlternativas,
            ),
          ),
      ];
    }

    final prova = ProvaGerada(
      nome: _nomeProvaController.text.trim(),
      turmaNome: turma.nome,
      mesmaProvaParaTodos: _config.mesmaProvaParaTodos,
      embaralhouQuestoes: _config.embaralharQuestoes,
      embaralhouAlternativas: _config.embaralharAlternativas,
      colunas: _config.colunas,
      tamanhoFonte: _config.tamanhoFonte,
      provas: provas,
    );

    setState(() => _salvando = true);
    try {
      await _provaRepository.salvar(prova);
      if (!mounted) return;
      setState(() => _salvando = false);

      await showDialog<void>(
        context: this.context, // seguro: já checamos `mounted` acima
        builder: (dialogContext) => AlertDialog(
          title: const Text('Prova gerada'),
          content: Text(
            'A prova "${prova.nome}" foi gerada com '
            '${selecionadas.length} questões para a turma ${turma.nome} '
            'e salva no banco de dados '
            '(${provas.length} ${provas.length == 1 ? 'versão' : 'versões'}).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      messenger.showSnackBar(SnackBar(content: Text(mensagemDeErro(erro))));
    }
  }
}

/// Card individual de uma questão dentro do preview da prova.
class _QuestaoPreview extends StatelessWidget {
  final int numero;
  final GeneratedQuestion questao;
  final double tamanhoFonte;

  const _QuestaoPreview({
    required this.numero,
    required this.questao,
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
            ...questao.alternatives.asMap().entries.map(
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
