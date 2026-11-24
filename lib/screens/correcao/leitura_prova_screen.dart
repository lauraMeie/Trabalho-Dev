import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/correction_result.dart';
import '../../routes/app_routes.dart';
import '../../services/correcao_repository.dart';
import '../../services/leitor_folha_respostas.dart';
import '../../theme/app_theme.dart';
import '../../utils/exam_generator.dart';
import '../../utils/firestore_errors.dart';
import '../../utils/folha_respostas_layout.dart';
import 'resultado_correcao_screen.dart';

/// Tela de leitura das respostas marcadas na folha de respostas (RF10).
///
/// A prova e o gabarito já vieram reais do Firestore (identificados pelo QR
/// Code na etapa anterior). O professor fotografa a folha de respostas e o
/// app detecta a alternativa marcada em cada questão; antes de corrigir,
/// ele confere e pode ajustar qualquer questão manualmente.
class LeituraProvaScreen extends StatefulWidget {
  final ProvaParaCorrigir prova;

  const LeituraProvaScreen({super.key, required this.prova});

  @override
  State<LeituraProvaScreen> createState() => _LeituraProvaScreenState();
}

class _LeituraProvaScreenState extends State<LeituraProvaScreen> {
  /// Índice da alternativa marcada em cada questão (pela posição na lista
  /// `prova.questoes`). Ausente = o professor ainda não mexeu nela (conta
  /// como em branco, igual a uma folha sem marcação nenhuma).
  final Map<int, int?> _respostas = {};

  final _nomeAlunoController = TextEditingController();
  final _correcaoRepository = CorrecaoRepository();
  final _seletorDeFoto = ImagePicker();
  bool _corrigindo = false;
  bool _lendoFolha = false;
  int _folhaSelecionada = 0;

  /// Questões em que a foto mostrou mais de uma bolinha preenchida.
  final Set<int> _duplas = {};

  bool get _precisaDigitarAluno => widget.prova.aluno == null;

  int get _totalFolhas =>
      FolhaRespostasLayout.totalFolhas(widget.prova.questoes.length);

  Future<void> _lerFolha(ImageSource origem) async {
    final avisos = ScaffoldMessenger.of(context);
    final XFile? foto;
    try {
      foto = await _seletorDeFoto.pickImage(
        source: origem,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
    } catch (_) {
      avisos.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir a câmera. Verifique a permissão do app.',
          ),
        ),
      );
      return;
    }
    if (foto == null || !mounted) return;

    setState(() => _lendoFolha = true);
    try {
      final leitura = await compute(
        lerFolhaRespostas,
        PedidoLeituraFolha(
          bytesImagem: await foto.readAsBytes(),
          totalQuestoes: widget.prova.questoes.length,
          folha: _folhaSelecionada,
        ),
      );
      if (!mounted) return;

      setState(() {
        for (final questao in leitura.questoes) {
          _respostas[questao.indiceQuestao] = questao.marcada;
          if (questao.duplaMarcacao) {
            _duplas.add(questao.indiceQuestao);
          } else {
            _duplas.remove(questao.indiceQuestao);
          }
        }
      });

      final resumo = [
        '${leitura.marcadas} marcada(s)',
        '${leitura.emBranco} em branco',
        if (leitura.duplas > 0) '${leitura.duplas} com mais de uma marcação',
      ].join(', ');
      avisos.showSnackBar(
        SnackBar(
          content: Text('Folha lida: $resumo. Confira antes de corrigir.'),
        ),
      );
    } on FolhaNaoEncontradaException catch (erro) {
      avisos.showSnackBar(SnackBar(content: Text(erro.mensagem)));
    } catch (_) {
      avisos.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível ler a foto. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _lendoFolha = false);
    }
  }

  @override
  void dispose() {
    _nomeAlunoController.dispose();
    super.dispose();
  }

  Future<void> _corrigir() async {
    final aluno = widget.prova.aluno ?? _nomeAlunoController.text.trim();
    if (aluno.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do aluno antes de corrigir.'),
        ),
      );
      return;
    }

    setState(() => _corrigindo = true);

    final questoes = widget.prova.questoes;
    final respostas = [
      for (var i = 0; i < questoes.length; i++)
        RespostaCorrigida(
          questaoId: questoes[i].originalId,
          materia: questoes[i].subject,
          enunciado: questoes[i].statement,
          alternativas: questoes[i].alternatives,
          indiceCorreto: questoes[i].correctIndex,
          indiceMarcado: _respostas[i],
        ),
    ];

    final resultado = ResultadoCorrecao(
      id: '', // definido pelo Firestore ao salvar (ver salvarResultado).
      aluno: aluno,
      turma: widget.prova.turmaNome,
      provaId: widget.prova.provaId,
      corrigidoEm: DateTime.now(),
      respostas: respostas,
    );

    try {
      final resultadoSalvo =
          await _correcaoRepository.salvarResultado(resultado);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          settings:
              const RouteSettings(name: AppRoutes.corrigirProvaResultado),
          builder: (_) => ResultadoCorrecaoScreen(resultado: resultadoSalvo),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() => _corrigindo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemDeErro(erro))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prova = widget.prova;

    return Scaffold(
      appBar: AppBar(title: const Text('Leitura da Prova')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'QR Code identificado',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoLinha(label: 'Prova', valor: prova.provaNome),
                  _InfoLinha(label: 'Turma', valor: prova.turmaNome),
                  if (prova.aluno != null)
                    _InfoLinha(label: 'Aluno', valor: prova.aluno!),
                ],
              ),
            ),
          ),
          if (_precisaDigitarAluno) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nomeAlunoController,
              decoration: const InputDecoration(
                labelText: 'Nome do aluno',
                hintText: 'Quem está respondendo esta folha?',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _LeituraPelaCameraCard(
            lendo: _lendoFolha,
            totalFolhas: _totalFolhas,
            folhaSelecionada: _folhaSelecionada,
            onSelecionarFolha: (folha) =>
                setState(() => _folhaSelecionada = folha),
            onFotografar: () => _lerFolha(ImageSource.camera),
            onEscolherFoto: () => _lerFolha(ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Confira a alternativa lida em cada questão. Se precisar, '
            'ajuste manualmente; deixe "Em branco" se o aluno não marcou.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...prova.questoes.asMap().entries.map(
            (entry) => _QuestaoLeituraCard(
              numero: entry.key + 1,
              questao: entry.value,
              selecionado: _respostas[entry.key],
              duplaMarcacao: _duplas.contains(entry.key),
              onSelecionar: (indice) => setState(() {
                _respostas[entry.key] = indice;
                _duplas.remove(entry.key);
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _corrigindo || _lendoFolha ? null : _corrigir,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Corrigir prova'),
          ),
        ],
      ),
    );
  }
}

