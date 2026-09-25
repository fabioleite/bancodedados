# Gabarito — Roteiro de Carga da Tabela do Anexo 5

**Material do instrutor. Não distribuir junto com a apostila.**
Referência: `roteiro_carga_anexo5.md`

---

## Parte A — Etapas 1 a 3

### A.1 Resultados esperados da investigação (Etapa 1)


| Verificação                 | Resultado correto                                                       |
| ------------------------------- | ------------------------------------------------------------------------- |
| BOM                           | Ausente. Os primeiros bytes são`54 61 62 65` (`Tabe`), não `EF BB BF` |
| Linhas físicas totais        | 1.844 (1 cabeçalho + 1.843 de dados)                                   |
| Linhas com nº de pipes ≠ 42 | **Duas**: uma com 4 pipes, outra com 38                                 |
| Registros lógicos            | 1.842                                                                   |
| Registros com conteúdo       | 1.836                                                                   |

O aluno que reportar "1.843 registros" não fez a verificação de pipes. É o erro mais comum e o mais consequente — leve-o a executar o comando do PowerShell antes de seguir.

As duas linhas anômalas somam 42 pipes (4 + 38) porque são **um único registro** partido pelo CRLF embutido. A linha em branco entre elas não tem pipe nenhum e por isso não aparece no filtro; peça ao aluno que explique por que ela existe (o campo `DESCRICAO` original, no XLSX, tinha um parágrafo vazio ao final).

### A.2 Erros previsíveis na Etapa 2

**Sintoma: acentuação corrompida (`cerÃ¢mica`).**
Faltou `CODEPAGE = '65001'`. Em SQL Server 2019+ com collation UTF-8 no banco, às vezes funciona sem — não conte com isso.

**Sintoma: `Bulk load data conversion error (truncation) row 1830, column 5`.**
Faltou `FORMAT='CSV'` ou `FIELDQUOTE='"'`. É a quebra de linha embutida.

**Sintoma: `The bulk load failed. Unexpected NULL value in data file row 1, column 43`.**
`ROWTERMINATOR = '0x0d0a'` combinado com `FORMAT='CSV'`. O `\r` é consumido duas vezes e a última coluna fica desalinhada. Corrija para `'0x0a'`.

**Sintoma: `Cannot bulk load. The file does not exist.`**
O caminho é resolvido pela conta de serviço do SQL Server. Verifique com:

```sql
SELECT servicename, service_account
FROM sys.dm_server_services
WHERE servicename LIKE 'SQL Server (%';
```

**Sintoma: `ERRORFILE could not be opened`.**
Sobrou o `.log` ou o `.log.Error.Txt` da tentativa anterior. Apague os dois.

### A.3 Contagens de referência (Etapa 3)

Números para conferência direta. Se algum divergir, a carga não está correta.


| Métrica                                                   | Valor                                   |
| ------------------------------------------------------------ | ----------------------------------------- |
| `staging.anexo5_bruto`                                     | 1.842                                   |
| `fisc.anexo5_sefaz_normalizado`                            | 1.836                                   |
| `Vigencia_inicial` nula                                    | 1                                       |
| `Vigencia_final` nula                                      | 1.062                                   |
| `Aliq_Interna` nula                                        | 0                                       |
| `NCM_SH` nulo                                              | 10                                      |
| `Tabela_CEST` distintos                                    | 22                                      |
| `CEST` distintos                                           | 608                                     |
| `NCM_SH` distintos                                         | 418                                     |
| `Legislacao` distintos                                     | 106                                     |
| Abas de origem                                             | 20                                      |
| Pares`(CEST, NCM_SH)` duplicados                           | 634                                     |
| `MVA_Original_deriv_Petr` numérica                        | 1.704                                   |
| `Regime_deriv_Petr` preenchida                             | 132 (PMPF 80, AD REM 50, DIFERIMENTO 2) |
| `MVA_Original_deriv_Petr` **e** `Regime_deriv_Petr` juntas | 0                                       |
| `Regime_N_deriv_Petr` preenchida                           | 1                                       |

**Registro com `Vigencia_inicial` nula:** o do texto `27/03 2020`. Peça ao aluno que o localize com a consulta da seção 3.2 e decida o que fazer — a resposta defensável é corrigir para `2020-03-27` **na staging**, com registro da correção, e recarregar. Corrigir direto no destino perde a rastreabilidade.

