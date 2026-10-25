import 'package:flutter/material.dart';

import '../../models/correction_result.dart';
import '../../routes/app_routes.dart';
import '../../services/correcao_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/exam_generator.dart';
import '../../utils/firestore_errors.dart';
import 'resultado_correcao_screen.dart';

/// Tela de leitura das respostas marcadas na folha de respostas (RF07).
///
/// A prova e o gabarito já vieram reais do Firestore (identificados pelo QR
/// Code na etapa anterior). Aqui o professor informa, questão por questão,
/// qual alternativa o aluno marcou na folha — e o app corrige
/// automaticamente comparando com o gabarito real (RF08).
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
  bool _corrigindo = false;

  bool get _precisaDigitarAluno => widget.prova.aluno == null;

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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Marque, para cada questão, a alternativa que o aluno marcou '
            'na folha de respostas. Deixe sem marcar se a questão estiver '
            'em branco.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...prova.questoes.asMap().entries.map(
                (entry) => _QuestaoLeituraCard(
                  numero: entry.key + 1,
                  questao: entry.value,
                  selecionado: _respostas[entry.key],
                  onSelecionar: (indice) =>
                      setState(() => _respostas[entry.key] = indice),
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _corrigindo ? null : _corrigir,
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
  final ValueChanged<int?> onSelecionar;

  const _QuestaoLeituraCard({
    required this.numero,
    required this.questao,
    required this.selecionado,
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
