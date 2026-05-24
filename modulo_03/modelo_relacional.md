# O MODELO RELACIONAL
*Apresentação: Fábio Leite*

## AGENDA

1.  Conceitos
2.  Restrições e regras de integridade
3.  Projeto relacional
4.  Normalização


# 1. Conceitos Fundamentais do Modelo Relacional

Nesta seção apresentamos o **Modelo Relacional**, proposto por Edgar F. Codd, como uma abordagem formal para organização de dados em bancos de dados.

O modelo relacional é fundamentado em:

- Teoria dos conjuntos
- Relações matemáticas
- Lógica de predicados

O Modelo se tornou um padrão de fato para aplicações comerciais,
devido a sua simplicidade e performance.

Um dos SGBD's precursores que implementaram este modelo foi o System R (IBM). Baseado em seus conceitos surgiram: DB2 (IBM), SQL-DS (IBM), Oracle, Informix, Ingres, Sybase entre outros.

A principal ideia é representar os dados por meio de **relações (tabelas)**.

---

## 1.1 Relação (Relation)

Uma relação corresponde a uma tabela relacional.

### A. Exemplo

| Matr | Nome  | Endereço                         | Função      | Salário  | Departamento |
|------|-------|----------------------------------|-------------|----------|-------|
| 100  | Ana   | R. Pedro I, 12, A. Branco        | Secretária  | 500,00   | D1    |
| 250  | Pedro | R. J. Silva, 24, Liberdade       | Engenheiro  | 1500,00  | D1    |
| 108  | André | R. Itália, 33, B. Nações         | Técnico     | 950,00   | D2    |
| 210  | Paulo | R. Pará 98, B. Estados           | Engenheiro  | 1810,00  | D2    |

### Características

- Cada tabela terá um nome, que será único, e um conjunto de atributos com seus respectivos nomes e domínios.
- **Valores Atômicos**: Cada valor em uma tupla deve ser indivisível. Atributos multivalorados ou compostos não são permitidos no modelo relacional básico (esta é a Primeira Forma Normal ou 1NF)
- **Ordenação**: A ordem das tuplas em uma relação não é importante, assim como, a ordem das colunas.
- **Valores NULL**: Representam valores desconhecidos ou que não se aplicam a uma tupla específica
---

## Tupla (Tuple)

Uma tupla representa uma linha da tabela.
- **Não existem tuplas duplicadas**

### Exemplo

```text
(210, Paulo R. Pará 98, Bairro Estados, Engenheiro, 1810.00, D2)
```

Cada tupla representa uma ocorrência específica de uma entidade.

---

## Atributo (Attribute)

Os atributos representam as colunas da relação.
- Todos os valores de uma coluna são do mesmo tipo de dados

### Exemplos

- Matrícula
- Nome
- Endereço
- Função
- Salário
- Departamento 

Cada atributo possui:

- Nome
- Tipo de dado
- Domínio associado

---

## Domínio (Domain)

Um domínio define os valores válidos permitidos para um atributo.

### Exemplos

| Atributo | Domínio |
|---|---|
| Salário | números positivos |
| Nome | cadeias de caracteres |
| Idade| inteiros positivos |

O domínio funciona como uma restrição semântica.

---

# Esquema Relacional

Um esquema relacional define:

- Nome da relação
- Conjunto de atributos
- Domínios

### Representação

```text
EMPLOYEE(Ssn, Name, Salary)
```

---

# Estado da Relação

O estado da relação corresponde ao conjunto atual de tuplas armazenadas.

---

# Grau e Cardinalidade

## Grau (Degree)

O número de atributos que seu
esquema contém.

### Exemplo

```text
EMPLOYEE(Ssn, Name, Salary)
```

Grau = 3

---

## Cardinalidade

Quantidade de tuplas da relação.

### Exemplo

Se a tabela possui 100 registros:

```text
Cardinalidade = 100
```

---

# Valores NULL

O modelo relacional admite valores NULL.

NULL pode representar:

- Valor desconhecido
- Valor inexistente
- Valor não aplicável

### Exemplo

| Employee | Bonus |
|---|---|
| João | NULL |

NULL não é:

- Zero
- String vazia

---

# Resumo das Características das Relações

Uma relação válida deve obedecer:

1. Cada célula possui valor atômico
2. Não existem tuplas duplicadas
3. Todos os valores de uma coluna pertencem ao mesmo domínio
4. Cada atributo possui nome único
5. A ordem das linhas não importa
6. A ordem das colunas não importa