**Verificação 3.5-b (formato do CEST):** retorna resultados. Há CEST com 6 e 7 caracteres (`01.001`, `13.001.`), além dos 9 do formato completo. Não é erro de carga — é inconsistência da planilha de origem. O aluno deve reportar, não silenciar.

**Verificação 3.5-c (NCM não numérico):** deve retornar **zero linhas** após o `REPLACE(NCM_SH, '.', '')`. Se retornar, o `REPLACE` foi omitido e o `1902.20.00` passou.

**Verificação 3.3 (desdobramento das colunas de regime):** os dois erros previsíveis são simétricos e ambos passam despercebidos se o aluno não conferir a soma `1.704 + 132 = 1.836`.

- Omitir a condição `NULLIF(...) IS NOT NULL` no `CASE`: os campos vazios viram string vazia em vez de `NULL`, e `com_regime` sobe de 132 para 132 + (quantidade de vazios). A coluna deixa de responder "esta mercadoria tem regime especial?" com um simples `IS NOT NULL`.
- Omitir a condição `TRY_CONVERT(...) IS NULL`: valores numéricos são copiados para as duas colunas, `ambos_preenchidos` deixa de ser zero e a `CHECK CONSTRAINT` da seção 2.4 barra a carga inteira.

O segundo erro é o mais instrutivo, porque a restrição do banco o denuncia imediatamente. Se o aluno não criou a constraint, o erro entra silencioso — use isso para justificar por que a regra de negócio deve estar no esquema, não apenas no script.

**Verificação 3.5-d (sobreposição de vigência):** os 634 pares duplicados **não** são todos sobreposição. A maioria são versões sequenciais (uma termina, a outra começa). Espere um número pequeno de sobreposições reais — cada uma é um achado a reportar à área normativa, porque significa duas MVA válidas para a mesma mercadoria na mesma data.

---

## Parte B — Questões de auditoria

### Preliminar obrigatória: os tipos das tabelas `fisc.TB_*`

As tabelas de resultado foram criadas por `SELECT ... INTO` a partir de expressões `CASE WHEN col IS NULL THEN '-' ELSE col END`. O tipo final depende da precedência de tipos do SQL Server, e o resultado é heterogêneo. Confirmado por inspeção da DDL:


| Coluna                          | Tipo            | Observação                                     |
| --------------------------------- | ----------------- | -------------------------------------------------- |
| `REG0200_COD_NCM` (em `TB_506`) | `nvarchar`      | **pode conter `'-'`** no lugar de NULL           |
| `REG0200_COD_NCM` (em `TB_418`) | `nvarchar(8)`   | aceita NULL normalmente                          |
| `REG0200_TIPO_ITEM`             | `varchar(29)`   | descritivo:`'0 - MERCADORIA PARA REVENDA'`       |
| `C100_COD_SIT`                  | `varchar(76)`   | descritivo:`'2 - DOCUMENTO CANCELADO'`           |
| `REG0200_ALIQ_ICMS`             | `decimal(6,2)`  | escala**percentual** (18.00)                     |
| `REG0200_CEST`                  | `int`           | sem pontuação; ausência pode ser NULL**ou** 0 |
| `C170_VL_ICMS`, `C190_VL_OPR`   | `decimal(16,2)` | NULL substituído por**0**, não por `'-'`       |
| `C170_CST_ICMS`, `C170_CFOP`    | `int`           | mas o`CASE` prevê `'-'`; use `TRY_CONVERT`      |

O uso de `TRY_CONVERT` em todas as comparações numéricas do gabarito é defensivo por esse motivo, não por preciosismo. Um `WHERE C170_CFOP BETWEEN 1000 AND 2999` estoura se a coluna tiver virado texto em algum ambiente.

**Detalhe do CST.** `CDCSTICMS` na origem tem 3 dígitos: origem da mercadoria + CST propriamente dito. O valor `60` armazenado como `int` corresponde a origem `0` + CST `60`. Para isolar o CST:

```sql
RIGHT('00' + CAST(TRY_CONVERT(INT, C170_CST_ICMS) AS VARCHAR(3)), 2)
```

**Detalhe do período.** `REG0_PERIODO_DECLARACAO` vem de `CONCAT(MONTH(DTINICIAL),'/',YEAR(DTINICIAL))` — sem zero à esquerda, comprimento variável (`'1/2024'`, `'12/2024'`). Para converter em data:

