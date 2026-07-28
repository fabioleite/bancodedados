-- Script de criação das tabelas FINAIS do esquema fiscal.
-- Recebem os dados já validados e convertidos a partir das tabelas de
-- staging definidas em staging_bulk_tabelas.sql (staging.stg_nfe_bulk,
-- staging.stg_item_nfe_bulk, staging.stg_nfce_bulk, staging.stg_item_nfce_bulk,
-- staging.stg_cte_bulk, staging.stg_efd_registro_bulk).
--
-- Diferente da staging (colunas NVARCHAR, sem regras), aqui os tipos já são
-- os definitivos e as restrições (PK, FK, CHECK, UNIQUE) garantem a
-- integridade referencial e o domínio de valores esperado pela legislação
-- fiscal (situação do documento, formato de NCM/CFOP, período de apuração).

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fiscal')
BEGIN
    EXEC('CREATE SCHEMA fiscal');
END
GO

-- =============================================================
-- fiscal.CONTRIBUINTE
-- Cadastro dos contribuintes (emitentes/destinatários dos documentos
-- fiscais). As tabelas de staging trazem apenas o id do contribuinte;
-- aqui ele vira uma referência real, permitindo checar se o emitente
-- ou destinatário de fato existe no cadastro.
-- =============================================================
IF OBJECT_ID('fiscal.CONTRIBUINTE', 'U') IS NOT NULL
    DROP TABLE fiscal.CONTRIBUINTE;
GO

