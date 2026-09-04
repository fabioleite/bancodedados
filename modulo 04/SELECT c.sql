SELECT c.razao_social
FROM dbo.contribuinte AS c
WHERE c.id_contribuinte NOT IN (
    SELECT n.id_destinatario
    FROM dbo.nfe AS n
);

SELECT c.razao_social, c.id_contribuinte
FROM dbo.contribuinte AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.nfe AS n
    WHERE n.id_destinatario = c.id_contribuinte
);

SELECT c.id_contribuinte, c.razao_social, n.chave_acesso
    FROM dbo.nfe AS n RIGHT JOIN dbo.contribuinte AS c ON n.id_destinatario = c.id_contribuinte
    order by n.chave_acesso asc


SELECT * from dbo.nfe where id_destinatario is null
SELECT * from dbo.nfe where id_emitente is null


-- COntagem
select COUNT(*)
FROM dbo.nfe AS n INNER JOIN dbo.contribuinte AS c ON n.id_destinatario = c.id_contribuinte


SELECT
    resumo.regime_tributario,
    resumo.qtd_contribuintes,
    resumo.media_nota
FROM (
    SELECT
        c.regime_tributario,
        COUNT(DISTINCT c.id_contribuinte) AS qtd_contribuintes,
        AVG(n.valor_total) AS media_nota
    FROM dbo.contribuinte AS c
    JOIN dbo.nfe AS n
        ON n.id_emitente = c.id_contribuinte
    GROUP BY c.regime_tributario
) AS resumo
WHERE resumo.qtd_contribuintes > 5
ORDER BY resumo.media_nota DESC;

SELECT dbo.contribuinte.regime_tributario, 
    COUNT(DISTINCT dbo.contribuinte.id_contribuinte) AS qtd_contribuintes, 
    AVG(dbo.nfe.valor_total) AS media_nota
FROM  dbo.contribuinte INNER JOIN
         dbo.nfe ON dbo.contribuinte.id_contribuinte = dbo.nfe.id_emitente
GROUP BY dbo.contribuinte.regime_tributario
HAVING (COUNT(DISTINCT dbo.contribuinte.id_contribuinte) > 5)