```sql
DATEFROMPARTS(
    CAST(RIGHT(REG0_PERIODO_DECLARACAO, 4) AS INT),
    CAST(LEFT(REG0_PERIODO_DECLARACAO, CHARINDEX('/', REG0_PERIODO_DECLARACAO) - 1) AS INT),
    1)
```

---

### Questão 1 — Crédito de ICMS em entrada sob ST

#### Consulta completa

```sql
SELECT
    c170.REG0_IE,
    c170.REG0_NOME,
    a5.CEST,
    c170.REG0200_COD_NCM,
    COUNT(*)                                              AS qtd_itens,
    SUM(TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS))    AS icms_creditado_indevido
FROM fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL c170
INNER JOIN fisc.anexo5_sefaz_normalizado a5
    -- (1) casamento por prefixo: o NCM do Anexo 5 tem de 4 a 8 dígitos
    ON  a5.NCM_SH IS NOT NULL
    AND LEN(a5.NCM_SH) BETWEEN 4 AND 8
    AND LEFT(c170.REG0200_COD_NCM, LEN(a5.NCM_SH)) = a5.NCM_SH
    -- (2) regra vigente na data do documento; Vigencia_final NULL = ainda vigente
    -- TRY_CONVERT(DATE, ...) nos dois lados: o ISNULL nunca chega a operar em DATETIME
    AND TRY_CONVERT(DATE, c170.C100_DT_DOC) >= TRY_CONVERT(DATE, a5.Vigencia_inicial)
    AND TRY_CONVERT(DATE, c170.C100_DT_DOC) <= ISNULL(TRY_CONVERT(DATE, a5.Vigencia_final), '9999-12-31')
WHERE TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS) > 0
  -- (3) entradas (1xxx interna, 2xxx interestadual) destinadas a revenda
  AND TRY_CONVERT(INT, c170.C170_CFOP) IN (1102, 2102, 1113, 2113, 1116, 2116)
  -- (4) CST que indica crédito: 00, 10, 20, 51, 70, 90
  AND RIGHT('00' + CAST(TRY_CONVERT(INT, c170.C170_CST_ICMS) AS VARCHAR(3)), 2)
      IN ('00', '10', '20', '70', '90')
  AND c170.REG0200_COD_NCM NOT IN ('-', '')
  AND c170.REG0200_COD_NCM IS NOT NULL
GROUP BY c170.REG0_IE, c170.REG0_NOME, a5.CEST, c170.REG0200_COD_NCM
-- (5) materialidade
HAVING SUM(TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS)) >= 1000.00
ORDER BY icms_creditado_indevido DESC;
```

#### Justificativa das lacunas

**(1)** A igualdade simples `c170.REG0200_COD_NCM = a5.NCM_SH` casa apenas os 1.166 registros do Anexo 5 que têm NCM de 8 dígitos, perdendo os 670 que são prefixo. O `LEN(a5.NCM_SH) BETWEEN 4 AND 8` protege contra os valores anômalos de 9 e 10 dígitos (6 registros) e contra os nulos.

**(2)** `ISNULL(Vigencia_final, '9999-12-31')` é o ponto crítico. 1.062 dos 1.836 registros têm vigência final nula — sem esse tratamento, a condição `C100_DT_DOC <= NULL` avalia como UNKNOWN e **58% da tabela normativa desaparece da junção** sem nenhum erro. É o tipo de defeito que passa em revisão de código e só aparece quando alguém confere o resultado contra a norma.

**Armadilha adicional de tipo.** `C100_DT_DOC` é `DATE`; `Vigencia_inicial`/`Vigencia_final` são `DATETIME`. Comparar os dois força o SQL Server a promover o `DATE` para `DATETIME` pela regra de precedência de tipos — mas `DATETIME` só aceita anos entre 1753 e 9999, enquanto `DATE` aceita de 0001 a 9999. Se algum valor não for uma data limpa (texto malformado ou fora dessa faixa), a comparação estoura com `Msg 242: A conversão de um tipo de dados varchar em um tipo de dados datetime resultou em um valor fora do intervalo.` A correção é inverter o sentido da conversão — reduzir o `DATETIME` para `DATE` com `TRY_CONVERT`, nunca o contrário — porque a faixa de `DATE` cobre por completo a de `DATETIME` e `TRY_CONVERT` devolve `NULL` (excluindo a linha da junção) em vez de interromper a consulta inteira.

