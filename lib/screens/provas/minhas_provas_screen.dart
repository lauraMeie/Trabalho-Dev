import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/prova_consulta_repository.dart';
import 'visualizar_prova_screen.dart';

class MinhasProvasScreen extends StatefulWidget {
  const MinhasProvasScreen({super.key});

  @override
  State<MinhasProvasScreen> createState() => _MinhasProvasScreenState();
}

class _MinhasProvasScreenState extends State<MinhasProvasScreen> {
  final _repository = ProvaConsultaRepository();
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _carregamento;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  void _atualizar() {
    _carregamento = _repository.listar();
  }

  Future<void> _confirmarExclusao(String id, String? nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir prova'),
        content: Text(
          'Deseja excluir "${nome ?? 'esta prova'}"? '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repository.excluir(id);
      if (!mounted) return;
      setState(_atualizar);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prova excluída.')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Provas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () => setState(_atualizar),
          ),
        ],
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _carregamento,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar provas: ${snapshot.error}'),
            );
          }
          final provas = snapshot.data ?? [];
          if (provas.isEmpty) {
            return const Center(child: Text('Nenhuma prova cadastrada.'));
          }
          return ListView.builder(
            itemCount: provas.length,
            itemBuilder: (context, index) {
              final doc = provas[index];
              final dados = doc.data();
              final nome = dados['nome']?.toString();
              return Card(
                child: ListTile(
                  title: Text(nome ?? 'Sem título'),
                  subtitle: Text(
                    'Turma: ${dados['turmaNome'] ?? '-'} • ${dados['totalQuestoes'] ?? 0} questões',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarExclusao(doc.id, nome),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VisualizarProvaScreen(provaId: doc.id),
                      ),
                    );
                    if (mounted) setState(_atualizar);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}