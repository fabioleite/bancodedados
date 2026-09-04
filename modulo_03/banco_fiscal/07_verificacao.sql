/* =====================================================================
   Script 07 - Verificacao da carga e mapa das inconsistencias
   ---------------------------------------------------------------------
   Execute depois dos scripts 01 a 06. Cada consulta traz a contagem
   ESPERADA ao lado da contagem obtida: se as duas colunas forem iguais,
   a base foi carregada corretamente.
   ===================================================================== */
USE curso_integridade_fiscal;
GO
SET NOCOUNT ON;
GO

PRINT '=== 1. VOLUME POR TABELA ===';
SELECT 'municipio'        AS tabela, COUNT(*) AS obtido,    35 AS esperado FROM dbo.municipio
UNION ALL SELECT 'contribuinte',     COUNT(*),     60 FROM dbo.contribuinte
UNION ALL SELECT 'auditor_fiscal',   COUNT(*),     20 FROM dbo.auditor_fiscal
UNION ALL SELECT 'referencia_preco', COUNT(*),     28 FROM dbo.referencia_preco
UNION ALL SELECT 'nfe',              COUNT(*),  10636 FROM dbo.nfe
UNION ALL SELECT 'nfe_item',         COUNT(*),  30794 FROM dbo.nfe_item
UNION ALL SELECT 'efd_c100',         COUNT(*),   8059 FROM dbo.efd_c100
UNION ALL SELECT 'efd_c170',         COUNT(*),  23158 FROM dbo.efd_c170
UNION ALL SELECT 'ordem_servico',    COUNT(*),    150 FROM dbo.ordem_servico
UNION ALL SELECT 'auto_infracao',    COUNT(*),     72 FROM dbo.auto_infracao;
GO

PRINT '=== 2. PANORAMA DOS DOCUMENTOS ===';
SELECT situacao, tipo_operacao, COUNT(*) AS qtd, SUM(valor_total) AS valor
FROM   dbo.nfe
GROUP BY situacao, tipo_operacao
ORDER BY situacao, tipo_operacao;
GO

/* =====================================================================
   3. MAPA DAS INCONSISTENCIAS PLANTADAS
      (o "gabarito" da base: o que cada cruzamento deve encontrar)
   ===================================================================== */

PRINT '=== 3.1 Omissao de escrituracao (NF-e autorizada de saida sem C100) ===';
-- Esperado: 2.023 no total  |  980 apenas entre declarantes do regime NORMAL
-- A diferenca e um ACHADO DIDATICO: contribuintes do Simples e MEI nao
-- entregam EFD ICMS/IPI, de modo que apareceriam como falso positivo se a
-- consulta nao filtrasse o regime tributario.
SELECT COUNT(*) AS omissoes_todas
FROM   dbo.nfe AS n
WHERE  n.situacao = 'AUTORIZADA' AND n.tipo_operacao = '1'
  AND  NOT EXISTS (SELECT 1 FROM dbo.efd_c100 AS e
                   WHERE e.chave_acesso    = n.chave_acesso
                     AND e.id_contribuinte = n.id_emitente
                     AND e.ind_oper        = '1'
                     AND e.cod_situacao    = '00');

SELECT COUNT(*) AS omissoes_regime_normal
FROM   dbo.nfe AS n
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = n.id_emitente
WHERE  n.situacao = 'AUTORIZADA' AND n.tipo_operacao = '1'
  AND  c.regime_tributario = 'NORMAL'
  AND  NOT EXISTS (SELECT 1 FROM dbo.efd_c100 AS e
                   WHERE e.chave_acesso    = n.chave_acesso
                     AND e.id_contribuinte = n.id_emitente
                     AND e.ind_oper        = '1'
                     AND e.cod_situacao    = '00');
GO

PRINT '=== 3.2 Operadores de conjunto sobre as chaves de acesso ===';
-- Esperado: EXCEPT (nfe - efd) = 2.994 | EXCEPT (efd - nfe) = 440 | INTERSECT = 6.897
-- Dos 440 do segundo caso, 38 sao chaves que NAO existem na base de NF-e
-- (documento de outra UF ou inexistente) e 402 sao notas canceladas,
-- escrituradas corretamente com cod_situacao = '02'.
SELECT COUNT(*) AS nfe_sem_efd FROM (
    SELECT chave_acesso FROM dbo.nfe      WHERE situacao = 'AUTORIZADA'
    EXCEPT
    SELECT chave_acesso FROM dbo.efd_c100 WHERE chave_acesso IS NOT NULL) AS t;

SELECT COUNT(*) AS efd_sem_nfe FROM (
    SELECT chave_acesso FROM dbo.efd_c100 WHERE chave_acesso IS NOT NULL
    EXCEPT
    SELECT chave_acesso FROM dbo.nfe      WHERE situacao = 'AUTORIZADA') AS t;

SELECT COUNT(*) AS chaves_sem_nenhuma_nfe
FROM   dbo.efd_c100 AS e
WHERE  e.chave_acesso IS NOT NULL
  AND  NOT EXISTS (SELECT 1 FROM dbo.nfe AS n WHERE n.chave_acesso = e.chave_acesso);   -- 38
