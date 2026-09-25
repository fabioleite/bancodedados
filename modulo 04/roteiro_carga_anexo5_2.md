# Roteiro de Carga — Tabela do Anexo 5 (CEST/MVA) no BDFISC

**Arquivo de origem:** `tabela_anexo_5_sefaz.csv`
**Banco de destino:** BDFISC — esquema `fisc`
**Tabela alvo:** `fisc.anexo5_sefaz_normalizado` (já existe no banco)
**Plataforma:** SQL Server (T-SQL) — SSMS / VS Code + extensão MSSQL

---

## Etapa 1 — Análise preparatória do arquivo

Antes de escrever uma única linha de `BULK INSERT`, o arquivo precisa ser interrogado. Carregar sem investigar é a forma mais rápida de gerar uma tabela silenciosamente errada — os erros que não param a carga são os perigosos.

### 1.1 Fatos estruturais apurados


| Característica                    | Valor apurado        | Consequência para a carga                                                                  |
| ------------------------------------ | ---------------------- | --------------------------------------------------------------------------------------------- |
| Codificação                      | UTF-8  **sem BOM** | `CODEPAGE = '65001'` obrigatório, senão acentos viram lixo (`cerâmica` → `cerÃ¢mica`) |
| Terminador de linha                | CRLF (`0x0D0A`)      | Ver 1.4 — interage com`FORMAT='CSV'`                                                       |
| Delimitador de campo               | Pipe`                | `                                                                                           |
| Cabeçalho                         | 1 linha              | `FIRSTROW = 2`                                                                              |
| Colunas                            | 43                   | A tabela de staging precisa ter exatamente 43                                               |
| Linhas físicas (após cabeçalho) | 1.843                | **Não** é o número de registros                                                          |
| Registros lógicos                 | 1.842                | Diferença de 1: há quebra de linha embutida                                               |
| Registros com conteúdo            | 1.836                | 6 linhas totalmente vazias no final                                                         |
| Separador decimal                  | Ponto (`.`)          | Não é o padrão pt-BR; ver 1.5                                                            |
| Aspas presentes                    | Sim (61 pares)       | `FIELDQUOTE = '"'` obrigatório                                                             |

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
| `MVA_Original_deriv_Petr`   | Marcação de regime em coluna numérica              | `PMPF` (80×), `AD REM` (50×), `DIFERIMENTO` (2×)                              |
| `MVA_Original_N_deriv_Petr` | Texto livre em coluna numérica                       | `conforme art.2º do decreto 46.692/25` (1×)                                    |
| `CEST`                      | Espaços à direita                                   | `'25.032.00  '`                                                                  |
| `NCM/SH`                    | Pontuação inconsistente                             | `1902.20.00` entre 418 valores só de dígitos                                   |
| `NCM/SH`                    | Comprimento variável: 4, 5, 6, 7, 8, 9 e 10 dígitos | NCM na tabela CEST é**prefixo** (posição/subposição), não código completo |
| `ITEM`                      | Formatado como decimal                                | `1.0`, `1.1`, `104.0` — é numeração de item, não valor                      |
| Últimas 6 linhas           | Todos os 43 campos vazios                             | Resíduo da conversão do XLSX                                                   |

`Pauta_Fiscal`, `Lista`, `Ato_Cotepe` e `Funcep_Bebidas_Gaseificada` também têm conteúdo textual, mas ali isso é **esperado** — são colunas-marcador (`'Pauta'`, `'Positiva'`, `'Ato Cotepe'`), não numéricas. Repare que a DDL existente de `fisc.anexo5_sefaz_normalizado` acerta em `Pauta_Fiscal nvarchar(200)` mas erra em `Funcep_Bebidas_Gaseificada`, tipada como `nvarchar(200)` quando os dados são numéricos.

O caso das duas colunas de derivados de petróleo é diferente e mais grave: `MVA_Original_deriv_Petr` está tipada como `decimal(18,4)` e **não comporta** `PMPF`, `AD REM` nem `DIFERIMENTO`. Essas três palavras não são sujeira — são **regimes de tributação de combustível**. `PMPF` é preço médio ponderado a consumidor final, `AD REM` é alíquota específica por unidade de medida e `DIFERIMENTO` é adiamento do lançamento. Em cada um deles a base de cálculo não se apura por MVA, e é por isso que o campo numérico está vazio. Descartar essa informação equivale a afirmar que 132 mercadorias não têm regime definido quando, na verdade, têm um regime que a coluna não sabe representar.

