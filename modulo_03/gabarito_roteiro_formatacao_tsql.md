# Gabarito — Formatação, Apresentação e Tratamento de Dados no SELECT

**Curso de Banco de Dados Relacional aplicado à Fiscalização Tributária — Módulo 11**
**Documento de uso do instrutor / correção**

> As soluções não são as únicas possíveis. Aceite qualquer formulação que produza o mesmo conjunto de resultados e respeite as três regras estruturantes do módulo: **filtrar e ordenar pelo dado bruto**, **formatar apenas na apresentação** e **normalizar antes de cruzar**.

---

## Bloco A — Números e arredondamento

**A1.**
```sql
SELECT TOP (10)
       n.chave_acesso,
       n.valor_total,
       CAST(ROUND(n.valor_total, 0) AS INT)                              AS arredondado,
       CAST(ROUND(n.valor_total, 0, 1) AS INT)                           AS truncado,
       ROUND(n.valor_total, 0) - ROUND(n.valor_total, 0, 1)              AS diferenca
FROM   dbo.nfe AS n
WHERE  n.situacao = 'AUTORIZADA'
ORDER BY n.valor_total DESC;
```
> Ponto avaliado: o `CAST(... AS INT)` — sem ele, `ROUND(x, 0)` devolve `13640.00`, e não `13640`. A diferença é zero quando os centavos são inferiores a cinquenta e um real quando são iguais ou superiores.

**A2.**
```sql
SELECT ROUND(SUM(i.valor_total_item * 0.18), 2)      AS soma_e_depois_arredonda,
       SUM(ROUND(i.valor_total_item * 0.18, 2))      AS arredonda_e_depois_soma,
       SUM(ROUND(i.valor_total_item * 0.18, 2, 1))   AS trunca_e_depois_soma,
       ROUND(SUM(i.valor_total_item * 0.18), 2)
     - SUM(ROUND(i.valor_total_item * 0.18, 2))      AS dif_1,
       SUM(ROUND(i.valor_total_item * 0.18, 2))
     - SUM(ROUND(i.valor_total_item * 0.18, 2, 1))   AS dif_2
FROM   dbo.nfe_item AS i;
-- A base adequada para CONFERIR ESCRITURACAO e a segunda: o contribuinte
-- arredonda item a item na emissao do documento, e e esse valor que sera
-- comparado com o declarado. A primeira e matematicamente mais precisa,
-- porem nao reproduz o comportamento do sistema emissor.
```

**A3.**
```sql
SELECT c.regime_tributario,
       COUNT(*)                                                        AS total_notas,
       SUM(CASE WHEN n.situacao = 'CANCELADA' THEN 1 ELSE 0 END)       AS canceladas,
       CAST(SUM(CASE WHEN n.situacao = 'CANCELADA' THEN 1 ELSE 0 END) AS DECIMAL(12,4))
            / NULLIF(COUNT(*), 0) * 100                                AS pct_cancelamento
FROM   dbo.nfe AS n
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = n.id_emitente
GROUP BY c.regime_tributario
ORDER BY pct_cancelamento DESC;
```
> Sem o `CAST` para `DECIMAL`, a divisão entre inteiros trunca e todas as linhas devolvem zero.

**A4.**
```sql
SELECT TOP (10)
       n.chave_acesso,
       ROUND(n.valor_total, 2)                       AS numero_simples,
       FORMAT(n.valor_total, 'N2', 'pt-BR')          AS padrao_br,
       FORMAT(n.valor_total, 'C',  'pt-BR')          AS moeda
FROM   dbo.nfe AS n
ORDER BY n.valor_total DESC;
```

**A5.**
```sql
SELECT RIGHT(REPLICATE(' ', 18) + FORMAT(n.valor_total, 'N2', 'pt-BR'), 18) AS [valor_18],
       LEFT(UPPER(TRIM(c.razao_social)) + REPLICATE(' ', 45), 45)           AS [razao_45]
FROM   dbo.nfe AS n
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = n.id_emitente
WHERE  n.situacao = 'AUTORIZADA'
ORDER BY n.valor_total DESC;
```
> Cobrar a verificação com `Ctrl+T`: na grade, o alinhamento não aparece, porque a fonte é proporcional.

