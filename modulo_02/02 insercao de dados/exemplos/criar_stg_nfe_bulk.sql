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
    situacao                     NVARCHAR(20) NULL,
    imported_dt                  DATETIME2 DEFAULT SYSUTCDATETIME()
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
