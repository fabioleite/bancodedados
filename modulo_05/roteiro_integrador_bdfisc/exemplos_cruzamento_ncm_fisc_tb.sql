/*
    NCM x fisc.TB_: exemplos de fiscalizacao tributaria de produtos.

    Tabela fiscal usada: fisc.TB_126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA_03.
    Ela e resultado de auditoria de entradas com CFOP de substituicao tributaria.
    Como nao possui NCM, o codigo e recuperado de dbo.ITEM_NFE pela chave da NF-e
    e pelo numero do item, e validado em dbo.ncm.

    Os resultados sao indicios de auditoria, nao conclusao automatica de infracao.
*/

-- 1. Itens da TB_126 com NCM ausente, malformado ou nao localizado no cadastro oficial.
SELECT
    T.NF_CHAVE_ACESSO, T.NF_DHEMI, T.NF_XNOME_EMIT, T.ITEMNF_NITEM,
    T.ITEMNF_CPROD, T.ITEMNF_XPROD, I.cdncm AS ncm_declarado,
    T.ITEMNF_CFOP, T.ITEMNF_CST, T.ITEMNF_VPROD,
    CASE
        WHEN NULLIF(LTRIM(RTRIM(I.cdncm)), '') IS NULL THEN 'NCM nao informado'
        WHEN NcmNormalizado.codigo LIKE '%[^0-9]%' OR LEN(NcmNormalizado.codigo) <> 8
            THEN 'Formato diferente de oito digitos'
        WHEN NC.codigo_ncm IS NULL THEN 'NCM nao localizado na tabela oficial'
    END AS motivo_indicio
FROM fisc.TB_126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA_03 AS T
INNER JOIN dbo.NFE AS N ON N.nrchaveacesso = T.NF_CHAVE_ACESSO
INNER JOIN dbo.ITEM_NFE AS I
    ON I.sqnfe = N.sqnfe AND I.tpnfe = N.tpnfe AND I.nritemnfe = T.ITEMNF_NITEM
CROSS APPLY (SELECT REPLACE(REPLACE(LTRIM(RTRIM(I.cdncm)), '.', ''), ' ', '') AS codigo) AS NcmNormalizado
LEFT JOIN dbo.ncm AS NC ON NC.codigo_ncm = NcmNormalizado.codigo
WHERE NULLIF(LTRIM(RTRIM(I.cdncm)), '') IS NULL
   OR NcmNormalizado.codigo LIKE '%[^0-9]%'
   OR LEN(NcmNormalizado.codigo) <> 8
   OR NC.codigo_ncm IS NULL
ORDER BY T.NF_DHEMI DESC, T.NF_CHAVE_ACESSO, T.ITEMNF_NITEM;
GO

-- 2. NCM cadastrado, mas fora da vigencia na data de emissao da NF-e.
SELECT
    T.NF_CHAVE_ACESSO, T.NF_DHEMI, T.NF_XNOME_EMIT, T.ITEMNF_CPROD,
    T.ITEMNF_XPROD, I.cdncm, NC.descricao_ncm, NC.data_inicio, NC.data_fim,
    CASE
        WHEN NC.data_inicio IS NOT NULL AND CAST(T.NF_DHEMI AS date) < NC.data_inicio
            THEN 'NCM ainda nao vigente na emissao'
        WHEN NC.data_fim IS NOT NULL AND CAST(T.NF_DHEMI AS date) > NC.data_fim
            THEN 'NCM encerrado na emissao'
    END AS motivo_indicio
FROM fisc.TB_126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA_03 AS T
INNER JOIN dbo.NFE AS N ON N.nrchaveacesso = T.NF_CHAVE_ACESSO
INNER JOIN dbo.ITEM_NFE AS I
    ON I.sqnfe = N.sqnfe AND I.tpnfe = N.tpnfe AND I.nritemnfe = T.ITEMNF_NITEM
CROSS APPLY (SELECT REPLACE(REPLACE(LTRIM(RTRIM(I.cdncm)), '.', ''), ' ', '') AS codigo) AS NcmNormalizado
INNER JOIN dbo.ncm AS NC ON NC.codigo_ncm = NcmNormalizado.codigo
WHERE (NC.data_inicio IS NOT NULL AND CAST(T.NF_DHEMI AS date) < NC.data_inicio)
   OR (NC.data_fim IS NOT NULL AND CAST(T.NF_DHEMI AS date) > NC.data_fim)
ORDER BY T.NF_DHEMI DESC;
GO

-- 3. Priorizacao de capitulos NCM pelo valor e ICMS da selecao TB_126.
SELECT
    LEFT(NC.codigo_ncm, 2) AS capitulo_ncm,
    COUNT(*) AS quantidade_itens,
    COUNT(DISTINCT T.NF_CHAVE_ACESSO) AS quantidade_notas,
    SUM(ISNULL(T.ITEMNF_VPROD, 0)) AS valor_produtos,
    SUM(ISNULL(T.ITEMNF_VBC, 0)) AS base_icms_proprio,
    SUM(ISNULL(T.ITEMNF_VLICMS, 0)) AS icms_proprio,
    SUM(ISNULL(T.ITEMNF_VBCST, 0)) AS base_icms_st,
    SUM(ISNULL(T.ITEMNF_VICMSST, 0)) AS icms_st
FROM fisc.TB_126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA_03 AS T
INNER JOIN dbo.NFE AS N ON N.nrchaveacesso = T.NF_CHAVE_ACESSO
INNER JOIN dbo.ITEM_NFE AS I
    ON I.sqnfe = N.sqnfe AND I.tpnfe = N.tpnfe AND I.nritemnfe = T.ITEMNF_NITEM