---

## Bloco B — Datas

**B1.**
```sql
SELECT TOP (20)
       os.numero_os,
       CONVERT(VARCHAR(10), os.data_abertura, 103)              AS abertura_br,
       CONVERT(VARCHAR(6),  os.data_abertura, 112)              AS competencia,
       FORMAT(os.data_abertura, 'MMMM', 'pt-BR')                AS mes_extenso,
       FORMAT(os.data_abertura, 'dddd', 'pt-BR')                AS dia_semana
FROM   dbo.ordem_servico AS os
ORDER BY os.id_os;
```

**B2.**
```sql
SELECT os.numero_os,
       FORMAT(os.data_abertura, 'dd/MM/yyyy') AS abertura,
       DATEDIFF(DAY, os.data_abertura, GETDATE()) AS dias_corridos,
       CASE WHEN DATEDIFF(DAY, os.data_abertura, GETDATE()) > 180 THEN 'CRITICA'
            WHEN DATEDIFF(DAY, os.data_abertura, GETDATE()) >  90 THEN 'ATENCAO'
            ELSE 'NO PRAZO'
       END AS faixa
FROM   dbo.ordem_servico AS os
WHERE  os.data_conclusao IS NULL
ORDER BY dias_corridos DESC;
```

**B3.**
```sql
SELECT DISTINCT
       e.periodo_apuracao,
       CONVERT(DATE, e.periodo_apuracao + '01')                              AS primeiro_dia,
       EOMONTH(CONVERT(DATE, e.periodo_apuracao + '01'))                     AS ultimo_dia,
       FORMAT(CONVERT(DATE, e.periodo_apuracao + '01'), 'MMM/yyyy', 'pt-BR') AS competencia
FROM   dbo.efd_c100 AS e
ORDER BY e.periodo_apuracao;
```
> Ponto avaliado: a concatenação `periodo + '01'` produz o literal ISO compacto `AAAAMMDD`, imune a `SET DATEFORMAT`.

**B4.**
```sql
SELECT a.numero_auto,
       FORMAT(a.data_lavratura, 'dd ''de'' MMMM ''de'' yyyy', 'pt-BR')      AS lavratura_extenso,
       FORMAT(DATEADD(DAY, 30, a.data_lavratura), 'dd/MM/yyyy')             AS prazo_impugnacao
FROM   dbo.auto_infracao AS a
ORDER BY a.data_lavratura DESC;
```

**B5.**
```sql
-- (a) nao sargable: aplica funcao sobre a coluna filtrada
SELECT SUM(valor_total) FROM dbo.nfe
WHERE situacao = 'AUTORIZADA' AND YEAR(data_emissao) = 2025 AND MONTH(data_emissao) = 3;

-- (b) sargable
SELECT SUM(valor_total) FROM dbo.nfe
WHERE situacao = 'AUTORIZADA'
  AND data_emissao >= '2025-03-01' AND data_emissao < '2025-04-01';
```
> Resposta esperada: as duas devolvem o mesmo total. No plano, (a) exibe **Verificação** (Scan), porque a função sobre `data_emissao` impede o uso de índice; (b) exibe **Busca** (Seek) quando existe índice em `data_emissao` (script 08). O conceito é o de predicado *sargable*: a coluna precisa aparecer isolada de um lado da comparação.

---

## Bloco C — Conversões e qualidade do dado

**C1.**
```sql
SELECT COUNT(*)                                    AS total,
       COUNT(TRY_CAST(cpf AS BIGINT))              AS conversiveis,
       COUNT(*) - COUNT(TRY_CAST(cpf AS BIGINT))   AS nao_conversiveis
FROM   dbo.socio_administrador;

SELECT TOP (5) id_socio, cpf, 'CONVERSIVEL' AS grupo
FROM   dbo.socio_administrador WHERE TRY_CAST(cpf AS BIGINT) IS NOT NULL
UNION ALL
SELECT TOP (5) id_socio, cpf, 'NAO CONVERSIVEL'
FROM   dbo.socio_administrador WHERE TRY_CAST(cpf AS BIGINT) IS NULL;
```
> Espera-se que os não conversíveis sejam os que têm ponto, hífen ou espaço. Cobrar a observação de que `TRY_CAST` **não valida CPF**: apenas informa se a cadeia é numérica.

