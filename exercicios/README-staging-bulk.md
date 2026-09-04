# Arquivos de exemplo para BULK INSERT em staging

Este conjunto de arquivos foi preparado para exercícios de carga em massa com CSVs pequenos e fáceis de revisar.

## Como devem ser as tabelas de staging

As tabelas de staging devem funcionar como área de recepção temporária, com colunas em formato textual ou de fácil conversão. O objetivo é aceitar o arquivo bruto, validar e só depois mover para as tabelas definitivas.

### Regras recomendadas
- usar schema `staging`;
- preferir colunas `NVARCHAR`/`VARCHAR` para os campos que virão do CSV;
- incluir uma coluna `imported_dt` para registrar o momento da carga;
- manter os dados brutos sem transformações complexas na etapa de ingestão;
- usar `TRY_CONVERT`/`TRY_CAST` na etapa de consolidação para as tabelas finais.

### Estrutura sugerida

```sql
CREATE TABLE staging.stg_nfe_bulk (
    chave_acesso NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente NVARCHAR(20) NULL,
    id_contribuinte_destinatario NVARCHAR(20) NULL,
    data_emissao NVARCHAR(10) NULL,
    valor_total NVARCHAR(20) NULL,
    situacao NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
```

As demais tabelas seguem a mesma ideia, com colunas correspondentes aos arquivos CSV abaixo.

## Como devem ser os dados CSV

- usar `;` como separador de colunas;
- usar `UTF-8`;
- incluir cabeçalho na primeira linha;
- usar `\n` (LF) como fim de linha;
- manter datas no formato `YYYY-MM-DD`;
- manter valores monetários com ponto decimal (`100.00`);
- manter 20 registros por arquivo para facilitar a prática.

## Arquivos disponíveis
- [staging_nfe_20.csv](staging_nfe_20.csv)
- [staging_item_nfe_20.csv](staging_item_nfe_20.csv)
- [staging_nfce_20.csv](staging_nfce_20.csv)
- [staging_item_nfce_20.csv](staging_item_nfce_20.csv)
- [staging_cte_20.csv](staging_cte_20.csv)
- [staging_efd_registro_20.csv](staging_efd_registro_20.csv)
- [staging_bulk_tabelas.sql](staging_bulk_tabelas.sql)

## Passo a passo para o BULK INSERT

### 1. Criar as tabelas de staging
Execute o script [staging_bulk_tabelas.sql](staging_bulk_tabelas.sql) no banco de destino para criar o schema `staging` e as seis tabelas.

```sql
:r staging_bulk_tabelas.sql
```

### 2. Conferir o caminho dos arquivos CSV
O `BULK INSERT` exige um caminho acessível pela instância do SQL Server (não pelo cliente). Se o SQL Server rodar em outra máquina/container, copie os CSVs para um caminho local do servidor ou para um compartilhamento de rede visível por ele, por exemplo `C:\dados\staging\` ou `\\servidor\staging\`.

### 3. Executar o BULK INSERT de cada arquivo
Como os CSVs usam `;` como delimitador de coluna, `\n` (LF) como fim de linha, cabeçalho na primeira linha (`FIRSTROW = 2`) e codificação UTF-8 (`CODEPAGE = '65001'`), use o padrão abaixo, ajustando apenas o caminho e a tabela de destino:

```sql
BULK INSERT staging.stg_nfe_bulk
FROM 'C:\dados\staging\staging_nfe_20.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT staging.stg_item_nfe_bulk
FROM 'C:\dados\staging\staging_item_nfe_20.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT staging.stg_nfce_bulk
FROM 'C:\dados\staging\staging_nfce_20.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT staging.stg_item_nfce_bulk
FROM 'C:\dados\staging\staging_item_nfce_20.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT staging.stg_cte_bulk
FROM 'C:\dados\staging\staging_cte_20.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT staging.stg_efd_registro_bulk
FROM 'C:\dados\staging\staging_efd_registro_20.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
```

### 4. Validar a carga
Confira se cada tabela recebeu exatamente 20 linhas e se os campos numéricos/data convertem sem erro antes de mover para as tabelas definitivas:

```sql
SELECT COUNT(*) FROM staging.stg_nfe_bulk;
SELECT COUNT(*) FROM staging.stg_item_nfe_bulk;
SELECT COUNT(*) FROM staging.stg_nfce_bulk;
SELECT COUNT(*) FROM staging.stg_item_nfce_bulk;
SELECT COUNT(*) FROM staging.stg_cte_bulk;
SELECT COUNT(*) FROM staging.stg_efd_registro_bulk;

-- Exemplo de validação de conversão antes de consolidar
SELECT chave_acesso, valor_total
FROM staging.stg_nfe_bulk
WHERE TRY_CONVERT(DECIMAL(18,2), valor_total) IS NULL
   OR TRY_CONVERT(DATE, data_emissao) IS NULL;
```

### 5. Repetir a carga (opcional)
Se for repetir o exercício, esvazie as tabelas de staging antes de rodar o `BULK INSERT` novamente para evitar duplicidade:

```sql
TRUNCATE TABLE staging.stg_nfe_bulk;
TRUNCATE TABLE staging.stg_item_nfe_bulk;
TRUNCATE TABLE staging.stg_nfce_bulk;
TRUNCATE TABLE staging.stg_item_nfce_bulk;
TRUNCATE TABLE staging.stg_cte_bulk;
TRUNCATE TABLE staging.stg_efd_registro_bulk;
```
