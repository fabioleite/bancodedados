-- =========================================================
-- DDL ATUALIZADO - hierarquia NCM (adequado aos dados reais
-- do Portal Unico Siscomex, que tem profundidade VARIAVEL:
-- niveis de 2, 4, 5, 6 e 7 digitos antes do codigo NCM de 8
-- digitos, e nem todo ramo possui todos os niveis.
-- Por isso a hierarquia foi modelada como tabela auto-
-- referenciada (lista de adjacencia) em vez de uma tabela
-- fixa por nivel (secao/capitulo/posicao/subposicao).
-- SQL Server
-- =========================================================

CREATE TABLE ncm_nivel (
    id_nivel        INT           NOT NULL PRIMARY KEY,   -- gerado na carga (ordem do arquivo oficial)
    codigo          VARCHAR(10)   NOT NULL,                -- ex: '01', '01.01', '0101.2', '0102.21', '0102.29.1'
    descricao       NVARCHAR(1500) NOT NULL,
    nivel           TINYINT       NOT NULL,                -- quantidade de digitos: 2, 4, 5, 6 ou 7
    id_nivel_pai    INT           NULL,                    -- NULL somente para capitulo (nivel 2)
    data_inicio     DATE          NULL,
    data_fim        DATE          NULL,                    -- NULL = vigente (sem data fim definida)
    CONSTRAINT UQ_ncm_nivel_codigo UNIQUE (codigo),
    CONSTRAINT FK_ncm_nivel_pai FOREIGN KEY (id_nivel_pai)
        REFERENCES ncm_nivel (id_nivel),
    CONSTRAINT CK_ncm_nivel_nivel CHECK (nivel IN (2,4,5,6,7))
);

CREATE TABLE ncm (
    codigo_ncm          CHAR(8)       NOT NULL PRIMARY KEY, -- somente digitos, ex: '01012100' (formato usado em NF-e/ERPs)
    codigo_ncm_formatado VARCHAR(10)  NOT NULL,              -- ex: '0101.21.00' (formato de exibicao do Siscomex)
    descricao_ncm       NVARCHAR(1500) NOT NULL,
    id_nivel_pai        INT           NULL,                  -- referencia o ancestral mais proximo em ncm_nivel
    data_inicio         DATE          NULL,
    data_fim            DATE          NULL,
    CONSTRAINT FK_ncm_nivel_pai FOREIGN KEY (id_nivel_pai)
        REFERENCES ncm_nivel (id_nivel)
);

CREATE INDEX IX_ncm_nivel_pai ON ncm_nivel (id_nivel_pai);
CREATE INDEX IX_ncm_nivel_pai2 ON ncm (id_nivel_pai);
GO