A solução adotada neste roteiro é o **desdobramento em duas colunas** — uma numérica para a MVA, uma textual para o regime. A seção 2.2 aplica a alteração.

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

CREATE schema staging

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

### 2.2 Criar e ajustar a tabela de destino

Em um banco novo, crie a tabela normalizada com os tipos definitivos. As colunas numéricas recebem `DECIMAL(18,4)` e os campos textuais permanecem em `NVARCHAR`. O `Id` é uma chave técnica, pois o par `CEST` + `NCM_SH` pode aparecer em várias vigências.

```sql
USE BDFISC;
GO

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
        Funcep_Bebidas_Gaseificada    DECIMAL(18,4) NULL,
        MVA_Original_deriv_Petr       DECIMAL(18,4) NULL,
        Regime_deriv_Petr             NVARCHAR(30) NULL,
        MVA_deriv_Petr_Aliq_4         DECIMAL(18,4) NULL,
        MVA_deriv_Petr_Aliq_7         DECIMAL(18,4) NULL,
        MVA_deriv_Petr_Aliq_12        DECIMAL(18,4) NULL,
        MVA_Original_N_deriv_Petr     DECIMAL(18,4) NULL,
        Regime_N_deriv_Petr           NVARCHAR(100) NULL,
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
```

Em um banco que já possui a tabela criada pela versão anterior do roteiro, acrescente as colunas textuais de regime identificadas em 1.3. As verificações condicionais evitam erro quando a coluna já existir:

```sql
USE BDFISC;
GO

IF COL_LENGTH('fisc.anexo5_sefaz_normalizado', 'Regime_deriv_Petr') IS NULL
BEGIN
    ALTER TABLE fisc.anexo5_sefaz_normalizado
        ADD Regime_deriv_Petr NVARCHAR(30) NULL; -- PMPF, AD REM, DIFERIMENTO
END;

IF COL_LENGTH('fisc.anexo5_sefaz_normalizado', 'Regime_N_deriv_Petr') IS NULL
BEGIN
    ALTER TABLE fisc.anexo5_sefaz_normalizado
        ADD Regime_N_deriv_Petr NVARCHAR(100) NULL; -- texto normativo livre
END;
GO
```

**Sobre os tamanhos.** `Regime_deriv_Petr` recebe no máximo `DIFERIMENTO`, 11 caracteres; `NVARCHAR(30)` deixa folga para novos regimes sem virar campo de texto livre. `Regime_N_deriv_Petr` precisa acomodar `conforme art.2º do decreto 46.692/25`, 36 caracteres — daí `NVARCHAR(100)`, ainda restritivo o bastante para que ninguém o use como campo de observação.

**Sobre a assimetria.** As duas colunas nasceram do mesmo defeito, mas o conteúdo é de natureza distinta: uma guarda um vocabulário fechado de três termos, a outra guarda uma remissão legal isolada. Tratá-las com o mesmo tamanho esconderia essa diferença. Se, nas próximas atualizações do Anexo 5, `Regime_N_deriv_Petr` continuar recebendo texto livre, o caminho é criar uma tabela de exceções normativas com FK — não alargar a coluna.

```SQL

BULK INSERT staging.anexo5_bruto
FROM 'C:\temp\tabela_anexo_5_sefaz.csv'
WITH (
    FORMAT          = 'CSV',           -- habilita o tratamento de aspas
    FIELDQUOTE      = '"',             -- resolve a quebra de linha embutida
    FIELDTERMINATOR = '|',
    ROWTERMINATOR   = '0x0a',          -- ver nota abaixo
    FIRSTROW        = 2,               -- pula o cabeçalho
    CODEPAGE        = '65001',         -- UTF-8
    TABLOCK,
    MAXERRORS       = 0,               -- qualquer erro interrompe a carga
    ERRORFILE       = 'C:\temp\erros_anexo5.log'
);
```

