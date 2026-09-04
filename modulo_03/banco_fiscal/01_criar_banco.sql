/* =====================================================================
   Curso de Banco de Dados Relacional aplicado a Fiscalizacao Tributaria
   Banco de exemplo: curso_integridade_fiscal
   Script 01 - Criacao do banco, das tabelas e das restricoes
   SGBD: Microsoft SQL Server 2016 ou superior (T-SQL)
   ---------------------------------------------------------------------
   ATENCAO: este script APAGA e RECRIA as tabelas do esquema, caso ja
   existam. Execute-o apenas em ambiente de estudos.
   ===================================================================== */

/* ---------------------------------------------------------------------
   1. Banco de dados
   --------------------------------------------------------------------- */
IF DB_ID('curso_integridade_fiscal') IS NULL
BEGIN
    CREATE DATABASE curso_integridade_fiscal;
END
GO

USE curso_integridade_fiscal;
GO

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   2. Remocao das exibicoes e tabelas (ordem inversa das dependencias)
   --------------------------------------------------------------------- */
DROP VIEW  IF EXISTS dbo.vw_painel_malha;
DROP VIEW  IF EXISTS dbo.vw_autos_por_auditor;
DROP VIEW  IF EXISTS dbo.vw_nfe_saidas;
DROP VIEW  IF EXISTS dbo.vw_divergencia_nfe_efd;
GO

DROP TABLE IF EXISTS dbo.auto_infracao;
DROP TABLE IF EXISTS dbo.ordem_servico;
DROP TABLE IF EXISTS dbo.efd_c170;
DROP TABLE IF EXISTS dbo.efd_c100;
DROP TABLE IF EXISTS dbo.nfe_item;
DROP TABLE IF EXISTS dbo.nfe;
DROP TABLE IF EXISTS dbo.referencia_preco;
DROP TABLE IF EXISTS dbo.contribuinte;
DROP TABLE IF EXISTS dbo.auditor_fiscal;
DROP TABLE IF EXISTS dbo.municipio;
GO

/* ---------------------------------------------------------------------
   3. Tabelas de cadastro
   --------------------------------------------------------------------- */

