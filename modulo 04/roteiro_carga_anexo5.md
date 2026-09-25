x	

# Roteiro de Carga — Tabela do Anexo 5 (CEST/MVA) no BDFISC

**Arquivo de origem:** `tabela_anexo_5_sefaz.csv`
**Banco de destino:** BDFISC — esquema `fisc`
**Tabela alvo:** `fisc.anexo5_sefaz_normalizado` (já existe no banco)
**Plataforma:** SQL Server (T-SQL) — SSMS / VS Code + extensão MSSQL

---

## Etapa 1 — Análise preparatória do arquivo

Antes de escrever uma única linha de `BULK INSERT`, o arquivo precisa ser interrogado. Carregar sem investigar é a forma mais rápida de gerar uma tabela silenciosamente errada — os erros que não param a carga são os perigosos.

### 1.1 Fatos estruturais apurados


| Característica                    | Valor apurado    | Consequência para a carga                                                                  |
| ------------------------------------ | ------------------ | --------------------------------------------------------------------------------------------- |
| Codificação                      | UTF-8**sem BOM** | `CODEPAGE = '65001'` obrigatório, senão acentos viram lixo (`cerâmica` → `cerÃ¢mica`) |
| Terminador de linha                | CRLF (`0x0D0A`)  | Ver 1.4 — interage com`FORMAT='CSV'`                                                       |
| Delimitador de campo               | Pipe`            | `                                                                                           |
| Cabeçalho                         | 1 linha          | `FIRSTROW = 2`                                                                              |
| Colunas                            | 43               | A tabela de staging precisa ter exatamente 43                                               |
| Linhas físicas (após cabeçalho) | 1.843            | **Não** é o número de registros                                                          |
| Registros lógicos                 | 1.842            | Diferença de 1: há quebra de linha embutida                                               |
| Registros com conteúdo            | 1.836            | 6 linhas totalmente vazias no final                                                         |
| Separador decimal                  | Ponto (`.`)      | Não é o padrão pt-BR; ver 1.5                                                            |
| Aspas presentes                    | Sim (61 pares)   | `FIELDQUOTE = '"'` obrigatório                                                             |

### 1.2 O problema mais grave: quebra de linha dentro de campo com aspas

O registro do CEST `25.032.00` / NCM `87046000` (veículos elétricos de transporte de mercadorias) tem a `DESCRICAO` entre aspas, e dentro dela existe um **CRLF seguido de linha em branco**. O campo ocupa três linhas físicas do arquivo:

```
25|32.0|25.032.00  |87046000|"Outros veículos para transporte de mercadorias, [...] 3,9 toneladas   
                                                    ← linha física em branco, dentro das aspas
"|DECRETO ICMS/PB Nº46.210/25|2025-02-01 00:00:00|...
```

Sem `FORMAT = 'CSV'` e `FIELDQUOTE = '"'`, o `BULK INSERT` vai tratar isso como três linhas independentes: uma com 5 campos, uma vazia e uma com 39 campos. Resultado: erro de conversão, ou pior — carga parcial com registro truncado.

**Esta é a razão pela qual `FORMAT = 'CSV'` não é opcional neste arquivo.**

### 1.3 Sujeira de conteúdo (não impede a carga, contamina a análise)


| Coluna                      | Problema                                              | Exemplo                                                                          |
| ----------------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `Vigencia_inicial`          | Data em formato inválido                             | `27/03 2020` (falta a barra do ano)                                              |
| `Vigencia_final`            | Valor com um único espaço em branco                 | `' '` — não é `NULL`, não é data                                            |
| `MVA_Original_deriv_Petr`   | Texto em coluna numérica                             | `AD REM`, `PMPF`, `DIFERIMENTO`                                                  |
| `MVA_Original_N_deriv_Petr` | Texto livre em coluna numérica                       | `conforme art.2º do decreto 46.692/25`                                          |
| `CEST`                      | Espaços à direita                                   | `'25.032.00  '`                                                                  |
| `NCM/SH`                    | Pontuação inconsistente                             | `1902.20.00` entre 418 valores só de dígitos                                   |
| `NCM/SH`                    | Comprimento variável: 4, 5, 6, 7, 8, 9 e 10 dígitos | NCM na tabela CEST é**prefixo** (posição/subposição), não código completo |
| `ITEM`                      | Formatado como decimal                                | `1.0`, `1.1`, `104.0` — é numeração de item, não valor                      |
| Últimas 6 linhas           | Todos os 43 campos vazios                             | Resíduo da conversão do XLSX                                                   |

`Pauta_Fiscal`, `Lista`, `Ato_Cotepe` e `Funcep_Bebidas_Gaseificada` também têm conteúdo textual, mas ali isso é **esperado** — são colunas-marcador (`'Pauta'`, `'Positiva'`, `'Ato Cotepe'`), não numéricas. Repare que a DDL existente de `fisc.anexo5_sefaz_normalizado` acerta em `Pauta_Fiscal nvarchar(200)` mas erra em `Funcep_Bebidas_Gaseificada`, tipada como `nvarchar(200)` quando os dados são numéricos, e em `MVA_Original_deriv_Petr decimal(18,4)`, que **não comporta** `AD REM`.

### 1.4 Nomes de coluna hostis ao T-SQL

