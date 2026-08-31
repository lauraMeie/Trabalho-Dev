# Provas App

Sistema para professores criarem, gerarem e corrigirem provas de forma automatizada.

## Resumo do projeto

O Provas App é um aplicativo voltado a professores que precisam lidar com grandes
volumes de correção de provas. A proposta é reunir, em um único sistema, a criação
de questões, a geração de provas e a correção automatizada, hoje feitas em
ferramentas separadas ou manualmente.

## Objetivo

O principal problema identificado com o cliente é a perda de tempo na correção manual
de provas: professores chegam a corrigir de 200 a 400 provas por semana, o que
consome tempo que poderia ser usado em outras atividades, além de atrasar a devolução
do resultado aos alunos.

O objetivo do app é automatizar esse fluxo — da criação da prova até a correção —
tornando o processo mais rápido, organizado e com menos esforço manual para o
professor, com uma interface minimalista, simples e fácil de usar.

## Escopo delimitado (Fase N1)

Nesta fase (N1), o aplicativo contempla:

- Telas navegáveis entre si (Home → Turmas → Banco de Questões → Criar Prova →
  Corrigir Prova → Relatórios);
- Dados fictícios (mock), sem persistência real;
- Padrão visual (cores, tipografia, espaçamentos) aplicado de forma consistente
  em todas as telas.

**Fora da N1** (previsto para as próximas fases do projeto):
- Conexão com banco de dados (Firebase/Firestore);
- Autenticação de usuários;
- Geração real de provas a partir do banco de questões;
- Leitura/correção automatizada de folhas de resposta (QR code, OCR);
- Geração de relatórios e estatísticas reais;
- Exportação de dados em Excel.

## Requisitos Funcionais gerais (RF)

| Código | Descrição |
|---|---|
| RF01 | Gerar provas automaticamente a partir de um banco de questões |
| RF02 | Cadastrar e organizar um banco de questões |
| RF03 | Randomizar a ordem das questões e alternativas entre provas de uma turma |
| RF04 | Escolher entre usar as mesmas questões para todos ou gerar provas diferentes por aluno |
| RF05 | Gerar folha de respostas separada da prova, com QR code de identificação |
| RF06 | Ler o QR code para identificar a prova/gabarito |
| RF07 | Corrigir automaticamente a prova a partir das alternativas marcadas |
| RF08 | Calcular a nota automaticamente após a correção |
| RF09 | Exibir relatório das avaliações corrigidas |
| RF10 | Exportar resultados em planilha (Excel) |
| RF11 | Gerar estatística por questão (alternativa mais marcada) |
| RF12 | Importar lista de alunos |
| RF13 | Gerar prova individualizada e identificável por aluno |
| RF14 | Editar o layout da prova gerada |

## Requisitos Não Funcionais gerais (RNF)

| Código | Descrição |
|---|---|
| RNF01 | Interface minimalista, com poucos elementos na tela |
| RNF02 | Navegação lógica, intuitiva e de fácil uso |
| RNF03 | Correção rápida o suficiente para turmas grandes |
| RNF04 | Leitura confiável das respostas, sem erro de quebra de página |
| RNF05 | Exportação de dados em formato de planilha (Excel) |

## Telas principais

| Tela | Descrição |
|---|---|
| **Home** | Tela inicial com saudação, resumo rápido (turmas/alunos/provas) e menu principal de acesso às demais funcionalidades |
| **Turmas** | Gerenciamento das turmas e alunos cadastrados |
| **Banco de Questões** | Cadastro e organização das questões utilizadas nas provas |
| **Criar Prova** | Montagem/geração de uma nova avaliação |
| **Corrigir Prova** | Correção automatizada das provas aplicadas |
| **Relatórios** | Visualização dos resultados e estatísticas das provas corrigidas |

> Nesta fase (N1), todas as telas — exceto a Home — são versões mock, com dados
> fictícios, servindo para validar a navegação entre as funcionalidades do app.

## Como executar

1. Instale o Flutter SDK: https://docs.flutter.dev/get-started/install
2. Verifique a instalação: