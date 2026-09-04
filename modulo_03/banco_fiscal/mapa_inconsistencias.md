## 1. Mapa das inconsistências plantadas

A base foi construída para que os cruzamentos dos Módulos 9 e 10 **encontrem alguma coisa**. As quantidades abaixo são as respostas esperadas — o script `07_verificacao.sql` as confere uma a uma.


| Inconsistência                                                 |                                                Quantidade | Exercício correspondente          |
| ----------------------------------------------------------------- | ----------------------------------------------------------: | ------------------------------------ |
| NF-e autorizada de saída sem C100 (omissão de escrituração) | 2.023 no total;**980** entre declarantes do regime normal | M9 §16.1, F5, G2, H1              |
| Chave escriturada que**não existe** na base de NF-e            |                                                        38 | M9 D3                              |
| Chave escriturada de nota**cancelada** (`cod_situacao='02'`)    |                                                       402 | M9 D3 — falso positivo a discutir |
| Divergência de valor/ICMS entre NF-e e EFD                     |                                                       147 | M9 §16.2, H2                      |
| Divergência de item (NCM, CFOP, alíquota ou valor)            |                                                       354 | M9 H2                              |
| Chave com CNPJ divergente do cadastro                           |                                                         6 | M9 H3                              |
| Chave com período (AAMM) divergente da emissão                |                                                         5 | M9 H3                              |
| Chave com 43 posições                                         |                                                         2 | M9 H3                              |
| Emitentes com mais de 1.000 notas autorizadas                   |                                          3 (ids 1, 2 e 3) | M9 C4                              |
| Emitentes com mais de 500 notas                                 |                                                         6 | M9 §8.3                           |
| Cancelamento acima de 15%                                       |                                            2 (ids 4 e 12) | M9 C8                              |
| Carga efetiva abaixo de 4% no regime normal                     |                                            2 (ids 5 e 17) | M9 §8.3, G3                       |
| Contribuintes ativos do regime normal sem EFD de 202501         |                                                         8 | M9 G1                              |
| Contribuintes que nunca foram destinatários                    |                                                         7 | M9 E3                              |
| NF-e a consumidor não identificado (`id_destinatario` nulo)    |                                                     1.041 | M9 A7, B7, F1                      |
| C100 sem chave (documento não eletrônico)                     |                                                        25 | M9 A5, E3                          |
| Notas em que a soma dos itens diverge do cabeçalho             |                                                        15 | M9 §15, G6                        |
| Pares de contribuintes com operações circulares               |                                 3 (8↔19, 14↔27, 23↔31) | M9 F7                              |
| Contribuintes sem faturamento declarado                         |                                                         6 | M9 B4, C2                          |
| Municípios sem região fiscal (outras UFs)                     |                                                        10 | M9 §4.6                           |
| Ordens de serviço sem data de conclusão                       |                                                        63 | M9 B9, A4                          |
| Itens com descrição genérica ou muito curta                  |                                                      ~370 | M9 B10                             |

### Três armadilhas propositais

1. **`NOT IN` com nulo.** `nfe.id_destinatario` é nulo em 1.041 documentos. A consulta `WHERE id_contribuinte NOT IN (SELECT id_destinatario FROM nfe)` retorna **vazio** — é o exercício H6 do Módulo 9, e aqui ele acontece de verdade.
2. **Regime tributário no cruzamento de EFD.** Empresas do Simples e MEI não entregam EFD ICMS/IPI. Quem esquecer de filtrar `regime_tributario = 'NORMAL'` encontra 2.023 "omissões" em vez de 980 — metade delas falso positivo.
3. **Nota cancelada escriturada.** Um `EXCEPT` ingênuo entre as chaves da EFD e as da NF-e autorizada devolve 440 linhas, das quais 402 são documentos cancelados escriturados corretamente. Só 38 são achado real.

---

## 2. Ideias SQL para identificar as inconsistências

Os exemplos a seguir apresentam pontos de partida para as consultas de malha. Eles privilegiam `NOT EXISTS` nos cruzamentos que podem envolver nulos, comparam valores monetários por tolerância de centavos e separam indícios de irregularidade de uma conclusão fiscal.

### 1.1 Omissão de escrituração e chaves sem correspondência

Para localizar NF-e autorizadas de saída que não foram declaradas na EFD pelo próprio emitente, inicie em `nfe` e teste a inexistência do C100 correspondente. O filtro de regime elimina os contribuintes que não entregam EFD ICMS/IPI.

```sql
SELECT n.id_nfe, n.chave_acesso, n.id_emitente, n.valor_total
FROM dbo.nfe AS n
INNER JOIN dbo.contribuinte AS c
		ON c.id_contribuinte = n.id_emitente
WHERE n.situacao = 'AUTORIZADA'
	AND n.tipo_operacao = '1'
	AND c.regime_tributario = 'NORMAL'
	AND NOT EXISTS (
			SELECT 1
			FROM dbo.efd_c100 AS e
			WHERE e.chave_acesso = n.chave_acesso
				AND e.id_contribuinte = n.id_emitente
				AND e.ind_oper = '1'
				AND e.cod_situacao = '00'
	);
```

No sentido inverso, procure documentos escriturados cuja chave não exista em nenhuma NF-e local. Esse resultado pode conter documentos de outra UF, devendo ser analisado antes de ser tratado como irregularidade.

```sql
SELECT e.id_c100, e.id_contribuinte, e.chave_acesso, e.valor_documento
FROM dbo.efd_c100 AS e
WHERE e.chave_acesso IS NOT NULL
	AND NOT EXISTS (
			SELECT 1
			FROM dbo.nfe AS n
			WHERE n.chave_acesso = e.chave_acesso
	);
```

Como alternativa didática, aplique `EXCEPT` entre os conjuntos de chaves de `nfe` e `efd_c100`; em seguida, classifique separadamente as chaves de NF-e canceladas para evitar falso positivo.

### 1.2 Divergências entre NF-e e EFD

Para comparar os totais do documento, una as tabelas pela `chave_acesso`. A função `ABS` evita que diferenças negativas deixem de ser encontradas.

```sql
SELECT n.chave_acesso,
			 n.valor_total AS valor_nfe,
			 e.valor_documento AS valor_efd,
			 n.valor_icms AS icms_nfe,
			 e.valor_icms AS icms_efd
FROM dbo.nfe AS n
INNER JOIN dbo.efd_c100 AS e
		ON e.chave_acesso = n.chave_acesso
WHERE n.situacao = 'AUTORIZADA'
	AND e.cod_situacao = '00'
	AND e.ind_oper = '1'
	AND (ABS(n.valor_total - e.valor_documento) > 0.01
			 OR ABS(n.valor_icms - e.valor_icms) > 0.01);
```

Para a auditoria de itens, relacione `nfe_item` e `efd_c170` pelo número do item, depois de conectar cada documento pela chave. Compare NCM, CFOP, alíquota e valor, tratando alíquotas nulas com `COALESCE`.

```sql
SELECT n.chave_acesso, i.num_item,
			 i.ncm AS ncm_nfe, c170.ncm AS ncm_efd,
			 i.cfop AS cfop_nfe, c170.cfop AS cfop_efd
FROM dbo.nfe AS n
INNER JOIN dbo.nfe_item AS i ON i.id_nfe = n.id_nfe
INNER JOIN dbo.efd_c100 AS e ON e.chave_acesso = n.chave_acesso
INNER JOIN dbo.efd_c170 AS c170
		ON c170.id_c100 = e.id_c100
	 AND c170.num_item = i.num_item
WHERE n.situacao = 'AUTORIZADA'
	AND e.cod_situacao = '00'
	AND (i.ncm <> c170.ncm
			 OR i.cfop <> c170.cfop
			 OR ABS(COALESCE(i.aliquota_icms, 0) - COALESCE(c170.aliquota_icms, 0)) > 0.01
			 OR ABS(i.valor_total_item - c170.valor_item) > 0.01);
```

### 1.3 Validação da composição da chave de acesso

A chave contém, entre outros dados, o período `AAMM` nas posições 3 a 6 e o CNPJ do emitente nas posições 7 a 20. Compare esses segmentos com o cadastro e com a data de emissão, incluindo uma verificação de tamanho.

```sql
SELECT n.id_nfe, n.chave_acesso, c.cnpj, n.data_emissao,
			 CASE
					 WHEN LEN(n.chave_acesso) <> 44 THEN 'TAMANHO INVALIDO'
					 WHEN SUBSTRING(n.chave_acesso, 7, 14) <> c.cnpj THEN 'CNPJ DIVERGENTE'
					 WHEN SUBSTRING(n.chave_acesso, 3, 4) <> FORMAT(n.data_emissao, 'yyMM') THEN 'PERIODO DIVERGENTE'
			 END AS inconsistencia
FROM dbo.nfe AS n
INNER JOIN dbo.contribuinte AS c
		ON c.id_contribuinte = n.id_emitente
WHERE LEN(n.chave_acesso) <> 44
	 OR SUBSTRING(n.chave_acesso, 7, 14) <> c.cnpj
	 OR SUBSTRING(n.chave_acesso, 3, 4) <> FORMAT(n.data_emissao, 'yyMM');
```

### 1.4 Indicadores de risco por emitente

Agrupe NF-e por `id_emitente` e use `HAVING` para identificar alto volume de documentos. O mesmo agrupamento permite calcular o percentual de cancelamento e a carga efetiva de ICMS.

```sql
SELECT n.id_emitente,
			 COUNT(*) AS total_notas,
			 CAST(SUM(CASE WHEN n.situacao = 'CANCELADA' THEN 1 ELSE 0 END) AS DECIMAL(10, 2))
					 / NULLIF(COUNT(*), 0) * 100 AS pct_cancelamento,
			 SUM(n.valor_icms) / NULLIF(SUM(n.valor_total), 0) * 100 AS carga_efetiva_pct
FROM dbo.nfe AS n
WHERE n.tipo_operacao = '1'
GROUP BY n.id_emitente
HAVING COUNT(*) > 500;
```

Para a carga efetiva, junte `contribuinte`, restrinja a análise ao regime `NORMAL` e aplique a faixa de risco no `HAVING`. Aplique também um valor mínimo de operações para evitar conclusões a partir de amostras pequenas.

### 1.5 Ausências cadastrais e marcadores de qualidade

Use `IS NULL` para localizar NF-e a consumidor não identificado, C100 sem chave, contribuintes sem faturamento, municípios sem região fiscal e ordens de serviço ainda sem conclusão. Para contribuintes sem EFD em uma competência ou que nunca foram destinatários, prefira o padrão abaixo com `NOT EXISTS`.

```sql
SELECT c.id_contribuinte, c.razao_social
FROM dbo.contribuinte AS c
WHERE c.situacao_cadastral = 'ATIVO'
	AND c.regime_tributario = 'NORMAL'
	AND NOT EXISTS (
			SELECT 1
			FROM dbo.efd_c100 AS e
			WHERE e.id_contribuinte = c.id_contribuinte
				AND e.periodo_apuracao = '202501'
	);
```

Para identificar descrições genéricas, aplique `LIKE` a termos como `'%DIVERSOS%'` ou `'%MERCADORIA%'` e combine com `LEN(LTRIM(RTRIM(descricao)))` para itens excessivamente curtos.

### 1.6 Totais de itens e operações circulares

Uma expressão de tabela comum permite somar os itens por NF-e e confrontar o resultado com o total do cabeçalho.

```sql
WITH totais_itens AS (
		SELECT i.id_nfe, SUM(i.valor_total_item) AS total_itens
		FROM dbo.nfe_item AS i
		GROUP BY i.id_nfe
)
SELECT n.id_nfe, n.valor_total, t.total_itens
FROM dbo.nfe AS n
INNER JOIN totais_itens AS t ON t.id_nfe = n.id_nfe
WHERE ABS(n.valor_total - t.total_itens) > 0.01;
```

Para detectar operações potencialmente circulares, faça uma autojunção de `nfe`: o emitente da primeira nota deve ser o destinatário da segunda, e vice-versa. Restrinja ambas às NF-e autorizadas, defina uma janela de datas com `DATEDIFF` e utilize `n1.id_emitente < n1.id_destinatario` para não duplicar cada par.

---
