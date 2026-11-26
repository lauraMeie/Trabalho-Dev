<div align="center">

# 🚀 Provas App

**Sistema para professores criarem, gerarem e corrigirem provas de forma automatizada.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)

![Status](https://img.shields.io/badge/status-concluído-2EA043?style=flat-square)
![Entrega](https://img.shields.io/badge/entrega%20atual-N3-3D348B?style=flat-square)
![Licença](https://img.shields.io/badge/licença-uso%20acadêmico-7B4FA6?style=flat-square)

📘 **[Manual do usuário](docs/manual/README.md)**

</div>

## 👥 Equipe

| Nome completo |
|---|
| Laura Meier |
| Tiago Spezia |
| Nicolas Renan Dellani |
| Henrique Roberti Ribeiro |
| Phelipe Gonçalves Blanco |

## 📑 Sumário

- [1. Visão Geral](#1-visão-geral)
- [2. Requisitos](#2-requisitos)
  - [2.1 Funcionais (RF)](#21-funcionais-rf)
  - [2.2 Não Funcionais (RNF)](#22-não-funcionais-rnf)
- [3. Telas do Sistema](#3-telas-do-sistema)
- [4. Modelo de Dados](#4-modelo-de-dados)
- [5. Stack Tecnológica](#5-stack-tecnológica)
- [6. Estrutura de Pastas](#6-estrutura-de-pastas)
- [7. Como Executar o Projeto](#7-como-executar-o-projeto)
- [8. Backlog de Atividades da N2](#8-backlog-de-atividades-da-n2)
- [9. Backlog de Atividades da N3](#9-backlog-de-atividades-da-n3)
- [📘 Manual do usuário](docs/manual/README.md)

---

## 1. Visão Geral

📌 **N1**

O Provas App é um aplicativo Android para professores que lidam com grandes volumes de correção de provas. Hoje, a criação de questões, a geração de provas e a correção são feitas em ferramentas separadas ou manualmente, e professores chegam a corrigir de 200 a 400 provas por semana, o que consome tempo e atrasa a devolução dos resultados aos alunos.

O app reúne tudo em um único sistema, da criação da prova até a correção automática pela câmera do celular, com uma interface minimalista, simples e fácil de usar.

**Escopo por fase**

- **N1 (concluída):** telas navegáveis entre si (Home → Turmas → Banco de Questões → Criar Prova → Corrigir Prova → Relatórios), com dados fictícios e padrão visual consistente.
- **N2 (concluída):** integração real com o **Firebase** (Authentication e Cloud Firestore): login, cadastro e recuperação de senha; Home com números reais; CRUD de turmas, alunos e questões; criação de provas com geração de PDF; correção por QR Code com resultado salvo na coleção `correcoes`; relatórios em tempo real com exportação para Excel; regras de segurança que exigem usuário autenticado.
- **N3 (concluída):** app completo e integrado ao banco, entregue como **APK para Android**:
  - **Folha de respostas** impressa junto com a prova, em página separada do caderno de questões, com **QR Code** de identificação, bolinhas A–E e marcadores para a câmera.
  - **Correção pela câmera:** o QR Code identifica a prova e o aluno, a foto da folha preenche automaticamente as alternativas marcadas (com aviso de questão em branco ou com mais de uma marcação) e o professor confere antes de corrigir.
  - **Resultado salvo** com nome da prova e matrícula; corrigir de novo a mesma folha **substitui** a correção anterior, sem duplicar; lista de todas as **provas corrigidas**.
  - **Relatórios** e **planilha Excel** com resumo, uma aba por turma (alunos × provas, com média) e a alternativa marcada em cada questão, com **compartilhamento** pelo Android (Drive, WhatsApp, e-mail).
  - **Minhas Provas:** ver, editar, excluir e **baixar ou imprimir o PDF de novo**, mantendo o mesmo QR Code.
  - **Dados separados por professor** (campo `uid` em turmas, questões, provas e correções), cadastro com **verificação de e-mail** e tela de **perfil**.
  - **Turmas:** bloqueio de matrícula e nome de turma repetidos e **busca** por nome ou matrícula.
  - **Manual do usuário** com passo a passo e prints ([docs/manual](docs/manual/README.md)).
- **Não implementado:** importação da lista de alunos a partir de uma planilha (RF12).

## 2. Requisitos

📌 **N1** (ajustados ao longo das entregas seguintes conforme o escopo evoluiu)

### 2.1 Funcionais (RF)

| Código | Requisito | Situação na N3 |
|---|---|---|
| RF01 | Gerar provas automaticamente a partir de um banco de questões | ✅ |
| RF02 | Cadastrar e organizar um banco de questões | ✅ |
| RF03 | Randomizar a ordem das questões e alternativas entre provas de uma turma | ✅ |
| RF04 | Escolher entre usar as mesmas questões para todos ou gerar provas diferentes por aluno | ✅ |
| RF05 | Gerar folha de respostas separada da prova, com QR code de identificação | ✅ |
| RF06 | Ler o QR code para identificar a prova/gabarito | ✅ |
| RF07 | Corrigir automaticamente a prova a partir das alternativas marcadas | ✅ (leitura da folha pela câmera) |
| RF08 | Calcular a nota automaticamente após a correção | ✅ |
| RF09 | Exibir relatório das avaliações corrigidas | ✅ |
| RF10 | Exportar resultados em planilha (Excel) | ✅ |
| RF11 | Gerar estatística por questão (alternativa mais marcada) | ✅ |
| RF12 | Importar lista de alunos | ❌ não implementado |
| RF13 | Gerar prova individualizada e identificável por aluno | ✅ |
| RF14 | Editar o layout da prova gerada | ✅ (colunas, fonte e questões) |
| RF15 | Exigir autenticação (login ou cadastro) para acessar o app; os dados são gravados no banco apenas para usuários autenticados | ✅ |
| RF16 | Conseguir editar e remover questões, turmas e provas | ✅ |
| RF17 | Permitir cadastro de novo usuário e recuperação de senha por e-mail | ✅ (com verificação de e-mail) |
| RF18 | Exibir na Home a quantidade real de turmas, alunos e provas | ✅ |

> **Mudança em relação à v1:** o RF15 original previa navegação sem login. Na N2 o app passou a exigir autenticação para abrir, pois os dados ficam no banco e pertencem a um usuário.

### 2.2 Não Funcionais (RNF)

| Código | Requisito |
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
| RNF10 | Cada professor acessa apenas os próprios dados (regras do Firestore e campo `uid`) |
| RNF11 | Instalar e funcionar em celular Android real (APK) |

## 3. Telas do Sistema

📌 **N3** (prints do APK rodando em um celular Android)

> Fluxo de navegação: **Login/Cadastro → Home → Turmas / Banco de Questões / Criar Prova / Minhas Provas / Corrigir Prova / Relatórios / Perfil**. O passo a passo de cada tela está no [manual do usuário](docs/manual/README.md).

### Acesso

| | | |
|:---:|:---:|:---:|
| <img src="docs/telas/01-login.jpg" width="210"><br>*Login com e-mail e senha* | <img src="docs/telas/02-verificar-email.jpg" width="210"><br>*Verificação do e-mail no cadastro* | <img src="docs/telas/03-home.jpg" width="210"><br>*Home com os totais reais* |
| <img src="docs/telas/04-perfil.jpg" width="210"><br>*Perfil do professor* |  |  |

### Turmas e questões

| | | |
|:---:|:---:|:---:|
| <img src="docs/telas/05-turmas.jpg" width="210"><br>*Turmas, com busca* | <img src="docs/telas/06-turma-alunos.jpg" width="210"><br>*Alunos da turma, com busca por nome ou matrícula* | <img src="docs/telas/07-banco-questoes.jpg" width="210"><br>*Banco de Questões* |
| <img src="docs/telas/08-nova-questao.jpg" width="210"><br>*Cadastro de questão* |  |  |

### Provas

| | | |
|:---:|:---:|:---:|
| <img src="docs/telas/09-criar-prova-questoes.jpg" width="210"><br>*Criar Prova: seleção das questões* | <img src="docs/telas/10-criar-prova-configurar.jpg" width="210"><br>*Criar Prova: nome, turma e tipo de prova* | <img src="docs/telas/11-criar-prova-embaralhamento.jpg" width="210"><br>*Criar Prova: embaralhar questões e alternativas* |
| <img src="docs/telas/12-folha-respostas.jpg" width="210"><br>*Folha de respostas com QR Code (página do PDF)* | <img src="docs/telas/13-minhas-provas.jpg" width="210"><br>*Minhas Provas* | <img src="docs/telas/14-visualizar-prova.jpg" width="210"><br>*Visualizar Prova: baixar e imprimir o PDF* |
| <img src="docs/telas/15-visualizar-questoes.jpg" width="210"><br>*Questões e gabarito de cada versão* | <img src="docs/telas/16-editar-prova.jpg" width="210"><br>*Editar dados e layout* | <img src="docs/telas/17-editar-questao.jpg" width="210"><br>*Editar questão* |

### Correção e relatórios

| | | |
|:---:|:---:|:---:|
| <img src="docs/telas/18-corrigir-prova.jpg" width="210"><br>*Corrigir Prova* | <img src="docs/telas/19-escanear-qr.jpg" width="210"><br>*Leitura do QR Code pela câmera* | <img src="docs/telas/20-leitura-prova.jpg" width="210"><br>*Leitura da folha: fotografar ou escolher a foto* |
| <img src="docs/telas/21-prova-ja-corrigida.jpg" width="210"><br>*Aviso ao corrigir de novo a mesma folha* | <img src="docs/telas/22-resultado.jpg" width="210"><br>*Resultado da correção* | <img src="docs/telas/23-provas-corrigidas.jpg" width="210"><br>*Provas corrigidas* |
| <img src="docs/telas/24-relatorios.jpg" width="210"><br>*Relatórios* |  |  |

<img src="docs/manual/img/correcao/13-excel-aba-turma.png" width="440"><br>
*Planilha exportada para o Excel (aba da turma, com alunos × provas e média), compartilhada pelo Android.*

### 🎥 Vídeos de demonstração

- N1: [vídeo das telas](https://youtube.com/shorts/PHKnWtK98DI?feature=share)
- N2: [vídeo das telas](https://youtube.com/shorts/d_52iMSrJM0?feature=share)

## 4. Modelo de Dados

📌 **N3**

O Firestore não guarda dados em tabelas com linhas e colunas, ele guarda em coleções de documentos no formato JSON. Abaixo, um exemplo de documento de cada coleção, seguido do dicionário de dados. Todas as coleções principais guardam o `uid` do professor dono, e as regras do Firestore só deixam cada professor ler e gravar os próprios documentos.

### Coleção `professores`

ID do documento: o `uid` do professor no Firebase Authentication.

```json
{
  "nome": "Tiago Spezia",
  "email": "professor@escola.com",
  "criadoEm": "2026-11-25T19:20:00Z"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| nome | String | Nome do professor (editável na tela de Perfil) |
| email | String | E-mail usado no login |
| criadoEm | Timestamp | Data de criação da conta |

### Coleção `turmas`

```json
{
  "nome": "3º Ano A",
  "quantidadeAlunos": 25,
  "uid": "k3Jx9QmZpLe2VbT8uYhN4wRs7cA1"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| nome | String | Nome da turma (não pode repetir para o mesmo professor) |
| quantidadeAlunos | number | Quantidade de alunos cadastrados |
| uid | String | Professor dono da turma |

### Subcoleção `turmas/{turmaId}/alunos`

```json
{
  "nome": "Ana Beatriz Souza",
  "matricula": "2026001"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| nome | String | Nome do aluno |
| matricula | String | Matrícula do aluno (não pode repetir na mesma turma) |

### Coleção `questoes`

```json
{
  "subject": "Matemática",
  "statement": "Quanto é 7 x 8?",
  "alternatives": ["54", "56", "58", "60", "62"],
  "correctIndex": 1,
  "uid": "k3Jx9QmZpLe2VbT8uYhN4wRs7cA1",
  "criadoEm": "2026-11-20T10:00:00Z",
  "atualizadoEm": "2026-11-20T10:00:00Z"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| subject | String | Matéria da questão |
| statement | String | Enunciado da questão |
| alternatives | Array\<String\> | As 5 alternativas (A a E) |
| correctIndex | number | Índice (0 a 4) da alternativa correta |
| uid | String | Professor dono da questão |
| criadoEm / atualizadoEm | Timestamp | Datas de criação e da última edição |

### Coleção `provas`

```json
{
  "nome": "Avaliação Bimestral",
  "turmaNome": "3º Ano A",
  "mesmaProvaParaTodos": false,
  "embaralhouQuestoes": true,
  "embaralhouAlternativas": true,
  "colunas": 2,
  "tamanhoFonte": 12,
  "totalProvas": 25,
  "totalQuestoes": 10,
  "uid": "k3Jx9QmZpLe2VbT8uYhN4wRs7cA1",
  "criadaEm": "2026-11-24T15:00:00Z"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| nome | String | Nome da prova |
| turmaNome | String | Turma para a qual a prova foi gerada |
| mesmaProvaParaTodos | boolean | Se todos recebem a mesma prova ou uma versão por aluno |
| embaralhouQuestoes / embaralhouAlternativas | boolean | Se a ordem das questões e das alternativas foi embaralhada |
| colunas / tamanhoFonte | number | Layout do PDF (1 ou 2 colunas e tamanho da fonte) |
| totalProvas / totalQuestoes | number | Quantidade de versões (alunos) e de questões |
| uid | String | Professor dono da prova |
| criadaEm | Timestamp | Data de criação |

### Subcoleção `provas/{provaId}/individuais`

ID do documento: `0000`, `0001`, `0002`... na mesma ordem do PDF. O QR Code da folha de respostas guarda `provaId` e esse ID (ex.: `provalab://prova/AbC123XyZ/0001`), por isso editar a prova ou baixar o PDF de novo não invalida as folhas já impressas.

```json
{
  "aluno": "Ana Beatriz Souza",
  "matricula": "2026001",
  "questoes": [
    {
      "originalId": "q7",
      "subject": "Matemática",
      "statement": "Quanto é 7 x 8?",
      "alternatives": ["58", "54", "62", "56", "60"],
      "correctIndex": 3
    }
  ],
  "gabarito": ["D"]
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| aluno / matricula | String | Aluno dono dessa versão (nulos quando é a mesma prova para todos) |
| questoes | Array\<Map\> | Questões dessa versão, já embaralhadas (`originalId` aponta para a questão do banco) |
| gabarito | Array\<String\> | Gabarito (letras) dessa versão, na ordem das questões |

### Coleção `correcoes`

ID do documento: fixo por folha de respostas (`{provaId}_{individualId}`, e na "mesma prova para todos" também o nome do aluno). Assim, corrigir de novo a mesma folha **substitui** a correção anterior, sem duplicar.

```json
{
  "aluno": "Ana Beatriz Souza",
  "matricula": "2026001",
  "turma": "3º Ano A",
  "provaId": "AbC123XyZ",
  "provaNome": "Avaliação Bimestral",
  "corrigidoEm": "2026-11-25T14:30:00.000",
  "uid": "k3Jx9QmZpLe2VbT8uYhN4wRs7cA1",
  "respostas": [
    {
      "questaoId": "q7",
      "materia": "Matemática",
      "enunciado": "Quanto é 7 x 8?",
      "alternativas": ["58", "54", "62", "56", "60"],
      "indiceCorreto": 3,
      "indiceMarcado": 3
    }
  ]
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| aluno / matricula | String | Aluno corrigido e matrícula |
| turma | String | Turma do aluno |
| provaId / provaNome | String | ID e nome da prova corrigida |
| corrigidoEm | String (ISO 8601) | Data/hora da correção |
| uid | String | Professor que corrigiu |
| respostas | Array\<Map\> | Cada questão com alternativas, índice correto e índice marcado (`null` = em branco). A nota, os acertos e os erros são calculados a partir daqui |

## 5. Stack Tecnológica

📌 **N1** (lista inicial da disciplina, expandida ao longo das entregas seguintes)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white)

- **Flutter / Dart**: framework e linguagem do app Android.
- **firebase_core / cloud_firestore**: banco de dados em nuvem (NoSQL) com turmas, alunos, questões, provas, correções e perfis.
- **firebase_auth**: login, cadastro, verificação de e-mail e recuperação de senha.
- **google_fonts / flutter_svg**: fontes e ilustrações do padrão visual.
- **pdf / printing**: geração do PDF da prova e da folha de respostas com QR Code, para baixar ou imprimir.
- **mobile_scanner**: leitura do QR Code da folha de respostas pela câmera.
- **image_picker / image**: foto da folha de respostas e leitura das bolinhas marcadas (feita no próprio app, sem serviço externo).
- **excel / path_provider / share_plus**: geração da planilha `.xlsx` e compartilhamento pelo Android.
- **GitHub Actions**: a cada push e Pull Request roda o `flutter analyze` (Flutter 3.47.8).

## 6. Estrutura de Pastas

📌 **N1**, atualizada conforme o projeto cresceu

```
lib/
  data/                  # repositório de turmas/alunos e cálculos dos relatórios
  models/                # entidades do app (Turma, Aluno, Question, ProvaGerada, ResultadoCorrecao...)
  routes/                # nomes/definições das rotas do app
  screens/               # telas do aplicativo, uma subpasta por área
    correcao/            # Corrigir Prova (QR Code, leitura da folha, resultado, provas corrigidas)
    home/                # Home
    login/               # Login, Cadastro e verificação de e-mail
    perfil/              # Perfil do professor
    provas/              # Criar Prova, Minhas Provas e Visualizar Prova
    questoes/            # formulário de questão
    relatorios/          # Relatórios
    turmas/              # Turmas e Alunos
  services/              # comunicação com o Firebase, leitor da folha, PDF e Excel
  theme/                 # cores, tipografia e espaçamentos do app
  utils/                 # validadores, layout da folha de respostas, PDF e utilitários
  widgets/               # componentes de interface reutilizáveis entre telas
  auth_gate.dart         # mostra Login, verificação de e-mail ou Home conforme a sessão
  firebase_options.dart  # configuração de conexão com o Firebase (gerada pelo FlutterFire)
  main.dart              # inicialização do Firebase e ponto de entrada do app
docs/
  manual/                # manual do usuário (uma seção por módulo)
  telas/                 # prints das telas do app
test/                    # testes automatizados (flutter test)
```

## 7. Como Executar o Projeto

📌 **N1**, revisado a cada entrega

**Usar o app (professor):** instale o arquivo `app-release.apk` em um celular Android (permita "instalar apps desconhecidos" quando o Android pedir), crie a conta e confirme o e-mail. O uso de cada tela está no [manual do usuário](docs/manual/README.md).

**Rodar o código (desenvolvimento):**

```
1. git clone https://github.com/lauraMeie/Trabalho-Dev.git
2. cd Trabalho-Dev
3. flutter pub get
4. flutter run            (com um celular Android conectado ou um emulador)
```

Observações:
- O app já inclui a configuração do Firebase (`lib/firebase_options.dart` e `android/app/google-services.json`).
- Para gerar o APK: `flutter build apk --release`. O arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`.
- Na primeira leitura de QR Code ou foto da folha, o Android pede permissão para usar a câmera.
- Testes automatizados: `flutter test`. Análise estática: `flutter analyze`.

## 8. Backlog de Atividades da N2

📌 **N2**

> Backlog real (o que cada integrante efetivamente fez na N2), com base nos Pull Requests mesclados na branch `main`.

### Laura Meier

| Tarefa | Prazo | Status |
|---|---|---|
| Implementar login com Firebase Authentication | 26/10 | Concluído |
| Criar tela de cadastro de usuário | 26/10 | Concluído |
| Recuperação de senha por e-mail | 26/10 | Concluído |
| Controlar sessão do usuário (AuthGate) e botão Sair | 26/10 | Concluído |
| Contadores reais na Home (Turmas, Alunos, Provas) | 26/10 | Concluído |
| Vincular turmas ao usuário logado (uid) | 26/10 | Concluído |
| Atualizar o README para v2 | 26/10 | Concluído |

### Tiago Spezia

| Tarefa | Prazo | Status |
|---|---|---|
| Implementar leitura real do QR code pela câmera | 27/10 | Concluído |
| Implementar leitura/correção automática real das respostas | 27/10 | Concluído |
| Persistir resultados de correção no Firestore | 27/10 | Concluído |
| Conectar Relatórios aos dados reais do Firestore | 27/10 | Concluído |
| Implementar exportação de notas e resultados em Excel | 27/10 | Concluído |

### Nicolas Dellani

| Tarefa | Prazo | Status |
|---|---|---|
|Substituir a lista mock de turmas por leitura real da coleção 'turmas' no Firestore (listar, criar, editar e excluir) | 22/10 | Concluído |
| Listar, cadastrar, editar e excluir alunos de uma turma direto no banco de dados real, substituindo os dados mock. | 22/10 | Concluído |
| Adaptar as classes Turma e Aluno com métodos toMap()/fromMap() (ou fromJson/toJson) para o Banco. | 22/10 | Concluído |

### Henrique Roberti Ribeiro

| Tarefa | Prazo | Status |
|---|---|---|
| Conectar a tela Criar Prova às turmas do Firestore | 20/10 | Concluído |
| Validar a configuração da prova antes de gerar | 20/10 | Concluído |
| Tratar erros no fluxo de criação de prova | 20/10 | Concluído |
| Gerar o PDF da prova | 20/10 | Concluído |

### Phelipe Gonçalves Blanco

| Tarefa | Prazo | Status |
|---|---|---|
| Conectar o Banco de Questões ao Firestore | 20/10 | Concluído |
| Ajustar o model Question (toMap/fromMap) | 20/10 | Concluído |
| Implementar edição e exclusão de questões | 20/10 | Concluído |
| Validar o formulário de criar/editar questão | 20/10 | Concluído |
| Tratar erros e estados vazios no Banco de Questões | 20/10 | Concluído |
| Persistir a geração de prova no Firestore | 20/10 | Concluído |
| Remover tela duplicada de Banco de Questões | 20/10 | Concluído |

## 9. Backlog de Atividades da N3

📌 **N3**

> Entregas da N3 registradas no repositório (commits e Pull Requests na branch `main`). O planejamento completo, com todas as tarefas, responsáveis e prazos, está na planilha de backlog da N3.

### Laura Meier

| Tarefa | Data | Status |
|---|---|---|
| Minhas Provas: excluir prova e aba Editar Provas | 16/11 | Concluído |
| Ajustes no login e na senha, com verificação de e-mail no cadastro | 23/11 | Concluído |
| Gravar o professor dono (`uid`) nas provas e filtrar Minhas Provas por ele | 25/11 | Concluído |
| Validação de matrícula repetida na turma | 25/11 | Concluído |
| Tela de Perfil, acesso pelo menu e correção do logout | 25/11 | Concluído |
| Configuração do Firebase Hosting | 25/11 | Concluído |

### Tiago Spezia

| Tarefa | Data | Status |
|---|---|---|
| B40 — Folha de respostas com QR Code e leitura pela câmera das alternativas marcadas ([#37](https://github.com/lauraMeie/Trabalho-Dev/pull/37)) | 24/11 | Concluído |
| Correção do check do GitHub Actions (versão do Flutter fixada) ([#37](https://github.com/lauraMeie/Trabalho-Dev/pull/37)) | 24/11 | Concluído |
| B41 — Lista de provas corrigidas com dados reais ([#38](https://github.com/lauraMeie/Trabalho-Dev/pull/38)) | 25/11 | Concluído |
| B42 — Manual do usuário de Correção e Relatórios ([#39](https://github.com/lauraMeie/Trabalho-Dev/pull/39), [#41](https://github.com/lauraMeie/Trabalho-Dev/pull/41), [#45](https://github.com/lauraMeie/Trabalho-Dev/pull/45), [#49](https://github.com/lauraMeie/Trabalho-Dev/pull/49)) | 25/11 | Concluído |
| B38 — Nome da prova e matrícula no resultado da correção ([#42](https://github.com/lauraMeie/Trabalho-Dev/pull/42)) | 25/11 | Concluído |
| Remoção do QR Code de teste ([#43](https://github.com/lauraMeie/Trabalho-Dev/pull/43)) e correção duplicada da mesma folha ([#44](https://github.com/lauraMeie/Trabalho-Dev/pull/44)) | 25/11 | Concluído |
| B08 — Relatório de notas em Excel por turma, com respostas e compartilhamento ([#47](https://github.com/lauraMeie/Trabalho-Dev/pull/47)) | 25/11 | Concluído |
| Baixar e imprimir o PDF de uma prova já salva ([#48](https://github.com/lauraMeie/Trabalho-Dev/pull/48)) | 25/11 | Concluído |

### Nicolas Renan Dellani

| Tarefa | Data | Status |
|---|---|---|
| B02 — Validação de turmas e alunos (nome e matrícula repetidos, espaços extras) ([#46](https://github.com/lauraMeie/Trabalho-Dev/pull/46)) | 25/11 | Concluído |
| B03 — Totais de turmas e alunos para os outros módulos ([#46](https://github.com/lauraMeie/Trabalho-Dev/pull/46)) | 25/11 | Concluído |
| B05 — Busca por nome e matrícula em turmas e alunos ([#46](https://github.com/lauraMeie/Trabalho-Dev/pull/46)) | 25/11 | Concluído |
| B07 — Testes automatizados dos models e validações ([#46](https://github.com/lauraMeie/Trabalho-Dev/pull/46)) | 25/11 | Concluído |

### Henrique Roberti Ribeiro

| Tarefa | Data | Status |
|---|---|---|
| Minhas Provas e Visualizar Prova (consulta e edição das provas salvas) | 16/11 | Concluído |
| QR Code de identificação no PDF da prova, com teste automatizado | 23/11 | Concluído |

### Phelipe Gonçalves Blanco

| Tarefa | Data | Status |
|---|---|---|
| Manual do usuário do Banco de Questões: abrir o banco, carregar questões de exemplo, criar, editar e excluir questão, regras do formulário, prévia de prova gerada e problemas comuns ([#51](https://github.com/lauraMeie/Trabalho-Dev/pull/51)) | 26/11 | Concluído |

---

<div align="center">

*README elaborado para a disciplina de Desenvolvimento de Dispositivos Móveis*

</div>