**C2.**
```sql
SELECT s.id_socio,
       s.nome,
       s.cpf                                                                     AS original,
       REPLACE(REPLACE(REPLACE(TRIM(s.cpf), '.', ''), '-', ''), ' ', '')         AS digitos,
       LEN(REPLACE(REPLACE(REPLACE(TRIM(s.cpf), '.', ''), '-', ''), ' ', ''))    AS qtd
FROM   dbo.socio_administrador AS s
WHERE  LEN(REPLACE(REPLACE(REPLACE(TRIM(s.cpf), '.', ''), '-', ''), ' ', '')) < 11
ORDER BY qtd, s.id_socio;
```
> Causa provável: o CPF foi gravado como **número** em algum ponto da cadeia de sistemas, e o zero (ou os zeros) à esquerda foi descartado. Correção: `RIGHT('00000000000' + digitos, 11)`.

**C3.**
```sql
SELECT CONCAT(DATEPART(QUARTER, CONVERT(DATE, e.periodo_apuracao + '01')), 'o TRI/',
              LEFT(e.periodo_apuracao, 4))                       AS trimestre,
       COUNT(*)                                                  AS documentos,
       FORMAT(SUM(e.valor_documento), 'N2', 'pt-BR')             AS total_escriturado
FROM   dbo.efd_c100 AS e
WHERE  e.ind_oper = '1' AND e.cod_situacao = '00'
GROUP BY DATEPART(QUARTER, CONVERT(DATE, e.periodo_apuracao + '01')), LEFT(e.periodo_apuracao, 4)
ORDER BY LEFT(e.periodo_apuracao, 4),
         DATEPART(QUARTER, CONVERT(DATE, e.periodo_apuracao + '01'));
```

**C4.**
```sql
SELECT TOP (5)
       n.valor_total,
       CAST(n.valor_total AS INT)                  AS com_cast_trunca,
       CAST(ROUND(n.valor_total, 0) AS INT)        AS com_round_arredonda
FROM   dbo.nfe AS n
WHERE  n.valor_total - FLOOR(n.valor_total) > 0.50
ORDER BY n.id_nfe;
```
> Espera-se a conclusão: `CAST` para inteiro **sempre trunca**; para arredondar é preciso `ROUND` antes.

**C5.** (desafio — cálculo do dígito verificador em T-SQL)
```sql
WITH limpo AS (
    SELECT id_socio, nome, cpf AS cpf_original,
           RIGHT('00000000000' +
                 REPLACE(REPLACE(REPLACE(TRIM(cpf), '.', ''), '-', ''), ' ', ''), 11) AS cpf
    FROM   dbo.socio_administrador
),
d AS (
    SELECT *,
           CAST(SUBSTRING(cpf,1,1) AS INT) AS d1, CAST(SUBSTRING(cpf,2,1) AS INT) AS d2,
           CAST(SUBSTRING(cpf,3,1) AS INT) AS d3, CAST(SUBSTRING(cpf,4,1) AS INT) AS d4,
           CAST(SUBSTRING(cpf,5,1) AS INT) AS d5, CAST(SUBSTRING(cpf,6,1) AS INT) AS d6,
           CAST(SUBSTRING(cpf,7,1) AS INT) AS d7, CAST(SUBSTRING(cpf,8,1) AS INT) AS d8,
           CAST(SUBSTRING(cpf,9,1) AS INT) AS d9,
           CAST(SUBSTRING(cpf,10,1) AS INT) AS dv1, CAST(SUBSTRING(cpf,11,1) AS INT) AS dv2
    FROM   limpo
),
p1 AS (
    SELECT *, (d1*10 + d2*9 + d3*8 + d4*7 + d5*6 + d6*5 + d7*4 + d8*3 + d9*2) AS soma1 FROM d
),
p2 AS (
    SELECT *, CASE WHEN (soma1 * 10) % 11 >= 10 THEN 0 ELSE (soma1 * 10) % 11 END AS dv1_calc FROM p1
),
p3 AS (
    SELECT *, (d1*11 + d2*10 + d3*9 + d4*8 + d5*7 + d6*6 + d7*5 + d8*4 + d9*3 + dv1_calc*2) AS soma2
    FROM   p2
),
p4 AS (
    SELECT *, CASE WHEN (soma2 * 10) % 11 >= 10 THEN 0 ELSE (soma2 * 10) % 11 END AS dv2_calc FROM p3
)
SELECT id_socio,
       UPPER(TRIM(nome))                                    AS nome,
       cpf_original,
       SUBSTRING(cpf,1,3)+'.'+SUBSTRING(cpf,4,3)+'.'+SUBSTRING(cpf,7,3)+'-'+SUBSTRING(cpf,10,2) AS cpf_formatado,
       CONCAT(dv1_calc, dv2_calc)                           AS dv_esperado,
       CONCAT(dv1, dv2)                                     AS dv_informado
FROM   p4
WHERE  dv1 <> dv1_calc OR dv2 <> dv2_calc
ORDER BY id_socio;
```
> **Resultado esperado: 5 registros** (ids 15, 32, 67, 78 e 109). São erros de digitação plantados de propósito na base. Cobrar duas observações: (a) a validação só faz sentido **depois** da normalização — sem ela, os CPF com máscara nem chegariam à conta; (b) nenhum dos CPF do grupo econômico está entre os inválidos, de modo que o exercício E3 continua íntegro.

