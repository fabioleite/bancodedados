/* =====================================================================
   Script 06 - Exibicoes (VIEWS) do curso
   Padronizam as definicoes usadas nos Modulos 9 e 10 e simplificam o
   consumo por Excel/Power Query e Power BI.
   ===================================================================== */
USE curso_integridade_fiscal;
GO

/* ---------------------------------------------------------------------
   6.1 vw_nfe_saidas - documentos de saida com o cadastro do emitente
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_nfe_saidas AS
SELECT n.id_nfe,
       n.chave_acesso,
       n.numero,
       n.serie,
       n.data_emissao,
       n.valor_total,
       n.valor_icms,
       n.situacao,
       c.id_contribuinte,
       c.cnpj,
       c.razao_social,
       c.regime_tributario,
       c.situacao_cadastral,
       m.nome          AS municipio,
       m.uf,
       m.regiao_fiscal
FROM   dbo.nfe          AS n
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = n.id_emitente
       INNER JOIN dbo.municipio    AS m ON m.id_municipio    = c.id_municipio
WHERE  n.tipo_operacao = '1';
GO

/* ---------------------------------------------------------------------
   6.2 vw_autos_por_auditor - produtividade da fiscalizacao
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_autos_por_auditor AS
SELECT af.matricula,
       af.nome,
       af.cargo,
       af.regiao_fiscal,
       COUNT(DISTINCT os.id_os)  AS qtd_os,
       COUNT(DISTINCT CASE WHEN os.situacao = 'CONCLUIDA' THEN os.id_os END) AS qtd_os_concluidas,
       COUNT(a.id_auto)          AS qtd_autos,
       COALESCE(SUM(a.valor_principal + a.valor_multa), 0) AS valor_autuado
FROM   dbo.auditor_fiscal AS af
       LEFT JOIN dbo.ordem_servico AS os ON os.matricula_auditor = af.matricula
       LEFT JOIN dbo.auto_infracao AS a  ON a.id_os = os.id_os
GROUP BY af.matricula, af.nome, af.cargo, af.regiao_fiscal;
GO

/* ---------------------------------------------------------------------
   6.3 vw_divergencia_nfe_efd - conciliacao documento a documento
        resultado: CONCILIADA, NAO ESCRITURADA, ESCRITURADA SEM NF-E
                   ou DIVERGENCIA DE VALOR
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_divergencia_nfe_efd AS
SELECT COALESCE(n.chave_acesso, e.chave_acesso)      AS chave_acesso,
       COALESCE(c1.cnpj, c2.cnpj)                    AS cnpj,
       COALESCE(c1.razao_social, c2.razao_social)    AS razao_social,
       n.data_emissao,
       n.valor_total                                 AS valor_nfe,
       e.valor_documento                             AS valor_efd,
       n.valor_icms                                  AS icms_nfe,
       e.valor_icms                                  AS icms_efd,
       e.periodo_apuracao,
       CASE WHEN e.id_c100 IS NULL THEN 'NAO ESCRITURADA'
            WHEN n.id_nfe  IS NULL THEN 'ESCRITURADA SEM NF-E'
            WHEN ABS(n.valor_total - e.valor_documento) > 0.01
              OR ABS(n.valor_icms  - e.valor_icms)     > 0.01 THEN 'DIVERGENCIA DE VALOR'
            ELSE 'CONCILIADA'
       END                                           AS resultado
FROM   dbo.nfe AS n
       FULL OUTER JOIN dbo.efd_c100 AS e
                    ON e.chave_acesso = n.chave_acesso
                   AND e.ind_oper     = '1'
                   AND e.cod_situacao = '00'
       LEFT JOIN dbo.contribuinte AS c1 ON c1.id_contribuinte = n.id_emitente
       LEFT JOIN dbo.contribuinte AS c2 ON c2.id_contribuinte = e.id_contribuinte
WHERE  (n.id_nfe IS NULL OR (n.situacao = 'AUTORIZADA' AND n.tipo_operacao = '1'));
GO

/* ---------------------------------------------------------------------
   6.4 vw_painel_malha - uma linha por contribuinte e exercicio
        (fonte do painel de Power BI da Figura 7 do Modulo 10)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_painel_malha AS
WITH emissao AS (
    SELECT n.id_emitente                                                   AS id_contribuinte,
           YEAR(n.data_emissao)                                            AS exercicio,
           COUNT(*)                                                        AS qtd_notas,
           SUM(CASE WHEN n.situacao = 'CANCELADA'  THEN 1 ELSE 0 END)      AS qtd_canceladas,
           SUM(CASE WHEN n.situacao = 'AUTORIZADA' THEN n.valor_total ELSE 0 END) AS valor_autorizado,
           SUM(CASE WHEN n.situacao = 'AUTORIZADA' THEN n.valor_icms  ELSE 0 END) AS icms_autorizado,
           SUM(CASE WHEN n.id_destinatario IS NULL THEN 1 ELSE 0 END)      AS qtd_consumidor_nao_ident
    FROM   dbo.nfe AS n
    WHERE  n.tipo_operacao = '1'
    GROUP BY n.id_emitente, YEAR(n.data_emissao)
),
escrituracao AS (
    SELECT e.id_contribuinte,
           CAST(LEFT(e.periodo_apuracao, 4) AS INT)  AS exercicio,
           COUNT(DISTINCT e.periodo_apuracao)        AS periodos_entregues,
           SUM(e.valor_documento)                    AS total_escriturado,
           SUM(e.valor_icms)                         AS icms_escriturado
    FROM   dbo.efd_c100 AS e
    WHERE  e.ind_oper = '1' AND e.cod_situacao = '00'
    GROUP BY e.id_contribuinte, CAST(LEFT(e.periodo_apuracao, 4) AS INT)
)
SELECT c.id_contribuinte,
       c.cnpj,
       c.razao_social,
       c.regime_tributario,
       c.situacao_cadastral,
       m.nome                                   AS municipio,
       m.regiao_fiscal,
       em.exercicio,
       em.qtd_notas,
       em.qtd_canceladas,
       CAST(em.qtd_canceladas AS DECIMAL(12,2)) / NULLIF(em.qtd_notas, 0) * 100 AS pct_cancelamento,
       em.valor_autorizado,
       em.icms_autorizado,
       em.icms_autorizado / NULLIF(em.valor_autorizado, 0) * 100                AS carga_efetiva_pct,
       em.qtd_consumidor_nao_ident,
       COALESCE(esc.periodos_entregues, 0)                                      AS periodos_efd_entregues,
       12 - COALESCE(esc.periodos_entregues, 0)                                 AS periodos_efd_omissos,
       COALESCE(esc.total_escriturado, 0)                                       AS total_escriturado,
       em.valor_autorizado - COALESCE(esc.total_escriturado, 0)                 AS dif_emitido_escriturado,
       em.icms_autorizado  - COALESCE(esc.icms_escriturado, 0)                  AS icms_potencial,
       c.faturamento_declarado
FROM   emissao          AS em
       INNER JOIN dbo.contribuinte AS c  ON c.id_contribuinte  = em.id_contribuinte
       INNER JOIN dbo.municipio    AS m  ON m.id_municipio     = c.id_municipio
       LEFT  JOIN escrituracao     AS esc ON esc.id_contribuinte = c.id_contribuinte
                                         AND esc.exercicio       = em.exercicio;
GO

PRINT 'Script 06 concluido: exibicoes criadas.';
GO
