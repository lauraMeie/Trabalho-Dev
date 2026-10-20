import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/prova_config.dart';
import '../../models/prova_gerada.dart';
import '../../services/prova_pdf_service.dart';
import '../../services/prova_repository.dart';
import '../../services/question_repository.dart';
import '../../services/turma_leitura_repository.dart';
import '../../utils/exam_generator.dart';
import '../../utils/firestore_errors.dart';
import '../../utils/prova_validator.dart';


class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  int _etapaAtual = 0;

  final QuestionRepository _questionRepository = QuestionRepository();
  final ProvaRepository _provaRepository = ProvaRepository();
  final TurmaLeituraRepository _turmaRepository = TurmaLeituraRepository();

  /// Tempo máximo esperando o Firestore responder uma LEITURA. Sem
  /// internet, o Firestore pode ficar pendente em vez de dar erro.
  static const Duration _tempoLimiteLeitura = Duration(seconds: 10);

  // Questões vindas do Firestore (Banco de Questões).
  List<Question> _bancoQuestoes = const [];
  bool _carregandoQuestoes = true;
  String? _erroQuestoes;

  // Turmas vindas do Firestore (coleção `turmas`).
  List<Turma> _turmas = const [];
  bool _carregandoTurmas = true;
  String? _erroTurmas;

  bool _salvando = false;
  bool _gerandoPdf = false;

  // Só mostra os erros de validação nos campos depois que o professor
  // tenta avançar (para não "gritar" com a tela ainda vazia).
  bool _mostrarErros = false;

  // Última prova salva com sucesso (usada para gerar o PDF dela).
  ProvaGerada? _provaSalva;

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
    _carregarTurmas();
  }

  /// Mensagem de erro para LEITURAS (a de `mensagemDeErro` fala em
  /// "alteração será enviada", que só faz sentido para gravações).
  String _mensagemLeitura(Object erro) {
    if (erro is TimeoutException) {
      return 'Sem conexão com o servidor. Verifique sua internet e '
          'tente novamente.';
    }
    return mensagemDeErro(erro);
  }

  Future<void> _carregarQuestoes() async {
    setState(() {
      _carregandoQuestoes = true;
      _erroQuestoes = null;
    });
    try {
      final questoes = await _questionRepository
          .buscarTodas()
          .timeout(_tempoLimiteLeitura);
      if (!mounted) return;
      setState(() {
        _bancoQuestoes = questoes;
        // Descarta seleções de questões que não existem mais no banco.
        final idsExistentes = questoes.map((q) => q.id).toSet();
        _questoesSelecionadasIds.removeWhere((id) => !idsExistentes.contains(id));
        _carregandoQuestoes = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erroQuestoes = _mensagemLeitura(erro);
        _carregandoQuestoes = false;
      });
    }
  }

  Future<void> _carregarTurmas() async {
    setState(() {
      _carregandoTurmas = true;
      _erroTurmas = null;
    });
    try {
      final turmas =
          await _turmaRepository.buscarTodas().timeout(_tempoLimiteLeitura);
      if (!mounted) return;
      setState(() {
        _turmas = turmas;
        // Os objetos Turma são novos a cada leitura; refaz a seleção
        // pelo nome para o Dropdown não ficar com um valor "órfão".
        final nomeSelecionado = _config.turma?.nome;
        _config.turma = null;
        for (final turma in turmas) {
          if (turma.nome == nomeSelecionado) _config.turma = turma;
        }
        _carregandoTurmas = false;
      });
    } catch (erro) {
      if (!mounted) return;
      debugPrint('Erro ao carregar turmas: $erro');
      setState(() {
        _erroTurmas = _mensagemLeitura(erro);
        _carregandoTurmas = false;
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

  // ---------------------------------------------------------------------
  // Validação da configuração da prova
  // ---------------------------------------------------------------------
  ProvaValidationResult get _validacao => ProvaValidator.validar(
        nome: _nomeProvaController.text,
        turma: _config.turma,
        quantidadeQuestoes: _questoesSelecionadas.length,
        mesmaProvaParaTodos: _config.mesmaProvaParaTodos,
      );

  /// Mensagem do primeiro problema da etapa, ou `null` se está tudo OK.
  String? _erroDaEtapa(int etapa) {
    final v = _validacao;
    switch (etapa) {
      case 0:
        return v.erroQuestoes;
      case 1:
        return v.erroNome ?? v.erroTurma ?? v.erroAlunos;
      default:
        return null;
    }
  }

  /// Primeira etapa (a partir da atual, até antes de [destino]) com
  /// problema, ou `null` se dá para ir até [destino].
  int? _etapaComErro(int destino) {
    for (int etapa = _etapaAtual; etapa < destino; etapa++) {
      if (_erroDaEtapa(etapa) != null) return etapa;
    }
    return null;
  }

  void _irParaEtapa(int etapa) {
    _etapaAtual = etapa;
    _mostrarErros = false;
    if (etapa < 3) _provaSalva = null;
    if (etapa == 3) _gerarPreview();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
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
          // Só permite pular para uma etapa se TODAS as anteriores
          // (até ela) estiverem válidas.
          final etapaComErro = _etapaComErro(step);
          if (etapaComErro == null) {
            setState(() => _irParaEtapa(step));
          } else {
            setState(() => _mostrarErros = true);
            _avisar(_erroDaEtapa(etapaComErro)!);
          }
        },
        onStepContinue: () {
          final erro = _erroDaEtapa(_etapaAtual);
          if (erro != null) {
            setState(() => _mostrarErros = true);
            _avisar(erro);
            return;
          }
          if (_etapaAtual < 3) {
            setState(() => _irParaEtapa(_etapaAtual + 1));
          }
        },
        onStepCancel: () {
          if (_etapaAtual > 0) {
            setState(() => _irParaEtapa(_etapaAtual - 1));
          }
        },
        controlsBuilder: (context, details) {
          final ultimaEtapa = _etapaAtual == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!ultimaEtapa)
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continuar'),
                  )
                else
                  FilledButton.icon(
                    onPressed: (_salvando || _provaSalva != null)
                        ? null
                        : () => _gerarESalvarProva(context),
                    icon: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _salvando
                          ? 'Salvando...'
                          : (_provaSalva != null
                              ? 'Prova salva'
                              : 'Gerar Prova'),
                    ),
                  ),
                if (ultimaEtapa && _provaSalva != null) ...[
                  OutlinedButton.icon(
                    onPressed: _gerandoPdf ? null : () => _exportarPdf(),
                    icon: _gerandoPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined),
                    label: Text(_gerandoPdf ? 'Gerando PDF...' : 'Imprimir PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _gerandoPdf ? null : () => _exportarPdf(baixar: true),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Baixar PDF'),
                  ),
                ],
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O Banco de Questões está vazio. Cadastre questões no Banco de '
            'Questões antes de criar uma prova.',
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _carregarQuestoes,
            child: const Text('Atualizar'),
          ),
        ],
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
        if (_mostrarErros && _validacao.erroQuestoes != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _validacao.erroQuestoes!,
              style: TextStyle(color: colorScheme.error),
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
          maxLength: ProvaValidator.tamanhoMaximoNome,
          decoration: InputDecoration(
            labelText: 'Nome da prova',
            hintText: 'Ex: Avaliação Bimestral - Matemática',
            border: const OutlineInputBorder(),
            errorText: _mostrarErros ? _validacao.erroNome : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildCampoTurma(),
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
        if (_validacao.erroAlunos != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _validacao.erroAlunos!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  /// Campo "Turma": mostra carregando, erro (com nova tentativa), lista
  /// vazia ou o seletor, conforme o estado da leitura no Firestore.
  Widget _buildCampoTurma() {
    if (_carregandoTurmas) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Carregando turmas...'),
        ],
      );
    }

    if (_erroTurmas != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_erroTurmas!),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _carregarTurmas,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    if (_turmas.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nenhuma turma cadastrada. Cadastre uma turma na tela Turmas '
            'antes de criar uma prova.',
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _carregarTurmas,
            child: const Text('Atualizar'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<Turma>(
      // A chave muda quando a lista é recarregada, para o campo
      // reconstruir com o valor selecionado atualizado.
      key: ObjectKey(_turmas),
      initialValue: _config.turma,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Turma',
        border: const OutlineInputBorder(),
        errorText: _mostrarErros ? _validacao.erroTurma : null,
      ),
      items: _turmas
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text('${t.nome} (${t.quantidadeAlunos} alunos)'),
            ),
          )
          .toList(),
      onChanged: (turma) => setState(() => _config.turma = turma),
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

    final validacao = _validacao;
    if (!validacao.valido) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            validacao.erroNome ??
                validacao.erroTurma ??
                validacao.erroQuestoes ??
                validacao.erroAlunos ??
                'Preencha todas as etapas antes de gerar a prova.',
          ),
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
      setState(() {
        _salvando = false;
        _provaSalva = prova;
      });

      final querPdf = await showDialog<bool>(
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Fechar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Gerar PDF'),
            ),
          ],
        ),
      );

      if (querPdf == true) await _exportarPdf();
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      messenger.showSnackBar(SnackBar(content: Text(mensagemDeErro(erro))));
    }
  }

  /// Gera o PDF da prova que acabou de ser salva (imprimir ou baixar).
  Future<void> _exportarPdf({bool baixar = false}) async {
    final prova = _provaSalva;
    if (prova == null || _gerandoPdf) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _gerandoPdf = true);
    try {
      if (baixar) {
        await ProvaPdfService.baixar(prova);
      } else {
        await ProvaPdfService.imprimir(prova);
      }
    } catch (erro) {
      debugPrint('Erro ao gerar PDF: $erro');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar o PDF. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
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
