SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'departamentos')
    EXEC('CREATE SCHEMA departamentos');
GO

-- Remove objetos anteriores para permitir reexecucao do script.
DROP TABLE IF EXISTS departamentos.empregado_desconto;
DROP TABLE IF EXISTS departamentos.empregado_vencimento;
DROP TABLE IF EXISTS departamentos.tab_resumo_depto;
DROP TABLE IF EXISTS departamentos.desconto;
DROP TABLE IF EXISTS departamentos.vencimento;
DROP TABLE IF EXISTS departamentos.empregado;
DROP TABLE IF EXISTS departamentos.divisao;
DROP TABLE IF EXISTS departamentos.departamento;
GO

CREATE TABLE departamentos.departamento (
    id_departamento INT IDENTITY(1,1) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    endereco_rua VARCHAR(150) NULL,
    endereco_numero VARCHAR(4) NULL,
    endereco_bairro VARCHAR(100) NULL,
    endereco_cidade VARCHAR(100) NULL,
    endereco_cep CHAR(8) NULL,
    endereco_uf CHAR(2) NULL,
    id_gerente INT NULL,
    data_inicio_gestao DATE NULL,
    data_fim_gestao DATE NULL,
    CONSTRAINT PK_departamento PRIMARY KEY (id_departamento),
    CONSTRAINT CHK_departamento_uf CHECK (endereco_uf IS NULL OR LEN(LTRIM(RTRIM(endereco_uf))) = 2),
    CONSTRAINT CHK_periodo_gestao CHECK (
        data_inicio_gestao IS NULL
        OR data_fim_gestao IS NULL
        OR data_fim_gestao >= data_inicio_gestao
    )
);
GO

CREATE TABLE departamentos.divisao (
    id_divisao INT IDENTITY(1,1) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    endereco_rua VARCHAR(150) NULL,
    endereco_numero VARCHAR(4) NULL,
    endereco_bairro VARCHAR(100) NULL,
    endereco_cidade VARCHAR(100) NULL,
    endereco_cep CHAR(8) NULL,
    endereco_uf CHAR(2) NULL,
    id_departamento INT NOT NULL,
    id_chefe INT NULL,
    CONSTRAINT PK_divisao PRIMARY KEY (id_divisao),
    CONSTRAINT DF_divisao_id_departamento DEFAULT (1) FOR id_departamento
);
GO

CREATE TABLE departamentos.empregado (
    id_empregado INT IDENTITY(1,1) NOT NULL,
    matricula VARCHAR(20) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    cpf CHAR(11) NOT NULL,
    endereco_rua VARCHAR(150) NULL,
    endereco_numero VARCHAR(4) NULL,
    endereco_bairro VARCHAR(100) NULL,
    endereco_cidade VARCHAR(100) NULL,
    endereco_cep CHAR(8) NULL,
    endereco_uf CHAR(2) NULL,
    data_lotacao DATE NULL,
    id_divisao INT NOT NULL,
    CONSTRAINT PK_empregado PRIMARY KEY (id_empregado),
    CONSTRAINT UQ_empregado_cpf UNIQUE (cpf),
    CONSTRAINT UQ_empregado_matricula UNIQUE (matricula)
);
GO

CREATE TABLE departamentos.vencimento (
    id_vencimento INT IDENTITY(1,1) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    valor DECIMAL(10,2) NOT NULL CONSTRAINT DF_vencimento_valor DEFAULT (0.00),
    CONSTRAINT PK_vencimento PRIMARY KEY (id_vencimento),
    CONSTRAINT CHK_valor_vencimento CHECK (valor >= 0)
);
GO

CREATE TABLE departamentos.desconto (
    id_desconto INT IDENTITY(1,1) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    valor DECIMAL(10,2) NOT NULL CONSTRAINT DF_desconto_valor DEFAULT (0.00),
    CONSTRAINT PK_desconto PRIMARY KEY (id_desconto),
    CONSTRAINT CHK_valor_desconto CHECK (valor >= 0)
);
GO

CREATE TABLE departamentos.empregado_vencimento (
    id_empregado INT NOT NULL,
    id_vencimento INT NOT NULL,
    CONSTRAINT PK_empregado_vencimento PRIMARY KEY (id_empregado, id_vencimento)
);
GO

CREATE TABLE departamentos.empregado_desconto (
    id_empregado INT NOT NULL,
    id_desconto INT NOT NULL,
    CONSTRAINT PK_empregado_desconto PRIMARY KEY (id_empregado, id_desconto)
);
GO

CREATE TABLE departamentos.tab_resumo_depto (
    id_departamento INT NULL,
    departamento VARCHAR(100) NULL,
    [insert] BIGINT NULL
);
GO

ALTER TABLE departamentos.divisao
ADD CONSTRAINT FK_divisao_departamento
FOREIGN KEY (id_departamento)
REFERENCES departamentos.departamento (id_departamento)
ON DELETE SET DEFAULT;
GO

ALTER TABLE departamentos.empregado
ADD CONSTRAINT FK_empregado_divisao
FOREIGN KEY (id_divisao)
REFERENCES departamentos.divisao (id_divisao);
GO

ALTER TABLE departamentos.departamento
ADD CONSTRAINT FK_departamento_gerente
FOREIGN KEY (id_gerente)
REFERENCES departamentos.empregado (id_empregado);
GO

ALTER TABLE departamentos.divisao
ADD CONSTRAINT FK_divisao_chefe
FOREIGN KEY (id_chefe)
REFERENCES departamentos.empregado (id_empregado);
GO

ALTER TABLE departamentos.empregado_vencimento
ADD CONSTRAINT FK_ev_empregado
FOREIGN KEY (id_empregado)
REFERENCES departamentos.empregado (id_empregado);
GO

ALTER TABLE departamentos.empregado_vencimento
ADD CONSTRAINT FK_ev_vencimento
FOREIGN KEY (id_vencimento)
REFERENCES departamentos.vencimento (id_vencimento);
GO

ALTER TABLE departamentos.empregado_desconto
ADD CONSTRAINT FK_ed_empregado
FOREIGN KEY (id_empregado)
REFERENCES departamentos.empregado (id_empregado);
GO

ALTER TABLE departamentos.empregado_desconto
ADD CONSTRAINT FK_ed_desconto
FOREIGN KEY (id_desconto)
REFERENCES departamentos.desconto (id_desconto);
GO
