import '../../models/correction_result.dart';
import '../../utils/texto_utils.dart';

/// Uma aba da planilha de relatório, ainda sem nada do pacote `excel`:
/// nome da aba, cabeçalho e linhas. Cada célula é `String`, `int`,
/// `double` (notas, já arredondadas a 1 casa) ou `null` (célula vazia).
class TabelaPlanilha {
  final String nome;
  final List<String> cabecalho;
  final List<List<Object?>> linhas;

  /// Índices das colunas que contêm notas (formatadas com 1 casa decimal).
  final Set<int> colunasDeNota;

  const TabelaPlanilha({
    required this.nome,
    required this.cabecalho,
    required this.linhas,
    this.colunasDeNota = const {},
  });
}

/// Monta as tabelas do relatório em Excel (RF-15/RF-16) a partir dos
/// resultados salvos. Funções puras (sem Firebase e sem o pacote `excel`),
/// para poderem ser testadas isoladamente.
class PlanilhaRelatorio {
  PlanilhaRelatorio._();

  static const String nomeAbaResumo = 'Resumo';
  static const String nomeAbaRespostas = 'Respostas';
  static const int tamanhoMaximoNomeAba = 31;

  static const String marcaAcerto = '✓';
  static const String marcaErro = '✗';
  static const String marcaEmBranco = '—';

  static final RegExp _caracteresProibidos = RegExp(r'[\[\]:*?/\\]');

  /// Todas as abas, na ordem: Resumo, uma por turma, Respostas.
  static List<TabelaPlanilha> montarTabelas(
    List<ResultadoCorrecao> resultados,
  ) {
    return [
      montarResumo(resultados),
      ...montarAbasPorTurma(resultados),
      montarRespostas(resultados),
    ];
  }

  /// Arredonda a nota para 1 casa decimal.
  static double arredondarNota(double nota) => (nota * 10).round() / 10;

  /// Aba "Resumo": uma linha por correção, ordenada por turma e aluno.
  static TabelaPlanilha montarResumo(List<ResultadoCorrecao> resultados) {
    return TabelaPlanilha(
      nome: nomeAbaResumo,
      cabecalho: const [
        'Aluno',
        'Matrícula',
        'Turma',
        'Prova',
        'Nota',
        'Acertos',
        'Erros',
        'Em branco',
        'Corrigido em',
      ],
      colunasDeNota: const {4},
      linhas: [
        for (final r in _ordenados(resultados))
          [
            r.aluno,
            r.matricula,
            r.turma,
            r.provaExibicao,
            arredondarNota(r.nota),
            r.acertos,
            r.erros,
            r.emBranco,
            formatarData(r.corrigidoEm),
          ],
      ],
    );
  }

  /// Uma aba por turma: linhas = alunos, colunas = provas (nota) + "Média".
  static List<TabelaPlanilha> montarAbasPorTurma(
    List<ResultadoCorrecao> resultados,
  ) {
    // Agrupa sem diferenciar maiúsculas/acentos/espaços ("3º Ano A" e
    // "3º ano  a" são a mesma turma); o nome exibido é o primeiro visto.
    final porTurma = <String, List<ResultadoCorrecao>>{};
    final nomeTurma = <String, String>{};
    for (final r in resultados) {
      final chave = TextoUtils.chaveDeComparacao(r.turma);
      porTurma.putIfAbsent(chave, () => []).add(r);
      nomeTurma.putIfAbsent(chave, () => TextoUtils.normalizarEspacos(r.turma));
    }

    final turmas = porTurma.keys.toList()..sort();
    final nomesUsados = <String>{
      nomeAbaResumo.toLowerCase(),
      nomeAbaRespostas.toLowerCase(),
    };

    return [
      for (final turma in turmas)
        _montarAbaTurma(
          nomeAba: nomeUnicoDeAba(
            nomeTurma[turma]!.isEmpty ? 'Sem turma' : nomeTurma[turma]!,
            nomesUsados,
          ),
          resultados: porTurma[turma]!,
        ),
    ];
  }

  static TabelaPlanilha _montarAbaTurma({
    required String nomeAba,
    required List<ResultadoCorrecao> resultados,
  }) {
    // Provas da turma, na ordem da primeira correção de cada uma.
    final primeiraCorrecao = <String, DateTime>{};
    final nomeProva = <String, String>{};
    for (final r in resultados) {
      final atual = primeiraCorrecao[r.provaId];
      if (atual == null || r.corrigidoEm.isBefore(atual)) {
        primeiraCorrecao[r.provaId] = r.corrigidoEm;
      }
      nomeProva.putIfAbsent(r.provaId, () => r.provaExibicao);
    }
    final provas = primeiraCorrecao.keys.toList()
      ..sort((a, b) {
        final porData = primeiraCorrecao[a]!.compareTo(primeiraCorrecao[b]!);
        return porData != 0
            ? porData
            : _compararTexto(nomeProva[a]!, nomeProva[b]!);
      });

    // Por aluno, a correção mais recente de cada prova.
    final maisRecente = <String, Map<String, ResultadoCorrecao>>{};
    for (final r in resultados) {
      final provasDoAluno = maisRecente.putIfAbsent(chaveAluno(r), () => {});
      final atual = provasDoAluno[r.provaId];
      if (atual == null || r.corrigidoEm.isAfter(atual.corrigidoEm)) {
        provasDoAluno[r.provaId] = r;
      }
    }

    // Nome/matrícula exibidos: os da correção mais recente do aluno.
    ResultadoCorrecao ultimaDoAluno(String chave) => maisRecente[chave]!.values
        .reduce((a, b) => b.corrigidoEm.isAfter(a.corrigidoEm) ? b : a);

    final alunos = maisRecente.keys.toList()
      ..sort((a, b) {
        final porNome = _compararTexto(
          ultimaDoAluno(a).aluno,
          ultimaDoAluno(b).aluno,
        );
        return porNome != 0 ? porNome : a.compareTo(b);
      });

    final linhas = <List<Object?>>[];
    for (final chave in alunos) {
      final ultima = ultimaDoAluno(chave);
      final notas = <double?>[
        for (final provaId in provas) maisRecente[chave]![provaId]?.nota,
      ];
      final feitas = notas.whereType<double>().toList();
      final media = feitas.isEmpty
          ? null
          : arredondarNota(feitas.reduce((a, b) => a + b) / feitas.length);

      linhas.add([
        ultima.aluno,
        ultima.matricula,
        for (final nota in notas) nota == null ? null : arredondarNota(nota),
        media,
      ]);
    }

    return TabelaPlanilha(
      nome: nomeAba,
      cabecalho: [
        'Aluno',
        'Matrícula',
        for (final provaId in provas) nomeProva[provaId]!,
        'Média',
      ],
      colunasDeNota: {for (var i = 2; i < provas.length + 3; i++) i},
      linhas: linhas,
    );
  }

