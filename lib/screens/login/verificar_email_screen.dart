import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class VerificarEmailScreen extends StatefulWidget {
  const VerificarEmailScreen({super.key});

  @override
  State<VerificarEmailScreen> createState() => _VerificarEmailScreenState();
}

class _VerificarEmailScreenState extends State<VerificarEmailScreen> {
  bool _carregando = false;

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _jaVerifiquei() async {
    setState(() => _carregando = true);
    try {
      final auth = FirebaseAuth.instance;
      await auth.currentUser!.reload();
      // Atualiza o token para refletir email_verified == true.
      await auth.currentUser!.getIdToken(true);
      final user = auth.currentUser!;

      if (!user.emailVerified) {
        _mensagem(
            'Ainda não verificado. Clique no link enviado ao seu e-mail.');
        return;
      }

      // Agora a regra do Firestore permite criar o perfil.
      await FirebaseFirestore.instance
          .collection('professores')
          .doc(user.uid)
          .set({
        'nome': user.displayName ?? '',
        'email': user.email,
        'criadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } on FirebaseException catch (e) {
      _mensagem('Erro: ${e.code}');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _reenviar() async {
    try {
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();
      _mensagem('E-mail reenviado. Confira também o spam.');
    } on FirebaseAuthException catch (e) {
      _mensagem(e.code == 'too-many-requests'
          ? 'Muitas tentativas. Aguarde um pouco e tente de novo.'
          : 'Erro: ${e.code}');
    }
  }

  Future<void> _sair() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text('Verifique seu e-mail',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enviamos um link para $email.\nClique nele e depois volte aqui.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _carregando ? null : _jaVerifiquei,
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Já verifiquei'),
              ),
              TextButton(
                onPressed: _carregando ? null : _reenviar,
                child: const Text('Reenviar e-mail'),
              ),
              TextButton(
                onPressed: _carregando ? null : _sair,
                child: const Text('Usar outro e-mail'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}