---

## Bloco D — `CASE`

**D1.**
```sql
SELECT e.cod_situacao,
       CASE e.cod_situacao
            WHEN '00' THEN 'Documento regular'
            WHEN '02' THEN 'Documento cancelado'
            ELSE 'Codigo nao mapeado: ' + e.cod_situacao
       END        AS descricao,
       COUNT(*)   AS qtd
FROM   dbo.efd_c100 AS e
GROUP BY e.cod_situacao
ORDER BY qtd DESC;
```
> Valorizar o `ELSE` que **mostra** o código desconhecido em vez de escondê-lo sob `'OUTROS'`.

**D2.**
```sql
SELECT CASE WHEN i.aliquota_icms IS NULL OR i.aliquota_icms = 0 THEN 'ISENTO/NAO TRIBUTADO'
            WHEN i.aliquota_icms <=  7 THEN 'REDUZIDA'
            WHEN i.aliquota_icms <= 12 THEN 'INTERESTADUAL'
            ELSE                            'INTERNA'
       END                                            AS faixa_aliquota,
       COUNT(*)                                       AS qtd_itens,
       FORMAT(SUM(i.valor_total_item), 'N2', 'pt-BR') AS valor_total,
       FORMAT(SUM(i.valor_icms_item),  'N2', 'pt-BR') AS icms
FROM   dbo.nfe_item AS i
GROUP BY CASE WHEN i.aliquota_icms IS NULL OR i.aliquota_icms = 0 THEN 'ISENTO/NAO TRIBUTADO'
              WHEN i.aliquota_icms <=  7 THEN 'REDUZIDA'
              WHEN i.aliquota_icms <= 12 THEN 'INTERESTADUAL'
              ELSE                            'INTERNA'
         END
ORDER BY qtd_itens DESC;
```
> O teste de nulidade **precisa vir primeiro**: se `aliquota_icms <= 7` fosse a primeira condição, os nulos cairiam no `ELSE` (`INTERNA`), classificando item isento como tributado à alíquota interna — erro de consequência fiscal direta.

**D3.**
```sql
SELECT a.numero_auto,
       a.situacao,
       FORMAT(a.valor_principal + a.valor_multa, 'N2', 'pt-BR') AS valor_total
FROM   dbo.auto_infracao AS a
ORDER BY CASE a.situacao
              WHEN 'INSCRITO DIVIDA ATIVA'  THEN 1
              WHEN 'IMPUGNADO'              THEN 2
              WHEN 'JULGADO PROCEDENTE'     THEN 3
              WHEN 'LAVRADO'                THEN 4
              WHEN 'PAGO'                   THEN 5
              ELSE 6
         END,
         a.valor_principal + a.valor_multa DESC;
```

