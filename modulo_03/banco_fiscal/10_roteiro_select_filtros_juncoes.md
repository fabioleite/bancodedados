# Roteiro de Exercicios - SELECT, Filtros e Juncoes

**Banco:** `curso_integridade_fiscal`

**SGBD:** Microsoft SQL Server (T-SQL)

## Preparacao

Execute, nesta ordem, os scripts `01_criar_banco.sql` a `05_inserir_fiscalizacao.sql`.

Para realizar a questao 3, execute tambem `09_quadro_societario.SQL`. Esse arquivo cria a tabela `dbo.socio_administrador`, que possui a coluna `cpf` usada no exercicio.

Em todas as questoes, use aliases claros e atribua nomes significativos as colunas calculadas com `AS`.

## Questoes

1. Elabore uma listagem das 10 primeiras NF-e da tabela `dbo.nfe`. Exiba o numero da nota preenchido com nove zeros a esquerda, a data de emissao no formato `dd/MM/aaaa`, o valor total e o ICMS no formato monetario brasileiro, usando `FORMAT` com a cultura `pt-BR`. Ordene pelo identificador da NF-e.

```sql
SELECT -- 10 primeiras?
    RIGHT(REPLICATE('0', 9) + CAST(n.numero AS VARCHAR(9)), 9) AS numero_nfe,
    FORMAT(n.data_emissao, 'dd/MM/yyyy', 'pt-BR') AS data_emissao,
    FORMAT(n.valor_total, 'C', 'pt-BR') AS valor_total,
    -- Inclua o ICMS formatado
FROM dbo.nfe AS n
-- Complete a ordenacao
;
```

2. Monte uma consulta para `dbo.ordem_servico` que apresente o numero da OS, a data de abertura, o ultimo dia do mes de abertura, a data prevista para 30 dias apos a abertura e o trimestre de abertura. Exiba as datas no formato brasileiro e ordene da OS mais recente para a mais antiga.

```sql
SELECT os.numero_os,
             FORMAT(os.data_abertura, 'dd/MM/yyyy', 'pt-BR') AS data_abertura,
			 EOMONTH(os.data_abertura) AS ultimo_dia_mes,
			 -- a data prevista para 30 dias apos a abertura
			 -- trimestre de abertura QUARTER
FROM dbo.ordem_servico AS os
-- Complete a ordenacao
;
```

3. Na tabela `dbo.socio_administrador`, apresente os socios com `id_socio` de 1 a 20, mostrando nome, CPF original e CPF formatado como `000.000.000-00`. Antes de aplicar a mascara, remova espacos, pontos e hifens; complete com zeros a esquerda quando necessario. Ordene por `id_socio`.

```sql
SELECT s.id_socio,
            s.nome,
            s.cpf AS cpf_original,
            RIGHT(REPLICATE('0', 11) +
                        REPLACE(REPLACE(REPLACE(TRIM(s.cpf), ' ', ''), '.', ''), '-', ''), 11) AS cpf_numeros,
  
		FROM dbo.socio_administrador AS s
;
```

4. Liste os contribuintes ativos cujo regime tributario pertença aos grupos `NORMAL`, `SIMPLES` ou `MEI`, usando a clausula `IN`. Exiba CNPJ, razao social, regime e faturamento declarado. Ordene primeiro pelo regime e depois pela razao social.

```sql
SELECT c.cnpj,
			 c.razao_social,
			 c.regime_tributario,
			 c.faturamento_declarado
FROM dbo.contribuinte AS c
WHERE c.situacao_cadastral = 'ATIVO'
	AND -- clausula IN
-- Complete a ordenacao
;
```

**Resultado esperado com os dados de `02_inserir_cadastros.sql`:** 54 contribuintes. Os valores `NULL` indicam faturamento não declarado.


| CNPJ           | Razao social                                              | Regime  | Faturamento declarado |
| ---------------- | ----------------------------------------------------------- | --------- | ----------------------: |
| 96510522000102 | ESPINHEIRO ATACADISTA DE MATERIAL DE CONSTRUCAO EIRELI    | MEI     |         27.330.488,57 |
| 75644362000114 | FLORESTA TRANSPORTES E LOGISTICA COMERCIO LTDA            | MEI     |         43.214.603,05 |
| 23233085000153 | LUAR INDUSTRIA DE MOVEIS COMERCIO LTDA                    | MEI     |        138.821.191,28 |
| 27712979000187 | ALFA DISTRIBUIDORA DE BEBIDAS EIRELI                      | NORMAL  |            995.349,67 |
| 68874662000124 | ARARA COMERCIO DE COMBUSTIVEIS COMERCIO LTDA              | NORMAL  |                  NULL |
| 99399866000184 | ATLAS COMERCIO DE COMBUSTIVEIS COMERCIO LTDA              | NORMAL  |            211.452,11 |
| 66609997000190 | AURORA INDUSTRIA DE MOVEIS ME                             | NORMAL  |        256.871.611,59 |
| 08144520000180 | BETA COMERCIO DE ALIMENTOS LTDA                           | NORMAL  |          4.241.916,18 |
| 70308021000154 | BOREAL DISTRIBUIDORA DE BEBIDAS COMERCIO LTDA             | NORMAL  |                  NULL |
| 14542053000149 | CAJU COMERCIO DE ALIMENTOS COMERCIO LTDA                  | NORMAL  |          2.966.752,52 |
| 38774414000140 | DELTA TRANSPORTES E LOGISTICA LTDA                        | NORMAL  |            293.129,50 |
| 24568733000195 | DUNAS ATACADISTA DE MATERIAL DE CONSTRUCAO S/A            | NORMAL  |        142.948.079,63 |
| 37161273000128 | EPSILON COMERCIO VAREJISTA DE CONFECCOES EIRELI           | NORMAL  |         18.453.989,97 |
| 70986797000123 | ESTRELA TRANSPORTES E LOGISTICA S/A                       | NORMAL  |         53.157.685,17 |
| 95673255000121 | ETA COMERCIO DE COMBUSTIVEIS ME                           | NORMAL  |          1.575.595,30 |
| 33839864000150 | FAROL COMERCIO VAREJISTA DE CONFECCOES COMERCIO LTDA      | NORMAL  |            241.921,59 |
| 94063525000110 | GAMA ATACADISTA DE MATERIAL DE CONSTRUCAO COMERCIO LTDA   | NORMAL  |            272.284,30 |
| 72591306000170 | GIRASSOL DROGARIA E PERFUMARIA LTDA                       | NORMAL  |        245.016.779,83 |
| 99010123000170 | IMPERIAL INDUSTRIA DE MOVEIS COMERCIO LTDA                | NORMAL  |            328.822,61 |
| 68124326000164 | IOTA DISTRIBUIDORA DE BEBIDAS S/A                         | NORMAL  |        219.383.586,78 |
| 85858679000107 | KAPPA COMERCIO DE ALIMENTOS EIRELI                        | NORMAL  |         19.841.971,52 |
| 11843391000122 | LAMBDA ATACADISTA DE MATERIAL DE CONSTRUCAO COMERCIO LTDA | NORMAL  |         60.811.767,41 |
| 38793929000198 | MANGUE ATACADISTA DE MATERIAL DE CONSTRUCAO LTDA          | NORMAL  |            167.545,26 |
| 73342024000100 | OMEGA TRANSPORTES E LOGISTICA COMERCIO LTDA               | NORMAL  |         30.115.840,09 |
| 89078626000124 | PHI DROGARIA E PERFUMARIA EIRELI                          | NORMAL  |         10.538.903,58 |
| 74850747000175 | SIGMA COMERCIO VAREJISTA DE CONFECCOES LTDA               | NORMAL  |          1.573.469,67 |
| 00644224000136 | SOLIMOES DROGARIA E PERFUMARIA S/A                        | NORMAL  |        237.261.507,35 |
| 59478055000154 | TETA INDUSTRIA DE MOVEIS EIRELI                           | NORMAL  |        248.229.793,93 |
| 57032388000120 | VITORIA INDUSTRIA DE MOVEIS EIRELI                        | NORMAL  |          1.741.493,37 |
| 43582882000153 | ZETA DROGARIA E PERFUMARIA LTDA                           | NORMAL  |          2.889.175,43 |
| 03502844000129 | BREJO INDUSTRIA DE MOVEIS LTDA                            | SIMPLES |          1.521.863,02 |
| 12965735000139 | CARIRI DISTRIBUIDORA DE BEBIDAS ME                        | SIMPLES |        232.850.983,88 |
| 94126456000146 | CORAL ATACADISTA DE MATERIAL DE CONSTRUCAO ME             | SIMPLES |         68.728.070,66 |
| 99287935000168 | DIAMANTE COMERCIO DE ALIMENTOS COMERCIO LTDA              | SIMPLES |            227.779,55 |
| 31627476000180 | GAVIAO COMERCIO VAREJISTA DE CONFECCOES LTDA              | SIMPLES |          3.763.071,71 |
| 74769894000115 | HORIZONTE COMERCIO DE COMBUSTIVEIS LTDA                   | SIMPLES |             72.730,30 |
| 61501220000193 | IPE DROGARIA E PERFUMARIA EIRELI                          | SIMPLES |        140.555.375,27 |
| 12784539000168 | JANDAIA DISTRIBUIDORA DE BEBIDAS EIRELI                   | SIMPLES |            130.670,68 |
| 01811206000164 | LITORAL COMERCIO DE ALIMENTOS S/A                         | SIMPLES |             66.733,25 |
| 29867002000164 | NORDESTE TRANSPORTES E LOGISTICA LTDA                     | SIMPLES |        138.242.026,80 |
| 70444421000197 | NOVA ERA COMERCIO DE ALIMENTOS LTDA                       | SIMPLES |            244.648,67 |
| 85927598000111 | ORQUIDEA COMERCIO VAREJISTA DE CONFECCOES S/A             | SIMPLES |            174.350,20 |
| 65928751000118 | PEDRA BRANCA TRANSPORTES E LOGISTICA LTDA                 | SIMPLES |                  NULL |
| 04897892000126 | PLANALTO DROGARIA E PERFUMARIA LTDA                       | SIMPLES |         51.490.174,71 |
| 83144269000179 | QUIXABA COMERCIO DE COMBUSTIVEIS ME                       | SIMPLES |          9.099.755,46 |
| 05872632000169 | RECANTO INDUSTRIA DE MOVEIS COMERCIO LTDA                 | SIMPLES |         83.395.418,97 |
| 19917977000104 | SERTAO DISTRIBUIDORA DE BEBIDAS EIRELI                    | SIMPLES |        116.775.151,70 |
| 14490480000120 | TAMBAU COMERCIO DE ALIMENTOS COMERCIO LTDA                | SIMPLES |         61.468.986,48 |
| 68524588000116 | UNIAO ATACADISTA DE MATERIAL DE CONSTRUCAO ME             | SIMPLES |          2.515.777,76 |
| 41271777000178 | VARZEA TRANSPORTES E LOGISTICA S/A                        | SIMPLES |            201.014,80 |
| 08829189000131 | XIQUE COMERCIO VAREJISTA DE CONFECCOES COMERCIO LTDA      | SIMPLES |         28.804.653,32 |
| 88355464000161 | ZEBU DROGARIA E PERFUMARIA EIRELI                         | SIMPLES |                  NULL |