Sete cabeçalhos contêm caracteres que exigem colchetes ou quebram scripts: `NCM/SH`, `MVA_Original_S/Fid`, `MVA_S/Fid_Aliq_4%`, `Exterior_UF_nao_Signat.`, `Funcep_Consumo_maior_100Kw/h` e similares. A tabela de destino já resolveu isso trocando `/` e `%` por `_` (`NCM_SH`, `MVA_S_Fid_Aliq_4`). A staging deve seguir a mesma convenção.

### 1.5 Por que carregar tudo como texto

O separador decimal do arquivo é o ponto. Se o `BULK INSERT` gravar direto em colunas `decimal`, a conversão depende do idioma da sessão e do `collation` — em uma sessão pt-BR, `0.7178` pode ser lido como `7178`. Somado ao texto em colunas numéricas (1.3), a conclusão é:

> **Carregue tudo como `NVARCHAR` numa staging, converta com `TRY_CONVERT` num segundo passo.** O que não converter vira `NULL` e fica visível — em vez de derrubar a carga inteira ou, pior, entrar com valor errado.

### 1.6 Comandos de investigação (execute antes de carregar)

No PowerShell, na máquina onde está o arquivo:

```powershell
# Codificação e BOM (primeiros bytes; se começar com EF BB BF, há BOM)
Format-Hex -Path .\tabela_anexo_5_sefaz.csv -Count 8

# Contagem de linhas físicas
(Get-Content .\tabela_anexo_5_sefaz.csv | Measure-Object -Line).Lines

# Linhas cujo número de pipes difere de 42 (43 colunas → 42 delimitadores)
Get-Content .\tabela_anexo_5_sefaz.csv |
  Where-Object { ($_.ToCharArray() | Where-Object {$_ -eq '|'}).Count -ne 42 }
```

A última verificação é a que revela a quebra de linha embutida. Guarde o resultado: ele será conferido de novo na Etapa 3.

---

## Etapa 2 — Carga com BULK INSERT

### 2.1 Criar a tabela de staging

Todas as colunas em `NVARCHAR`, na ordem exata do arquivo, mais três colunas de controle.

```sql
USE BDFISC;
GO

IF OBJECT_ID('staging.anexo5_bruto', 'U') IS NOT NULL
    DROP TABLE staging.anexo5_bruto;
GO

CREATE TABLE staging.anexo5_bruto (
    Tabela_CEST                   NVARCHAR(50),
    ITEM                          NVARCHAR(50),
    CEST                          NVARCHAR(50),
    NCM_SH                        NVARCHAR(50),
    DESCRICAO                     NVARCHAR(2000),
    Legislacao                    NVARCHAR(2000),
    Vigencia_inicial              NVARCHAR(50),
    Vigencia_final                NVARCHAR(50),
    Aliq_Interna                  NVARCHAR(50),
    MVA_Original                  NVARCHAR(50),
    MVA_Original_S_Fid            NVARCHAR(50),
    MVA_S_Fid_Aliq_4              NVARCHAR(50),
    MVA_S_Fid_Aliq_7              NVARCHAR(50),
    MVA_S_Fid_Aliq_12             NVARCHAR(50),
    MVA_Original_C_Fid            NVARCHAR(50),
    MVA_C_Fid_Aliq_4              NVARCHAR(50),
    MVA_C_Fid_Aliq_7              NVARCHAR(50),
    MVA_C_Fid_Aliq_12             NVARCHAR(50),
    Funcep                        NVARCHAR(50),
    Pauta_Fiscal                  NVARCHAR(200),
    MVA_Aliq_4                    NVARCHAR(50),
    MVA_Aliq_7                    NVARCHAR(50),
    MVA_Aliq_12                   NVARCHAR(50),
    Funcep_Bebidas_Gaseificada    NVARCHAR(200),
    MVA_Original_deriv_Petr       NVARCHAR(100),
    MVA_deriv_Petr_Aliq_4         NVARCHAR(50),
    MVA_deriv_Petr_Aliq_7         NVARCHAR(50),
    MVA_deriv_Petr_Aliq_12        NVARCHAR(50),
    MVA_Original_N_deriv_Petr     NVARCHAR(200),   -- comporta o texto do decreto
    MVA_N_deriv_Petr_Aliq_4       NVARCHAR(50),
    MVA_N_deriv_Petr_Aliq_7       NVARCHAR(50),
    MVA_N_deriv_Petr_Aliq_12      NVARCHAR(50),
    MVA_Original_Outros_Prod      NVARCHAR(50),
    MVA_Outros_Prod_Aliq_4        NVARCHAR(50),
    MVA_Outros_Prod_Aliq_7        NVARCHAR(50),
    MVA_Outros_Prod_Aliq_12       NVARCHAR(50),
    Funcep_Consumo_maior_100Kw_h  NVARCHAR(50),
    Lista                         NVARCHAR(50),
    UF_Signataria                 NVARCHAR(50),
    Exterior_UF_nao_Signat        NVARCHAR(50),
    Ato_Cotepe                    NVARCHAR(200),
    Origem_Arquivo                NVARCHAR(200),
    Nome_Aba_Planilha             NVARCHAR(200)
);
GO
```

> Se o esquema `staging` não existir: `CREATE SCHEMA staging;`