class _QuestaoLeituraCard extends StatelessWidget {
  final int numero;
  final GeneratedQuestion questao;
  final int? selecionado;
  final bool duplaMarcacao;
  final ValueChanged<int?> onSelecionar;

  const _QuestaoLeituraCard({
    required this.numero,
    required this.questao,
    required this.selecionado,
    required this.duplaMarcacao,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final alternativas = questao.alternatives;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questão $numero · ${questao.subject}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              questao.statement,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (duplaMarcacao) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Mais de uma bolinha preenchida na folha. Escolha a '
                      'alternativa válida ou deixe em branco.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < alternativas.length; i++)
                  ChoiceChip(
                    label: Text(
                      '${String.fromCharCode(65 + i)}) ${alternativas[i]}',
                    ),
                    selected: selecionado == i,
                    onSelected: (marcado) => onSelecionar(marcado ? i : null),
                  ),
                ChoiceChip(
                  label: const Text('Em branco'),
                  selected: selecionado == null,
                  onSelected: (marcado) {
                    if (marcado) onSelecionar(null);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeituraPelaCameraCard extends StatelessWidget {
  final bool lendo;
  final int totalFolhas;
  final int folhaSelecionada;
  final ValueChanged<int> onSelecionarFolha;
  final VoidCallback onFotografar;
  final VoidCallback onEscolherFoto;

  const _LeituraPelaCameraCard({
    required this.lendo,
    required this.totalFolhas,
    required this.folhaSelecionada,
    required this.onSelecionarFolha,
    required this.onFotografar,
    required this.onEscolherFoto,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.document_scanner_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Ler a folha de respostas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Fotografe a folha inteira, de frente e com boa luz, com os 4 '
              'quadrados pretos aparecendo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (totalFolhas > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (var folha = 0; folha < totalFolhas; folha++)
                    ChoiceChip(
                      label: Text('Folha ${folha + 1}'),
                      selected: folhaSelecionada == folha,
                      onSelected: lendo
                          ? null
                          : (_) => onSelecionarFolha(folha),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            if (lendo)
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text('Lendo as marcações...'),
                ],
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: onFotografar,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Fotografar folha'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEscolherFoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Escolher foto'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoLinha({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              valor,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