**Por que só envolver o `ISNULL` em `TRY_CONVERT` não basta.** `ISNULL(a5.Vigencia_final, '9999-12-31')` precisa decidir, antes de qualquer coisa, um tipo único para os dois argumentos — e a regra de precedência escolhe `DATETIME`, convertendo o literal `'9999-12-31'` **para `DATETIME`** internamente, por conta própria, antes que um `TRY_CONVERT` colocado por fora tenha chance de agir. Por isso o `TRY_CONVERT(DATE, ...)` precisa envolver `a5.Vigencia_final` **antes** do `ISNULL`, não depois: `ISNULL(TRY_CONVERT(DATE, a5.Vigencia_final), '9999-12-31')`. Assim o `ISNULL` já resolve seus dois argumentos em `DATE`, e o literal nunca é interpretado como `DATETIME`.

**Se o erro persistir depois dessa correção**, confirme os tipos reais das colunas no seu banco — a DDL pode divergir da documentada aqui:

```sql
SELECT c.name, t.name AS tipo, c.max_length
FROM sys.columns c
JOIN sys.types   t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('fisc.anexo5_sefaz_normalizado')
  AND c.name IN ('Vigencia_inicial', 'Vigencia_final');

SELECT c.name, t.name AS tipo, c.max_length
FROM sys.columns c
JOIN sys.types   t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL')
  AND c.name = 'C100_DT_DOC';
```

**(3)** CFOP 1102/2102 é compra para comercialização em operação **normal**. Se a mercadoria está no Anexo 5, esse é justamente o CFOP errado — o correto seria 1403/2403. Incluir 1403/2403 no filtro anularia o achado: com esses CFOP o contribuinte declarou que sabe tratar-se de ST, e aí o crédito seria outro tipo de erro. 1113/2113 e 1116/2116 cobrem compras via consignação e via ordem de compra, também para revenda.

**(4)** CST 60 é o correto para mercadoria com ICMS já retido. O filtro busca justamente quem **não** usou 60. Note que CST 10 aparece na lista: 10 é "tributada com cobrança de ICMS por ST" — legítimo para o substituto, indevido para quem só revende.

**(5)** R$ 1.000,00 é referência de trabalho, não norma. O aluno deve justificar o patamar que escolheu — o argumento aceitável liga o piso ao custo de abrir e instruir uma ordem de serviço.

#### Respostas da análise

**1.1** A quantidade de itens com `REG0200_COD_NCM = '-'` ou NULL. Esses itens não são inocentes — são **invisíveis**, o que é pior: item sem NCM cadastrado é irregularidade autônoma no registro 0200 e ainda escapa de toda validação por NCM. Deve virar um achado separado:

```sql
SELECT REG0_IE, REG0_NOME, COUNT(*) AS itens_sem_ncm
FROM fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL
WHERE REG0200_COD_NCM IN ('-', '') OR REG0200_COD_NCM IS NULL
GROUP BY REG0_IE, REG0_NOME
ORDER BY itens_sem_ncm DESC;
```

**1.2** Com `LEFT JOIN` aparecem os itens que não casaram com nenhuma regra do Anexo 5. Isso é ruído para **esta** questão — o crédito é legítimo em mercadoria fora da ST. Mas o subconjunto desses itens com CST 60 é um achado real e invertido: o contribuinte declarou ST em mercadoria que não está sujeita a ST, o que costuma indicar recolhimento indevido a título de substituição.

**1.3** Contando as combinações antes de somar:

```sql
SELECT c170.C100_CHV_NFE, c170.C170_NUM_ITEM, COUNT(*) AS regras_casadas
FROM fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL c170
INNER JOIN fisc.anexo5_sefaz_normalizado a5
    ON LEFT(c170.REG0200_COD_NCM, LEN(a5.NCM_SH)) = a5.NCM_SH
   AND TRY_CONVERT(DATE, c170.C100_DT_DOC) >= TRY_CONVERT(DATE, a5.Vigencia_inicial)
   AND TRY_CONVERT(DATE, c170.C100_DT_DOC) <= ISNULL(TRY_CONVERT(DATE, a5.Vigencia_final), '9999-12-31')
GROUP BY c170.C100_CHV_NFE, c170.C170_NUM_ITEM
HAVING COUNT(*) > 1;
```

