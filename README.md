# Provas App

Sistema para professores criarem, gerarem e corrigirem provas de forma automatizada.

**Versão do documento:** v2 (Fase N2 – integração com banco de dados)

## Resumo do projeto

O Provas App (identificado na interface como ProvaLab) é um aplicativo voltado a professores que precisam lidar com grandes volumes de correção de provas. A proposta é reunir, em um único sistema, a criação de questões, a geração de provas e a correção automatizada, hoje feitas em ferramentas separadas ou manualmente.

## Objetivo

O principal problema identificado com o cliente é a perda de tempo na correção manual de provas: professores chegam a corrigir de 200 a 400 provas por semana, o que consome tempo que poderia ser usado em outras atividades, além de atrasar a devolução do resultado aos alunos.

O objetivo do app é automatizar esse fluxo, da criação da prova até a correção, tornando o processo mais rápido, organizado e com menos esforço manual para o professor, com uma interface minimalista, simples e fácil de usar.

## Escopo implementado

### Fase N1 (concluída)

- Telas navegáveis entre si (Home → Turmas → Banco de Questões → Criar Prova → Corrigir Prova → Relatórios);
- Dados fictícios (mock), sem persistência real;
- Padrão visual (cores, tipografia, espaçamentos) aplicado de forma consistente em todas as telas.

### Fase N2 (atual): integração real com banco de dados

Nesta fase o app deixou de depender de dados mock nas telas principais e passou a ler e gravar dados no **Firebase** (Authentication e Cloud Firestore).

**Implementado na N2:**

- **Autenticação real** com Firebase Authentication (e-mail e senha):
  - Tela de **Login** com validação e mensagens de erro em português;
  - Tela de **Cadastro** (nome, e-mail, senha e confirmação);
  - Recuperação de senha por e-mail ("Esqueci minha senha");
  - Controle de sessão: sem usuário logado o app abre no Login; com usuário logado abre direto na Home; botão **Sair** na Home encerra a sessão.
- **Home com números reais**: os contadores de Turmas, Alunos e Provas são lidos do Firestore e atualizados automaticamente.
- **Turmas e Alunos no Firestore**: cadastrar, listar, editar e excluir turmas (a exclusão remove também os alunos da turma).
- **Banco de Questões no Firestore**: cadastro e listagem das questões usadas na geração das provas.
- **Provas no Firestore**: as provas geradas são gravadas e consultadas no banco.
- **Correção de provas no Firestore**: a leitura do QR code da folha de respostas identifica a prova, e o resultado da correção é salvo na coleção `correcoes`.
- **Relatórios com dados reais**: a tela lê as correções do Firestore em tempo real e exibe provas corrigidas, média geral, total de turmas, desempenho por matéria e estatística por questão (alternativa mais marcada e percentual de acerto).
- **Exportação para Excel** dos resultados corrigidos.
- **Regras de segurança do Firestore**: acesso permitido apenas a usuários autenticados.

**Fora da N2** (previsto para as próximas fases do projeto):

- Restrição de acesso por dono (cada professor ver somente os próprios dados).

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
| RF15 | Exigir autenticação (login ou cadastro) para acessar o app; os dados são gravados no banco apenas para usuários autenticados |
| RF16 | Conseguir editar e remover questões, turmas e provas |
| RF17 | Permitir cadastro de novo usuário e recuperação de senha por e-mail |
| RF18 | Exibir na Home a quantidade real de turmas, alunos e provas |

> **Mudança em relação à v1:** o RF15 original previa navegação sem login. Na N2 o app passou a exigir autenticação para abrir, pois os dados ficam no banco e pertencem a um usuário.

## Requisitos Não Funcionais gerais (RNF)

| Código | Descrição |
|---|---|
| RNF01 | Interface minimalista, com poucos elementos na tela |
| RNF02 | Navegação lógica, intuitiva e de fácil uso |
| RNF03 | Correção rápida o suficiente para turmas grandes |
| RNF04 | Leitura confiável das respostas, sem erro de quebra de página |
| RNF05 | Exportação de dados em formato de planilha (Excel) |
| RNF06 | Funcionalidades de escrita/persistência devem exigir usuário autenticado |
| RNF07 | Os dados devem ser persistidos em banco de dados real (Cloud Firestore) |
| RNF08 | Senhas gerenciadas pelo Firebase Authentication, sem armazenamento próprio |
| RNF09 | Mensagens de erro claras e em português |