**D4.**
```sql
SELECT n.chave_acesso,
       IIF(n.id_destinatario IS NULL, 'CONSUMIDOR NAO IDENTIFICADO', 'DESTINATARIO IDENTIFICADO') AS com_iif,
       CASE WHEN n.id_destinatario IS NULL THEN 'CONSUMIDOR NAO IDENTIFICADO'
            ELSE 'DESTINATARIO IDENTIFICADO' END                                                 AS com_case
FROM   dbo.nfe AS n
WHERE  n.id_nfe <= 20;
```
> Resposta esperada: **`CASE`** em material didático, por três motivos — é ANSI (portável para PostgreSQL, Oracle, MySQL), escala para mais de dois ramos sem reescrita e deixa a lógica explícita. `IIF` é conveniente em expressão curta e código de uso interno.

**D5.** A consulta falha porque os dois ramos do `CASE` devolvem tipos diferentes — `VARCHAR` (`'NAO INFORMADO'`) e `DECIMAL` (`faturamento_declarado`). Pela **precedência de tipos** do SQL Server, o tipo numérico prevalece, e o servidor tenta converter a cadeia `'NAO INFORMADO'` para número, produzindo o erro *"Conversion failed when converting the varchar value ... to data type ..."*. A correção é uniformizar o tipo de retorno:
```sql
SELECT c.razao_social,
       CASE WHEN c.faturamento_declarado IS NULL THEN 'NAO INFORMADO'
            ELSE FORMAT(c.faturamento_declarado, 'N2', 'pt-BR')
       END AS faturamento
FROM   dbo.contribuinte AS c;
```
> Cobrar a observação de que a coluna resultante é **texto** e, portanto, não serve para ordenar por valor. Se a ordenação importar, mantenha duas colunas: a numérica (para `ORDER BY`) e a formatada (para exibição).

**D6.**
```sql
SELECT m.nome                                                              AS municipio,
       COUNT(*)                                                            AS total,
       COUNT(CASE WHEN n.situacao = 'AUTORIZADA'  THEN 1 END)              AS autorizadas,
       COUNT(CASE WHEN n.situacao = 'CANCELADA'   THEN 1 END)              AS canceladas,
       COUNT(CASE WHEN n.situacao = 'DENEGADA'    THEN 1 END)              AS denegadas,
       COUNT(CASE WHEN n.situacao = 'INUTILIZADA' THEN 1 END)              AS inutilizadas,
       CAST(COUNT(CASE WHEN n.situacao = 'CANCELADA' THEN 1 END) AS DECIMAL(12,4))
            / NULLIF(COUNT(*), 0) * 100                                    AS pct_cancelamento
FROM   dbo.nfe AS n
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = n.id_emitente
       INNER JOIN dbo.municipio    AS m ON m.id_municipio    = c.id_municipio
GROUP BY m.nome
HAVING COUNT(*) >= 50
ORDER BY pct_cancelamento DESC;
```
> Erro a procurar na correção: `COUNT(CASE WHEN ... THEN 1 ELSE 0 END)`. Com o `ELSE 0`, todas as linhas ficam não nulas e a contagem devolve o total do grupo.

---

## Bloco E — Máscaras de CPF e CNPJ

**E1.**
```sql
SELECT TOP (20)
       c.cnpj,
       SUBSTRING(c.cnpj,1,2)+'.'+SUBSTRING(c.cnpj,3,3)+'.'+SUBSTRING(c.cnpj,6,3)+'/'
            +SUBSTRING(c.cnpj,9,4)+'-'+SUBSTRING(c.cnpj,13,2)                        AS via_substring,
       STUFF(STUFF(STUFF(STUFF(c.cnpj, 13, 0, '-'), 9, 0, '/'), 6, 0, '.'), 3, 0, '.') AS via_stuff,
       CASE WHEN SUBSTRING(c.cnpj,1,2)+'.'+SUBSTRING(c.cnpj,3,3)+'.'+SUBSTRING(c.cnpj,6,3)+'/'
                 +SUBSTRING(c.cnpj,9,4)+'-'+SUBSTRING(c.cnpj,13,2)
                 = STUFF(STUFF(STUFF(STUFF(c.cnpj, 13, 0, '-'), 9, 0, '/'), 6, 0, '.'), 3, 0, '.')
            THEN 'IGUAIS' ELSE 'DIVERGEM' END                                        AS conferencia,
       c.razao_social
FROM   dbo.contribuinte AS c
ORDER BY c.id_contribuinte;
```
> Todas as linhas devem exibir `IGUAIS`. Cobrar a explicação da ordem das inserções no `STUFF`: da direita para a esquerda, porque cada inserção desloca as posições seguintes.