### 2.2 O comando de carga

```sql
BULK INSERT staging.anexo5_bruto
FROM 'C:\cargas\anexo5\tabela_anexo_5_sefaz.csv'
WITH (
    FORMAT          = 'CSV',           -- habilita o tratamento de aspas
    FIELDQUOTE      = '"',             -- resolve a quebra de linha embutida
    FIELDTERMINATOR = '|',
    ROWTERMINATOR   = '0x0a',          -- ver nota abaixo
    FIRSTROW        = 2,               -- pula o cabeçalho
    CODEPAGE        = '65001',         -- UTF-8
    TABLOCK,
    MAXERRORS       = 0,               -- qualquer erro interrompe a carga
    ERRORFILE       = 'C:\cargas\anexo5\erros_anexo5.log'
);
```

**Sobre o `ROWTERMINATOR`.** O arquivo usa CRLF, mas com `FORMAT = 'CSV'` o SQL Server já consome o `\r` que antecede o `\n`. Use `'0x0a'`. Se você escrever `'0x0d0a'` junto com `FORMAT='CSV'`, algumas versões descartam o `\r` duas vezes e a carga falha. Se por algum motivo precisar rodar **sem** `FORMAT='CSV'` (não recomendado aqui), aí sim use `'0x0d0a'` — e aceite que o registro do CEST 25.032.00 vai quebrar.

**Sobre `MAXERRORS = 0`.** Deliberado. Em carga de tabela normativa, uma linha perdida é uma mercadoria que deixa de ser fiscalizada. É melhor a carga falhar e alguém investigar do que carregar 1.841 de 1.842 sem ninguém perceber.

**Sobre `ERRORFILE`.** O SQL Server cria dois arquivos: o `.log` com as linhas rejeitadas e um `.log.Error.Txt` com o motivo. Se qualquer um dos dois já existir, o `BULK INSERT` falha antes de começar — apague-os entre tentativas.

**Permissões.** `BULK INSERT` exige `ADMINISTER BULK OPERATIONS` (ou `bulkadmin`) e o caminho é resolvido **pela conta de serviço do SQL Server**, não pela sua. Em ambiente on-premises isso normalmente significa colocar o arquivo num compartilhamento que a conta de serviço enxergue, ou usar caminho local do servidor.

### 2.3 Conversão da staging para a tabela de destino

