BULK INSERT [turma2_sefaz].staging.stg_nfe_bulk FROM '\\FREYJA\dados\staging\staging_nfe_20.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\r\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT [turma2_sefaz].staging.stg_nfe_bulk 
FROM '\\FREYJA\dados\staging\staging_nfe_20.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0A', -- Alterado para padrão Windows 0x0A
    CODEPAGE = '65001',
    TABLOCK
);

select * from staging.stg_nfe_bulk

CREATE TABLE staging.stg_nfe_bulk (
    chave_acesso NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente NVARCHAR(20) NULL,
    id_contribuinte_destinatario NVARCHAR(20) NULL,
    data_emissao NVARCHAR(10) NULL,
    valor_total NVARCHAR(20) NULL,
    situacao NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);


select * from staging.stg_nfe_bulk;