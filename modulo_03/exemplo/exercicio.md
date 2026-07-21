# Exercício Prático – Importação de Arquivos CSV e Cruzamento de Dados para Auditoria Tributária

## Objetivo

Neste exercício será demonstrado como importar dois arquivos CSV para o SQL Server e realizar o cruzamento dessas informações com uma tabela já existente do banco de dados da auditoria fiscal.

Ao final do exercício o aluno será capaz de:

- importar arquivos CSV para o SQL Server;
- criar tabelas de apoio;
- realizar consultas utilizando `INNER JOIN`;
- enriquecer informações do SPED Fiscal;
- produzir uma base consolidada para auditoria tributária.

---

# Cenário

Suponha que um auditor da SEFAZ possua em seu banco de dados a tabela contendo os produtos declarados pelos contribuintes através da **EFD ICMS/IPI**.

Tabela existente:

```
fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO
```

Além disso, a fiscalização recebeu duas bases oficiais:

- Anexo V do Convênio ICMS (Tabela CEST)
- Base ABCFARMA

Essas duas bases serão utilizadas para validar e complementar os produtos declarados pelos contribuintes.

---

# Arquivo CSV 1

## anexo_5_sefaz.csv

Campos:

```
Tabela_CEST
ITEM
CEST
NCM/SH
DESCRICAO
Legislacao
Vigencia_inicial
Vigencia_final
Aliq_Interna
MVA_Original
...
Origem_Arquivo
Nome_Aba_Planilha
```

Essa tabela contém o relacionamento oficial entre:

- NCM
- CEST
- MVA
- Alíquota Interna
- Legislação

---

# Arquivo CSV 2

## abcfarma.csv

Campos principais

```
CODIGO
EAN
REGISTRO ANVISA
NCM
CEST
NOME
LABORATORIO
TIPO
CLASSE TERAPEUTICA
COMPOSICAO
...
PMC
PF
DATA_VIGENCIA
GGREM
ARQUIVO_ORIGEM
```

Esta base contém informações comerciais e regulatórias dos medicamentos comercializados no Brasil.

---

# Tabela existente

```sql
fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO
```

Principais campos

|Campo|Descrição|
|------|-----------|
|REG0200_COD_ITEM|Código do produto no contribuinte|
|REG0200_DESCR_ITEM|Descrição|
|REG0200_COD_BARRA|Código de barras|
|REG0200_COD_NCM|NCM declarado|
|REG0200_CEST|CEST declarado|
|REG0200_ALIQ_ICMS|Alíquota ICMS|

---

# Passo 1 — Criar banco de dados

```sql
CREATE DATABASE AuditoriaFiscal;
GO

USE AuditoriaFiscal;
GO
```

---

# Passo 2 — Criar tabela para o Anexo V

Para facilitar a importação, inicialmente criaremos todos os campos como VARCHAR.

```sql
CREATE TABLE dbo.TB_ANEXO5_SEFAZ
(
    Tabela_CEST varchar(30),
    ITEM varchar(30),
    CEST varchar(20),
    NCM_SH varchar(20),
    DESCRICAO varchar(500),
    Legislacao varchar(200),
    Vigencia_inicial date,
    Vigencia_final date,
    Aliq_Interna decimal(8,2),
    MVA_Original decimal(8,2),
    Origem_Arquivo varchar(200),
    Nome_Aba_Planilha varchar(100)
);
```

*(Os demais campos podem ser acrescentados conforme necessidade.)*

---

# Passo 3 — Criar tabela da ABCFARMA

```sql
CREATE TABLE dbo.TB_ABCFARMA
(
    CODIGO varchar(20),
    EAN varchar(30),
    REGISTRO_ANVISA varchar(20),
    NCM varchar(20),
    CEST varchar(20),
    NOME varchar(300),
    LABORATORIO varchar(200),
    CLASSE_TERAPEUTICA varchar(300),
    COMPOSICAO varchar(500),
    PMC decimal(18,2),
    PF decimal(18,2),
    DATA_VIGENCIA date,
    GGREM varchar(20),
    ARQUIVO_ORIGEM varchar(200)
);
```

---

# Passo 4 — Importar os arquivos CSV

No SQL Server Management Studio

```
Banco

↓

Tasks

↓

Import Flat File
```

Importar

```
anexo_5_sefaz.csv
```

Depois

```
abcfarma.csv
```

---

## Alternativa utilizando BULK INSERT

### Anexo V

```sql
BULK INSERT dbo.TB_ANEXO5_SEFAZ
FROM 'C:\Importacao\anexo_5_sefaz.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE='65001'
);
```

---

### ABCFARMA

```sql
BULK INSERT dbo.TB_ABCFARMA
FROM 'C:\Importacao\abcfarma.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE='65001'
);
```

---

# Passo 5 — Conferindo os dados

```sql
SELECT TOP 10 *
FROM dbo.TB_ANEXO5_SEFAZ;
```

```sql
SELECT TOP 10 *
FROM dbo.TB_ABCFARMA;
```

---

# Passo 6 — Cruzamento entre SPED e Anexo V

Relacionar pelo NCM.