Se retornar linhas, há duplicação de valor no resultado da Questão 1. A causa mais comum não é a sobreposição de vigência da seção 3.5-d, e sim **prefixos aninhados**: o NCM `39172100` casa tanto com `3917` quanto com `39172100`, se ambos existirem na tabela. A correção é escolher o casamento mais específico:

```sql
CROSS APPLY (
    SELECT TOP 1 a.CEST, a.Aliq_Interna
    FROM fisc.anexo5_sefaz_normalizado a
    WHERE LEFT(c170.REG0200_COD_NCM, LEN(a.NCM_SH)) = a.NCM_SH
      AND TRY_CONVERT(DATE, c170.C100_DT_DOC) >= TRY_CONVERT(DATE, a.Vigencia_inicial)
      AND TRY_CONVERT(DATE, c170.C100_DT_DOC) <= ISNULL(TRY_CONVERT(DATE, a.Vigencia_final), '9999-12-31')
    ORDER BY LEN(a.NCM_SH) DESC
) a5
```

Este é o ponto de maior valor didático da questão. Vale gastar tempo nele.

---

### Questão 2 — Saída tributada normalmente de mercadoria sob ST

#### Consulta completa

```sql
SELECT
    c100.REG0_PERIODO_DECLARACAO,
    c100.REG0_IE,
    a5.CEST,
    a5.Aliq_Interna                                       AS aliquota_prevista_anexo5,
    COUNT(DISTINCT c100.C100_CHV_NFE)                     AS qtd_notas,
    SUM(TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS))    AS debito_a_maior
FROM fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL c100
INNER JOIN fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL c170
    -- (1) a chave de acesso é o único identificador seguro entre contribuintes
    ON  c170.C100_CHV_NFE = c100.C100_CHV_NFE
    AND c170.REG0_IE      = c100.REG0_IE
INNER JOIN fisc.anexo5_sefaz_normalizado a5
    -- (2) mesma lógica da Questão 1
    ON  a5.NCM_SH IS NOT NULL
    AND LEN(a5.NCM_SH) BETWEEN 4 AND 8
    AND LEFT(c170.REG0200_COD_NCM, LEN(a5.NCM_SH)) = a5.NCM_SH
    AND TRY_CONVERT(DATE, c100.C100_DT_DOC) >= TRY_CONVERT(DATE, a5.Vigencia_inicial)
    AND TRY_CONVERT(DATE, c100.C100_DT_DOC) <= ISNULL(TRY_CONVERT(DATE, a5.Vigencia_final), '9999-12-31')
-- (3) saídas: 5xxx interna, 6xxx interestadual
WHERE TRY_CONVERT(INT, c170.C170_CFOP) BETWEEN 5000 AND 6999
  -- (4) tributação normal com débito efetivo
  AND RIGHT('00' + CAST(TRY_CONVERT(INT, c170.C170_CST_ICMS) AS VARCHAR(3)), 2)
      IN ('00', '20')
  AND TRY_CONVERT(DECIMAL(16,2), c170.C170_VL_ICMS) > 0
  -- (5) a coluna é descritiva; comparar com 0 ou 2 não funciona
  AND c100.C100_COD_SIT LIKE '0 -%'
GROUP BY c100.REG0_PERIODO_DECLARACAO, c100.REG0_IE, a5.CEST, a5.Aliq_Interna
ORDER BY debito_a_maior DESC;
```

#### Justificativa das lacunas

**(1)** `C100_NUM_DOC + C100_SER` **não** é suficiente. Número e série se repetem entre contribuintes diferentes — dois emitentes podem ter a nota 1234 série 1 no mesmo mês. A junção por número/série produziria produto cartesiano entre contribuintes. A chave de acesso (44 dígitos) é única por definição; o `REG0_IE` adicional é redundância barata que protege contra chave nula.

**(5)** `C100_COD_SIT` armazena `'0 - DOCUMENTO REGULAR'`, `'2 - DOCUMENTO CANCELADO'`, etc. Escrever `WHERE C100_COD_SIT = 0` gera erro de conversão; escrever `WHERE C100_COD_SIT <> 2` não filtra nada. `LIKE '0 -%'` mantém apenas documentos regulares. Situação 1 (escrituração extemporânea de documento regular) também poderia ser incluída, a critério do enunciado da OS.

