import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/turmas_repository.dart';
import '../../models/aluno.dart';
import '../../models/turma.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

/// Tela de perfil do professor: dados da conta, edição do nome,
/// troca de senha e consulta das próprias turmas e alunos.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _repo = TurmasRepository();
  late final Stream<List<Turma>> _turmasStream = _repo.turmasStream();

  User get _user => FirebaseAuth.instance.currentUser!;

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _editarNome(String atual) async {
    final controller = TextEditingController(text: atual);
    final novo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (novo == null || novo.isEmpty || novo == atual) return;

    try {
      await _user.updateDisplayName(novo);
      await FirebaseFirestore.instance
          .collection('professores')
          .doc(_user.uid)
          .set({
        'nome': novo,
        'email': _user.email, // exigido pelas regras do Firestore
      }, SetOptions(merge: true));
      _mensagem('Nome atualizado.');
    } on FirebaseException catch (e) {
      _mensagem('Não foi possível atualizar o nome: ${e.code}');
    }
  }

  Future<void> _trocarSenha() async {
    final email = _user.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _mensagem('Enviamos um link para $email para você criar uma nova senha.');
    } on FirebaseAuthException catch (e) {
      _mensagem(e.code == 'too-many-requests'
          ? 'Muitas tentativas. Aguarde um pouco e tente de novo.'
          : 'Erro: ${e.code}');
    }
  }

  Future<void> _sair() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildDados(),
          const SizedBox(height: AppSpacing.lg),
          _buildTurmasEAlunos(),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _sair,
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ DADOS

  Widget _buildDados() {
    final user = _user;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('professores')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final nome = (snapshot.data?.data()?['nome'] as String?) ??
            user.displayName ??
            '';
        final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        inicial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome.isEmpty ? '(sem nome)' : nome,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(user.email ?? ''),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                user.emailVerified
                                    ? Icons.verified_outlined
                                    : Icons.warning_amber_outlined,
                                size: 16,
                                color: user.emailVerified
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.emailVerified
                                    ? 'E-mail verificado'
                                    : 'E-mail não verificado',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar nome'),
                  onTap: () => _editarNome(nome),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_reset_outlined),
                  title: const Text('Trocar senha'),
                  subtitle: const Text('Enviamos um link para o seu e-mail'),
                  onTap: _trocarSenha,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------- TURMAS / ALUNOS

  Widget _buildTurmasEAlunos() {
    return StreamBuilder<List<Turma>>(
      stream: _turmasStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erro ao carregar as turmas: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final turmas = snapshot.data!;
        final totalAlunos =
            turmas.fold<int>(0, (soma, t) => soma + t.quantidadeAlunos);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minhas turmas e alunos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('${turmas.length} turma(s) • $totalAlunos aluno(s)'),
            const SizedBox(height: AppSpacing.sm),
            if (turmas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('Você ainda não cadastrou nenhuma turma.'),
              )
            else
              for (final turma in turmas)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.groups_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(turma.nome),
                    subtitle: Text('${turma.quantidadeAlunos} aluno(s)'),
                    children: [
                      if (turma.id != null) _AlunosDaTurma(turmaId: turma.id!),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Lista (em tempo real) os alunos de uma turma. Só é construída quando
/// o professor expande a turma.
class _AlunosDaTurma extends StatefulWidget {
  final String turmaId;
  const _AlunosDaTurma({required this.turmaId});

  @override
  State<_AlunosDaTurma> createState() => _AlunosDaTurmaState();
}

class _AlunosDaTurmaState extends State<_AlunosDaTurma> {
  late final Stream<List<Aluno>> _stream =
      TurmasRepository().alunosStream(widget.turmaId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Aluno>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('Não foi possível carregar os alunos.'),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final alunos = snapshot.data!;
        if (alunos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('Nenhum aluno nesta turma.'),
          );
        }
        return Column(
          children: [
            for (final aluno in alunos)
              ListTile(
                dense: true,
                leading: const Icon(Icons.person_outline, size: 20),
                title: Text(aluno.nome),
                subtitle: Text('Matrícula: ${aluno.matricula}'),
              ),
          ],
        );
      },
    );
  }
}