**Sobre o `ROWTERMINATOR`.** O arquivo usa CRLF, mas com `FORMAT = 'CSV'` o SQL Server já consome o `\r` que antecede o `\n`. Use `'0x0a'`. Se você escrever `'0x0d0a'` junto com `FORMAT='CSV'`, algumas versões descartam o `\r` duas vezes e a carga falha. Se por algum motivo precisar rodar **sem** `FORMAT='CSV'` (não recomendado aqui), aí sim use `'0x0d0a'` — e aceite que o registro do CEST 25.032.00 vai quebrar.

**Sobre `MAXERRORS = 0`.** Deliberado. Em carga de tabela normativa, uma linha perdida é uma mercadoria que deixa de ser fiscalizada. É melhor a carga falhar e alguém investigar do que carregar 1.841 de 1.842 sem ninguém perceber.

**Sobre `ERRORFILE`.** O SQL Server cria dois arquivos: o `.log` com as linhas rejeitadas e um `.log.Error.Txt` com o motivo. Se qualquer um dos dois já existir, o `BULK INSERT` falha antes de começar — apague-os entre tentativas.

**Permissões.** `BULK INSERT` exige `ADMINISTER BULK OPERATIONS` (ou `bulkadmin`) e o caminho é resolvido **pela conta de serviço do SQL Server**, não pela sua. Em ambiente on-premises isso normalmente significa colocar o arquivo num compartilhamento que a conta de serviço enxergue, ou usar caminho local do servidor.

### 2.4 Conversão da staging para a tabela de destino

```sql
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
    MVA_Original_deriv_Petr, Regime_deriv_Petr,
    MVA_deriv_Petr_Aliq_4, MVA_deriv_Petr_Aliq_7, MVA_deriv_Petr_Aliq_12,
    MVA_Original_N_deriv_Petr, Regime_N_deriv_Petr,
    MVA_N_deriv_Petr_Aliq_4, MVA_N_deriv_Petr_Aliq_7, MVA_N_deriv_Petr_Aliq_12,
    MVA_Original_Outros_Prod,
    MVA_Outros_Prod_Aliq_4, MVA_Outros_Prod_Aliq_7, MVA_Outros_Prod_Aliq_12,
    Funcep_Consumo_maior_100Kw_h,
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

    -- Desdobramento: derivados de petróleo
    TRY_CONVERT(DECIMAL(18,4), MVA_Original_deriv_Petr),
    CASE WHEN NULLIF(LTRIM(RTRIM(MVA_Original_deriv_Petr)), '') IS NOT NULL
          AND TRY_CONVERT(DECIMAL(18,4), MVA_Original_deriv_Petr) IS NULL
         THEN LTRIM(RTRIM(MVA_Original_deriv_Petr))
    END,
    TRY_CONVERT(DECIMAL(18,4), MVA_deriv_Petr_Aliq_4),
    TRY_CONVERT(DECIMAL(18,4), MVA_deriv_Petr_Aliq_7),
    TRY_CONVERT(DECIMAL(18,4), MVA_deriv_Petr_Aliq_12),

    -- Desdobramento: não derivados de petróleo
    TRY_CONVERT(DECIMAL(18,4), MVA_Original_N_deriv_Petr),
    CASE WHEN NULLIF(LTRIM(RTRIM(MVA_Original_N_deriv_Petr)), '') IS NOT NULL
          AND TRY_CONVERT(DECIMAL(18,4), MVA_Original_N_deriv_Petr) IS NULL
         THEN LTRIM(RTRIM(MVA_Original_N_deriv_Petr))
    END,
    TRY_CONVERT(DECIMAL(18,4), MVA_N_deriv_Petr_Aliq_4),
    TRY_CONVERT(DECIMAL(18,4), MVA_N_deriv_Petr_Aliq_7),
    TRY_CONVERT(DECIMAL(18,4), MVA_N_deriv_Petr_Aliq_12),

    TRY_CONVERT(DECIMAL(18,4), MVA_Original_Outros_Prod),
    TRY_CONVERT(DECIMAL(18,4), MVA_Outros_Prod_Aliq_4),
    TRY_CONVERT(DECIMAL(18,4), MVA_Outros_Prod_Aliq_7),
    TRY_CONVERT(DECIMAL(18,4), MVA_Outros_Prod_Aliq_12),
    TRY_CONVERT(DECIMAL(18,4), Funcep_Consumo_maior_100Kw_h),

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

**Como funciona o desdobramento.** Cada coluna de origem alimenta dois destinos, e o critério é o próprio resultado da conversão:


| Valor na origem                 | `MVA_Original_deriv_Petr` | `Regime_deriv_Petr` |
| --------------------------------- | --------------------------- | --------------------- |
| `0.00`, `0.6131`                | valor convertido          | `NULL`              |
| `PMPF`, `AD REM`, `DIFERIMENTO` | `NULL`                    | o texto             |
| vazio                           | `NULL`                    | `NULL`              |

O `CASE` implementa exatamente isso: só grava o texto quando o campo **tem conteúdo** e **falhou** na conversão numérica. As duas condições são necessárias. Sem a primeira, campos vazios virariam string vazia em vez de `NULL`; sem a segunda, valores numéricos seriam duplicados nas duas colunas.

As duas colunas são **mutuamente exclusivas por construção** — nunca as duas preenchidas, e é isso que a Etapa 3 vai verificar. Quem consome a tabela lê `Regime_deriv_Petr IS NOT NULL` para saber que a base de cálculo daquela mercadoria não se apura por MVA, em vez de encontrar um `NULL` mudo e ter que adivinhar se é ausência de regra ou regra de outro tipo.

Se quiser tornar a exclusividade uma garantia do banco, e não apenas do script de carga:

```sql
ALTER TABLE fisc.anexo5_sefaz_normalizado
    ADD CONSTRAINT CK_anexo5_deriv_petr_exclusivo
        CHECK (MVA_Original_deriv_Petr IS NULL OR Regime_deriv_Petr IS NULL);