#### Respostas da análise

**2.1** `COUNT(*)` conta linhas de item; `COUNT(DISTINCT C100_CHV_NFE)` conta notas. Uma nota com 40 itens sob ST aparece 40 vezes. Se o relatório informar "1.200 notas com débito indevido" quando são 130 notas com 1.200 itens, o número vai para o auto de infração inflado quase dez vezes. Escreva as duas versões lado a lado e mostre a razão média itens/nota.

**2.2** Compare `C170_ALIQ_ICMS` (percentual, ex. 18.00) com `a5.Aliq_Interna * 100` (0.18 × 100). Onde diverge, a resposta depende: se o item está sob ST, a alíquota do Anexo 5 é a que serve de base ao cálculo do imposto retido — mas o item nem deveria estar sendo tributado na saída. A divergência de alíquota, aqui, é sintoma secundário; o achado principal continua sendo o CST.

**2.3** Hipóteses legítimas de CST 00 em mercadoria listada no Anexo 5:

- venda pelo **próprio substituto** (indústria/importador), quando a operação é a que gera a retenção — mas nesse caso o CST correto é 10, não 00;
- operação **interestadual para UF não signatária** do protocolo, quando a coluna `UF_Signataria` do Anexo 5 restringe o alcance;
- saída para **industrialização**, em que a mercadoria não se destina à revenda;
- período anterior à `Vigencia_inicial` da regra — daí a importância do filtro (2).

---

### Questão 3 — Divergência C100 × C190

#### Passo 1 — por que a versão errada está errada

A consulta do enunciado junta C100 a C190 **e** a C170. Cada nota tem N registros analíticos e M itens; a junção produz N × M linhas antes do `GROUP BY`. O `SUM(C190_VL_OPR)` soma cada valor analítico M vezes.

Demonstração para uma nota específica:

```sql
DECLARE @chave NVARCHAR(44) = '<informe uma chave da base>';

SELECT
    (SELECT COUNT(*) FROM fisc.TB_534_PR_EFD_REGISTRO_C190_ANALITICO_DOC_FISCAL_CST_CFOP_ALIQ_ICMS
     WHERE C100_CHV_NFE = @chave) AS qtd_c190,
    (SELECT COUNT(*) FROM fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL
     WHERE C100_CHV_NFE = @chave) AS qtd_c170;
```

O produto dos dois é o número de linhas que a junção gera para aquela nota, e o fator pelo qual a soma foi multiplicada.

#### Passo 2 — consulta corrigida

```sql
WITH analitico AS (
    SELECT
        C100_CHV_NFE,
        -- (1) agregação na granularidade do documento, antes de qualquer junção
        SUM(TRY_CONVERT(DECIMAL(16,2), C190_VL_OPR)) AS soma_analitico,
        COUNT(*)                                     AS qtd_linhas_c190
    FROM fisc.TB_534_PR_EFD_REGISTRO_C190_ANALITICO_DOC_FISCAL_CST_CFOP_ALIQ_ICMS
    -- (2) filtro de período
    WHERE REG0_PERIODO_DECLARACAO = '1/2025'
    GROUP BY C100_CHV_NFE
)
SELECT
    c100.REG0_IE,
    c100.REG0_NOME,
    c100.C100_CHV_NFE,
    c100.C100_VL_DOC,
    a.soma_analitico,
    a.qtd_linhas_c190,
    -- (3) diferença com sinal: positiva = analítico menor que o documento
    c100.C100_VL_DOC - ISNULL(a.soma_analitico, 0) AS diferenca
FROM fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL c100
LEFT JOIN analitico a
    ON a.C100_CHV_NFE = c100.C100_CHV_NFE
WHERE c100.REG0_PERIODO_DECLARACAO = '1/2025'
  AND c100.C100_COD_SIT LIKE '0 -%'
  -- (4) tolerância proporcional ao número de linhas analíticas
  AND ABS(c100.C100_VL_DOC - ISNULL(a.soma_analitico, 0))
      > (0.01 * ISNULL(a.qtd_linhas_c190, 1))
ORDER BY ABS(c100.C100_VL_DOC - ISNULL(a.soma_analitico, 0)) DESC;
```