Essas propriedades definem a Primeira Forma Normal (1FN).

---

# Estrutura Conceitual de uma Relação

| Ssn | Name | Salary | Dept |
|---|---|---|---|
| 111 | Ana | 5000 | 5 |
| 222 | Bruno | 6000 | 4 |
| 333 | Carla | 7200 | 1 |

### Interpretação

- Linhas → Tuplas
- Colunas → Atributos
- Tabela → Relação

---

# Chaves no Modelo Relacional

## Superchave (Super Key)

Conjunto de atributos capaz de identificar unicamente uma tupla.

### Exemplos

- Ssn
- Ssn + Name
- Ssn + Salary

---

## Chave Candidata (Candidate Key)

Superchave mínima.

### Exemplo

```text
Ssn
```

---

## Chave Primária (Primary Key)

Uma das chaves candidatas escolhida para identificar as tuplas.

### Características

- Não pode repetir
- Não pode ser NULL

### Exemplo

```text
EMPLOYEE(Ssn)
```

---

## Chave Alternativa

Chaves candidatas não escolhidas como chave primária.

---

## Chave Estrangeira (Foreign Key)

Atributo que referencia uma chave primária de outra relação.

### Exemplo

```text
DEPARTMENT(Dnumber)
EMPLOYEE(Dno)
```

Onde:

```text
EMPLOYEE.Dno → DEPARTMENT.Dnumber
```

---

# Relacionamento entre Relações

## DEPARTMENT

| Dnumber | Dname |
|---|---|
| 1 | Research |
| 5 | Sales |

## EMPLOYEE

| Ssn | Name | Dno |
|---|---|---|
| 111 | Ana | 1 |
| 222 | Bruno | 5 |

---

# 5.2 Relational Model Constraints and Relational Database Schemas

O capítulo apresenta as restrições de integridade.

Essas restrições garantem:

- Consistência
- Correção semântica
- Validade dos dados

---

# Tipos de Restrições

## Domain Constraints

Os valores devem pertencer ao domínio definido.

### Exemplo

```text
Age deve ser inteiro positivo
```

---

## Key Constraints

As chaves devem ser únicas.

Não podem existir duas tuplas com a mesma chave primária.

---

## Entity Integrity Constraint

A chave primária nunca pode ser NULL.

### Motivação

Cada tupla precisa ser identificável.

---

## Referential Integrity Constraint

A chave estrangeira deve:

- Referenciar um valor existente
ou
- Ser NULL

### Exemplo

Se:

```text
EMPLOYEE.Dno = 5
```

Então deve existir:

```text
DEPARTMENT.Dnumber = 5
```

---

# Integridade Referencial

## Situação válida

### DEPARTMENT

| Dnumber |
|---|
| 1 |
| 5 |

### EMPLOYEE

| Name | Dno |
|---|---|
| Ana | 1 |
| Bruno | 5 |

---

## Situação inválida

### EMPLOYEE

| Name | Dno |
|---|---|
| Carlos | 9 |

Erro:

```text
Departamento 9 não existe
```

---

# Relational Database Schema

Um banco relacional é composto por múltiplos esquemas relacionais.

### Exemplos

- EMPLOYEE
- DEPARTMENT
- PROJECT
- WORKS_ON

Cada relação possui:

- atributos
- chaves
- restrições

---

# Schema e State

## Schema

Estrutura lógica do banco.

Define:

- tabelas
- atributos
- restrições

Muda raramente.

---

## State (Instance)

Conteúdo atual do banco.

Muda frequentemente.

---

# 5.3 Update Operations, Transactions, and Dealing with Constraint Violations

O capítulo apresenta operações de atualização.

Principais operações:

- INSERT
- DELETE
- UPDATE

Essas operações podem causar violações de restrições.

---

# INSERT

Adiciona novas tuplas.

## Possíveis violações

1. Violação de chave primária
2. Violação de domínio
3. Violação de integridade referencial

### Exemplo

Inserir funcionário com departamento inexistente.

---

# DELETE

Remove tuplas.

## Problema clássico

Remover uma tupla referenciada por outra tabela.

### Exemplo

Excluir departamento utilizado por funcionários.

---

# Estratégias para DELETE

## Restrict

Impede exclusão.

---

## Cascade

Remove automaticamente registros dependentes.

---

## Set Null

Define chaves estrangeiras como NULL.