CROSS APPLY (SELECT REPLACE(REPLACE(LTRIM(RTRIM(I.cdncm)), '.', ''), ' ', '') AS codigo) AS NcmNormalizado
INNER JOIN dbo.ncm AS NC ON NC.codigo_ncm = NcmNormalizado.codigo
GROUP BY LEFT(NC.codigo_ncm, 2)
ORDER BY valor_produtos DESC;
GO

-- 4. ST e ICMS proprio destacados: caso para revisar CFOP, CST e legislacao aplicavel.
SELECT
    T.NF_CHAVE_ACESSO, T.NF_DHEMI, T.NF_XNOME_EMIT, T.NF_UF_EMIT,
    T.NF_XNOME_DEST, T.NF_UF_DEST, T.ITEMNF_NITEM, T.ITEMNF_CPROD,
    T.ITEMNF_XPROD, I.cdncm, NC.codigo_ncm_formatado, NC.descricao_ncm,
    T.ITEMNF_CFOP, T.ITEMNF_CST, T.ITEMNF_VPROD, T.ITEMNF_VBC,
    T.ITEMNF_VLICMS, T.ITEMNF_VBCST, T.ITEMNF_VICMSST
FROM fisc.TB_126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA_03 AS T
INNER JOIN dbo.NFE AS N ON N.nrchaveacesso = T.NF_CHAVE_ACESSO
INNER JOIN dbo.ITEM_NFE AS I
    ON I.sqnfe = N.sqnfe AND I.tpnfe = N.tpnfe AND I.nritemnfe = T.ITEMNF_NITEM
LEFT JOIN dbo.ncm AS NC
    ON NC.codigo_ncm = REPLACE(REPLACE(LTRIM(RTRIM(I.cdncm)), '.', ''), ' ', '')
WHERE ISNULL(T.ITEMNF_VBCST, 0) > 0
  AND ISNULL(T.ITEMNF_VICMSST, 0) > 0
  AND ISNULL(T.ITEMNF_VLICMS, 0) > 0
ORDER BY T.ITEMNF_VLICMS DESC, T.ITEMNF_VICMSST DESC;
GO

-- 5. Revisao humana: descricao comercial, NCM oficial e nivel hierarquico pai.
SELECT
    T.NF_CHAVE_ACESSO, T.NF_DHEMI, T.ITEMNF_CPROD, T.ITEMNF_XPROD,
    NC.codigo_ncm, NC.codigo_ncm_formatado, NC.descricao_ncm,
    Nivel.codigo AS codigo_nivel_pai, Nivel.descricao AS descricao_nivel_pai,
    Nivel.nivel AS quantidade_digitos_nivel_pai,
    T.ITEMNF_CFOP, T.ITEMNF_CST, T.ITEMNF_VPROD
FROM fisc.TB_126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA_03 AS T
INNER JOIN dbo.NFE AS N ON N.nrchaveacesso = T.NF_CHAVE_ACESSO
INNER JOIN dbo.ITEM_NFE AS I
    ON I.sqnfe = N.sqnfe AND I.tpnfe = N.tpnfe AND I.nritemnfe = T.ITEMNF_NITEM
INNER JOIN dbo.ncm AS NC
    ON NC.codigo_ncm = REPLACE(REPLACE(LTRIM(RTRIM(I.cdncm)), '.', ''), ' ', '')
LEFT JOIN dbo.ncm_nivel AS Nivel ON Nivel.id_nivel = NC.id_nivel_pai
ORDER BY T.NF_DHEMI DESC, NC.codigo_ncm, T.ITEMNF_XPROD;
GO

-- 6. Produto interno com mais de um NCM nos itens filtrados pela TB_126.
WITH ProdutoNcm AS (
    SELECT
        T.ITEMNF_CPROD, MIN(T.ITEMNF_XPROD) AS descricao_exemplo, I.cdncm,
        MIN(CAST(T.NF_DHEMI AS date)) AS primeira_emissao,
        MAX(CAST(T.NF_DHEMI AS date)) AS ultima_emissao,
        COUNT(*) AS quantidade_itens, SUM(ISNULL(T.ITEMNF_VPROD, 0)) AS valor_produtos
    FROM fisc.TB_126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA_03 AS T
    INNER JOIN dbo.NFE AS N ON N.nrchaveacesso = T.NF_CHAVE_ACESSO
    INNER JOIN dbo.ITEM_NFE AS I
        ON I.sqnfe = N.sqnfe AND I.tpnfe = N.tpnfe AND I.nritemnfe = T.ITEMNF_NITEM
    WHERE NULLIF(LTRIM(RTRIM(T.ITEMNF_CPROD)), '') IS NOT NULL
      AND NULLIF(LTRIM(RTRIM(I.cdncm)), '') IS NOT NULL
    GROUP BY T.ITEMNF_CPROD, I.cdncm
), ProdutosComDivergencia AS (
    SELECT ITEMNF_CPROD
    FROM ProdutoNcm
    GROUP BY ITEMNF_CPROD
    HAVING COUNT(DISTINCT REPLACE(REPLACE(LTRIM(RTRIM(cdncm)), '.', ''), ' ', '')) > 1
)
SELECT
    P.ITEMNF_CPROD, P.cdncm AS ncm_declarado, NC.descricao_ncm,
    P.descricao_exemplo, P.primeira_emissao, P.ultima_emissao,
    P.quantidade_itens, P.valor_produtos
FROM ProdutoNcm AS P
INNER JOIN ProdutosComDivergencia AS D ON D.ITEMNF_CPROD = P.ITEMNF_CPROD
LEFT JOIN dbo.ncm AS NC
    ON NC.codigo_ncm = REPLACE(REPLACE(LTRIM(RTRIM(P.cdncm)), '.', ''), ' ', '')
ORDER BY P.ITEMNF_CPROD, P.primeira_emissao, P.cdncm;
GO