**(4)** A tolerância fixa de R$ 0,01 é insuficiente: cada linha do C190 arredonda para dois decimais, então uma nota com 12 linhas analíticas pode legitimamente divergir R$ 0,12. Tolerância proporcional à quantidade de linhas resolve. Aluno que fixar R$ 0,01 vai reportar centenas de falsos positivos — deixe acontecer e depois peça a correção.

#### Respostas da análise

**3.1** Resposta numérica, calculada com a consulta do Passo 1 para uma nota concreta. O objetivo é que o aluno veja a multiplicação, não que decore o termo "fan-out".

**3.2** `LEFT JOIN` porque o caso mais grave é o documento C100 **sem nenhum** C190 — nota escriturada sem qualquer registro analítico, ou seja, sem apuração. Com `INNER JOIN` esses documentos somem exatamente do relatório que deveria denunciá-los. Por isso também o `ISNULL(a.soma_analitico, 0)`: sem ele, a diferença de uma nota órfã seria NULL e o `WHERE` a descartaria.

**3.3** Explicações legítimas: nota com valor de frete, seguro ou despesas acessórias que compõem o `VL_DOC` mas não integram a base do analítico; nota com itens de ISS ao lado de itens de ICMS; documento complementar. O achado é indício, não prova — a linguagem do relatório deve refletir isso.

---

### Questão 4 — Cadastro 0200 divergente da tabela normativa

#### Consulta completa

```sql
SELECT
    r0200.REG0_IE,
    r0200.REG0_NOME,
    COUNT(*)                                              AS itens_sujeitos_a_st,
    -- (1) CEST ausente: a coluna é int, ausência aparece como NULL ou 0
    SUM(CASE WHEN r0200.REG0200_CEST IS NULL
               OR r0200.REG0200_CEST = 0
             THEN 1 ELSE 0 END)                           AS sem_cest,
    -- (2) escalas diferentes: 18.00 no 0200 contra 0.18 no Anexo 5
    SUM(CASE WHEN r0200.REG0200_ALIQ_ICMS IS NOT NULL
               AND a5.Aliq_Interna       IS NOT NULL
               AND ABS(r0200.REG0200_ALIQ_ICMS - (a5.Aliq_Interna * 100)) > 0.01
             THEN 1 ELSE 0 END)                           AS aliquota_divergente,
    CAST(100.0 * SUM(CASE WHEN r0200.REG0200_CEST IS NULL
                            OR r0200.REG0200_CEST = 0
                          THEN 1 ELSE 0 END)
         / NULLIF(COUNT(*), 0) AS DECIMAL(5,2))           AS perc_sem_cest
FROM fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO r0200
INNER JOIN fisc.anexo5_sefaz_normalizado a5
    -- (3) prefixo + vigência no primeiro dia do período declarado
    ON  a5.NCM_SH IS NOT NULL
    AND LEN(a5.NCM_SH) BETWEEN 4 AND 8
    AND LEFT(r0200.REG0200_COD_NCM, LEN(a5.NCM_SH)) = a5.NCM_SH
    AND DATEFROMPARTS(
            CAST(RIGHT(r0200.REG0_PERIODO_DECLARACAO, 4) AS INT),
            CAST(LEFT(r0200.REG0_PERIODO_DECLARACAO,
                      CHARINDEX('/', r0200.REG0_PERIODO_DECLARACAO) - 1) AS INT),
            1)
        BETWEEN TRY_CONVERT(DATE, a5.Vigencia_inicial)
            AND ISNULL(TRY_CONVERT(DATE, a5.Vigencia_final), '9999-12-31')
-- (4) a coluna é descritiva
WHERE r0200.REG0200_TIPO_ITEM IN (
        '0 - MERCADORIA PARA REVENDA',
        '4 - PRODUTO ACABADO')
  AND r0200.REG0200_COD_NCM IS NOT NULL
GROUP BY r0200.REG0_IE, r0200.REG0_NOME
-- (5) relevância
HAVING COUNT(*) >= 20
   AND SUM(CASE WHEN r0200.REG0200_CEST IS NULL
                  OR r0200.REG0200_CEST = 0
                THEN 1 ELSE 0 END) > 0
ORDER BY perc_sem_cest DESC, itens_sujeitos_a_st DESC;
```

#### Justificativa das lacunas

