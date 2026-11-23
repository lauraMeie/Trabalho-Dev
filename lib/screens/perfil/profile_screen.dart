import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

/// Tela de perfil do professor: editar nome, trocar senha e sair.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nomeController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _salvandoNome = false;
  bool _trocandoSenha = false;
  bool _ocultarAtual = true;
  bool _ocultarNova = true;
  bool _ocultarConfirmacao = true;

  User get _user => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _nomeController.text = _user.displayName ?? '';
    _carregarNome();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _carregarNome() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('professores')
          .doc(_user.uid)
          .get();
      final nome = doc.data()?['nome'] as String?;
      if (nome != null && nome.isNotEmpty && mounted) {
        _nomeController.text = nome;
      }
    } catch (_) {
      // Mantém o nome do Auth se não conseguir ler o Firestore.
    }
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _traduzirErro(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha atual incorreta.';
      case 'weak-password':
        return 'A nova senha precisa ter pelo menos 6 caracteres.';
      case 'requires-recent-login':
        return 'Faça login novamente para realizar esta ação.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro: $code';
    }
  }

  Future<void> _salvarNome() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      _mostrarMensagem('Digite seu nome.');
      return;
    }
    setState(() => _salvandoNome = true);
    try {
      await _user.updateDisplayName(nome);
      await FirebaseFirestore.instance
          .collection('professores')
          .doc(_user.uid)
          .set({'nome': nome}, SetOptions(merge: true));
      _mostrarMensagem('Nome atualizado.');
    } on FirebaseException catch (e) {
      _mostrarMensagem('Não foi possível salvar: ${e.code}');
    } finally {
      if (mounted) setState(() => _salvandoNome = false);
    }
  }

  Future<void> _trocarSenha() async {
    final atual = _senhaAtualController.text;
    final nova = _novaSenhaController.text;
    final confirmar = _confirmarController.text;

    if (atual.isEmpty || nova.isEmpty || confirmar.isEmpty) {
      _mostrarMensagem('Preencha todos os campos de senha.');
      return;
    }
    if (nova.length < 6) {
      _mostrarMensagem('A nova senha precisa ter pelo menos 6 caracteres.');
      return;
    }
    if (nova != confirmar) {
      _mostrarMensagem('As senhas não coincidem.');
      return;
    }

    setState(() => _trocandoSenha = true);
    try {
      // Reautentica com a senha atual antes de trocar.
      final credencial = EmailAuthProvider.credential(
        email: _user.email!,
        password: atual,
      );
      await _user.reauthenticateWithCredential(credencial);
      await _user.updatePassword(nova);

      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarController.clear();
      _mostrarMensagem('Senha alterada com sucesso.');
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_traduzirErro(e.code));
    } finally {
      if (mounted) setState(() => _trocandoSenha = false);
    }
  }

  Future<void> _sair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Widget _campoSenha({
    required TextEditingController controller,
    required String hint,
    required bool oculto,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: oculto,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(oculto
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          tooltip: oculto ? 'Mostrar senha' : 'Ocultar senha',
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ---------- Dados ----------
            Text('Dados pessoais', style: titulo),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: TextEditingController(text: _user.email ?? ''),
              enabled: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: _salvandoNome ? null : _salvarNome,
              child: _salvandoNome
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar nome'),
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),

            // ---------- Senha ----------
            Text('Alterar senha', style: titulo),
            const SizedBox(height: AppSpacing.sm),
            _campoSenha(
              controller: _senhaAtualController,
              hint: 'Senha atual',
              oculto: _ocultarAtual,
              onToggle: () => setState(() => _ocultarAtual = !_ocultarAtual),
            ),
            const SizedBox(height: AppSpacing.sm),
            _campoSenha(
              controller: _novaSenhaController,
              hint: 'Nova senha (mínimo 6 caracteres)',
              oculto: _ocultarNova,
              onToggle: () => setState(() => _ocultarNova = !_ocultarNova),
            ),
            const SizedBox(height: AppSpacing.sm),
            _campoSenha(
              controller: _confirmarController,
              hint: 'Confirmar nova senha',
              oculto: _ocultarConfirmacao,
              onToggle: () =>
                  setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: _trocandoSenha ? null : _trocarSenha,
              child: _trocandoSenha
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Alterar senha'),
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // ---------- Sair ----------
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: _sair,
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }
}