GO

PRINT '=== 3.3 Divergencias de valor e de item entre NF-e e EFD ===';
-- Esperado: 147 documentos com divergencia de valor / ICMS
SELECT COUNT(*) AS divergencia_de_valor
FROM   dbo.nfe AS n
       INNER JOIN dbo.efd_c100 AS e ON e.chave_acesso = n.chave_acesso
WHERE  n.situacao = 'AUTORIZADA' AND e.cod_situacao = '00' AND e.ind_oper = '1'
  AND (ABS(n.valor_total - e.valor_documento) > 0.01
    OR ABS(n.valor_icms  - e.valor_icms)      > 0.01);

-- Esperado: 354 itens com divergencia de NCM, CFOP, aliquota ou valor
SELECT COUNT(*) AS divergencia_de_item
FROM   dbo.nfe      AS n
       INNER JOIN dbo.nfe_item AS i    ON i.id_nfe       = n.id_nfe
       INNER JOIN dbo.efd_c100 AS e    ON e.chave_acesso = n.chave_acesso
       INNER JOIN dbo.efd_c170 AS c170 ON c170.id_c100   = e.id_c100
                                      AND c170.num_item  = i.num_item
WHERE  n.situacao = 'AUTORIZADA' AND e.cod_situacao = '00' AND e.ind_oper = '1'
  AND (i.ncm  <> c170.ncm
    OR i.cfop <> c170.cfop
    OR ABS(COALESCE(i.aliquota_icms,0) - COALESCE(c170.aliquota_icms,0)) > 0.01
    OR ABS(i.valor_total_item - c170.valor_item) > 0.01);
GO

PRINT '=== 3.4 Chaves de acesso internamente inconsistentes ===';
-- Esperado: 13 no total (6 com CNPJ divergente, 5 com periodo divergente, 2 com 43 posicoes)
SELECT CASE WHEN LEN(n.chave_acesso) <> 44 THEN 'TAMANHO INVALIDO'
            WHEN SUBSTRING(n.chave_acesso, 7, 14) <> c.cnpj THEN 'CNPJ DIVERGENTE'
            ELSE 'PERIODO DIVERGENTE' END AS inconsistencia,
       COUNT(*) AS qtd
FROM   dbo.nfe AS n
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = n.id_emitente
WHERE  LEN(n.chave_acesso) <> 44
   OR  SUBSTRING(n.chave_acesso, 7, 14) <> c.cnpj
   OR  SUBSTRING(n.chave_acesso, 3, 4)  <> FORMAT(n.data_emissao, 'yyMM')
GROUP BY CASE WHEN LEN(n.chave_acesso) <> 44 THEN 'TAMANHO INVALIDO'
              WHEN SUBSTRING(n.chave_acesso, 7, 14) <> c.cnpj THEN 'CNPJ DIVERGENTE'
              ELSE 'PERIODO DIVERGENTE' END;
GO

PRINT '=== 3.5 Indicadores de risco por contribuinte ===';
-- Esperado: 3 emitentes com mais de 1.000 notas autorizadas (ids 1, 2 e 3)
--           6 emitentes com mais de 500
SELECT COUNT(*) AS emitentes_acima_de_1000 FROM (
    SELECT id_emitente FROM dbo.nfe WHERE situacao = 'AUTORIZADA'
    GROUP BY id_emitente HAVING COUNT(*) > 1000) AS t;

-- Esperado: 2 contribuintes com cancelamento acima de 15% (ids 4 e 12)
SELECT n.id_emitente, COUNT(*) AS qtd_notas,
       CAST(SUM(CASE WHEN n.situacao='CANCELADA' THEN 1 ELSE 0 END) AS DECIMAL(10,2))
            / NULLIF(COUNT(*),0) * 100 AS pct_cancelamento
FROM   dbo.nfe AS n
GROUP BY n.id_emitente
HAVING COUNT(*) >= 100
   AND CAST(SUM(CASE WHEN n.situacao='CANCELADA' THEN 1 ELSE 0 END) AS DECIMAL(10,2))
       / NULLIF(COUNT(*),0) * 100 > 15
ORDER BY pct_cancelamento DESC;

-- Esperado: 2 contribuintes do regime NORMAL com carga efetiva abaixo de 4% (ids 5 e 17)
SELECT n.id_emitente,
       SUM(n.valor_icms) / NULLIF(SUM(n.valor_total),0) * 100 AS carga_efetiva_pct
FROM   dbo.nfe AS n
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = n.id_emitente
WHERE  n.situacao = 'AUTORIZADA' AND n.tipo_operacao = '1'
  AND  c.regime_tributario = 'NORMAL'
GROUP BY n.id_emitente
HAVING SUM(n.valor_total) > 100000
   AND SUM(n.valor_icms) / NULLIF(SUM(n.valor_total),0) < 0.04
ORDER BY carga_efetiva_pct;
GO