---

## Set Default

Substitui pelo valor padrão.

---

# Exemplo de DELETE CASCADE

## Antes

### DEPARTMENT

| Dnumber |
|---|
| 5 |

### EMPLOYEE

| Name | Dno |
|---|---|
| Ana | 5 |
| Bruno | 5 |

---

## Depois

### DEPARTMENT

| Dnumber |
|---|
| vazio |

### EMPLOYEE

| Name | Dno |
|---|---|
| vazio | vazio |

---

# UPDATE

Modifica valores existentes.

## Possíveis violações

- Violação de domínio
- Violação de integridade referencial
- Violação de chave

### Exemplo

Alterar chave primária referenciada.

---

# Transações

Uma transação corresponde a uma unidade lógica de trabalho.

### Características

- Conjunto de operações
- Execução completa
- Preservação da consistência

### Exemplo

Transferência bancária:

1. Debitar conta A
2. Creditar conta B

As duas operações precisam ocorrer juntas.

---

# Atomicidade

Uma transação:

- Executa completamente
ou
- Não executa nada

Isso evita inconsistências.

---

# Violação de Restrições

Quando uma operação viola restrições, o SGBD pode:

- Rejeitar a operação
- Cancelar a transação
- Aplicar regras automáticas

---

# Banco de Dados COMPANY

O capítulo utiliza o banco COMPANY como exemplo principal.

## Relações principais

- EMPLOYEE
- DEPARTMENT
- PROJECT
- WORKS_ON
- DEPENDENT

O banco COMPANY é usado para demonstrar:

- chaves
- integridade referencial
- consultas
- operações de atualização

---

# Fundamentos Matemáticos do Modelo Relacional

O modelo relacional possui base formal matemática.

### Elementos fundamentais

- Relações matemáticas
- Produto cartesiano
- Conjuntos
- Predicados lógicos

Uma relação é subconjunto do produto cartesiano dos domínios.

---

# Comparação com Arquivos Tradicionais

## Arquivos Tradicionais

- Forte acoplamento
- Redundância
- Dificuldade de manutenção
- Baixa independência de dados

---

## Modelo Relacional

- Estrutura simples
- Independência lógica
- Integridade
- Linguagens declarativas
- Facilidade de consulta

---

# Resumo Geral dos Conceitos

| Conceito | Definição |
|---|---|
| Relação | Tabela relacional |
| Tupla | Linha da tabela |
| Atributo | Coluna da tabela |
| Domínio | Conjunto válido de valores |
| Chave Primária | Identificador único |
| Chave Estrangeira | Referência para outra tabela |
| Integridade de Entidade | PK não pode ser NULL |
| Integridade Referencial | FK deve existir na tabela referenciada |
| Esquema | Estrutura do banco |
| Estado | Conteúdo atual |
| INSERT | Inserção de dados |
| DELETE | Remoção de dados |
| UPDATE | Alteração de dados |
| Transação | Unidade lógica de execução |

---

# Principais Ideias do Capítulo

1. O modelo relacional organiza dados em tabelas.
2. Relações possuem atributos e tuplas.
3. Restrições garantem integridade.
4. Chaves identificam e relacionam dados.
5. Integridade referencial mantém consistência.
6. Operações de atualização podem violar restrições.
7. Transações garantem consistência do banco.
8. O modelo relacional possui base matemática formal.

---

# Estrutura do Capítulo

## 5.1 Relational Model Concepts

- Relações
- Tuplas
- Atributos
- Domínios
- Chaves

---

## 5.2 Relational Model Constraints and Relational Database Schemas

- Restrições
- Integridade de entidade
- Integridade referencial
- Esquemas relacionais

---

## 5.3 Update Operations, Transactions, and Dealing with Constraint Violations

- INSERT
- DELETE
- UPDATE
- Transações
- Tratamento de violações

---

## 5.4 Summary

Síntese dos conceitos fundamentais do modelo relacional.

---

# Conclusão

O Capítulo 5 apresenta os fundamentos do paradigma relacional.

Os principais aprendizados são:

- organização relacional dos dados;
- uso de tabelas e relacionamentos;
- mecanismos de integridade;
- impacto das operações de atualização;
- importância das transações;
- fundamentos matemáticos do modelo relacional.

Esses conceitos servem como base para:

- SQL
- Álgebra Relacional
- Normalização
- Otimização
- Controle de transações
- Modelagem de bancos relacionais