**E2.**
```sql
SELECT s.id_socio,
       '[' + s.cpf + ']'                                                            AS original,
       RIGHT('00000000000' + REPLACE(REPLACE(REPLACE(TRIM(s.cpf),'.',''),'-',''),' ',''), 11) AS normalizado,
       LEN(TRIM(s.cpf))                                                             AS tam_original
FROM   dbo.socio_administrador AS s
WHERE  s.cpf <> RIGHT('00000000000' + REPLACE(REPLACE(REPLACE(TRIM(s.cpf),'.',''),'-',''),' ',''), 11)
ORDER BY tam_original, s.id_socio;
```
> Espera-se cerca de 78 registros (todos os que têm máscara, espaços ou zeros perdidos). Os colchetes na coluna `original` tornam os espaços visíveis na grade — truque que vale ensinar.

**E3.**
```sql
WITH socio_limpo AS (
    SELECT RIGHT('00000000000' + REPLACE(REPLACE(REPLACE(TRIM(cpf),'.',''),'-',''),' ',''), 11) AS cpf,
           UPPER(TRIM(nome)) AS nome,
           id_contribuinte
    FROM   dbo.socio_administrador
)
SELECT SUBSTRING(sl.cpf,1,3)+'.'+SUBSTRING(sl.cpf,4,3)+'.'+SUBSTRING(sl.cpf,7,3)+'-'+SUBSTRING(sl.cpf,10,2) AS cpf,
       MIN(sl.nome)                                                          AS nome,
       COUNT(DISTINCT sl.id_contribuinte)                                    AS qtd_empresas,
       STRING_AGG(c.razao_social, ' | ') WITHIN GROUP (ORDER BY c.razao_social) AS empresas
FROM   socio_limpo AS sl
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = sl.id_contribuinte
GROUP BY sl.cpf
HAVING COUNT(DISTINCT sl.id_contribuinte) >= 3
ORDER BY qtd_empresas DESC;
```
> **Resultado esperado: 6 pessoas físicas**, cada uma sócia de 3 ou 4 contribuintes.

**E4.** Agrupando pelo `cpf` **bruto**, o resultado vem **vazio ou muito menor**: o mesmo CPF gravado como `39566640510`, `395.666.405-10` e `' 395.666.405-10 '` forma três grupos distintos, nenhum deles atingindo o limite de três empresas.

Parágrafo esperado: em identificação de grupo econômico, a chave de ligação entre as empresas é a pessoa física. Se a chave não é normalizada, o vínculo se dissolve e o relatório conclui que **não há** grupo econômico — uma conclusão falsa produzida por defeito de tratamento, não por ausência do fato. É o tipo de erro que arquiva indevidamente uma linha de investigação, e que ninguém percebe, porque a consulta "rodou sem erro". Normalizar CPF e CNPJ antes de qualquer cruzamento é, portanto, requisito de confiabilidade da prova, não preferência de estilo.

