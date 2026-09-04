# Gabarito - Subsidios para SELECT, Filtros e Juncoes

Este gabarito traz somente os elementos iniciais de cada resolucao. Complete as colunas, filtros e ordenacoes marcados como comentarios.

1. Inicio da consulta:

```sql
SELECT TOP (10)
			 RIGHT(REPLICATE('0', 9) + CAST(n.numero AS VARCHAR(9)), 9) AS numero_nfe,
			 CONVERT(VARCHAR(10), n.data_emissao, 103) AS data_emissao,
			 FORMAT(n.valor_total, 'C', 'pt-BR') AS valor_total,
			 -- Inclua o ICMS formatado
FROM dbo.nfe AS n
-- Complete a ordenacao
;
```

2. Inicio da consulta:

```sql
SELECT os.numero_os,
			 CONVERT(VARCHAR(10), os.data_abertura, 103) AS data_abertura,
			 EOMONTH(os.data_abertura) AS ultimo_dia_mes,
			 DATEADD(DAY, 30, os.data_abertura) AS prazo_30_dias,
			 DATEPART(QUARTER, os.data_abertura) AS trimestre
FROM dbo.ordem_servico AS os
-- Complete a ordenacao
;
```

3. Inicio da consulta:

```sql
WITH cpf_limpo AS (
		SELECT s.id_socio,
					 s.nome,
					 s.cpf AS cpf_original,
					 RIGHT(REPLICATE('0', 11) +
								 REPLACE(REPLACE(REPLACE(TRIM(s.cpf), ' ', ''), '.', ''), '-', ''), 11) AS cpf_numeros
		FROM dbo.socio_administrador AS s
)
SELECT id_socio,
			 nome,
			 cpf_original,
			 -- Monte a mascara com SUBSTRING(cpf_numeros, ...)
FROM cpf_limpo
WHERE id_socio BETWEEN 1 AND 20
-- Complete a ordenacao
;
```

4. Inicio da consulta:

```sql
SELECT c.cnpj,
			 c.razao_social,
			 c.regime_tributario,
			 c.faturamento_declarado
FROM dbo.contribuinte AS c
WHERE c.situacao_cadastral = 'ATIVO'
	AND c.regime_tributario IN ('NORMAL', 'SIMPLES', 'MEI')
-- Complete a ordenacao
;
```

5. Inicio da consulta:

```sql
SELECT ai.numero_auto,
			 ai.data_lavratura,
			 ai.situacao,
			 ai.valor_principal,
			 ai.valor_multa
FROM dbo.auto_infracao AS ai
WHERE ai.data_lavratura BETWEEN '2025-01-01' AND '2025-12-31'
	AND ai.situacao IN ('LAVRADO', 'IMPUGNADO', 'JULGADO PROCEDENTE')
-- Complete a ordenacao
;
```

6. Inicio da consulta:

```sql
SELECT c.cnpj,
			 c.razao_social,
			 c.id_municipio,
			 c.situacao_cadastral
FROM dbo.contribuinte AS c
WHERE c.razao_social LIKE '%DROGARIA%'
	 OR c.razao_social LIKE '%COMBUSTIVEIS%'
;
```

7. Inicio da consulta:

```sql
SELECT ni.id_nfe,
			 ni.num_item,
			 ni.descricao,
			 ni.ncm,
			 ni.cfop,
			 ni.valor_total_item
FROM dbo.nfe_item AS ni
WHERE (ni.descricao LIKE 'OLEO%'
		OR ni.descricao LIKE '%PNEU%')
	AND ni.valor_total_item BETWEEN 500.00 AND 5000.00
-- Complete a ordenacao
;
```

8. Inicio da consulta:

```sql
SELECT TOP (30)
			 n.numero,
			 n.data_emissao,
			 ni.num_item,
			 ni.descricao,
			 ni.quantidade,
			 ni.valor_total_item
FROM dbo.nfe AS n
INNER JOIN dbo.nfe_item AS ni ON ni.id_nfe = n.id_nfe
WHERE n.situacao = 'AUTORIZADA'
	AND n.id_emitente = 1
-- Complete a ordenacao
;
```

9. Inicio da consulta:

```sql
SELECT n.chave_acesso,
			 n.data_emissao,
			 ni.num_item,
			 ni.descricao,
			 ni.valor_total_item
FROM dbo.nfe AS n
INNER JOIN dbo.nfe_item AS ni ON ni.id_nfe = n.id_nfe
WHERE n.situacao = 'CANCELADA'
	AND YEAR(n.data_emissao) = 2025
	AND MONTH(n.data_emissao) = 4
-- Complete a ordenacao
;
```

10. Inicio da consulta:

```sql
SELECT n.numero,
			 n.id_destinatario,
			 ni.cfop,
			 ni.descricao,
			 ni.valor_total_item,
			 ni.aliquota_icms
FROM dbo.nfe AS n
INNER JOIN dbo.nfe_item AS ni ON ni.id_nfe = n.id_nfe
WHERE n.tipo_operacao = '1'
	AND n.id_destinatario IS NOT NULL
	AND ni.cfop IN ('5101', '5102', '6101', '6102')
	AND ni.aliquota_icms >= 18
-- Complete a ordenacao
;
	```