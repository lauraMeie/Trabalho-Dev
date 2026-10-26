import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

/// Tela de login com Firebase Authentication (e-mail e senha).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
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
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro: $code';
    }
  }

  bool _camposPreenchidos() {
    if (_emailController.text.trim().isEmpty || _senhaController.text.isEmpty) {
      _mostrarMensagem('Preencha e-mail e senha.');
      return false;
    }
    return true;
  }

  Future<void> _entrar() async {
    if (!_camposPreenchidos()) return;
    setState(() => _carregando = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_traduzirErro(e.code));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _recuperarSenha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _mostrarMensagem('Digite seu e-mail para recuperar a senha.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _mostrarMensagem('Enviamos um link de recuperação para o seu e-mail.');
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_traduzirErro(e.code));
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
                height: 240,
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.only(bottom: 40),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_outlined,
                            color: Colors.white, size: 40),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'ProvaLab',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Entre para gerenciar suas avaliações.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'seu@email.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _senhaController,
                    obscureText: true,
                    onSubmitted: (_) => _entrar(),
                    decoration: const InputDecoration(
                      hintText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _recuperarSenha,
                      child: Text(
                        'Esqueci minha senha',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: _carregando ? null : _entrar,
                    child: _carregando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: _carregando
    ? null
    : () => Navigator.of(context).pushNamed(AppRoutes.cadastro),
                    child: const Text('Criar conta'),
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

/// Curva simples e arredondada na base do cabeçalho roxo.
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