```

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

### 3.3 O desdobramento das colunas de regime preservou tudo?

Esta é a verificação que prova que nenhuma marcação de regime se perdeu na conversão.

```sql
SELECT
    COUNT(*)                                                          AS total,
    SUM(CASE WHEN MVA_Original_deriv_Petr IS NOT NULL THEN 1 ELSE 0 END) AS mva_numerica,
    SUM(CASE WHEN Regime_deriv_Petr       IS NOT NULL THEN 1 ELSE 0 END) AS com_regime,
    SUM(CASE WHEN MVA_Original_deriv_Petr IS NOT NULL
              AND Regime_deriv_Petr       IS NOT NULL THEN 1 ELSE 0 END) AS ambos_preenchidos
FROM fisc.anexo5_sefaz_normalizado;
```


| Coluna do resultado | Valor esperado |
| --------------------- | ---------------- |
| `total`             | 1.836          |
| `mva_numerica`      | 1.704          |
| `com_regime`        | 132            |
| `ambos_preenchidos` | **0**          |

`1.704 + 132 = 1.836`. Se a soma não fechar, houve perda: algum valor não era numérico nem foi capturado como texto.

Confira também a distribuição dos regimes, que deve reproduzir exatamente a contagem apurada na Etapa 1:

```sql
SELECT Regime_deriv_Petr, COUNT(*) AS qtd
FROM fisc.anexo5_sefaz_normalizado
WHERE Regime_deriv_Petr IS NOT NULL
GROUP BY Regime_deriv_Petr
ORDER BY qtd DESC;
```


| Regime        | Registros |
| --------------- | ----------- |
| `PMPF`        | 80        |
| `AD REM`      | 50        |
| `DIFERIMENTO` | 2         |
| **Total**     | **132**   |

Para a coluna de não derivados, o resultado é mais simples: **1.835** com MVA numérica e **1** com regime (`conforme art.2º do decreto 46.692/25`).

Vocabulário fechado é premissa desta modelagem. Se uma carga futura trouxer um quarto valor em `Regime_deriv_Petr`, ele aparece nesta consulta e precisa de decisão explícita — não entra silenciosamente.

### 3.4 A distribuição bate com a origem?

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

### 3.5 A integridade lógica se sustenta?

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

**Atenção à verificação 3.5-d.** O par `(CEST, NCM_SH)` se repete **634 vezes** no arquivo — e isso é legítimo: cada repetição é uma versão da regra em uma vigência diferente (alteração de MVA por decreto). Duplicidade só é erro quando duas versões do mesmo par valem **na mesma data**. É por isso que a tabela tem um `Id IDENTITY` como PK em vez de chave natural: a chave lógica é `(CEST, NCM_SH, Vigencia_inicial)`.

### 3.6 Registrar a execução

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
    -- (1) casamento por prefixo: o NCM do Anexo 5 tem de 4 a 8 dígitos
    ON  a5.NCM_SH IS NOT NULL
    AND LEN(a5.NCM_SH) BETWEEN 4 AND 8 -- LEN(NCM_SH) BETWEEN 4 AND 8
    AND LEFT(c170.REG0200_COD_NCM, LEN(a5.NCM_SH)) = a5.NCM_SH
    -- (2) regra vigente na data do documento; Vigencia_final NULL = ainda vigente
    -- TRY_CONVERT(DATE, ...) nos dois lados: o ISNULL nunca chega a operar em DATETIME
    AND TRY_CONVERT(DATE, c170.C100_DT_DOC) >= TRY_CONVERT(DATE, a5.Vigencia_inicial)
  -- TRY_CONVERT(DATE;C100_DT_DOC) >= TRY_CONVERT(DATE;Vigencia_inicial)
    AND TRY_CONVERT(DATE, c170.C100_DT_DOC) <= ISNULL(TRY_CONVERT(DATE, a5.Vigencia_final), '9999-12-31')
  -- TRY_CONVERT(DATE;C100_DT_DOC) <= ISNULL(TRY_CONVERT(DATE;Vigencia_final);'9999-12-31')
WHERE TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS) > 0
  -- TRY_CONVERT(DECIMAL(16;2); C170_VL_ICMS)
  -- (3) entradas (1xxx interna, 2xxx interestadual) destinadas a revenda
  AND TRY_CONVERT(INT, c170.C170_CFOP) IN (1102, 2102, 1113, 2113, 1116, 2116)
  --  TRY_CONVERT(INT;C170_CFOP)   IN (1102; 2102; 1113; 2113; 1116; 2116)
  -- (4) CST que indica crédito: 00, 10, 20, 51, 70, 90 — o erro está aqui,
  --     o correto para mercadoria sob ST seria 60
  AND RIGHT('00' + CAST(TRY_CONVERT(INT, c170.C170_CST_ICMS) AS VARCHAR(3)), 2)
      IN ('00', '10', '20', '70', '90')
  AND c170.REG0200_COD_NCM NOT IN ('-', '')
  AND c170.REG0200_COD_NCM IS NOT NULL
GROUP BY c170.REG0_IE, c170.REG0_NOME, a5.CEST, c170.REG0200_COD_NCM
-- (5) materialidade
HAVING SUM(TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS)) >= 1000.00
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
-- 1.3 Se o mesmo NCM casar com dois CEST vigentes (verificação 3.5-d),
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

**Alteração de estrutura aplicada nesta carga.** As colunas `Regime_deriv_Petr` e `Regime_N_deriv_Petr` foram acrescentadas a `fisc.anexo5_sefaz_normalizado` (seção 2.2). Comunique a mudança a quem já consome a tabela: consultas existentes continuam funcionando, mas quem lia `MVA_Original_deriv_Petr IS NULL` como "sem regra" passa a precisar distinguir ausência de regra de regime não apurável por MVA.

A tradução para as 132 mercadorias afetadas:


| `Regime_deriv_Petr` | Significado para a auditoria                                                                                         |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `PMPF`              | Base de cálculo é o preço médio ponderado a consumidor final, publicado em ato próprio. Não confronte com MVA. |
| `AD REM`            | Tributação por alíquota específica sobre unidade de medida. O imposto não varia com o preço.                   |
| `DIFERIMENTO`       | Lançamento adiado para etapa posterior. A ausência de destaque na operação é**esperada**, não é omissão.     |

Sem essa distinção, as 2 mercadorias em diferimento apareceriam em qualquer relatório de "saída sem débito de ICMS" como irregularidade — e não são.