PRINT '=== 3.6 Omissos de obrigacao acessoria e demais marcadores ===';
-- Esperado: 8 contribuintes ATIVOS do regime NORMAL sem EFD do periodo 202501
SELECT COUNT(*) AS sem_efd_202501
FROM   dbo.contribuinte AS c
WHERE  c.situacao_cadastral = 'ATIVO' AND c.regime_tributario = 'NORMAL'
  AND  NOT EXISTS (SELECT 1 FROM dbo.efd_c100 AS e
                   WHERE e.id_contribuinte = c.id_contribuinte
                     AND e.periodo_apuracao = '202501');

-- Esperado: 7 contribuintes que nunca figuraram como destinatarios
SELECT COUNT(*) AS nunca_destinatarios
FROM   dbo.contribuinte AS c
WHERE  NOT EXISTS (SELECT 1 FROM dbo.nfe AS n WHERE n.id_destinatario = c.id_contribuinte);

-- Esperado:  1.041 notas a consumidor nao identificado
--               25 registros C100 sem chave (documento nao eletronico)
--                6 contribuintes sem faturamento declarado
--               10 municipios sem regiao fiscal (outras UFs)
--               63 ordens de servico sem data de conclusao
--               15 notas em que a soma dos itens diverge do cabecalho
SELECT (SELECT COUNT(*) FROM dbo.nfe WHERE id_destinatario IS NULL)              AS consumidor_nao_identificado,
       (SELECT COUNT(*) FROM dbo.efd_c100 WHERE chave_acesso IS NULL)            AS c100_sem_chave,
       (SELECT COUNT(*) FROM dbo.contribuinte WHERE faturamento_declarado IS NULL) AS sem_faturamento,
       (SELECT COUNT(*) FROM dbo.municipio WHERE regiao_fiscal IS NULL)          AS sem_regiao_fiscal,
       (SELECT COUNT(*) FROM dbo.ordem_servico WHERE data_conclusao IS NULL)     AS os_em_aberto;

WITH itens AS (
    SELECT id_nfe, SUM(valor_total_item) AS total_itens
    FROM   dbo.nfe_item GROUP BY id_nfe)
SELECT COUNT(*) AS notas_com_soma_divergente
FROM   dbo.nfe AS n INNER JOIN itens AS i ON i.id_nfe = n.id_nfe
WHERE  ABS(n.valor_total - i.total_itens) > 0.01;
GO

PRINT '=== 3.7 Operacoes circulares plantadas (indicio de simulacao) ===';
-- Esperado: 3 pares de contribuintes (8 e 19, 14 e 27, 23 e 31)
SELECT n1.id_emitente AS contribuinte_a, n1.id_destinatario AS contribuinte_b,
       COUNT(DISTINCT n1.id_nfe) AS notas_a_para_b,
       COUNT(DISTINCT n2.id_nfe) AS notas_b_para_a
FROM   dbo.nfe AS n1
       INNER JOIN dbo.nfe AS n2 ON n2.id_emitente     = n1.id_destinatario
                               AND n2.id_destinatario = n1.id_emitente
                               AND ABS(DATEDIFF(DAY, n1.data_emissao, n2.data_emissao)) <= 30
WHERE  n1.situacao = 'AUTORIZADA' AND n2.situacao = 'AUTORIZADA'
  AND  n1.id_emitente < n1.id_destinatario
GROUP BY n1.id_emitente, n1.id_destinatario
HAVING COUNT(DISTINCT n1.id_nfe) >= 3 AND COUNT(DISTINCT n2.id_nfe) >= 3
ORDER BY notas_a_para_b DESC;
GO

PRINT '=== 4. CONFERENCIA DE INTEGRIDADE (todas devem retornar ZERO) ===';
SELECT 'nfe sem emitente valido' AS verificacao, COUNT(*) AS deve_ser_zero
FROM dbo.nfe n WHERE NOT EXISTS (SELECT 1 FROM dbo.contribuinte c WHERE c.id_contribuinte = n.id_emitente)
UNION ALL
SELECT 'item orfao', COUNT(*) FROM dbo.nfe_item i WHERE NOT EXISTS (SELECT 1 FROM dbo.nfe n WHERE n.id_nfe = i.id_nfe)
UNION ALL
SELECT 'c170 orfao', COUNT(*) FROM dbo.efd_c170 x WHERE NOT EXISTS (SELECT 1 FROM dbo.efd_c100 e WHERE e.id_c100 = x.id_c100)
UNION ALL
SELECT 'auto sem OS', COUNT(*) FROM dbo.auto_infracao a WHERE NOT EXISTS (SELECT 1 FROM dbo.ordem_servico o WHERE o.id_os = a.id_os)
UNION ALL
SELECT 'valores negativos em nfe', COUNT(*) FROM dbo.nfe WHERE valor_total < 0 OR valor_icms < 0
UNION ALL
SELECT 'auditor que supervisiona a si mesmo', COUNT(*) FROM dbo.auditor_fiscal WHERE matricula_supervisor = matricula
UNION ALL
SELECT 'nota emitida para o proprio emitente', COUNT(*) FROM dbo.nfe WHERE id_destinatario = id_emitente;
GO

PRINT 'Script 07 concluido: verificacao executada.';
GO
