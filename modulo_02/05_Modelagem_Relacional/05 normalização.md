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

#### Exemplo Concreto 1: EFD com múltiplos valores em uma mesma coluna
Considere uma tabela que armazena a EFD com vários documentos em uma única linha:

- `EFD_DOCS(id_efd, periodo, documentos)`

Se `documentos` armazenasse vários registros como `NFE1;NFE2;NFE3`, isso viola a 1NF porque a coluna contém mais de um valor em uma mesma célula.

**Como normalizar para 1NF:**
1. `EFD(id_efd, periodo, id_contribuinte)`
2. `EFD_DOCUMENTO(id_efd, id_documento)`

#### Exemplo Concreto 2: NF-e com múltiplos itens em uma mesma linha
Considere uma relação:

- `NFE(id_nfe, chave_acesso, valor_total, itens)`

Se `itens` contiver algo como `100;200;300`, a coluna não é atômica.

**Como normalizar para 1NF:**
1. `NFE(id_nfe, chave_acesso, valor_total)`
2. `ITEM_NFE(id_item, id_nfe, descricao, valor_item)`

---

### Segunda Forma Normal (2NF)
**Definição:** Uma relação está na **2NF** se estiver na 1NF e **todo atributo não-chave for totalmente dependente da chave primária**. Isso significa que nenhum atributo não-chave pode depender de apenas uma parte da chave primária.

#### Exemplo Concreto: NF-e com chave composta
Considere uma relação:

- `ITEM_NFE(id_nfe, id_item, descricao_item, valor_item, valor_total_nfe)`

Se a chave primária for composta `(id_nfe, id_item)`, então:
- `descricao_item` e `valor_item` dependem de toda a chave composta.
- `valor_total_nfe` depende apenas de `id_nfe`.

Isso viola a 2NF, porque `valor_total_nfe` depende parcialmente da chave primária.

**Como normalizar para 2NF:**
1. `ITEM_NFE(id_nfe, id_item, descricao_item, valor_item)`
2. `NFE(id_nfe, valor_total_nfe)`

---

### Terceira Forma Normal (3NF)
**Definição:** Uma relação está na **3NF** se estiver na 2NF e **nenhum atributo não-chave for transitivamente dependente da chave primária**.

#### Exemplo Concreto: dados de contribuinte dentro da NF-e
Considere uma relação:

- `NFE(id_nfe, chave_acesso, id_contribuinte, nome_contribuinte, cnpj_contribuinte, uf_contribuinte)`

Aqui, `nome_contribuinte`, `cnpj_contribuinte` e `uf_contribuinte` dependem do `id_contribuinte`, e não diretamente da NF-e.

**Problema:** há redundância e dependência transitiva.

**Como normalizar para 3NF:**
1. `NFE(id_nfe, chave_acesso, id_contribuinte)`
2. `CONTRIBUINTE(id_contribuinte, nome_contribuinte, cnpj_contribuinte, uf_contribuinte)`

---

## Exemplos adicionais de normalização aplicada à fiscalização tributária

### Exemplo 1: Separar cabeçalho e detalhe
Uma tabela com muitos campos da NF-e e todos os itens em uma única linha fica difícil de manter. O ideal é separar:

- `NFE` → dados gerais da nota.
- `ITEM_NFE` → detalhes de cada item.

### Exemplo 2: Evitar repetição de dados do emitente
Se a mesma informação do emitente aparecer repetidamente em várias NF-e, ela deve ser armazenada em uma tabela própria.

- `CONTRIBUINTE`
- `NFE`

### Exemplo 3: Separar tabelas de domínios fiscais
Valores como `CFOP`, `CST`, `NCM` e `UF` podem ser organizados em tabelas de apoio, evitando repetição e inconsistência.

- `CFOP(id_cfop, descricao)`
- `CST(id_cst, descricao)`
- `NCM(id_ncm, descricao)`

---

## Exercícios de normalização

### Exercício 1 — 1NF
Uma tabela foi criada assim:

`EFD_DOCUMENTO(id_efd, periodo, documentos)`

Onde `documentos` contém valores como `NFE001;NFE002;NFE003`.

Pergunta:
- Por que essa tabela não está na 1NF?
- Como corrigir a estrutura?

### Exercício 2 — 2NF
Considere a tabela:

`ITEM_NFE(id_nfe, id_item, descricao_item, valor_item, valor_total_nfe)`

Pergunta:
- O que viola a 2NF?
- Como separar corretamente as tabelas?

### Exercício 3 — 3NF
Considere a tabela:

`NFE(id_nfe, chave_acesso, id_contribuinte, nome_contribuinte, cnpj_contribuinte)`

Pergunta:
- Por que essa tabela não está na 3NF?
- Como reestruturar?

### Exercício 4 — Aplicação prática
Imagine que uma empresa armazena todas as informações de NF-e em uma única tabela com os campos:
- `id_nfe`
- `chave_acesso`
- `emitente`
- `cnpj_emitente`
- `item1`
- `valor_item1`
- `item2`
- `valor_item2`

Pergunta:
- Quais problemas esse modelo apresenta?
- Como normalizar para um modelo mais adequado?

### Exercício 5 — Proposta de modelagem
Elabore um modelo normalizado para o seguinte cenário:
- uma EFD registra várias NF-e;
- cada NF-e possui vários itens;
- cada contribuinte pode emitir várias NF-e;
- cada item pode possuir um NCM e um CFOP.

---

## Resumo dos Testes de Normalização

| Forma Normal | Teste Principal | Remédio Comum |
| :--- | :--- | :--- |
| **1NF** | Atributos devem ser atômicos. | Mover atributos multivalorados para novas tabelas. |
| **2NF** | Sem dependências parciais da chave primária. | Decompor para associar atributos apenas às suas chaves totais. |
| **3NF** | Sem dependências transitivas entre atributos não-chave. | Separar atributos que dependem de outros atributos não-chave. |

Ao final deste processo, o banco de dados estará livre das redundâncias mais comuns e protegido contra inconsistências durante as operações de atualização, especialmente em cenários de fiscalização tributária, onde a confiabilidade dos dados é essencial.