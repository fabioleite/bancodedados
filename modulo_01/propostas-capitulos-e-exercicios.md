# Propostas de capítulos e exercícios para o módulo introdutório de Banco de Dados

## Análise do conteúdo atual do módulo

Os arquivos presentes em [modulo_01](.) abordam os conceitos fundamentais de bancos de dados e SGBDs, incluindo:

- definição de banco de dados e SGBD;
- vantagens e desvantagens do uso de SGBDs;
- elementos e serviços de um SGBD;
- histórico e classificações dos sistemas de banco de dados;
- níveis de abstração e independência de dados;
- modelo relacional e exemplos introdutórios;
- aplicação prática de instalação e criação de banco de dados.

Esse conteúdo já fornece uma base sólida para introdução à área. Para ampliar o módulo, sugiro incluir capítulos que conectem os conceitos teóricos com a prática de modelagem e manipulação de dados.

## Capítulos sugeridos para ampliar o módulo

### 1. Modelagem conceitual e lógica
Apresentar a diferença entre modelo conceitual, modelo lógico e modelo físico, com ênfase em entidades, atributos e relacionamentos.

### 2. Entidades, atributos e relacionamentos
Explicar como identificar entidades e relacionamentos em problemas reais e como representar esses conceitos em diagramas.

### 3. Chaves primárias e estrangeiras
Mostrar a importância de chaves para identificar registros únicos e estabelecer relações entre tabelas.

### 4. Integridade e constraints
Apresentar regras como NOT NULL, UNIQUE, CHECK e FOREIGN KEY para garantir a qualidade dos dados.

### 5. Linguagem SQL básica
Introduzir comandos fundamentais de SQL, como CREATE TABLE, INSERT, SELECT, UPDATE e DELETE.

### 6. Normalização introdutória
Explicar os primeiros conceitos de normalização, com exemplos simples de eliminação de redundância.

### 7. Transações e concorrência
Mostrar como o SGBD controla operações simultâneas por meio de transações e isolamento.

### 8. Segurança e permissões
Abordar conceitos básicos de autenticação, autorização e controle de acesso aos dados.

### 9. Backup, recuperação e desempenho
Explicar a importância de backups, restauração e uso básico de índices para melhorar consultas.

### 10. Projeto prático final
Propor um mini projeto de banco de dados para consolidar os conteúdos estudados.

## Exercícios práticos sugeridos

### Exercício 1 — Identificação de entidades
Descreva um cenário simples, como uma biblioteca, e liste:

- quais são as entidades;
- quais atributos pertencem a cada entidade;
- quais relacionamentos existem entre elas.

### Exercício 2 — Modelagem de um cadastro simples
Crie um modelo para armazenar informações de estudantes, disciplinas e matrículas.

Objetivos:

- definir entidades e atributos;
- criar relações entre as tabelas;
- identificar uma chave primária e uma chave estrangeira.

### Exercício 3 — Criação de tabelas em SQL
Escreva os comandos SQL para criar as seguintes tabelas:

- alunos;
- cursos;
- matriculas.

Inclua tipos de dados adequados e constraints básicas.

### Exercício 4 — Manipulação de dados
Utilizando as tabelas criadas no exercício anterior, escreva comandos para:

- inserir dois alunos;
- inserir dois cursos;
- realizar uma matrícula;
- atualizar o nome de um aluno;
- excluir uma matrícula.

### Exercício 5 — Consultas básicas
Elabore consultas para:

- listar todos os alunos;
- listar os cursos disponíveis;
- mostrar quais alunos estão matriculados em um determinado curso;
- encontrar alunos com nome iniciado por uma letra.

### Exercício 6 — Normalização simples
Considere uma tabela com os campos:

- aluno
- curso
- professor
- telefone_professor

Identifique os problemas de redundância e proponha uma estrutura melhor.

### Exercício 7 — Simulação de transação
Crie uma situação em que uma operação seja realizada em duas etapas e explique o que acontece se uma delas falhar.

### Exercício 8 — Mini projeto final
Desenvolva um banco de dados simples para um sistema de biblioteca, contendo:

- livros;
- alunos;
- empréstimos;
- autores.

O aluno deve entregar:

- modelo conceitual;
- modelo lógico;
- comandos DDL;
- comandos DML básicos;
- ao menos cinco consultas.

## Sugestão de organização do módulo

A sequência recomendada para o módulo seria:

1. conceitos básicos de banco de dados e SGBD;
2. modelagem conceitual;
3. modelagem lógica e relacional;
4. SQL básico;
5. integridade e constraints;
6. normalização;
7. transações e segurança;
8. projeto prático final.

Essa organização ajuda a conectar teoria e prática de forma mais natural para os estudantes.
