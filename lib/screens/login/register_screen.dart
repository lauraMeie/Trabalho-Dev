import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

/// Tela de cadastro com Firebase Authentication (e-mail e senha).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _carregando = false;
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _traduzirErro(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Login por e-mail/senha não está ativado no Firebase.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro: $code';
    }
  }

  String? _validar() {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmar = _confirmarController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirmar.isEmpty) {
      return 'Preencha todos os campos.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Digite um e-mail válido.';
    }
    if (senha.length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }
    if (senha != confirmar) {
      return 'As senhas não coincidem.';
    }
    return null;
  }

  Future<void> _cadastrar() async {
    final erro = _validar();
    if (erro != null) {
      _mostrarMensagem(erro);
      return;
    }

    setState(() => _carregando = true);
    try {
      final credencial =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );
      await credencial.user?.updateDisplayName(_nomeController.text.trim());

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_traduzirErro(e.code));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipPath(
              clipper: _TopCurveClipper(),
              child: Container(
                height: 200,
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.only(bottom: 40),
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_add_alt_1_outlined,
                                color: Colors.white, size: 36),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Criar conta',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'seu@email.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _senhaController,
                    obscureText: _ocultarSenha,
                    decoration: InputDecoration(
                      hintText: 'Senha (mínimo 6 caracteres)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_ocultarSenha
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _ocultarSenha = !_ocultarSenha),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _confirmarController,
                    obscureText: _ocultarSenha,
                    onSubmitted: (_) => _cadastrar(),
                    decoration: const InputDecoration(
                      hintText: 'Confirmar senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: _carregando ? null : _cadastrar,
                    child: _carregando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cadastrar'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed:
                        _carregando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Já tenho conta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 36);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 36,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}