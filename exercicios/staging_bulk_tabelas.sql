-- Script de criação das tabelas de staging para exercícios de BULK INSERT
CREATE SCHEMA IF NOT EXISTS staging;
GO

CREATE TABLE staging.stg_nfe_bulk (
    chave_acesso NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente NVARCHAR(20) NULL,
    id_contribuinte_destinatario NVARCHAR(20) NULL,
    data_emissao NVARCHAR(10) NULL,
    valor_total NVARCHAR(20) NULL,
    situacao NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE staging.stg_item_nfe_bulk (
    id_nfe NVARCHAR(20) NULL,
    ncm NVARCHAR(8) NULL,
    cfop NVARCHAR(4) NULL,
    valor_item NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE staging.stg_nfce_bulk (
    chave_acesso NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente NVARCHAR(20) NULL,
    data_emissao NVARCHAR(10) NULL,
    valor_total NVARCHAR(20) NULL,
    situacao NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE staging.stg_item_nfce_bulk (
    id_nfce NVARCHAR(20) NULL,
    ncm NVARCHAR(8) NULL,
    cfop NVARCHAR(4) NULL,
    valor_item NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE staging.stg_cte_bulk (
    chave_acesso NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente NVARCHAR(20) NULL,
    id_nfe_vinculada NVARCHAR(20) NULL,
    valor_frete NVARCHAR(20) NULL,
    situacao NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE staging.stg_efd_registro_bulk (
    id_contribuinte NVARCHAR(20) NULL,
    tipo_registro NVARCHAR(10) NULL,
    periodo_apuracao NVARCHAR(7) NULL,
    id_nfe_referenciada NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO
