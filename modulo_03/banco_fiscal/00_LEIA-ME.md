# Banco de exemplo `curso_integridade_fiscal`

**Curso de Banco de Dados Relacional aplicado à Fiscalização Tributária — SEFAZ**
Scripts T-SQL para criar e popular o banco usado nos Módulos 9 (Consultas SQL) e 10 (Ferramentas gráficas).

---

## 1. Ordem de execução


| # | Arquivo                       | O que faz                                                                                       | Tempo aproximado |
| --- | ------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------ |
| 1 | `01_criar_banco.sql`          | Cria o banco, as 10 tabelas, chaves, restrições e índices de FK                              | segundos         |
| 2 | `02_inserir_cadastros.sql`    | Municípios, contribuintes, auditores e pauta de referência                                    | segundos         |
| 3 | `03_inserir_nfe.sql`          | 10.636 NF-e e 30.794 itens                                                                      | 1 a 3 minutos    |
| 4 | `04_inserir_efd.sql`          | 8.059 registros C100 e 23.158 registros C170                                                    | 1 a 2 minutos    |
| 5 | `05_inserir_fiscalizacao.sql` | 150 ordens de serviço e 72 autos de infração                                                 | segundos         |
| 6 | `06_criar_views.sql`          | Exibições`vw_nfe_saidas`, `vw_autos_por_auditor`, `vw_divergencia_nfe_efd`, `vw_painel_malha` | segundos         |
| 7 | `07_verificacao.sql`          | Confere a carga e lista o que cada cruzamento deve encontrar                                    | segundos         |
| 8 | `08_indices_opcionais.sql`    | Índices de desempenho —**só depois do exercício de plano de execução**                    | segundos         |

> **Atenção:** o script 01 **apaga e recria** as tabelas, caso já existam. Execute apenas em ambiente de estudos.

**Requisitos:** SQL Server 2016 ou superior (usa `DROP TABLE IF EXISTS`, `STRING` functions e `CREATE OR ALTER`). Funciona em Express, Developer e Standard.

**Dica de execução.** Os scripts 03 e 04 têm alguns megabytes. No SSMS eles abrem normalmente, mas se preferir evitar o editor:

```
sqlcmd -S SRV-SEFAZ\FISCO -E -d master -i 01_criar_banco.sql
sqlcmd -S SRV-SEFAZ\FISCO -E -i 02_inserir_cadastros.sql
sqlcmd -S SRV-SEFAZ\FISCO -E -i 03_inserir_nfe.sql
sqlcmd -S SRV-SEFAZ\FISCO -E -i 04_inserir_efd.sql
sqlcmd -S SRV-SEFAZ\FISCO -E -i 05_inserir_fiscalizacao.sql
sqlcmd -S SRV-SEFAZ\FISCO -E -i 06_criar_views.sql
```

---

## 2. O que há na base


| Tabela             | Linhas | Papel                                                                                   |
| -------------------- | -------: | ----------------------------------------------------------------------------------------- |
| `municipio`        |     35 | 25 municípios da PB (com gerência regional) e 10 de outras UFs (`regiao_fiscal` nula) |
| `contribuinte`     |     60 | Cadastro do ICMS: regimes, situações cadastrais e faturamento declarado               |
| `auditor_fiscal`   |     20 | Hierarquia de três níveis por auto-relacionamento                                     |
| `referencia_preco` |     28 | Pauta fiscal por NCM (usada no exemplo de junção theta)                               |
| `nfe`              | 10.636 | Cabeçalhos de NF-e do exercício de 2025                                               |
| `nfe_item`         | 30.794 | Itens dos documentos                                                                    |
| `efd_c100`         |  8.059 | Documentos escriturados na EFD (bloco C)                                                |
| `efd_c170`         | 23.158 | Itens escriturados                                                                      |
| `ordem_servico`    |    150 | OS de fiscalização (2025 e 1º semestre de 2026)                                      |
| `auto_infracao`    |     72 | Autos lavrados                                                                          |

Todos os **CNPJ** e todas as **chaves de acesso** têm dígito verificador **calculado corretamente** (módulo 11), e a chave respeita o leiaute oficial: `cUF(2) + AAMM(4) + CNPJ(14) + modelo(2) + série(3) + número(9) + tpEmis(1) + código(8) + DV(1)`. Isso permite que os exercícios de decomposição da chave (`SUBSTRING`) façam sentido.

---

## 3. Mapa das inconsistências plantadas

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

## 4. Ideias SQL para identificar as inconsistências

Os exemplos a seguir apresentam pontos de partida para as consultas de malha. Eles privilegiam `NOT EXISTS` nos cruzamentos que podem envolver nulos, comparam valores monetários por tolerância de centavos e separam indícios de irregularidade de uma conclusão fiscal.

### 4.1 Omissão de escrituração e chaves sem correspondência

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

### 4.2 Divergências entre NF-e e EFD

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

### 4.3 Validação da composição da chave de acesso

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

### 4.4 Indicadores de risco por emitente

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

### 4.5 Ausências cadastrais e marcadores de qualidade

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

### 4.6 Totais de itens e operações circulares

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

## 5. Observações de modelagem

- **Não existe chave estrangeira entre `efd_c100.chave_acesso` e `nfe.chave_acesso`** — e não deveria existir. A EFD pode escriturar documentos emitidos em outras UFs, ausentes da base local. É justamente essa ausência de restrição que torna o cruzamento de malha fiscal necessário (exercício C3 do Módulo 10).
- `ON DELETE CASCADE` foi declarado apenas nas relações documento → item (`nfe_item` e `efd_c170`), onde o item não tem existência autônoma.
- Os índices de desempenho ficam no script **08**, separados de propósito: o exercício de plano de execução do Módulo 10 depende de a base começar sem eles.

---

## 6. Regenerar ou redimensionar a base

O arquivo `gerar_dados.py` (Python 3, sem dependências externas) produz os scripts 02 a 05. A semente é fixa: rodar de novo gera **exatamente** o mesmo banco.

```
python3 gerar_dados.py
```

Para mudar o volume, ajuste o dicionário `VOLUME` (linhas por emitente) na seção 6; para mudar o exercício, a constante `ANO`; para mudar a proporção de omissões, o `0.075` da seção 7. As quantidades esperadas do `07_verificacao.sql` precisarão ser atualizadas depois de qualquer alteração — o próprio script imprime o novo resumo ao final da execução.

---

## 7. Dados fictícios

Todos os CNPJ, razões sociais, chaves de acesso, valores, auditores e autos de infração são **fictícios**, gerados aleatoriamente. Qualquer coincidência com contribuintes reais é acidental. A base foi construída assim justamente para que o material do curso possa circular sem qualquer exposição de dado protegido por sigilo fiscal.
