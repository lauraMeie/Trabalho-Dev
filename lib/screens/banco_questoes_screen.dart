import 'package:flutter/material.dart';

import '../data/question_bank.dart';
import '../models/question.dart';
import '../services/question_repository.dart';
import '../utils/exam_generator.dart';
import '../utils/firestore_errors.dart';
import 'questoes/question_form_dialog.dart';

/// Tela "Banco de Questões": lista as questões salvas no Firestore,
/// permite criar, editar e excluir (RF02/RF16) e mostra uma prévia de
/// como fica uma prova gerada com alternativas embaralhadas.
class BancoQuestoesScreen extends StatefulWidget {
  const BancoQuestoesScreen({super.key});

  @override
  State<BancoQuestoesScreen> createState() => _BancoQuestoesScreenState();
}

class _BancoQuestoesScreenState extends State<BancoQuestoesScreen> {
  final QuestionRepository _repositorio = QuestionRepository();

  late Stream<List<Question>> _stream;
  List<Question> _ultimasQuestoes = const [];
  bool _ocupado = false; // true enquanto grava/exclui/importa

  @override
  void initState() {
    super.initState();
    _stream = _repositorio.observar();
  }

  /// Recria o stream (botão "Tentar novamente" da tela de erro).
  void _tentarNovamente() {
    setState(() => _stream = _repositorio.observar());
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Roda uma operação de escrita tratando erro e bloqueando cliques
  /// repetidos enquanto ela não termina.
  Future<void> _executar(
    Future<void> Function() operacao, {
    required String sucesso,
  }) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await operacao();
      if (mounted) _mostrarMensagem(sucesso);
    } catch (erro) {
      if (mounted) _mostrarMensagem(mensagemDeErro(erro));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _criarQuestao() async {
    final nova = await mostrarFormularioQuestao(context);
    if (nova == null || !mounted) return;
    await _executar(
      () => _repositorio.adicionar(nova),
      sucesso: 'Questão criada.',
    );
  }

  Future<void> _editarQuestao(Question questao) async {
    final editada = await mostrarFormularioQuestao(context, questao: questao);
    if (editada == null || !mounted) return;
    await _executar(
      () => _repositorio.atualizar(editada),
      sucesso: 'Questão atualizada.',
    );
  }

  Future<void> _excluirQuestao(Question questao) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir questão?'),
        content: Text(
          '"${questao.statement}"\n\nEssa ação não pode ser desfeita.',
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    await _executar(
      () => _repositorio.remover(questao.id),
      sucesso: 'Questão excluída.',
    );
  }

  Future<void> _carregarQuestoesExemplo() {
    return _executar(
      () => _repositorio.importarQuestoes(questionBank),
      sucesso: 'Questões de exemplo carregadas.',
    );
  }

  void _visualizarProvaGerada() {
    if (_ultimasQuestoes.isEmpty) {
      _mostrarMensagem('Cadastre ao menos uma questão para ver a prévia.');
      return;
    }

    final provaGerada = ExamGenerator.gerarDeQuestoes(
      _ultimasQuestoes.length > 5
          ? (List<Question>.from(_ultimasQuestoes)..shuffle()).take(5).toList()
          : _ultimasQuestoes,
      embaralharQuestoes: true,
      embaralharAlternativas: true,
    );

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
      body: Stack(
        children: [
          StreamBuilder<List<Question>>(
            stream: _stream,
            builder: (context, snapshot) {
              // 1) Erro ao ler do banco (sem permissão, sem internet...)
              if (snapshot.hasError) {
                return _EstadoMensagem(
                  icone: Icons.cloud_off,
                  titulo: 'Não foi possível carregar as questões',
                  mensagem: mensagemDeErro(snapshot.error!),
                  rotuloAcao: 'Tentar novamente',
                  onAcao: _tentarNovamente,
                );
              }

              // 2) Ainda carregando pela primeira vez
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final questoes = snapshot.data!;
              _ultimasQuestoes = questoes;

              // 3) Banco vazio
              if (questoes.isEmpty) {
                return _EstadoMensagem(
                  icone: Icons.quiz_outlined,
                  titulo: 'Nenhuma questão cadastrada',
                  mensagem:
                      'Toque em "Criar questão" para cadastrar a primeira, '
                      'ou carregue as questões de exemplo.',
                  rotuloAcao: 'Carregar questões de exemplo',
                  onAcao: _ocupado ? null : _carregarQuestoesExemplo,
                );
              }

              // 4) Lista normal
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: questoes.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final questao = questoes[index];
                  return ExpansionTile(
                    key: ValueKey(questao.id),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed:
                                  _ocupado ? null : () => _editarQuestao(questao),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                            ),
                            TextButton.icon(
                              onPressed:
                                  _ocupado ? null : () => _excluirQuestao(questao),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Excluir'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          if (_ocupado) const LinearProgressIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ocupado ? null : _criarQuestao,
        icon: const Icon(Icons.add),
        label: const Text('Criar questão'),
      ),
    );
  }
}

/// Mensagem centralizada usada nos estados de erro e de lista vazia.
class _EstadoMensagem extends StatelessWidget {
  const _EstadoMensagem({
    required this.icone,
    required this.titulo,
    required this.mensagem,
    required this.rotuloAcao,
    required this.onAcao,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final String rotuloAcao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: tema.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: tema.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              style: tema.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAcao, child: Text(rotuloAcao)),
          ],
        ),
      ),
    );
  }
}