CREATE TABLE fiscal.CONTRIBUINTE (
    id_contribuinte     BIGINT IDENTITY(1,1) NOT NULL,
    cnpj                CHAR(14)       NOT NULL,
    razao_social         VARCHAR(150)   NOT NULL,
    inscricao_estadual  VARCHAR(20)    NULL,
    uf                  CHAR(2)        NOT NULL,
    situacao_cadastral  VARCHAR(20)    NOT NULL CONSTRAINT DF_CONTRIBUINTE_situacao DEFAULT ('ATIVO'),

    CONSTRAINT PK_CONTRIBUINTE PRIMARY KEY (id_contribuinte),
    CONSTRAINT UQ_CONTRIBUINTE_cnpj UNIQUE (cnpj),
    CONSTRAINT CK_CONTRIBUINTE_cnpj_numerico CHECK (cnpj NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_CONTRIBUINTE_situacao CHECK (situacao_cadastral IN ('ATIVO', 'SUSPENSO', 'BAIXADO'))
);
GO

-- =============================================================
-- fiscal.NFE
-- Nota Fiscal Eletrônica consolidada. Cada linha corresponde a uma
-- nota já validada (chave de 44 posições, contribuintes existentes,
-- valor não negativo, situação dentro do domínio aceito pela SEFAZ).
-- =============================================================
IF OBJECT_ID('fiscal.NFE', 'U') IS NOT NULL
    DROP TABLE fiscal.NFE;
GO

CREATE TABLE fiscal.NFE (
    id_nfe                       BIGINT IDENTITY(1,1) NOT NULL,
    chave_acesso                 CHAR(44)      NOT NULL,
    id_contribuinte_emitente     BIGINT        NOT NULL,
    id_contribuinte_destinatario BIGINT        NOT NULL,
    data_emissao                 DATE          NOT NULL,
    valor_total                  DECIMAL(16,2) NOT NULL,
    situacao                     VARCHAR(20)   NOT NULL,

    CONSTRAINT PK_NFE PRIMARY KEY (id_nfe),
    CONSTRAINT UQ_NFE_chave_acesso UNIQUE (chave_acesso),
    CONSTRAINT CK_NFE_chave_acesso_numerica CHECK (chave_acesso NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_NFE_valor_total CHECK (valor_total >= 0),
    CONSTRAINT CK_NFE_situacao CHECK (situacao IN ('AUTORIZADA', 'CANCELADA', 'DENEGADA', 'INUTILIZADA')),
    CONSTRAINT CK_NFE_emitente_diferente_destinatario CHECK (id_contribuinte_emitente <> id_contribuinte_destinatario),

    CONSTRAINT FK_NFE_emitente FOREIGN KEY (id_contribuinte_emitente)
        REFERENCES fiscal.CONTRIBUINTE (id_contribuinte),
    CONSTRAINT FK_NFE_destinatario FOREIGN KEY (id_contribuinte_destinatario)
        REFERENCES fiscal.CONTRIBUINTE (id_contribuinte)
);
GO

-- Índices para acelerar consultas de cruzamento fiscal por contribuinte
CREATE INDEX IX_NFE_emitente ON fiscal.NFE (id_contribuinte_emitente);
CREATE INDEX IX_NFE_destinatario ON fiscal.NFE (id_contribuinte_destinatario);
GO

-- =============================================================
-- fiscal.ITEM_NFE
-- Itens (produtos/serviços) de cada NF-e. Não existe sem a nota "pai" —
-- por isso o FK usa ON DELETE CASCADE: se a nota for removida, os itens
-- associados são removidos junto, evitando itens órfãos.
-- =============================================================
IF OBJECT_ID('fiscal.ITEM_NFE', 'U') IS NOT NULL
    DROP TABLE fiscal.ITEM_NFE;
GO

CREATE TABLE fiscal.ITEM_NFE (
    id_item_nfe BIGINT IDENTITY(1,1) NOT NULL,
    id_nfe      BIGINT        NOT NULL,
    ncm         CHAR(8)       NOT NULL,
    cfop        CHAR(4)       NOT NULL,
    valor_item  DECIMAL(16,2) NOT NULL,

    CONSTRAINT PK_ITEM_NFE PRIMARY KEY (id_item_nfe),
    CONSTRAINT CK_ITEM_NFE_ncm_numerico CHECK (ncm NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_ITEM_NFE_cfop_numerico CHECK (cfop NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_ITEM_NFE_cfop_natureza CHECK (LEFT(cfop, 1) IN ('1', '2', '3', '5', '6', '7')),
    CONSTRAINT CK_ITEM_NFE_valor CHECK (valor_item >= 0),

    CONSTRAINT FK_ITEM_NFE_nfe FOREIGN KEY (id_nfe)
        REFERENCES fiscal.NFE (id_nfe) ON DELETE CASCADE
);
GO

CREATE INDEX IX_ITEM_NFE_nfe ON fiscal.ITEM_NFE (id_nfe);
GO

-- =============================================================
-- fiscal.NFCE
-- Nota Fiscal de Consumidor Eletrônica (venda a varejo). Estrutura
-- semelhante à NFE, mas com um único contribuinte (o consumidor final
-- não é cadastrado como contribuinte).
-- =============================================================
IF OBJECT_ID('fiscal.NFCE', 'U') IS NOT NULL
    DROP TABLE fiscal.NFCE;
GO

CREATE TABLE fiscal.NFCE (
    id_nfce                   BIGINT IDENTITY(1,1) NOT NULL,
    chave_acesso              CHAR(44)      NOT NULL,
    id_contribuinte_emitente  BIGINT        NOT NULL,
    data_emissao              DATE          NOT NULL,
    valor_total               DECIMAL(16,2) NOT NULL,
    situacao                  VARCHAR(20)   NOT NULL,

    CONSTRAINT PK_NFCE PRIMARY KEY (id_nfce),
    CONSTRAINT UQ_NFCE_chave_acesso UNIQUE (chave_acesso),
    CONSTRAINT CK_NFCE_chave_acesso_numerica CHECK (chave_acesso NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_NFCE_valor_total CHECK (valor_total >= 0),
    CONSTRAINT CK_NFCE_situacao CHECK (situacao IN ('AUTORIZADA', 'CANCELADA', 'DENEGADA')),

    CONSTRAINT FK_NFCE_emitente FOREIGN KEY (id_contribuinte_emitente)
        REFERENCES fiscal.CONTRIBUINTE (id_contribuinte)
);
GO

CREATE INDEX IX_NFCE_emitente ON fiscal.NFCE (id_contribuinte_emitente);
GO

-- =============================================================
-- fiscal.ITEM_NFCE
-- Itens da NFC-e — mesma lógica de dependência do ITEM_NFE.
-- =============================================================
IF OBJECT_ID('fiscal.ITEM_NFCE', 'U') IS NOT NULL
    DROP TABLE fiscal.ITEM_NFCE;
GO

CREATE TABLE fiscal.ITEM_NFCE (
    id_item_nfce BIGINT IDENTITY(1,1) NOT NULL,
    id_nfce      BIGINT        NOT NULL,
    ncm          CHAR(8)       NOT NULL,
    cfop         CHAR(4)       NOT NULL,
    valor_item   DECIMAL(16,2) NOT NULL,

    CONSTRAINT PK_ITEM_NFCE PRIMARY KEY (id_item_nfce),
    CONSTRAINT CK_ITEM_NFCE_ncm_numerico CHECK (ncm NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_ITEM_NFCE_cfop_numerico CHECK (cfop NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_ITEM_NFCE_cfop_natureza CHECK (LEFT(cfop, 1) IN ('1', '2', '3', '5', '6', '7')),
    CONSTRAINT CK_ITEM_NFCE_valor CHECK (valor_item >= 0),

    CONSTRAINT FK_ITEM_NFCE_nfce FOREIGN KEY (id_nfce)
        REFERENCES fiscal.NFCE (id_nfce) ON DELETE CASCADE
);
GO

CREATE INDEX IX_ITEM_NFCE_nfce ON fiscal.ITEM_NFCE (id_nfce);
GO

-- =============================================================
-- fiscal.CTE
-- Conhecimento de Transporte eletrônico (CT-e) — documento fiscal de
-- frete. Pode estar vinculado a uma NF-e transportada; por isso o FK
-- para fiscal.NFE é opcional (NULL) e usa ON DELETE SET NULL: se a nota
-- vinculada for excluída, o CT-e continua existindo, apenas perde a
-- referência (o frete em si não deixa de ter ocorrido).
-- =============================================================
IF OBJECT_ID('fiscal.CTE', 'U') IS NOT NULL
    DROP TABLE fiscal.CTE;
GO

CREATE TABLE fiscal.CTE (
    id_cte                    BIGINT IDENTITY(1,1) NOT NULL,
    chave_acesso              CHAR(44)      NOT NULL,
    id_contribuinte_emitente  BIGINT        NOT NULL,
    id_nfe_vinculada          BIGINT        NULL,
    valor_frete               DECIMAL(16,2) NOT NULL,
    situacao                  VARCHAR(20)   NOT NULL,

    CONSTRAINT PK_CTE PRIMARY KEY (id_cte),
    CONSTRAINT UQ_CTE_chave_acesso UNIQUE (chave_acesso),
    CONSTRAINT CK_CTE_chave_acesso_numerica CHECK (chave_acesso NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_CTE_valor_frete CHECK (valor_frete >= 0),
    CONSTRAINT CK_CTE_situacao CHECK (situacao IN ('AUTORIZADO', 'CANCELADO', 'DENEGADO')),

    CONSTRAINT FK_CTE_emitente FOREIGN KEY (id_contribuinte_emitente)
        REFERENCES fiscal.CONTRIBUINTE (id_contribuinte),
    CONSTRAINT FK_CTE_nfe_vinculada FOREIGN KEY (id_nfe_vinculada)
        REFERENCES fiscal.NFE (id_nfe) ON DELETE SET NULL
);
GO

CREATE INDEX IX_CTE_emitente ON fiscal.CTE (id_contribuinte_emitente);
CREATE INDEX IX_CTE_nfe_vinculada ON fiscal.CTE (id_nfe_vinculada);
GO

-- =============================================================
-- fiscal.EFD_REGISTRO
-- Registros da Escrituração Fiscal Digital (EFD-ICMS/IPI) entregues
-- pelo contribuinte, podendo referenciar uma NF-e específica (registro
-- C100/C170, por exemplo). O FK para NFE também é opcional, pelo mesmo
-- motivo do CT-e: nem todo registro EFD referencia uma nota.
-- =============================================================
IF OBJECT_ID('fiscal.EFD_REGISTRO', 'U') IS NOT NULL
    DROP TABLE fiscal.EFD_REGISTRO;
GO

CREATE TABLE fiscal.EFD_REGISTRO (
    id_efd_registro       BIGINT IDENTITY(1,1) NOT NULL,
    id_contribuinte       BIGINT      NOT NULL,
    tipo_registro         VARCHAR(4)  NOT NULL,
    periodo_apuracao      CHAR(7)     NOT NULL,
    id_nfe_referenciada   BIGINT      NULL,

    CONSTRAINT PK_EFD_REGISTRO PRIMARY KEY (id_efd_registro),
    CONSTRAINT CK_EFD_REGISTRO_periodo_formato CHECK (periodo_apuracao LIKE '[0-1][0-9]/[1-2][0-9][0-9][0-9]'),

    CONSTRAINT FK_EFD_REGISTRO_contribuinte FOREIGN KEY (id_contribuinte)
        REFERENCES fiscal.CONTRIBUINTE (id_contribuinte),
    CONSTRAINT FK_EFD_REGISTRO_nfe FOREIGN KEY (id_nfe_referenciada)
        REFERENCES fiscal.NFE (id_nfe) ON DELETE SET NULL
);
GO

CREATE INDEX IX_EFD_REGISTRO_contribuinte ON fiscal.EFD_REGISTRO (id_contribuinte);
CREATE INDEX IX_EFD_REGISTRO_nfe ON fiscal.EFD_REGISTRO (id_nfe_referenciada);
GO

-- =============================================================
-- Exemplo de migração staging -> final (ilustrativo, apenas para NFE)
-- =============================================================
-- INSERT INTO fiscal.NFE (chave_acesso, id_contribuinte_emitente, id_contribuinte_destinatario, data_emissao, valor_total, situacao)
-- SELECT
--     s.chave_acesso,
--     TRY_CONVERT(BIGINT, s.id_contribuinte_emitente),
--     TRY_CONVERT(BIGINT, s.id_contribuinte_destinatario),
--     TRY_CONVERT(DATE, s.data_emissao),
--     TRY_CONVERT(DECIMAL(16,2), s.valor_total),
--     s.situacao
-- FROM staging.stg_nfe_bulk s
-- WHERE TRY_CONVERT(DATE, s.data_emissao) IS NOT NULL
--   AND TRY_CONVERT(DECIMAL(16,2), s.valor_total) IS NOT NULL
--   AND NOT EXISTS (SELECT 1 FROM fiscal.NFE n WHERE n.chave_acesso = s.chave_acesso);