```sql
SELECT

    E.REG0200_COD_ITEM,
    E.REG0200_DESCR_ITEM,
    E.REG0200_COD_NCM,
    E.REG0200_CEST,

    A.CEST AS CEST_OFICIAL,
    A.DESCRICAO,
    A.Aliq_Interna,
    A.MVA_Original

FROM fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO E

INNER JOIN dbo.TB_ANEXO5_SEFAZ A

ON E.REG0200_COD_NCM = A.NCM_SH;
```

---

# Passo 7 — Cruzamento entre SPED e ABCFARMA

```sql
SELECT

    E.REG0200_COD_ITEM,
    E.REG0200_DESCR_ITEM,
    E.REG0200_COD_BARRA,

    B.NOME,
    B.LABORATORIO,
    B.REGISTRO_ANVISA,
    B.PMC,
    B.PF

FROM fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO E

INNER JOIN dbo.TB_ABCFARMA B

ON E.REG0200_COD_NCM = B.NCM;
```

---

# Passo 8 — Cruzamento das três tabelas

```sql
SELECT

    E.REG0200_COD_ITEM,
    E.REG0200_DESCR_ITEM,
    E.REG0200_COD_NCM,

    A.CEST,
    A.MVA_Original,
    A.Aliq_Interna,

    B.NOME,
    B.LABORATORIO,
    B.PMC,
    B.PF

FROM fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO E

LEFT JOIN dbo.TB_ANEXO5_SEFAZ A

ON E.REG0200_COD_NCM = A.NCM_SH

LEFT JOIN dbo.TB_ABCFARMA B

ON E.REG0200_COD_NCM = B.NCM;
```

---

# Passo 9 — Produtos sem correspondência no Anexo V

```sql
SELECT

E.REG0200_COD_ITEM,
E.REG0200_DESCR_ITEM,
E.REG0200_COD_NCM

FROM fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO E

LEFT JOIN dbo.TB_ANEXO5_SEFAZ A

ON E.REG0200_COD_NCM=A.NCM_SH

WHERE A.NCM_SH IS NULL;
```

Esses registros merecem análise, pois podem indicar:

- NCM incorreto;
- classificação fiscal desatualizada;
- produto inexistente na tabela oficial.

---

# Passo 10 — Produtos cujo CEST diverge

```sql
SELECT

E.REG0200_COD_ITEM,
E.REG0200_DESCR_ITEM,

E.REG0200_CEST AS CEST_DECLARADO,

A.CEST AS CEST_OFICIAL

FROM fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO E

INNER JOIN dbo.TB_ANEXO5_SEFAZ A

ON E.REG0200_COD_NCM=A.NCM_SH

WHERE
CAST(E.REG0200_CEST AS VARCHAR)=A.CEST;
```

*(Observação: para identificar divergências, a condição correta seria `CAST(E.REG0200_CEST AS VARCHAR) <> A.CEST`.)*

---

# Fluxo do Processo

```text
              SPED FISCAL
                  │
                  │
                  ▼
     Registro 0200 (Produtos)
                  │
      ┌───────────┴────────────┐
      │                        │
      ▼                        ▼
Anexo V SEFAZ             ABCFARMA
 (CEST/MVA)            (Medicamentos)
      │                        │
      └───────────┬────────────┘
                  │
                  ▼
      Base Consolidada de Auditoria
                  │
                  ▼
      Relatórios e Cruzamentos
```

---

# Aplicação na Auditoria Tributária

O Registro 0200 da EFD ICMS/IPI contém os produtos informados pelo contribuinte, incluindo descrição, código interno, NCM, CEST e alíquota de ICMS. Entretanto, essas informações refletem apenas o que foi declarado.

Ao integrar esses dados com a tabela oficial do **Anexo V da SEFAZ**, o auditor consegue verificar se a classificação fiscal (NCM) e o CEST estão compatíveis com a legislação vigente, além de recuperar automaticamente informações como MVA, alíquota interna e vigência normativa. Isso permite identificar indícios de enquadramento incorreto, aplicação indevida da substituição tributária (ICMS-ST) ou utilização de parâmetros desatualizados.

No caso dos medicamentos, o cruzamento com a base **ABCFARMA** adiciona informações regulatórias e comerciais, como registro na ANVISA, laboratório fabricante, código GGREM, Preço Fábrica (PF) e Preço Máximo ao Consumidor (PMC). Essas informações são úteis para validar a identificação do produto, conferir preços regulados e detectar inconsistências entre os produtos comercializados e os efetivamente declarados pelo contribuinte.

A consolidação dessas três fontes de dados — **SPED Fiscal**, **Anexo V** e **ABCFARMA** — fornece uma base enriquecida que apoia diversas atividades de auditoria fiscal, tais como:

- validação da classificação fiscal (NCM);
- conferência do CEST informado pelo contribuinte;
- identificação de produtos sujeitos ao regime de Substituição Tributária;
- recuperação automática da MVA e da alíquota interna aplicável;
- validação de medicamentos junto à ANVISA e à CMED;
- identificação de produtos sem correspondência em bases oficiais;
- seleção de contribuintes com maior potencial de risco para fiscalização.

Esse tipo de enriquecimento de dados é uma prática comum em projetos de inteligência fiscal, pois reduz o trabalho manual do auditor, aumenta a qualidade das análises e possibilita a construção de regras automatizadas para detecção de inconsistências e indícios de evasão tributária.