```sql
IF OBJECT_ID('fisc.anexo5_sefaz_normalizado', 'U') IS NULL
BEGIN
    CREATE TABLE fisc.anexo5_sefaz_normalizado (
        Id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_anexo5_sefaz_normalizado PRIMARY KEY,
        Tabela_CEST                   NVARCHAR(50) NULL,
        ITEM                          DECIMAL(18,4) NULL,
        CEST                          NVARCHAR(50) NULL,
        NCM_SH                        NVARCHAR(50) NULL,
        DESCRICAO                     NVARCHAR(2000) NULL,
        Legislacao                    NVARCHAR(2000) NULL,
        Vigencia_inicial              DATETIME NULL,
        Vigencia_final                DATETIME NULL,
        Aliq_Interna                  DECIMAL(18,4) NULL,
        MVA_Original                  DECIMAL(18,4) NULL,
        MVA_Original_S_Fid            DECIMAL(18,4) NULL,
        MVA_S_Fid_Aliq_4              DECIMAL(18,4) NULL,
        MVA_S_Fid_Aliq_7              DECIMAL(18,4) NULL,
        MVA_S_Fid_Aliq_12             DECIMAL(18,4) NULL,
        MVA_Original_C_Fid            DECIMAL(18,4) NULL,
        MVA_C_Fid_Aliq_4              DECIMAL(18,4) NULL,
        MVA_C_Fid_Aliq_7              DECIMAL(18,4) NULL,
        MVA_C_Fid_Aliq_12             DECIMAL(18,4) NULL,
        Funcep                        DECIMAL(18,4) NULL,
        Pauta_Fiscal                  NVARCHAR(200) NULL,
        MVA_Aliq_4                    DECIMAL(18,4) NULL,
        MVA_Aliq_7                    DECIMAL(18,4) NULL,
        MVA_Aliq_12                   DECIMAL(18,4) NULL,
        Funcep_Bebidas_Gaseificada    NVARCHAR(200) NULL,
        MVA_Original_deriv_Petr       NVARCHAR(200) NULL,
        MVA_deriv_Petr_Aliq_4         DECIMAL(18,4) NULL,
        MVA_deriv_Petr_Aliq_7         DECIMAL(18,4) NULL,
        MVA_deriv_Petr_Aliq_12        DECIMAL(18,4) NULL,
        MVA_Original_N_deriv_Petr     NVARCHAR(200) NULL,
        MVA_N_deriv_Petr_Aliq_4       DECIMAL(18,4) NULL,
        MVA_N_deriv_Petr_Aliq_7       DECIMAL(18,4) NULL,
        MVA_N_deriv_Petr_Aliq_12      DECIMAL(18,4) NULL,
        MVA_Original_Outros_Prod      DECIMAL(18,4) NULL,
        MVA_Outros_Prod_Aliq_4        DECIMAL(18,4) NULL,
        MVA_Outros_Prod_Aliq_7        DECIMAL(18,4) NULL,
        MVA_Outros_Prod_Aliq_12       DECIMAL(18,4) NULL,
        Funcep_Consumo_maior_100Kw_h  DECIMAL(18,4) NULL,
        Lista                         NVARCHAR(50) NULL,
        UF_Signataria                 NVARCHAR(50) NULL,
        Exterior_UF_nao_Signat        NVARCHAR(50) NULL,
        Ato_Cotepe                    NVARCHAR(200) NULL,
        Origem_Arquivo                NVARCHAR(200) NULL,
        Nome_Aba_Planilha             NVARCHAR(200) NULL
    );
END;
GO

TRUNCATE TABLE fisc.anexo5_sefaz_normalizado;

INSERT INTO fisc.anexo5_sefaz_normalizado (
    Tabela_CEST, ITEM, CEST, NCM_SH, DESCRICAO, Legislacao,
    Vigencia_inicial, Vigencia_final, Aliq_Interna,
    MVA_Original, MVA_Original_S_Fid,
    MVA_S_Fid_Aliq_4, MVA_S_Fid_Aliq_7, MVA_S_Fid_Aliq_12,
    MVA_Original_C_Fid,
    MVA_C_Fid_Aliq_4, MVA_C_Fid_Aliq_7, MVA_C_Fid_Aliq_12,
    Funcep, Pauta_Fiscal,
    MVA_Aliq_4, MVA_Aliq_7, MVA_Aliq_12,
    Funcep_Bebidas_Gaseificada,
    Lista, UF_Signataria, Exterior_UF_nao_Signat, Ato_Cotepe,
    Origem_Arquivo, Nome_Aba_Planilha
)
SELECT
    NULLIF(LTRIM(RTRIM(Tabela_CEST)), ''),
    TRY_CONVERT(DECIMAL(18,4), ITEM),
    NULLIF(LTRIM(RTRIM(CEST)), ''),
    NULLIF(REPLACE(LTRIM(RTRIM(NCM_SH)), '.', ''), ''),   -- normaliza 1902.20.00
    NULLIF(LTRIM(RTRIM(DESCRICAO)), ''),
    NULLIF(LTRIM(RTRIM(Legislacao)), ''),
    TRY_CONVERT(DATETIME, NULLIF(LTRIM(RTRIM(Vigencia_inicial)), ''), 120),
    TRY_CONVERT(DATETIME, NULLIF(LTRIM(RTRIM(Vigencia_final)),   ''), 120),
    TRY_CONVERT(DECIMAL(18,4), Aliq_Interna),
    TRY_CONVERT(DECIMAL(18,4), MVA_Original),
    TRY_CONVERT(DECIMAL(18,4), MVA_Original_S_Fid),
    TRY_CONVERT(DECIMAL(18,4), MVA_S_Fid_Aliq_4),
    TRY_CONVERT(DECIMAL(18,4), MVA_S_Fid_Aliq_7),
    TRY_CONVERT(DECIMAL(18,4), MVA_S_Fid_Aliq_12),
    TRY_CONVERT(DECIMAL(18,4), MVA_Original_C_Fid),
    TRY_CONVERT(DECIMAL(18,4), MVA_C_Fid_Aliq_4),
    TRY_CONVERT(DECIMAL(18,4), MVA_C_Fid_Aliq_7),
    TRY_CONVERT(DECIMAL(18,4), MVA_C_Fid_Aliq_12),
    TRY_CONVERT(DECIMAL(18,4), Funcep),
    NULLIF(LTRIM(RTRIM(Pauta_Fiscal)), ''),
    TRY_CONVERT(DECIMAL(18,4), MVA_Aliq_4),
    TRY_CONVERT(DECIMAL(18,4), MVA_Aliq_7),
    TRY_CONVERT(DECIMAL(18,4), MVA_Aliq_12),
    NULLIF(LTRIM(RTRIM(Funcep_Bebidas_Gaseificada)), ''),
    NULLIF(LTRIM(RTRIM(Lista)), ''),
    NULLIF(LTRIM(RTRIM(UF_Signataria)), ''),
    NULLIF(LTRIM(RTRIM(Exterior_UF_nao_Signat)), ''),
    NULLIF(LTRIM(RTRIM(Ato_Cotepe)), ''),
    NULLIF(LTRIM(RTRIM(Origem_Arquivo)), ''),
    NULLIF(LTRIM(RTRIM(Nome_Aba_Planilha)), '')
FROM staging.anexo5_bruto
WHERE Tabela_CEST IS NOT NULL          -- descarta as 6 linhas vazias
   OR CEST        IS NOT NULL
   OR NCM_SH      IS NOT NULL
   OR DESCRICAO   IS NOT NULL;
```

**As colunas de derivados de petróleo ficaram de fora do `INSERT` de propósito.** `MVA_Original_deriv_Petr` e `MVA_Original_N_deriv_Petr` estão tipadas como `decimal(18,4)` na tabela de destino, mas contêm `AD REM`, `PMPF`, `DIFERIMENTO` e o texto de um decreto. Um `TRY_CONVERT` transformaria essas 4 marcações de regime tributário em `NULL` silenciosamente — e regime de combustível é exatamente o tipo de informação que não se pode perder.