5. Liste os autos de infracao lavrados entre `2025-01-01` e `2025-12-31`, usando a clausula `BETWEEN`, cujo situação seja `LAVRADO`, `IMPUGNADO` ou `JULGADO PROCEDENTE`. Use tambem `IN` para os status. Exiba numero do auto, data de lavratura, situacao, valor principal e valor da multa. Ordene pela data de lavratura.

```sql

SELECT ai.numero_auto,
			 ai.data_lavratura,
			 ai.situacao,
			 ai.valor_principal,
			 ai.valor_multa
FROM dbo.auto_infracao AS ai
WHERE -- between
	AND -- IN
-- Complete a ordenacao
;
```

6. Na tabela `dbo.contribuinte`, localize com a clausula `LIKE` as empresas cuja razao social contenha a palavra `DROGARIA` ou `COMBUSTIVEIS`. Exiba CNPJ, razao social, municipio de cadastro e situacao cadastral. Nao use juncoes nesta questao.

```sql
SELECT c.cnpj,
			 c.razao_social,
			 c.id_municipio,
			 c.situacao_cadastral
FROM dbo.contribuinte AS c
WHERE c.razao_social LIKE '%DROGARIA%'
	 -- complete a próximo critério
;
```

7. Consulte `dbo.nfe_item` e apresente, com `LIKE`, os itens cuja descricao comece com `OLEO` **ou** contenha a palavra `PNEU`, desde que o valor total do item esteja entre `500.00` e `5000.00`, usando `BETWEEN`. Exiba identificador da NF-e, numero do item, descricao, NCM, CFOP e valor total do item. Ordene pelo maior valor.

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
	AND -- complete com between
-- Complete a ordenacao
;
```

8. Usando apenas um `INNER JOIN` entre `dbo.nfe` e `dbo.nfe_item`, liste os itens das NF-e autorizadas emitidas pelo contribuinte de identificador 1. Exiba numero e data da NF-e, numero do item, descricao, quantidade e valor total do item. Limite a saida aos 30 primeiros registros, ordenados pela data e pelo numero da nota.

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
	AND -- complete o filtro
-- Complete a ordenacao
;
```

9. Usando `INNER JOIN` entre `dbo.nfe` e `dbo.nfe_item`, apresente os itens de NF-e canceladas emitidas no mes de abril de 2025. Exiba chave de acesso, data de emissao, numero do item, descricao e valor total do item. Utilize uma funcao de data para identificar o mes e ordene pela data de emissao.

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

10. Usando `INNER JOIN` entre `dbo.nfe` e `dbo.nfe_item`, liste os itens de saida com CFOP em `5101`, `5102`, `6101` ou `6102`, emitidos para destinatario identificado. Exiba numero da NF-e, identificador do destinatario, CFOP, descricao, valor total do item e a aliquota de ICMS. Restrinja aos itens com aliquota igual ou superior a 18 e ordene pelo valor total do item, do maior para o menor.

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
	AND -- filtro do destinatário
	AND -- complete com IN ('5101', '5102', '6101', '6102') DESIGN: IN ('5101';'5102';'6101';'6102')
	AND -- filtro da aliquota
-- Complete a ordenacao
;
	```
-- 27712979000187
## Entrega

Salve as dez consultas em um unico arquivo `.sql`, separando cada resposta com um comentario no formato `-- Questao 1`, `-- Questao 2` e assim por diante.
```