  /// Aba "Respostas": uma linha por correção com a alternativa marcada em
  /// cada questão (ex.: "B ✓", "C ✗" ou "—" quando em branco).
  static TabelaPlanilha montarRespostas(List<ResultadoCorrecao> resultados) {
    final maxQuestoes = resultados.fold<int>(
      0,
      (maior, r) => r.respostas.length > maior ? r.respostas.length : maior,
    );

    return TabelaPlanilha(
      nome: nomeAbaRespostas,
      cabecalho: [
        'Aluno',
        'Matrícula',
        'Turma',
        'Prova',
        'Nota',
        for (var i = 1; i <= maxQuestoes; i++) 'Q$i',
      ],
      colunasDeNota: const {4},
      linhas: [
        for (final r in _ordenados(resultados))
          [
            r.aluno,
            r.matricula,
            r.turma,
            r.provaExibicao,
            arredondarNota(r.nota),
            for (var i = 0; i < maxQuestoes; i++)
              i < r.respostas.length ? textoResposta(r.respostas[i]) : null,
          ],
      ],
    );
  }

  /// Texto da célula de uma questão: letra marcada + ✓/✗, ou "—".
  static String textoResposta(RespostaCorrigida resposta) {
    final marcado = resposta.indiceMarcado;
    if (marcado == null) return marcaEmBranco;
    final letra = String.fromCharCode('A'.codeUnitAt(0) + marcado);
    return '$letra ${resposta.correta ? marcaAcerto : marcaErro}';
  }

  /// Identifica o aluno pela matrícula quando houver, senão pelo nome.
  static String chaveAluno(ResultadoCorrecao resultado) {
    final matricula = resultado.matricula.trim();
    if (matricula.isNotEmpty) return 'matricula:$matricula';
    return 'nome:${TextoUtils.chaveDeComparacao(resultado.aluno)}';
  }

  /// Nome de aba válido no Excel: sem `[ ] : * ? / \`, sem apóstrofo nas
  /// pontas e com no máximo 31 caracteres.
  static String sanitizarNomeAba(String nome) {
    var limpo = nome.replaceAll(_caracteresProibidos, '').trim();
    limpo = limpo.replaceAll(RegExp(r"^'+|'+$"), '').trim();
    if (limpo.isEmpty) limpo = 'Turma';
    if (limpo.length > tamanhoMaximoNomeAba) {
      limpo = limpo.substring(0, tamanhoMaximoNomeAba).trimRight();
    }
    return limpo;
  }

  /// [sanitizarNomeAba] + um número no fim quando o nome já foi usado
  /// (comparação sem diferenciar maiúsculas, como o Excel faz). O nome
  /// devolvido é adicionado a [nomesUsados].
  static String nomeUnicoDeAba(String nome, Set<String> nomesUsados) {
    final base = sanitizarNomeAba(nome);
    var candidato = base;
    var numero = 2;
    while (nomesUsados.contains(candidato.toLowerCase())) {
      final sufixo = ' $numero';
      final corte = tamanhoMaximoNomeAba - sufixo.length;
      final prefixo = base.length > corte
          ? base.substring(0, corte).trimRight()
          : base;
      candidato = '$prefixo$sufixo';
      numero++;
    }
    nomesUsados.add(candidato.toLowerCase());
    return candidato;
  }

  static String formatarData(DateTime data) {
    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');
    return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
        '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
  }

  /// Ordena por turma, aluno, prova e data da correção.
  static List<ResultadoCorrecao> _ordenados(List<ResultadoCorrecao> lista) {
    return [...lista]..sort((a, b) {
      for (final c in [
        _compararTexto(a.turma, b.turma),
        _compararTexto(a.aluno, b.aluno),
        _compararTexto(a.provaExibicao, b.provaExibicao),
      ]) {
        if (c != 0) return c;
      }
      return a.corrigidoEm.compareTo(b.corrigidoEm);
    });
  }

  static int _compararTexto(String a, String b) => TextoUtils.chaveDeComparacao(
    a,
  ).compareTo(TextoUtils.chaveDeComparacao(b));
}