Antes de completar a carga, decida com a área de negócio:

- **Opção A** — desdobrar em duas colunas: `MVA_Original_deriv_Petr DECIMAL(18,4)` + `Regime_deriv_Petr NVARCHAR(30)`, populando cada uma conforme o conteúdo seja numérico ou textual.
- **Opção B** — alterar as duas colunas para `NVARCHAR(200)` e tratar a conversão no consumo.

A Opção A é a correta do ponto de vista de modelagem. Enquanto a decisão não sai, essas colunas permanecem `NULL` e isso está **documentado**, não escondido.

---

## Etapa 3 — Verificação dos dados carregados

Verificação não é `SELECT COUNT(*)`. São quatro perguntas distintas.

### 3.1 A contagem bate?

```sql
SELECT
    (SELECT COUNT(*) FROM staging.anexo5_bruto)                AS linhas_staging,
    (SELECT COUNT(*) FROM fisc.anexo5_sefaz_normalizado)       AS linhas_destino;
```


| Valor esperado              | Quantidade |
| ----------------------------- | ------------ |
| Linhas na staging           | **1.842**  |
| Linhas descartadas (vazias) | **6**      |
| Linhas na tabela de destino | **1.836**  |

Se a staging vier com **1.843**, o `FIELDQUOTE` não funcionou e o registro do CEST 25.032.00 foi partido — refaça a Etapa 2.

### 3.2 Nada foi perdido na conversão?

Toda coluna convertida com `TRY_CONVERT` pode ter virado `NULL` sem avisar. Conte:

```sql
SELECT
    SUM(CASE WHEN Vigencia_inicial IS NULL THEN 1 ELSE 0 END) AS vig_ini_nula,
    SUM(CASE WHEN Vigencia_final   IS NULL THEN 1 ELSE 0 END) AS vig_fim_nula,
    SUM(CASE WHEN Aliq_Interna     IS NULL THEN 1 ELSE 0 END) AS aliq_nula,
    SUM(CASE WHEN NCM_SH           IS NULL THEN 1 ELSE 0 END) AS ncm_nulo
FROM fisc.anexo5_sefaz_normalizado;
```


| Coluna             | `NULL` esperados | Motivo                                       |
| -------------------- | ------------------ | ---------------------------------------------- |
| `Vigencia_inicial` | **1**            | O registro com`27/03 2020`                   |
| `Vigencia_final`   | **1.062**        | 1.058 vazios + 4 em branco + o de um espaço |
| `Aliq_Interna`     | **0**            | Todos os valores são numéricos válidos    |
| `NCM_SH`           | **10**           | Registros sem NCM na origem                  |

Qualquer número acima do esperado é conversão perdida. Localize os culpados comparando staging e destino:

```sql
SELECT s.CEST, s.NCM_SH, s.Vigencia_inicial AS texto_origem
FROM staging.anexo5_bruto s
WHERE s.Vigencia_inicial IS NOT NULL
  AND LTRIM(RTRIM(s.Vigencia_inicial)) <> ''
  AND TRY_CONVERT(DATETIME, LTRIM(RTRIM(s.Vigencia_inicial)), 120) IS NULL;
```

### 3.3 A distribuição bate com a origem?

```sql
SELECT Nome_Aba_Planilha, COUNT(*) AS qtd
FROM fisc.anexo5_sefaz_normalizado
GROUP BY Nome_Aba_Planilha
ORDER BY qtd DESC;
```


| Aba de origem              | Registros |
| ---------------------------- | ----------- |
| AutoPecas                  | 638       |
| Agua_Chop                  | 203       |
| Mat_Const                  | 181       |
| Prod_Alimenticios          | 181       |
| Combustiveis_Lubrificantes | 165       |
| Prod_Perfumaria_higiene    | 111       |
| Medicamento                | 98        |
| Bebidas                    | 76        |
| Veic_automotores           | 61        |
| (demais 11 abas)           | 122       |
| **Total**                  | **1.836** |

Outras cardinalidades de controle: **22** valores distintos de `Tabela_CEST`, **608** CEST distintos, **418** NCM distintos, **106** dispositivos legais distintos.

### 3.4 A integridade lógica se sustenta?

```sql
-- (a) Vigência final anterior à inicial: deve retornar 0 linhas
SELECT COUNT(*) AS vigencia_invertida
FROM fisc.anexo5_sefaz_normalizado
WHERE Vigencia_final IS NOT NULL
  AND Vigencia_final < Vigencia_inicial;

-- (b) CEST fora do formato NN.NNN.NN
SELECT CEST, COUNT(*) AS qtd
FROM fisc.anexo5_sefaz_normalizado
WHERE CEST NOT LIKE '[0-9][0-9].[0-9][0-9][0-9].[0-9][0-9]'
GROUP BY CEST;

-- (c) NCM com caractere não numérico após a normalização
SELECT NCM_SH, COUNT(*) AS qtd
FROM fisc.anexo5_sefaz_normalizado
WHERE NCM_SH LIKE '%[^0-9]%'
GROUP BY NCM_SH;

-- (d) Sobreposição de vigência para o mesmo par CEST + NCM
SELECT a.CEST, a.NCM_SH, COUNT(*) AS versoes_vigentes_simultaneas
FROM fisc.anexo5_sefaz_normalizado a
JOIN fisc.anexo5_sefaz_normalizado b
  ON  a.CEST = b.CEST
  AND a.NCM_SH = b.NCM_SH
  AND a.Id <> b.Id
  AND a.Vigencia_inicial <= ISNULL(b.Vigencia_final, '9999-12-31')
  AND ISNULL(a.Vigencia_final, '9999-12-31') >= b.Vigencia_inicial
GROUP BY a.CEST, a.NCM_SH
ORDER BY versoes_vigentes_simultaneas DESC;
```