**(2)** É a armadilha central da questão. `REG0200_ALIQ_ICMS` é `decimal(6,2)` em escala percentual; `Aliq_Interna` do Anexo 5 é `decimal(18,4)` em escala decimal. Comparação direta marca **100% dos itens** como divergentes. A tolerância de 0,01 absorve arredondamento — note que `Aliq_Interna` tem valores como `0.1533`, que multiplicado por 100 dá `15.33`, exatamente representável.

**(3)** A vigência é aferida no primeiro dia do período, não na data de cadastro do item. O 0200 descreve o estado do cadastro naquele mês; se a regra passou a valer no dia 15, há um mês de transição em que os dois estados são defensáveis. Vale registrar isso como limitação do teste.

**(4)** Tipos 1 (matéria-prima), 2 (embalagem), 7 (uso e consumo) e 8 (ativo imobilizado) foram excluídos porque não se destinam a revenda — a exigência de CEST não se aplica da mesma forma. Incluí-los infla o denominador e derruba o percentual, escondendo contribuintes realmente problemáticos.

#### Respostas da análise

**4.1** `NULLIF(COUNT(*), 0)` protege contra divisão por zero. Na prática, com `INNER JOIN` e `GROUP BY`, `COUNT(*)` nunca é zero dentro de um grupo — o grupo só existe se houver linha. Peça ao aluno que tente provocar o erro e descubra que **não consegue**. A lição é sobre reflexo defensivo em código que será copiado: mude o `INNER JOIN` para `LEFT JOIN` e a proteção passa a fazer diferença real.

**4.2** **Não encontra.** A consulta parte do NCM e verifica se o CEST está preenchido; não valida se o CEST informado existe. Consulta que encontra:

```sql
SELECT
    r0200.REG0_IE,
    r0200.REG0200_COD_ITEM,
    r0200.REG0200_CEST                                    AS cest_informado,
    r0200.REG0200_COD_NCM
FROM fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO r0200
LEFT JOIN (
    SELECT DISTINCT
        TRY_CONVERT(INT, REPLACE(CEST, '.', '')) AS cest_num
    FROM fisc.anexo5_sefaz_normalizado
    WHERE CEST IS NOT NULL
) v ON v.cest_num = r0200.REG0200_CEST
WHERE r0200.REG0200_CEST IS NOT NULL
  AND r0200.REG0200_CEST <> 0
  AND v.cest_num IS NULL;
```

O `REPLACE(CEST, '.', '')` seguido de `TRY_CONVERT(INT, ...)` é necessário porque o Anexo 5 guarda `'01.001.00'` e o 0200 guarda `1000100`. Os CEST malformados detectados na verificação 3.5-b (com 6 e 7 caracteres) vão gerar números com menos dígitos e nunca casar — o aluno deve notar e reportar essa limitação em vez de tratá-la como achado.

**4.3** Alíquota divergente **não** é necessariamente irregularidade. Redução de base de cálculo, benefício fiscal concedido por decreto, e regimes especiais (TARE) alteram a carga efetiva sem alterar a alíquota nominal do Anexo 5. O esquema `fisc` tem tabelas específicas de TARE (`TB_140`, `TB_145`, `TB_146`) que devem ser consultadas antes de qualquer conclusão. Este é o ponto em que se ensina a diferença entre **inconsistência de dados** e **infração tributária**.

---

## Parte C — Critérios de avaliação sugeridos


| Critério                                                                       | Peso |
| --------------------------------------------------------------------------------- | ------ |
| Identificou a quebra de linha embutida antes de carregar                        | 15%  |
| `BULK INSERT` com `FORMAT`, `FIELDQUOTE`, `CODEPAGE` e `ROWTERMINATOR` corretos | 15%  |
| Estratégia de staging em texto com conversão posterior justificada            | 10%  |
| Desdobramento das colunas de regime com exclusividade preservada                | 10%  |
| Verificações da Etapa 3 executadas com contagens conferidas                   | 10%  |
| Tratou`Vigencia_final` NULL corretamente nas junções                          | 15%  |
| Reconheceu e resolveu o fan-out da Questão 3                                   | 15%  |
| Distinguiu inconsistência de dados de infração tributária nas análises     | 10%  |

Os dois critérios de maior valor formativo são o tratamento de `Vigencia_final` nula e o fan-out — ambos produzem resultado plausível quando errados, e é isso que os torna perigosos.