-- 3.1 Municipios -------------------------------------------------------
CREATE TABLE dbo.municipio (
    id_municipio   INT           NOT NULL,
    cod_ibge       CHAR(7)       NOT NULL,
    nome           VARCHAR(80)   NOT NULL,
    uf             CHAR(2)       NOT NULL,
    regiao_fiscal  VARCHAR(40)   NULL,      -- NULL para municipios de outras UFs
    CONSTRAINT PK_municipio        PRIMARY KEY (id_municipio),
    CONSTRAINT UQ_municipio_ibge   UNIQUE (cod_ibge),
    CONSTRAINT CK_municipio_ibge   CHECK (cod_ibge NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_municipio_uf     CHECK (uf = UPPER(uf) AND LEN(uf) = 2)
);
GO

-- 3.2 Contribuintes ----------------------------------------------------
CREATE TABLE dbo.contribuinte (
    id_contribuinte        INT            NOT NULL,
    cnpj                   CHAR(14)       NOT NULL,
    razao_social           VARCHAR(120)   NOT NULL,
    nome_fantasia          VARCHAR(120)   NULL,
    id_municipio           INT            NOT NULL,
    regime_tributario      VARCHAR(20)    NOT NULL,
    situacao_cadastral     VARCHAR(20)    NOT NULL,
    data_inicio_atividade  DATE           NOT NULL,
    cnae_principal         CHAR(7)        NOT NULL,
    faturamento_declarado  DECIMAL(15,2)  NULL,      -- NULL = nao declarado
    CONSTRAINT PK_contribuinte           PRIMARY KEY (id_contribuinte),
    CONSTRAINT UQ_contribuinte_cnpj      UNIQUE (cnpj),
    CONSTRAINT FK_contribuinte_municipio FOREIGN KEY (id_municipio)
        REFERENCES dbo.municipio (id_municipio),
    CONSTRAINT CK_contribuinte_cnpj      CHECK (cnpj NOT LIKE '%[^0-9]%' AND LEN(cnpj) = 14),
    CONSTRAINT CK_contribuinte_regime    CHECK (regime_tributario IN ('NORMAL','SIMPLES','MEI','ISENTO')),
    CONSTRAINT CK_contribuinte_situacao  CHECK (situacao_cadastral IN ('ATIVO','SUSPENSO','BAIXADO','INAPTO')),
    CONSTRAINT CK_contribuinte_fatur     CHECK (faturamento_declarado IS NULL OR faturamento_declarado >= 0)
);
GO

-- 3.3 Auditores fiscais (auto-relacionamento) --------------------------
CREATE TABLE dbo.auditor_fiscal (
    matricula             INT           NOT NULL,
    nome                  VARCHAR(120)  NOT NULL,
    cargo                 VARCHAR(40)   NOT NULL,
    regiao_fiscal         VARCHAR(40)   NOT NULL,
    data_admissao         DATE          NOT NULL,
    matricula_supervisor  INT           NULL,       -- NULL no topo da hierarquia
    CONSTRAINT PK_auditor_fiscal            PRIMARY KEY (matricula),
    CONSTRAINT FK_auditor_supervisor        FOREIGN KEY (matricula_supervisor)
        REFERENCES dbo.auditor_fiscal (matricula),
    CONSTRAINT CK_auditor_cargo             CHECK (cargo IN ('AUDITOR','SUPERVISOR','GERENTE')),
    CONSTRAINT CK_auditor_nao_supervisiona_a_si CHECK (matricula_supervisor <> matricula)
);
GO

-- 3.4 Pauta fiscal de referencia (usada no exemplo de juncao theta) ----
CREATE TABLE dbo.referencia_preco (
    ncm         CHAR(8)        NOT NULL,
    descricao   VARCHAR(120)   NOT NULL,
    valor_min   DECIMAL(15,4)  NOT NULL,
    valor_max   DECIMAL(15,4)  NOT NULL,
    CONSTRAINT PK_referencia_preco  PRIMARY KEY (ncm),
    CONSTRAINT CK_referencia_faixa  CHECK (valor_min <= valor_max)
);
GO

/* ---------------------------------------------------------------------
   4. Documentos fiscais eletronicos
   --------------------------------------------------------------------- */

-- 4.1 NF-e (cabecalho) -------------------------------------------------
CREATE TABLE dbo.nfe (
    id_nfe           INT            NOT NULL,
    chave_acesso     CHAR(44)       NOT NULL,
    numero           INT            NOT NULL,
    serie            SMALLINT       NOT NULL,
    data_emissao     DATE           NOT NULL,
    id_emitente      INT            NOT NULL,
    id_destinatario  INT            NULL,      -- NULL = consumidor nao identificado
    tipo_operacao    CHAR(1)        NOT NULL,  -- 0 = entrada, 1 = saida
    valor_total      DECIMAL(15,2)  NOT NULL,
    valor_icms       DECIMAL(15,2)  NOT NULL,
    situacao         VARCHAR(20)    NOT NULL,
    CONSTRAINT PK_nfe               PRIMARY KEY (id_nfe),
    CONSTRAINT UQ_nfe_chave         UNIQUE (chave_acesso),
    CONSTRAINT FK_nfe_emitente      FOREIGN KEY (id_emitente)
        REFERENCES dbo.contribuinte (id_contribuinte),
    CONSTRAINT FK_nfe_destinatario  FOREIGN KEY (id_destinatario)
        REFERENCES dbo.contribuinte (id_contribuinte),
    CONSTRAINT CK_nfe_tipo_oper     CHECK (tipo_operacao IN ('0','1')),
    CONSTRAINT CK_nfe_situacao      CHECK (situacao IN ('AUTORIZADA','CANCELADA','DENEGADA','INUTILIZADA')),
    CONSTRAINT CK_nfe_valores       CHECK (valor_total >= 0 AND valor_icms >= 0),
    CONSTRAINT CK_nfe_emit_dest     CHECK (id_destinatario IS NULL OR id_destinatario <> id_emitente)
);
GO

-- 4.2 Itens da NF-e ----------------------------------------------------
CREATE TABLE dbo.nfe_item (
    id_item           INT            NOT NULL,
    id_nfe            INT            NOT NULL,
    num_item          SMALLINT       NOT NULL,
    cod_produto       VARCHAR(30)    NOT NULL,
    descricao         VARCHAR(150)   NOT NULL,
    ncm               CHAR(8)        NOT NULL,
    cfop              CHAR(4)        NOT NULL,
    cst_icms          CHAR(3)        NOT NULL,
    quantidade        DECIMAL(15,4)  NOT NULL,
    valor_unitario    DECIMAL(15,4)  NOT NULL,
    valor_total_item  DECIMAL(15,2)  NOT NULL,
    aliquota_icms     DECIMAL(5,2)   NULL,       -- NULL quando nao tributado
    valor_icms_item   DECIMAL(15,2)  NOT NULL,
    CONSTRAINT PK_nfe_item        PRIMARY KEY (id_item),
    CONSTRAINT UQ_nfe_item_ordem  UNIQUE (id_nfe, num_item),
    CONSTRAINT FK_nfe_item_nfe    FOREIGN KEY (id_nfe)
        REFERENCES dbo.nfe (id_nfe) ON DELETE CASCADE,
    CONSTRAINT CK_nfe_item_ncm    CHECK (ncm NOT LIKE '%[^0-9]%' AND LEN(ncm) = 8),
    CONSTRAINT CK_nfe_item_cfop   CHECK (cfop NOT LIKE '%[^0-9]%' AND LEN(cfop) = 4),
    CONSTRAINT CK_nfe_item_qtd    CHECK (quantidade > 0),
    CONSTRAINT CK_nfe_item_aliq   CHECK (aliquota_icms IS NULL OR (aliquota_icms >= 0 AND aliquota_icms <= 100))
);
GO

/* ---------------------------------------------------------------------
   5. Escrituracao Fiscal Digital (EFD) - Bloco C
   --------------------------------------------------------------------- */

-- 5.1 Registro C100 - documento escriturado ----------------------------
CREATE TABLE dbo.efd_c100 (
    id_c100          INT            NOT NULL,
    id_contribuinte  INT            NOT NULL,   -- declarante
    periodo_apuracao CHAR(6)        NOT NULL,   -- AAAAMM
    ind_oper         CHAR(1)        NOT NULL,   -- 0 = entrada, 1 = saida
    cod_situacao     CHAR(2)        NOT NULL,   -- 00 = regular, 02 = cancelado ...
    num_doc          INT            NOT NULL,
    serie            VARCHAR(3)     NULL,
    chave_acesso     CHAR(44)       NULL,       -- NULL em documento nao eletronico
    data_emissao     DATE           NOT NULL,
    valor_documento  DECIMAL(15,2)  NOT NULL,
    valor_icms       DECIMAL(15,2)  NOT NULL,
    CONSTRAINT PK_efd_c100            PRIMARY KEY (id_c100),
    CONSTRAINT FK_efd_c100_contrib    FOREIGN KEY (id_contribuinte)
        REFERENCES dbo.contribuinte (id_contribuinte),
    CONSTRAINT CK_efd_c100_ind_oper   CHECK (ind_oper IN ('0','1')),
    CONSTRAINT CK_efd_c100_periodo    CHECK (periodo_apuracao NOT LIKE '%[^0-9]%' AND LEN(periodo_apuracao) = 6),
    CONSTRAINT CK_efd_c100_valores    CHECK (valor_documento >= 0 AND valor_icms >= 0)
);
GO
/*  Observacao didatica: NAO existe chave estrangeira entre
    efd_c100.chave_acesso e nfe.chave_acesso - e nem deveria existir.
    A EFD pode escriturar documentos emitidos em outras UFs, ausentes da
    base local, e e justamente essa ausencia de restricao que permite as
    inconsistencias que a malha fiscal procura.                          */

-- 5.2 Registro C170 - itens do documento escriturado -------------------
CREATE TABLE dbo.efd_c170 (
    id_c170                INT            NOT NULL,
    id_c100                INT            NOT NULL,
    num_item               SMALLINT       NOT NULL,
    cod_item               VARCHAR(30)    NOT NULL,
    descricao_complementar VARCHAR(150)   NULL,
    ncm                    CHAR(8)        NOT NULL,
    cfop                   CHAR(4)        NOT NULL,
    cst_icms               CHAR(3)        NOT NULL,
    quantidade             DECIMAL(15,4)  NOT NULL,
    valor_item             DECIMAL(15,2)  NOT NULL,
    aliquota_icms          DECIMAL(5,2)   NULL,
    valor_icms_item        DECIMAL(15,2)  NOT NULL,
    CONSTRAINT PK_efd_c170        PRIMARY KEY (id_c170),
    CONSTRAINT UQ_efd_c170_ordem  UNIQUE (id_c100, num_item),
    CONSTRAINT FK_efd_c170_c100   FOREIGN KEY (id_c100)
        REFERENCES dbo.efd_c100 (id_c100) ON DELETE CASCADE,
    CONSTRAINT CK_efd_c170_qtd    CHECK (quantidade > 0)
);
GO

/* ---------------------------------------------------------------------
   6. Atividade de fiscalizacao
   --------------------------------------------------------------------- */

-- 6.1 Ordens de servico ------------------------------------------------
CREATE TABLE dbo.ordem_servico (
    id_os              INT           NOT NULL,
    numero_os          VARCHAR(20)   NOT NULL,
    id_contribuinte    INT           NOT NULL,
    matricula_auditor  INT           NOT NULL,
    tipo_fiscalizacao  VARCHAR(40)   NOT NULL,
    data_abertura      DATE          NOT NULL,
    data_conclusao     DATE          NULL,       -- NULL enquanto em andamento
    situacao           VARCHAR(20)   NOT NULL,
    CONSTRAINT PK_ordem_servico          PRIMARY KEY (id_os),
    CONSTRAINT UQ_ordem_servico_numero   UNIQUE (numero_os),
    CONSTRAINT FK_os_contribuinte        FOREIGN KEY (id_contribuinte)
        REFERENCES dbo.contribuinte (id_contribuinte),
    CONSTRAINT FK_os_auditor             FOREIGN KEY (matricula_auditor)
        REFERENCES dbo.auditor_fiscal (matricula),
    CONSTRAINT CK_os_tipo                CHECK (tipo_fiscalizacao IN ('MALHA FISCAL','AUDITORIA PLENA','MONITORAMENTO','DILIGENCIA')),
    CONSTRAINT CK_os_situacao            CHECK (situacao IN ('ABERTA','EM ANDAMENTO','CONCLUIDA','CANCELADA')),
    CONSTRAINT CK_os_datas               CHECK (data_conclusao IS NULL OR data_conclusao >= data_abertura)
);
GO

-- 6.2 Autos de infracao ------------------------------------------------
CREATE TABLE dbo.auto_infracao (
    id_auto           INT            NOT NULL,
    numero_auto       VARCHAR(20)    NOT NULL,
    id_os             INT            NOT NULL,
    id_contribuinte   INT            NOT NULL,
    data_lavratura    DATE           NOT NULL,
    dispositivo_legal VARCHAR(80)    NOT NULL,
    valor_principal   DECIMAL(15,2)  NOT NULL,
    valor_multa       DECIMAL(15,2)  NOT NULL,
    situacao          VARCHAR(25)    NOT NULL,
    CONSTRAINT PK_auto_infracao        PRIMARY KEY (id_auto),
    CONSTRAINT UQ_auto_infracao_numero UNIQUE (numero_auto),
    CONSTRAINT FK_auto_os              FOREIGN KEY (id_os)
        REFERENCES dbo.ordem_servico (id_os),
    CONSTRAINT FK_auto_contribuinte    FOREIGN KEY (id_contribuinte)
        REFERENCES dbo.contribuinte (id_contribuinte),
    CONSTRAINT CK_auto_valores         CHECK (valor_principal >= 0 AND valor_multa >= 0),
    CONSTRAINT CK_auto_situacao        CHECK (situacao IN ('LAVRADO','IMPUGNADO','JULGADO PROCEDENTE',
                                                           'JULGADO IMPROCEDENTE','PAGO','INSCRITO DIVIDA ATIVA'))
);
GO

/* ---------------------------------------------------------------------
   7. Indices minimos (chaves estrangeiras mais usadas nas juncoes)
      Os indices de DESEMPENHO ficam no script 08, propositalmente
      separados, para que o exercicio de plano de execucao do Modulo 10
      possa comparar o antes e o depois.
   --------------------------------------------------------------------- */
CREATE INDEX IX_nfe_emitente      ON dbo.nfe (id_emitente);
CREATE INDEX IX_nfe_destinatario  ON dbo.nfe (id_destinatario);
CREATE INDEX IX_nfe_item_nfe      ON dbo.nfe_item (id_nfe);
CREATE INDEX IX_efd_c100_contrib  ON dbo.efd_c100 (id_contribuinte);
CREATE INDEX IX_efd_c170_c100     ON dbo.efd_c170 (id_c100);
CREATE INDEX IX_os_contribuinte   ON dbo.ordem_servico (id_contribuinte);
CREATE INDEX IX_auto_os           ON dbo.auto_infracao (id_os);
GO

PRINT 'Script 01 concluido: banco e tabelas criados.';
GO