**Atenção à verificação (d).** O par `(CEST, NCM_SH)` se repete **634 vezes** no arquivo — e isso é legítimo: cada repetição é uma versão da regra em uma vigência diferente (alteração de MVA por decreto). Duplicidade só é erro quando duas versões do mesmo par valem **na mesma data**. É por isso que a tabela tem um `Id IDENTITY` como PK em vez de chave natural: a chave lógica é `(CEST, NCM_SH, Vigencia_inicial)`.

### 3.5 Registrar a execução

O esquema `fisc` já tem tabela própria para isso:

```sql
INSERT INTO fisc.ExecucaoScripts (QueryName, StartTime, EndTime, ExecutionTimeSeconds)
VALUES ('CARGA_ANEXO5_CEST', @inicio, SYSDATETIME(), DATEDIFF(SECOND, @inicio, SYSDATETIME()));
```

---

## Etapa 4 — Questões de auditoria fiscal

As quatro questões a seguir usam a tabela recém-carregada em conjunto com as tabelas de resultado do esquema `fisc`. Todas exigem junção, agregação e filtro.

### Nota técnica obrigatória antes de começar

**1. O NCM do Anexo 5 é prefixo, não código completo.** Os NCM da tabela CEST têm de 4 a 8 dígitos: `3917` cobre toda a posição, `38151210` é um código específico. Já o `REG0200_COD_NCM` da EFD tem 8 dígitos. Junção por igualdade perde a maioria dos casamentos. Use:

```sql
ON LEFT(efd.REG0200_COD_NCM, LEN(a5.NCM_SH)) = a5.NCM_SH
```

Isso impede uso de índice — em volume alto, materialize um mapa NCM8 × CEST antes.

**2. Os tipos nas tabelas `fisc.TB_*` não são uniformes.** Muitas foram criadas por `SELECT ... INTO` com `CASE WHEN col IS NULL THEN '-' ELSE col END`, o que converte colunas numéricas em texto e insere o literal `'-'` no lugar de `NULL`. Confira antes de comparar:

```sql
SELECT c.name, t.name AS tipo, c.max_length
FROM sys.columns c
JOIN sys.types   t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL');
```

Use `TRY_CONVERT` nas comparações numéricas e nunca compare direto com `0` uma coluna que pode conter `'-'`.

---

### Questão 1 — Crédito de ICMS em entrada de mercadoria sob substituição tributária

**Regra fiscal.** Mercadoria enquadrada no regime de substituição tributária tem o ICMS recolhido antecipadamente pelo substituto. O adquirente que revende essa mercadoria **não** se credita do imposto na entrada — o crédito já foi anulado na cadeia. Crédito lançado nessa hipótese é crédito indevido.

**Por que importa.** É uma das inconsistências de maior valor recuperado em malha fiscal, porque costuma ser sistemática: o contribuinte configura o ERP errado uma vez e replica o erro em todos os itens daquele NCM, todo mês, por anos.

**Técnica exigida.** `INNER JOIN` com casamento por prefixo, filtro de vigência com intervalo aberto, agregação por contribuinte com `HAVING`.

```sql
SELECT
    c170.REG0_IE,
    c170.REG0_NOME,
    a5.CEST,
    c170.REG0200_COD_NCM,
    COUNT(*)                                              AS qtd_itens,
    SUM(TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS))    AS icms_creditado_indevido
FROM fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL c170
INNER JOIN fisc.anexo5_sefaz_normalizado a5
    ON /* (1) casamento NCM por prefixo — ver nota técnica */
   AND /* (2) a data do documento deve estar dentro da vigência da regra;
              lembre que Vigencia_final NULL significa "ainda vigente" */
WHERE TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS) > 0
  AND /* (3) restringir a CFOP de entrada para revenda —
             qual faixa de CFOP identifica entrada? e revenda? */
  AND /* (4) o CST informado no item é coerente com o crédito tomado?
             considere que o erro pode estar justamente no CST */
GROUP BY c170.REG0_IE, c170.REG0_NOME, a5.CEST, c170.REG0200_COD_NCM
HAVING /* (5) filtrar materialidade — que patamar justifica abrir OS? */
ORDER BY icms_creditado_indevido DESC;
```

**Verificação.** A soma de `icms_creditado_indevido` de todos os grupos não pode exceder o total de `C170_VL_ICMS` das entradas do período. Compare com:

```sql
SELECT SUM(TRY_CONVERT(DECIMAL(16,2), C170_VL_ICMS))
FROM fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL
WHERE TRY_CONVERT(INT, C170_CFOP) BETWEEN 1000 AND 2999;
```

**Análise (responda como comentário SQL no seu script).**