## Telas principais

| Tela | Descrição |
|---|---|
| **Login** | Autenticação real com e-mail e senha (Firebase), com recuperação de senha. É a primeira tela para quem não está logado |
| **Cadastro** | Criação de conta com nome, e-mail, senha e confirmação de senha |
| **Home** | Tela inicial com saudação, resumo com números reais (turmas/alunos/provas), menu principal e botão Sair |
| **Turmas** | Gerenciamento das turmas e alunos cadastrados, gravados no Firestore |
| **Banco de Questões** | Cadastro e organização das questões utilizadas nas provas |
| **Criar Prova** | Montagem/geração de uma nova avaliação, com configuração de modo e embaralhamento |
| **Corrigir Prova** | Correção das provas aplicadas a partir do QR code da folha de respostas; o resultado é salvo no Firestore |
| **Relatórios** | Resultados das provas corrigidas, desempenho por matéria, estatística por questão e exportação para Excel, tudo a partir do Firestore |

> Na N2, a autenticação e os relatórios deixaram de ser mock: Login, Cadastro e Relatórios usam o Firebase de verdade.

## Integração com o banco de dados

### Estrutura no Firestore

```
turmas/{turmaId}
  ├─ nome: string
  ├─ quantidadeAlunos: number
  ├─ uid: string                (usuário dono da turma)
  └─ alunos/{alunoId}           (subcoleção)

provas/{provaId}                (provas geradas)
questoes/{questaoId}            (banco de questões)
correcoes/{correcaoId}          (resultado de cada prova corrigida:
                                 aluno, turma, provaId, data da correção
                                 e respostas marcadas)
```

### Arquivos principais

| Arquivo | Responsabilidade |
|---|---|
| `lib/main.dart` | Inicialização do Firebase |
| `lib/auth_gate.dart` | Mostra Login ou Home conforme a sessão |
| `lib/data/turmas_repository.dart` | CRUD de turmas e alunos |
| `lib/data/relatorios_calculos.dart` | Cálculos dos relatórios (média geral, turmas, desempenho por matéria, estatística por questão) |
| `lib/models/correction_result.dart` | Modelo do resultado de uma correção e das respostas corrigidas |
| `lib/models/estatistica_questao.dart` | Modelo da estatística agregada de uma questão |
| `lib/services/prova_repository.dart` | Provas |
| `lib/services/question_repository.dart` | Questões |
| `lib/services/correcao_repository.dart` | Leitura e gravação das correções (coleção `correcoes`) |
| `lib/services/excel_export_service.dart` | Exportação dos resultados para Excel |
| `lib/services/qr_prova_codec.dart` | Leitura e decodificação do QR code da folha de respostas |
| `lib/services/turma_leitura_repository.dart` | Leitura de turmas para outras telas |
| `lib/services/stats_service.dart` | Contadores da Home |

## Como executar

1. Instale o Flutter SDK: https://docs.flutter.dev/get-started/install
2. Verifique a instalação com `flutter doctor`.
3. Clone o repositório e instale as dependências:
   ```
   git clone [URL DO REPOSITÓRIO]
   cd trabalho_dev
   flutter pub get
   ```
4. O app já inclui a configuração do Firebase (`lib/firebase_options.dart`). Para usar outro projeto Firebase, rode `flutterfire configure`.
5. Rode no navegador: `flutter run -d chrome`.
6. Para gerar o APK: `flutter build apk --release`. O arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`.
7. Para rodar os testes: `flutter test`.

> Para o app funcionar no Android, o app Android deve estar registrado no projeto Firebase (`flutterfire configure`, marcando a plataforma android).

## Histórico de versões

| Versão | Fase | Descrição |
|---|---|---|
| v1 | N1 | Telas navegáveis com dados mock |
| v2 | N2 | Firebase Authentication e Firestore; login e cadastro reais; Home com números reais; CRUD de turmas e alunos; correções, relatórios e estatísticas por questão a partir do Firestore; exportação para Excel |

Link do vídeo das nossas telas: https://youtube.com/shorts/PHKnWtK98DI?feature=share
