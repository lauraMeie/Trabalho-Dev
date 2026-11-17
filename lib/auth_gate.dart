import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        return _PerfilGuard(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

/// Garante que o professor logado tenha documento em professores/{uid}
/// antes de mostrar a Home.
class _PerfilGuard extends StatefulWidget {
  final User user;
  const _PerfilGuard({super.key, required this.user});

  @override
  State<_PerfilGuard> createState() => _PerfilGuardState();
}

class _PerfilGuardState extends State<_PerfilGuard> {
  late final Future<void> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = _garantirPerfil();
  }

  Future<void> _garantirPerfil() {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('professores').doc(widget.user.uid);

    // Transação: só cria se ainda não existir, sem sobrescrever o perfil
    // que a tela de cadastro acabou de gravar.
    return db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) {
        tx.set(ref, {
          'nome': widget.user.displayName ?? '',
          'email': widget.user.email ?? '',
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _perfil,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Não foi possível carregar seu perfil.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const HomeScreen();
      },
    );
  }
}