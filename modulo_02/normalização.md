# Aula Completa: Normalização de Bancos de Dados Relacionais

Esta aula é baseada no livro *Fundamentals of Database Systems* de Ramez Elmasri e Shamkant Navathe, focando no processo de **normalização** como uma técnica para avaliar e melhorar a qualidade do projeto de um banco de dados relacional.

---

## 1. O que é Normalização?

A normalização é o processo de analisar esquemas de relação com base em suas **Dependências Funcionais (DFs)** e chaves primárias. O objetivo principal é atingir três metas:
1.  **Minimizar a redundância** de dados.
2.  **Evitar anomalias de atualização** (inserção, remoção e modificação).
3.  **Garantir a integridade** dos dados no banco de dados.

### Anomalias de Atualização
Quando um projeto é mal estruturado (por exemplo, misturando atributos de funcionários e departamentos em uma única tabela), surgem problemas críticos:
*   **Anomalias de Inserção:** Dificuldade em inserir um novo fato sem que outro fato independente também seja inserido (ex: não poder cadastrar um departamento novo que ainda não possui funcionários).
*   **Anomalias de Remoção:** A exclusão de um registro causa a perda acidental de uma informação diferente (ex: ao deletar o último funcionário de um departamento, os dados desse departamento desaparecem do banco).
*   **Anomalias de Modificação:** Alterar um valor exige a atualização de múltiplas linhas, aumentando o risco de inconsistência (ex: mudar o nome de um departamento exige alterar cada registro de funcionário vinculado a ele).

---

## 2. Conceito Fundamental: Dependência Funcional (DF)

Uma **Dependência Funcional**, denotada por $X \to Y$, especifica que o valor de um conjunto de atributos $X$ determina de forma única o valor do conjunto de atributos $Y$. 
*   **Exemplo:** Em uma empresa, o CPF ($Ssn$) determina o nome do funcionário ($Ename$). Logo, $Ssn \to Ename$.

---

## 3. As Três Formas Normais (1NF, 2NF e 3NF)

O processo de normalização leva uma relação através de uma série de testes para purificar o design.

### Primeira Forma Normal (1NF)
**Definição:** Uma relação está na **1NF** se o domínio de cada atributo incluir apenas **valores atômicos (indivisíveis)** e o valor de cada atributo em uma tupla for um valor único do domínio. Ela proíbe atributos multivalorados ou compostos.

#### Exemplo Concreto:
Considere a tabela $DEPARTAMENTO$  que armazena localizações:
*  $DEPARTAMENTO(Dnome, Dnumero, Dmgr_ssn, Dlocations)$ 
*   Se o departamento "Pesquisa" estiver em Houston, Bellaire e Sugarland, o campo $Dlocations$  conteria o conjunto ${Houston, Bellaire, Sugarland}$ . **Isso viola a 1NF**.

**Como normalizar para 1NF:**
Deve-se remover o atributo multivalorado e colocá-lo em uma relação separada junto com a chave primária da original.
1. $DEPARTAMENTO(Dnome, Dnumero, Dmgr_ssn)$ 
2. $DEPT_LOCATIONS(Dnumber, Dlocation)$  (onde a PK é a combinação de ambos).

---

### Segunda Forma Normal (2NF)
**Definição:** Uma relação está na **2NF** se estiver na 1NF e **todo atributo não-chave for totalmente dependente da chave primária**. Isso significa que nenhum atributo não-chave pode depender de apenas uma *parte* da chave primária (aplicável a chaves compostas).

#### Exemplo Concreto:
Considere a relação que registra o trabalho em projetos:
*  $EMP_PROJ(Ssn, Pnumber, Hours, Ename, Pname, Plocation)$ 
*   A Chave Primária é composta:${Ssn, Pnumber}$ .

**O Problema:**
*  $Hours$  depende de ${Ssn, Pnumber}$  (**Dependência Total**).
*  $Ename$  depende apenas de $Ssn$  (**Dependência Parcial**).
*   $Pname$  depende apenas de $Pnumber$  (**Dependência Parcial**).

**Como normalizar para 2NF:**
Decompõe-se a relação para que os atributos dependam apenas de sua chave inteira.
1.  $EP1(Ssn, Pnumber, Hours)$ 
2.  $EP2(Ssn, Ename)$ 
3.  $EP3(Pnumber, Pname, Plocation)$ .

---

### Terceira Forma Normal (3NF)
**Definição:** Uma relação está na **3NF** se estiver na 2NF e **nenhum atributo não-chave for transitivamente dependente da chave primária**. Ou seja, um atributo não-chave não pode determinar outro atributo não-chave.

#### Exemplo Concreto:
Considere a relação $EMP_DEPT$  que mistura dados de funcionários e seus departamentos:
*   $EMP_DEPT(Ename, Ssn, Bdate, Address, Dnumber, Dname, Dmgr_ssn)$ 
*   A Chave Primária é o $Ssn$ .

**O Problema:**
*  $Ssn \to Dnumber$ (DF direta).
*  $Dnumber \to Dname$  e $Dnumber \to Dmgr_ssn$ .
*   Logo, $Dname$  e $Dmgr_ssn$  dependem de $Ssn$  **transitivamente** através de $Dnumber$ .

**Como normalizar para 3NF:**
Decompõe-se a relação separando o determinante da dependência transitiva em uma nova tabela.
1. $ED1(Ename, Ssn, Bdate, Address, Dnumber)$ 
2. $ED2(Dnumber, Dname, Dmgr_ssn)$ .

---

## Resumo dos Testes de Normalização

| Forma Normal | Teste Principal | Remédio Comum |
| :--- | :--- | :--- |
| **1NF** | Atributos devem ser atômicos. | Mover atributos multivalorados para novas tabelas. |
| **2NF** | Sem dependências parciais da chave primária. | Decompor para associar atributos apenas às suas chaves totais. |
| **3NF** | Sem dependências transitivas entre atributos não-chave. | Separar atributos que dependem de outros atributos não-chave. |

Ao final deste processo, o banco de dados estará livre das redundâncias mais comuns e protegido contra inconsistências durante as operações de atualização.