```sql
-- 1.1 Quantos itens ficaram de fora por REG0200_COD_NCM ser NULL ou '-'?
--     Esses itens são inocentes ou apenas invisíveis?
-- 2.2 Trocando o INNER JOIN por LEFT JOIN, o que passa a aparecer? Isso é
--     um segundo achado de auditoria ou ruído?
-- 1.3 Se o mesmo NCM casar com dois CEST vigentes (verificação 3.4-d),
--     o valor do ICMS é contado duas vezes. Como você prova que isso
--     não aconteceu no seu resultado?
```

---

### Questão 2 — Saída tributada normalmente de mercadoria já alcançada pela ST

**Regra fiscal.** O inverso da Questão 1. Mercadoria sob ST sai com CST 60 (ICMS cobrado anteriormente por substituição) e sem débito de ICMS próprio. Se a saída foi escriturada com CST 00 e alíquota cheia, houve débito indevido — o contribuinte **pagou imposto a mais**.

**Por que importa.** Auditoria não é só glosa. Divergência que favorece o Fisco também precisa ser apontada: sustenta a legitimidade do trabalho e, em muitos casos, o contribuinte já protocolou pedido de restituição que a fiscalização vai ter que analisar de qualquer forma.

**Técnica exigida.** Junção de três tabelas (`C100` para a data do documento, `C170` para o item, Anexo 5 para a regra), agregação com múltiplas granularidades.

```sql
SELECT
    c100.REG0_PERIODO_DECLARACAO,
    c100.REG0_IE,
    a5.CEST,
    a5.Aliq_Interna                                       AS aliquota_prevista_anexo5,
    COUNT(DISTINCT c100.C100_CHV_NFE)                     AS qtd_notas,
    SUM(TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS))    AS debito_a_maior
FROM fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL c100
INNER JOIN fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL c170
    ON /* (1) qual coluna liga o item ao documento de forma segura?
             NUM_DOC + SER é suficiente entre contribuintes diferentes? */
INNER JOIN fisc.anexo5_sefaz_normalizado a5
    ON /* (2) casamento NCM por prefixo + vigência na data do documento */
WHERE /* (3) restringir a saídas (faixa de CFOP) */
  AND /* (4) CST que indica tributação normal — e o item tem débito */
  AND /* (5) excluir documentos cancelados/denegados — repare que
             C100_COD_SIT vem descritivo ('2 - DOCUMENTO CANCELADO'),
             não numérico */
GROUP BY c100.REG0_PERIODO_DECLARACAO, c100.REG0_IE, a5.CEST, a5.Aliq_Interna
ORDER BY debito_a_maior DESC;
```

**Verificação.** `COUNT(DISTINCT C100_CHV_NFE)` tem que ser menor ou igual a `COUNT(*)` de itens. Se forem iguais em todos os grupos, ou a base tem uma nota por item (improvável) ou a junção está errada.

**Análise.**

```sql
-- 2.1 Por que COUNT(DISTINCT chave) e não COUNT(*)? Escreva a consulta com
--     COUNT(*), execute, e explique numericamente a diferença.
-- 2.2 A alíquota do item (C170_ALIQ_ICMS) confere com Aliq_Interna do
--     Anexo 5? Onde não confere, qual das duas está certa?
-- 2.3 Um item pode estar corretamente com CST 00 mesmo constando no
--     Anexo 5. Cite pelo menos uma hipótese legal.
```

---

### Questão 3 — Divergência entre o total do documento (C100) e o analítico (C190)

**Regra fiscal.** O registro C190 é o resumo analítico da nota por combinação CST + CFOP + alíquota. A soma dos `VL_OPR` de todos os C190 de um documento deve reproduzir o `VL_DOC` do C100. Divergência indica escrituração incompleta — normalmente um CFOP omitido.

**Por que importa.** É a verificação de consistência interna mais barata da EFD e a que mais rapidamente revela arquivo montado à mão ou com erro de exportação do ERP.

**Técnica exigida.** Agregação **antes** da junção. Esta questão existe para o aluno errar primeiro.

**Passo 1 — escreva e execute a versão errada:**

```sql
-- ERRADA DE PROPÓSITO. Execute, observe o resultado, depois explique.
SELECT
    c100.C100_CHV_NFE,
    c100.C100_VL_DOC,
    SUM(TRY_CONVERT(DECIMAL(16,2), c190.C190_VL_OPR)) AS soma_analitico
FROM fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL c100
INNER JOIN fisc.TB_534_PR_EFD_REGISTRO_C190_ANALITICO_DOC_FISCAL_CST_CFOP_ALIQ_ICMS c190
    ON c100.C100_CHV_NFE = c190.C100_CHV_NFE
INNER JOIN fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL c170
    ON c170.C100_CHV_NFE = c100.C100_CHV_NFE
GROUP BY c100.C100_CHV_NFE, c100.C100_VL_DOC;
```

**Passo 2 — corrija:**