**E5.**
```sql
SELECT TOP (10)
       SUBSTRING(n.chave_acesso,1,4)  + ' ' + SUBSTRING(n.chave_acesso,5,4)  + ' ' +
       SUBSTRING(n.chave_acesso,9,4)  + ' ' + SUBSTRING(n.chave_acesso,13,4) + ' ' +
       SUBSTRING(n.chave_acesso,17,4) + ' ' + SUBSTRING(n.chave_acesso,21,4) + ' ' +
       SUBSTRING(n.chave_acesso,25,4) + ' ' + SUBSTRING(n.chave_acesso,29,4) + ' ' +
       SUBSTRING(n.chave_acesso,33,4) + ' ' + SUBSTRING(n.chave_acesso,37,4) + ' ' +
       SUBSTRING(n.chave_acesso,41,4)                                     AS chave_danfe,
       SUBSTRING(n.chave_acesso,1,2)                                      AS cuf,
       SUBSTRING(n.chave_acesso,3,4)                                      AS competencia_aamm,
       SUBSTRING(n.chave_acesso,7,2)+'.'+SUBSTRING(n.chave_acesso,9,3)+'.'+
       SUBSTRING(n.chave_acesso,12,3)+'/'+SUBSTRING(n.chave_acesso,15,4)+'-'+
       SUBSTRING(n.chave_acesso,19,2)                                     AS cnpj_emitente,
       CAST(CAST(SUBSTRING(n.chave_acesso,26,9) AS INT) AS VARCHAR(9))    AS numero_nf
FROM   dbo.nfe AS n
WHERE  LEN(n.chave_acesso) = 44
ORDER BY n.id_nfe;
```
> Atenção às posições do CNPJ dentro da chave: 7 a 20. As máscaras deslocam-se em relação ao CNPJ isolado — erro comum ao copiar a expressão da tabela `contribuinte` sem ajustar os deslocamentos.

---

## Bloco F — Relatório integrador

**F1.** A solução é a consulta da Etapa 9 do roteiro. Critérios de correção:

1. filtro e agregação sobre o dado bruto, formatação apenas na projeção final;
2. `NOT EXISTS` com as quatro condições (chave, declarante, `ind_oper`, `cod_situacao`) e filtro de regime `NORMAL`;
3. `ORDER BY` pela coluna numérica, não pela formatada;
4. `COALESCE` na região fiscal;
5. carimbo de extração presente.

**F2.** Acrescentar duas construções:
```sql
, socios AS (
    SELECT s.id_contribuinte,
           STRING_AGG(UPPER(TRIM(s.nome)), ' | ')
                WITHIN GROUP (ORDER BY UPPER(TRIM(s.nome))) AS quadro_societario
    FROM   dbo.socio_administrador AS s
    GROUP BY s.id_contribuinte
),
cpf_compartilhado AS (
    SELECT DISTINCT s1.id_contribuinte
    FROM   dbo.socio_administrador AS s1
    WHERE  EXISTS (
        SELECT 1 FROM dbo.socio_administrador AS s2
        WHERE s2.id_contribuinte <> s1.id_contribuinte
          AND RIGHT('00000000000'+REPLACE(REPLACE(REPLACE(TRIM(s2.cpf),'.',''),'-',''),' ',''),11)
            = RIGHT('00000000000'+REPLACE(REPLACE(REPLACE(TRIM(s1.cpf),'.',''),'-',''),' ',''),11))
)
```
e, na projeção:
```sql
       COALESCE(s.quadro_societario, '(sem socio cadastrado)')                     AS [Quadro Societario],
       CASE WHEN cc.id_contribuinte IS NOT NULL
            THEN 'SOCIO EM COMUM COM OUTRO CONTRIBUINTE' ELSE '' END              AS [Alerta]
```
com `LEFT JOIN cpf_compartilhado AS cc ON cc.id_contribuinte = c.id_contribuinte`.

**F3.**
```sql
-- Versao para EXPORTACAO: destino e outro sistema, nao o olho humano.
SELECT c.cnpj                                              AS cnpj,          -- 14 digitos, sem mascara
       UPPER(TRIM(c.razao_social))                         AS razao_social,  -- normalizado, sem formatacao
       CONVERT(VARCHAR(8), o.primeira, 112)                AS data_inicial,  -- AAAAMMDD, imune a locale
       CONVERT(VARCHAR(8), o.ultima,   112)                AS data_final,
       CAST(o.valor_omitido  AS DECIMAL(15,2))             AS valor_omitido, -- ponto decimal, sem milhar
       CAST(o.icms_potencial AS DECIMAL(15,2))             AS icms_potencial,
       o.qtd_documentos                                    AS qtd_documentos
FROM   omissoes AS o
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = o.id_emitente;
-- Sem mascara: o sistema de destino faz o proprio parsing e a mascara o quebraria.
-- AAAAMMDD: nao depende de SET DATEFORMAT nem da configuracao regional do destino.
-- DECIMAL sem separador de milhar: virgula em CSV cria coluna nova; ponto decimal e o padrao de intercambio.
-- Sem FORMAT: o resultado permanece tipado, o que preserva o query folding no Power Query.
```

