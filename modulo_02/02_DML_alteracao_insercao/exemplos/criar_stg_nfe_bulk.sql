-- Script de criação da tabela de staging para receber o staging_nfe_20.csv
-- Colunas em NVARCHAR para aceitar a carga bruta via BULK INSERT sem falhar
-- por conversão; a validação/conversão (TRY_CONVERT/TRY_CAST) fica para a
-- etapa de consolidação nas tabelas definitivas.

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC('CREATE SCHEMA staging');
END
GO

IF OBJECT_ID('staging.stg_nfe_bulk', 'U') IS NOT NULL
    DROP TABLE staging.stg_nfe_bulk;
GO

CREATE TABLE staging.stg_nfe_bulk (
    chave_acesso                 NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente     NVARCHAR(20) NULL,
    id_contribuinte_destinatario NVARCHAR(20) NULL,
    data_emissao                 NVARCHAR(10) NULL,
    valor_total                  NVARCHAR(20) NULL,
    situacao                     NVARCHAR(20) NULL
);
GO

-- Carga (ajuste o caminho para onde o SQL Server consegue ler o arquivo)
-- BULK INSERT staging.stg_nfe_bulk
-- FROM 'C:\dados\staging\staging_nfe_20.csv'
-- WITH (
--     FIRSTROW = 2,
--     FIELDTERMINATOR = ';',
--     ROWTERMINATOR = '\n',
--     CODEPAGE = '65001',
--     TABLOCK
-- );

-- Tabelas de staging dos demais arquivos CSV.
CREATE TABLE staging.stg_item_nfe_bulk (
    id_nfe      NVARCHAR(20) NULL,
    ncm         NVARCHAR(8) NULL,
    cfop        NVARCHAR(4) NULL,
    valor_item  NVARCHAR(20) NULL
);
GO

CREATE TABLE staging.stg_nfce_bulk (
    chave_acesso             NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente NVARCHAR(20) NULL,
    data_emissao             NVARCHAR(10) NULL,
    valor_total              NVARCHAR(20) NULL,
    situacao                 NVARCHAR(20) NULL
);
GO

CREATE TABLE staging.stg_item_nfce_bulk (
    id_nfce     NVARCHAR(20) NULL,
    ncm         NVARCHAR(8) NULL,
    cfop        NVARCHAR(4) NULL,
    valor_item  NVARCHAR(20) NULL
);
GO

CREATE TABLE staging.stg_cte_bulk (
    chave_acesso          NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente NVARCHAR(20) NULL,
    id_nfe_vinculada       NVARCHAR(20) NULL,
    valor_frete            NVARCHAR(20) NULL,
    situacao               NVARCHAR(20) NULL
);
GO

CREATE TABLE staging.stg_efd_registro_bulk (
    id_contribuinte       NVARCHAR(20) NULL,
    tipo_registro          NVARCHAR(10) NULL,
    periodo_apuracao       NVARCHAR(7) NULL,
    id_nfe_referenciada    NVARCHAR(20) NULL
);
GO

-- Cargas dos seis arquivos CSV desta pasta.
-- Ajuste @pasta_csv para um diretório que o serviço do SQL Server consiga ler.
DECLARE @pasta_csv NVARCHAR(260) = N'C:\dados\staging\';
DECLARE @sql NVARCHAR(MAX);

SET @sql = N'BULK INSERT staging.stg_nfe_bulk
FROM ''' + @pasta_csv + N'staging_nfe_20.csv''
WITH (FIRSTROW = 2, FIELDTERMINATOR = '';'', ROWTERMINATOR = ''0x0A'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;

SET @sql = N'BULK INSERT staging.stg_item_nfe_bulk
FROM ''' + @pasta_csv + N'staging_item_nfe_20.csv''
WITH (FIRSTROW = 2, FIELDTERMINATOR = '';'', ROWTERMINATOR = ''0x0A'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;

SET @sql = N'BULK INSERT staging.stg_nfce_bulk
FROM ''' + @pasta_csv + N'staging_nfce_20.csv''
WITH (FIRSTROW = 2, FIELDTERMINATOR = '';'', ROWTERMINATOR = ''0x0A'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;

SET @sql = N'BULK INSERT staging.stg_item_nfce_bulk
FROM ''' + @pasta_csv + N'staging_item_nfce_20.csv''
WITH (FIRSTROW = 2, FIELDTERMINATOR = '';'', ROWTERMINATOR = ''0x0A'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;

SET @sql = N'BULK INSERT staging.stg_cte_bulk
FROM ''' + @pasta_csv + N'staging_cte_20.csv''
WITH (FIRSTROW = 2, FIELDTERMINATOR = '';'', ROWTERMINATOR = ''0x0A'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;

SET @sql = N'BULK INSERT staging.stg_efd_registro_bulk
FROM ''' + @pasta_csv + N'staging_efd_registro_20.csv''
WITH (FIRSTROW = 2, FIELDTERMINATOR = '';'', ROWTERMINATOR = ''0x0A'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;
GO

-- Adiciona a coluna de controle somente depois da carga, usando o horário da
-- importação como valor padrão.
ALTER TABLE staging.stg_nfe_bulk
ADD imported_dt DATETIME2 NOT NULL
    CONSTRAINT DF_stg_nfe_bulk_imported_dt DEFAULT SYSUTCDATETIME();
GO

ALTER TABLE staging.stg_item_nfe_bulk
ADD imported_dt DATETIME2 NOT NULL
    CONSTRAINT DF_stg_item_nfe_bulk_imported_dt DEFAULT SYSUTCDATETIME();
GO

ALTER TABLE staging.stg_nfce_bulk
ADD imported_dt DATETIME2 NOT NULL
    CONSTRAINT DF_stg_nfce_bulk_imported_dt DEFAULT SYSUTCDATETIME();
GO

ALTER TABLE staging.stg_item_nfce_bulk
ADD imported_dt DATETIME2 NOT NULL
    CONSTRAINT DF_stg_item_nfce_bulk_imported_dt DEFAULT SYSUTCDATETIME();
GO

ALTER TABLE staging.stg_cte_bulk
ADD imported_dt DATETIME2 NOT NULL
    CONSTRAINT DF_stg_cte_bulk_imported_dt DEFAULT SYSUTCDATETIME();
GO

ALTER TABLE staging.stg_efd_registro_bulk
ADD imported_dt DATETIME2 NOT NULL
    CONSTRAINT DF_stg_efd_registro_bulk_imported_dt DEFAULT SYSUTCDATETIME();
GO
