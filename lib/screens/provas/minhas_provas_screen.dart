import 'package:flutter/material.dart';
import '../../services/prova_repository.dart';
import 'visualizar_prova_screen.dart';

class MinhasProvasScreen extends StatefulWidget {
  const MinhasProvasScreen({super.key});
  @override
  State<MinhasProvasScreen> createState() => _MinhasProvasScreenState();
}

class _MinhasProvasScreenState extends State<MinhasProvasScreen> {
  final _repository = ProvaRepository();
  late Future<dynamic> _carregamento;
  @override
  void initState() { super.initState(); _atualizar(); }
  void _atualizar() { _carregamento = _repository.listar(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Minhas Provas'), actions: [
      IconButton(icon: const Icon(Icons.refresh), tooltip: 'Atualizar',
        onPressed: () => setState(_atualizar)),
    ]),
    body: FutureBuilder<dynamic>(future: _carregamento, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) return Center(child: Text('Erro ao carregar provas: ${snapshot.error}'));
      final provas = snapshot.data as List;
      if (provas.isEmpty) return const Center(child: Text('Nenhuma prova cadastrada.'));
      return ListView.builder(itemCount: provas.length, itemBuilder: (context, index) {
        final doc = provas[index];
        final dados = doc.data() as Map<String, dynamic>;
        return Card(child: ListTile(
          title: Text(dados['nome']?.toString() ?? 'Sem título'),
          subtitle: Text('Turma: ${dados['turmaNome'] ?? '-'} • ${dados['totalQuestoes'] ?? 0} questões'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VisualizarProvaScreen(provaId: doc.id)));
            if (mounted) setState(_atualizar);
          },
        ));
      });
    }),
  );
}