**F4.** (desafio)
```sql
DECLARE @hoje DATE = GETDATE();

WITH omissoes AS (
    SELECT n.id_emitente,
           COUNT(*)           AS qtd,
           SUM(n.valor_total) AS valor
    FROM   dbo.nfe AS n
           INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = n.id_emitente
    WHERE  n.situacao = 'AUTORIZADA' AND n.tipo_operacao = '1'
      AND  n.data_emissao >= '2025-01-01' AND n.data_emissao < '2025-02-01'
      AND  c.regime_tributario = 'NORMAL'
      AND  NOT EXISTS (SELECT 1 FROM dbo.efd_c100 AS e
                       WHERE e.chave_acesso = n.chave_acesso
                         AND e.id_contribuinte = n.id_emitente
                         AND e.ind_oper = '1' AND e.cod_situacao = '00')
    GROUP BY n.id_emitente
),
extenso AS (
    SELECT * FROM (VALUES
        (1,'um'),(2,'dois'),(3,'tres'),(4,'quatro'),(5,'cinco'),(6,'seis'),(7,'sete'),
        (8,'oito'),(9,'nove'),(10,'dez'),(11,'onze'),(12,'doze'),(13,'treze'),(14,'quatorze'),
        (15,'quinze'),(16,'dezesseis'),(17,'dezessete'),(18,'dezoito'),(19,'dezenove'),(20,'vinte')
    ) AS t(n, texto)
)
SELECT CONCAT(
    'Fica o contribuinte ', UPPER(TRIM(c.razao_social)),
    ', inscrito no CNPJ sob o no ',
    SUBSTRING(c.cnpj,1,2)+'.'+SUBSTRING(c.cnpj,3,3)+'.'+SUBSTRING(c.cnpj,6,3)+'/'
        +SUBSTRING(c.cnpj,9,4)+'-'+SUBSTRING(c.cnpj,13,2),
    ', estabelecido no municipio de ', m.nome,
    ', intimado a apresentar, no prazo de 30 (trinta) dias contados de ',
    FORMAT(@hoje, 'dd ''de'' MMMM ''de'' yyyy', 'pt-BR'),
    ', os arquivos da EFD ICMS/IPI referentes a competencia ',
    FORMAT(CONVERT(DATE, '20250101'), 'MMMM/yyyy', 'pt-BR'),
    ', tendo em vista a constatacao de ', CAST(o.qtd AS VARCHAR(10)),
    ' (', COALESCE(e.texto, CAST(o.qtd AS VARCHAR(10))), ') documentos fiscais emitidos e nao escriturados',
    ', no valor total de R$ ', FORMAT(o.valor, 'N2', 'pt-BR'), '.'
) AS paragrafo_da_intimacao
FROM   omissoes AS o
       INNER JOIN dbo.contribuinte AS c ON c.id_contribuinte = o.id_emitente
       INNER JOIN dbo.municipio    AS m ON m.id_municipio    = c.id_municipio
       LEFT  JOIN extenso          AS e ON e.n = o.qtd
WHERE  o.qtd >= 5
ORDER BY o.valor DESC;
```
> Pontos avaliados: uso de `CONCAT` (que ignora nulos, ao contrário do `+`); data por extenso com cultura `pt-BR`; valor no padrão brasileiro; e a tabela auxiliar de números por extenso construída com `VALUES` — cobrar a observação de que **escrever número por extenso não é tarefa do SQL**: em produção, isso pertence à camada de aplicação ou a uma função dedicada, e a tabela acima só resolve o intervalo de 1 a 20.

---

*Gabarito do Módulo 11 — Curso de Banco de Dados Relacional aplicado à Fiscalização Tributária.*
