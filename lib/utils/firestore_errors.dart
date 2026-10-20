import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tempo máximo que esperamos o Firestore confirmar uma gravação.
///
/// Sem internet, o Firestore NÃO dá erro: ele guarda a alteração no
/// aparelho e deixa o Future pendente até a conexão voltar. Sem este
/// timeout, o botão "Salvar" ficaria carregando para sempre.
const Duration tempoLimiteGravacao = Duration(seconds: 10);

/// Transforma qualquer erro do Firestore numa mensagem simples para o
/// professor (sem jargão técnico).
String mensagemDeErro(Object erro) {
  if (erro is TimeoutException) {
    return 'Sem conexão com o servidor. A alteração será enviada '
        'quando a internet voltar.';
  }
  if (erro is FirebaseException) {
    switch (erro.code) {
      case 'permission-denied':
        return 'Você não tem permissão para fazer isso. '
            'Verifique o login e as regras do Firestore.';
      case 'unavailable':
        return 'Sem conexão com o servidor. Verifique sua internet e '
            'tente novamente.';
      case 'not-found':
        return 'Esse item não existe mais (talvez já tenha sido excluído).';
      case 'deadline-exceeded':
        return 'O servidor demorou demais para responder. Tente novamente.';
      case 'unauthenticated':
        return 'Faça login para salvar alterações.';
    }
  }
  return 'Ocorreu um erro inesperado. Tente novamente.';
}