```sql
WITH analitico AS (
    SELECT
        C100_CHV_NFE,
        /* (1) agregue aqui, na granularidade do documento, antes de junção */
    FROM fisc.TB_534_PR_EFD_REGISTRO_C190_ANALITICO_DOC_FISCAL_CST_CFOP_ALIQ_ICMS
    WHERE /* (2) filtro de período */
    GROUP BY C100_CHV_NFE
)
SELECT
    c100.REG0_IE,
    c100.REG0_NOME,
    c100.C100_CHV_NFE,
    c100.C100_VL_DOC,
    a.soma_analitico,
    /* (3) a diferença, com sinal — importa saber para que lado */
FROM fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL c100
LEFT JOIN analitico a
    ON a.C100_CHV_NFE = c100.C100_CHV_NFE
WHERE /* (4) tolerância de arredondamento — R$ 0,01 por item é razoável?
            justifique o valor escolhido */
ORDER BY ABS(/* (3) */) DESC;
```

**Verificação.** Some `C100_VL_DOC` de todos os documentos do período e some `C190_VL_OPR` de todos os registros analíticos do mesmo período, separadamente. Os dois totais devem estar a menos de 0,5% um do outro; se estiverem muito distantes, o problema é da base, não das notas individuais.

**Análise.**

```sql
-- 3.1 Quantas linhas a mais a consulta errada retornou? Multiplique
--     manualmente: qtd_C190 × qtd_C170 para uma nota específica e confira.
-- 3.2 Por que LEFT JOIN na versão corrigida, e não INNER? O que significa
--     um documento C100 sem nenhum C190?
-- 3.3 A diferença sempre indica omissão do contribuinte? Que outra
--     explicação (legítima) existe?
```

---

### Questão 4 — Cadastro de item (0200) divergente da tabela normativa

**Regra fiscal.** No registro 0200 o contribuinte declara, por item, o NCM, o CEST e a alíquota de ICMS. Esses três campos precisam ser coerentes entre si e com o Anexo 5: item com NCM sujeito a ST deve ter CEST informado, e a alíquota declarada deve ser a alíquota interna prevista.

**Por que importa.** O 0200 é a fundação de toda a escrituração — item cadastrado errado propaga o erro para C170, C190, H010 e apuração. Auditar o cadastro primeiro é mais eficiente que auditar cada lançamento.

**Técnica exigida.** `LEFT JOIN` com detecção de ausência, agregação condicional com `SUM(CASE WHEN ...)`, filtro de vigência.

```sql
SELECT
    r0200.REG0_IE,
    r0200.REG0_NOME,
    COUNT(*)                                              AS itens_sujeitos_a_st,
    SUM(CASE WHEN /* (1) condição de CEST ausente no cadastro —
                        cuidado: a coluna pode conter NULL, 0 ou '-' */
             THEN 1 ELSE 0 END)                           AS sem_cest,
    SUM(CASE WHEN /* (2) alíquota cadastrada diverge da Aliq_Interna
                        do Anexo 5; atenção à escala: o Anexo 5 guarda
                        0.18 e o registro 0200 guarda 18.00 */
             THEN 1 ELSE 0 END)                           AS aliquota_divergente,
    CAST(100.0 * SUM(CASE WHEN /* (1) */ THEN 1 ELSE 0 END)
         / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))           AS perc_sem_cest
FROM fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO r0200
INNER JOIN fisc.anexo5_sefaz_normalizado a5
    ON /* (3) casamento NCM por prefixo + regra vigente no período
             declarado; REG0_PERIODO_DECLARACAO vem como 'M/AAAA' —
             será preciso convertê-lo para data */
WHERE /* (4) restringir aos tipos de item que efetivamente circulam:
             mercadoria para revenda, produto acabado. Que valores de
             REG0200_TIPO_ITEM correspondem a isso, considerando que
             a coluna é descritiva? */
GROUP BY r0200.REG0_IE, r0200.REG0_NOME
HAVING /* (5) só interessa contribuinte com problema relevante:
             defina um piso de quantidade ou percentual */
ORDER BY perc_sem_cest DESC, itens_sujeitos_a_st DESC;
```

**Verificação.** `sem_cest + aliquota_divergente` pode ultrapassar `itens_sujeitos_a_st` — um item pode ter os dois defeitos. Se **nunca** ultrapassar, é sinal de que uma das duas condições nunca dispara; teste cada `SUM(CASE...)` isoladamente antes de concluir.

**Análise.**

```sql
-- 4.1 O NULLIF no denominador do percentual protege contra o quê?
--     Remova-o e provoque o erro.
-- 4.2 Se o Anexo 5 tem 608 CEST e o cadastro do contribuinte referencia
--     um CEST que não existe na tabela, esta consulta o encontra?
--     Se não, escreva a consulta que encontra.
-- 4.3 Alíquota divergente é sempre irregularidade? Considere redução de
--     base de cálculo e benefício fiscal.
```

---

## Encerramento

Ao final, a staging pode ser descartada — mas só depois que as verificações da Etapa 3 tiverem sido rodadas e o resultado arquivado. Guarde também o `ERRORFILE`, mesmo vazio: ele é a prova de que a carga foi limpa.

```sql
-- Somente após conferência documentada
DROP TABLE staging.anexo5_bruto;
```

**Pendência aberta:** definir com a área de negócio o tratamento das colunas `MVA_Original_deriv_Petr` e `MVA_Original_N_deriv_Petr` (seção 2.3). Enquanto não houver decisão, essas colunas permanecem sem carga e nenhuma análise de combustíveis deve ser feita sobre elas.
