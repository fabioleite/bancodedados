# Roteiro: Junções em tabelas EFD do BDFISC — auditoria SEFAZ-PB

**Banco de trabalho:** `933000081200000173202662_20260127_104141` (BDFISC real, schemas `dbo` e `fisc`)
**IE do contribuinte auditado:** `161392660` (o banco corresponde a um único contribuinte — não filtre por IE nas views)
**Ferramenta:** SQL Server Management Studio (SSMS) — **Designer de Consultas**
**Pré-requisitos:** [apostila_juncoes_sql_server.md](apostila_juncoes_sql_server.md) (tipos de junção), [01 revisao_carga/ssms_lowcode.md](01%20revisao_carga/ssms_lowcode.md) (recursos visuais do SSMS)

---

## Convenção do BDFISC usada nos dois roteiros

O BDFISC guarda os registros da EFD em dois lugares (ver também [roteiro_visoes.MD](roteiro_visoes.MD), seção 2.1):


|                   | `dbo.EFD_*` — dados brutos        | `fisc.TB_*_PR_EFD_REGISTRO_*` — tabelas derivadas              |
| ------------------- | ------------------------------------ | ----------------------------------------------------------------- |
| Nomes de coluna   | técnicos (`sqcontrib`, `idativo`) | "português fiscal" (`C100_CHV_NFE`, `E110_VL_TOT_AJ_CREDITOS`) |
| Uso neste roteiro | não usado diretamente             | fonte de**todas** as junções abaixo                           |

Os dois roteiros abaixo usam exclusivamente tabelas `fisc.TB_*_PR_EFD_REGISTRO_*`, cada um combinando **3 registros da EFD** com tipos de junção diferentes, sempre com a consulta final validada contra os dados reais deste banco.

> **Regra de junção que os dois roteiros repetem:** todo cruzamento entre registros da EFD neste banco é feito por `REG0_PERIODO_DECLARACAO` (+ `REG0_IE` quando presente, por disciplina — mesmo com um único contribuinte no banco) somado à chave específica do nível (`C100_CHV_NFE` para o documento, `REG0200_COD_ITEM` para o item/produto). Esquecer o período na junção multiplica linhas de contribuintes com o mesmo código de item declarado em anos diferentes.

---

## Roteiro 1 — Alíquota de ICMS aplicada × alíquota cadastrada do produto (C100 × C170 × 0200)

### 1.1 Objetivo

Encontrar, nas notas fiscais de **saída**, itens cuja alíquota de ICMS aplicada na operação (registro **C170**) diverge da alíquota cadastrada para aquele produto no registro **0200**, e também itens cujo código de produto não tem cadastro correspondente. Ambos são indício de tributação incorreta ou de cadastro de item desatualizado.

### 1.2 Tabelas e papéis


| Alias | Tabela (`fisc.`)                                                 | Registro EFD | Papel                                                                                                      |
| ------- | ------------------------------------------------------------------ | -------------- | ------------------------------------------------------------------------------------------------------------ |
| `C`   | `TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL`           | C100         | cabeçalho do documento fiscal                                                                             |
| `I`   | `TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL`                    | C170         | item do documento (o item já traz o NCM herdado do 0200, mas**não** traz alíquota nem CEST cadastrados) |
| `P`   | `TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO` | 0200         | cadastro do produto/serviço (alíquota interna cadastrada, CEST, código de barras)                       |

### 1.3 Por que estes tipos de junção

- **`INNER JOIN` entre `C` e `I`:** todo item do C170 pertence obrigatoriamente a um documento C100 do mesmo período — é uma relação de existência garantida pela própria estrutura do arquivo da EFD. Não há item "órfão" a preservar.
- **`LEFT JOIN` entre `I` e `P`:** o código de item pode não ter cadastro correspondente no 0200 daquele período (cadastro incompleto) — se a junção fosse `INNER`, esses itens desapareceriam silenciosamente da auditoria, exatamente o erro descrito na [apostila_juncoes_sql_server.md](apostila_juncoes_sql_server.md), seção 7. O `LEFT` preserva o item e permite classificar o achado com `CASE` (cadastro ausente **ou** alíquota divergente).

> **Nota sobre o Designer.** Ao arrastar `P` depois de `I` no painel Diagrama e marcar "Incluir todas as linhas" do lado de `I`, o SSMS gera `LEFT OUTER JOIN`. Se você marcar a caixa do lado errado (ou arrastar as tabelas na ordem inversa), o Designer gera `RIGHT OUTER JOIN` com o mesmo significado, só que lido ao contrário — reconheça e reescreva como `LEFT`, conforme a seção 8.2 da apostila de junções ("toda `RIGHT` pode virar `LEFT`").

### 1.4 Passo a passo no Designer de Consultas

**Passo 1.1** — Editor de consultas → selecione qualquer `SELECT` (ou nenhum) → botão direito → **Criar Consulta no Editor** (`Ctrl+Shift+Q`). Na janela "Adicionar Tabela", aba **Tabelas**, adicione nesta ordem: `TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL`, `TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL`, `TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO`. Feche a janela.

**Passo 1.2** — No **painel Diagrama**, o Designer **não** desenha a linha entre `C100` e `C170` automaticamente (não há `FOREIGN KEY` declarada nessas tabelas derivadas). Desenhe manualmente arrastando `REG0_PERIODO_DECLARACAO` de uma tabela até a outra, depois repita para `C100_CHV_NFE`. Duas linhas de junção compostas aparecem entre as duas tabelas.

**Passo 1.3** — Repita para `C170` × `0200`: arraste `REG0_PERIODO_DECLARACAO` e depois `REG0200_COD_ITEM` entre as duas tabelas.

**Passo 1.4** — Clique com o **botão direito sobre a linha de junção** entre `C170` e `0200` → **Tipo de Junção…** → marque **"Incluir TODAS as linhas de TB_506_..."**. O Designer redesenha a linha com uma seta apontando para `0200`, sinalizando `LEFT OUTER JOIN`. Deixe a junção `C100`×`C170` como está (o padrão do Designer já é `INNER JOIN`).

**Passo 1.5** — No painel Diagrama, marque as colunas: de `C100` → `C100_IND_OPER`; de `C170` → `REG0_PERIODO_DECLARACAO`, `C100_CHV_NFE`, `C170_NUM_ITEM`, `REG0200_COD_ITEM`, `REG0200_DESCR_ITEM`, `C170_ALIQ_ICMS`; de `0200` → `REG0200_ALIQ_ICMS`, `REG0200_CEST`.

**Passo 1.6** — No **painel Critérios**, preencha a coluna **Filtro** de `C100_IND_OPER` com `= '1 - SAIDA'`. Para o achado, a condição composta (cadastro ausente **ou** alíquota divergente) é mais fácil de digitar direto no **painel SQL** do que na grade — é exatamente o limite do Designer descrito na seção 3.1 de [roteiro_visoes.MD](roteiro_visoes.MD): monte o esqueleto no diagrama, finalize a condição no editor.

**Passo 1.7** — `Ctrl+R` para amostra; confira o **painel SQL** contra o script abaixo antes de salvar.

### 1.5 Consulta final (T-SQL)

```sql
USE [933000081200000173202662_20260127_104141];
GO

SELECT
    C.REG0_PERIODO_DECLARACAO AS PERIODO,
    C.C100_CHV_NFE            AS CHAVE_ACESSO,
    C.C100_DT_DOC              AS DT_DOC,
    I.C170_NUM_ITEM            AS NUM_ITEM,
    I.REG0200_COD_ITEM         AS COD_ITEM,
    I.REG0200_DESCR_ITEM       AS DESCR_ITEM,
    I.C170_ALIQ_ICMS           AS ALIQ_OPERACAO,
    P.REG0200_ALIQ_ICMS        AS ALIQ_CADASTRO,
    P.REG0200_CEST             AS CEST,
    CASE
        WHEN P.REG0200_COD_ITEM IS NULL THEN 'SEM CADASTRO NO 0200'
        ELSE 'ALIQUOTA DIVERGENTE'
    END AS ACHADO
FROM fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL AS C
INNER JOIN fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL AS I
    ON I.REG0_PERIODO_DECLARACAO = C.REG0_PERIODO_DECLARACAO
   AND I.C100_CHV_NFE            = C.C100_CHV_NFE
LEFT JOIN fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO AS P
    ON P.REG0_PERIODO_DECLARACAO = I.REG0_PERIODO_DECLARACAO
   AND P.REG0200_COD_ITEM        = I.REG0200_COD_ITEM
WHERE C.C100_IND_OPER = '1 - SAIDA'
  AND (
        P.REG0200_COD_ITEM IS NULL
        OR (P.REG0200_ALIQ_ICMS IS NOT NULL AND I.C170_ALIQ_ICMS <> P.REG0200_ALIQ_ICMS)
      )
ORDER BY C.C100_DT_DOC, C.C100_CHV_NFE, I.C170_NUM_ITEM;
```

### 1.6 Conferência (validada neste banco)


| Verificação                                               | Resultado real |
| ------------------------------------------------------------- | ---------------: |
| Itens de saída no universo (`C100_IND_OPER = '1 - SAIDA'`) |            504 |
| Itens sem cadastro correspondente no 0200                   |              0 |
| Itens com alíquota divergente                              |          **8** |
| Todos os 8 pertencem à mesma nota (`CHAVE_ACESSO`)         |            sim |

Consulta de conferência do universo total:

```sql
SELECT COUNT(*) AS itens_saida
FROM fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL AS C
INNER JOIN fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL AS I
    ON I.REG0_PERIODO_DECLARACAO = C.REG0_PERIODO_DECLARACAO
   AND I.C100_CHV_NFE            = C.C100_CHV_NFE
WHERE C.C100_IND_OPER = '1 - SAIDA';
```

### 1.7 Observações de auditoria

- Os 8 itens divergentes vêm todos do mesmo documento (período `3/2022`) e alternam nos dois sentidos: itens em que a operação aplicou `18%` mas o 0200 está cadastrado com `0%`, e um item em que ocorre o inverso. Isso descarta erro sistemático de um lado só — o próximo passo do auditor é abrir o 0200 vigente naquele período e confirmar se a alíquota cadastrada é a correta para o NCM do produto.
- **Não** use `CEST IS NOT NULL` sozinho como achado de ICMS-ST ausente: o `C170_CST_ICMS = '60'` (ICMS já retido em etapa anterior) é uma situação legítima em que o item **não** deve ter `C170_VL_ICMS_ST` preenchido pelo substituído. Verifique o CST antes de classificar.
- Query de apoio para essa checagem de CST antes de acusar ST ausente:

```sql
SELECT I.C170_CST_ICMS, COUNT(*) AS qt
FROM fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL AS C
INNER JOIN fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL AS I
    ON I.REG0_PERIODO_DECLARACAO = C.REG0_PERIODO_DECLARACAO
   AND I.C100_CHV_NFE            = C.C100_CHV_NFE
WHERE C.C100_IND_OPER = '1 - SAIDA'
GROUP BY I.C170_CST_ICMS
ORDER BY qt DESC;
```

### 1.8 Índices de apoio para a consulta final

As três tabelas do Roteiro 1 são `fisc.TB_*` — sem `PRIMARY KEY`, `UNIQUE` nem índice declarado — portanto cada `JOIN` da consulta final (seção 1.5) tende a varrer a tabela inteira. Os índices abaixo seguem exatamente as colunas usadas em `JOIN`/`WHERE` do script:

```sql
-- Recomendação do SQL Server
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>] 
  ON [fisc].[TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL] 
  ([C100_IND_OPER]) INCLUDE ([REG0_PERIODO_DECLARACAO],[C100_CHV_NFE],[C100_DT_DOC])

  

-- C100: filtra por IND_OPER e entra na junção por (PERIODO, CHV_NFE)
CREATE NONCLUSTERED INDEX IX_TB474_saida
    ON fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL
    (C100_IND_OPER, REG0_PERIODO_DECLARACAO, C100_CHV_NFE)
    INCLUDE (C100_DT_DOC);

-- C170: junta com C100 por (PERIODO, CHV_NFE) e com 0200 por (PERIODO, COD_ITEM)
CREATE NONCLUSTERED INDEX IX_TB506_periodo_chave
    ON fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL
    (REG0_PERIODO_DECLARACAO, C100_CHV_NFE)
    INCLUDE (C170_NUM_ITEM, REG0200_COD_ITEM, C170_ALIQ_ICMS);

CREATE NONCLUSTERED INDEX IX_TB506_periodo_item
    ON fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL
    (REG0_PERIODO_DECLARACAO, REG0200_COD_ITEM);

-- 0200: lado direito do LEFT JOIN, chave é (PERIODO, COD_ITEM)
CREATE NONCLUSTERED INDEX IX_TB418_periodo_item
    ON fisc.TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO
    (REG0_PERIODO_DECLARACAO, REG0200_COD_ITEM)
    INCLUDE (REG0200_ALIQ_ICMS, REG0200_CEST, REG0200_DESCR_ITEM);
```

> **Estas tabelas são recriadas a cada carga.** Como `fisc.TB_474_...`, `fisc.TB_506_...` e `fisc.TB_418_...` são apagadas e recriadas pelas procedures `nnn_PR_*` (`DROP TABLE` + `SELECT INTO`), os três índices acima **somem junto** a cada execução. Guarde o script e rode-o logo depois das procedures — o mesmo padrão defensivo (`IF OBJECT_ID(...) IS NOT NULL AND NOT EXISTS (...)`) usado em [roteiro_visoes.MD](roteiro_visoes.MD), seção 9.2:
>
> ```sql
> IF OBJECT_ID('fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL') IS NOT NULL
>    AND NOT EXISTS (SELECT 1 FROM sys.indexes
>                    WHERE name = 'IX_TB474_saida'
>                      AND object_id = OBJECT_ID('fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL'))
> BEGIN
>     CREATE NONCLUSTERED INDEX IX_TB474_saida
>         ON fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL
>         (C100_IND_OPER, REG0_PERIODO_DECLARACAO, C100_CHV_NFE)
>         INCLUDE (C100_DT_DOC);
> END;
> ```
>
> **Por que não uma view indexada aqui.** A consulta final tem `LEFT JOIN` (C170 × 0200), e view indexada (`WITH SCHEMABINDING` + índice clusterizado) proíbe `OUTER JOIN` na definição. Mesmo removendo o `LEFT JOIN`, `SCHEMABINDING` sobre `fisc.TB_*` travaria o `DROP TABLE` da próxima carga (ver [roteiro_visoes.MD](roteiro_visoes.MD), seção 7.3). Por isso a estratégia de desempenho deste roteiro é o índice comum acima, recriado a cada carga — não a view materializada.

---

## Roteiro 2 — Conciliação dos ajustes de apuração do ICMS (E100 × E110 × E111)

### 2.1 Objetivo

Para cada período de apuração, comparar o total de ajustes declarado no cabeçalho da apuração (**E110**) com a soma dos ajustes individualmente detalhados (**E111**). Divergência sistemática indica que o contribuinte lança ajustes no detalhe (E111) sem atualizar corretamente os totais do E110 — ou o inverso.

### 2.2 Tabelas e papéis


| Alias  | Tabela (`fisc.`)                                               | Registro EFD | Papel                                                                   |
| -------- | ---------------------------------------------------------------- | -------------- | ------------------------------------------------------------------------- |
| `E100` | `TB_734_PR_EFD_REGISTRO_E100_INFORMACAO_PERIODO_APURACAO_ICMS` | E100         | período de apuração declarado (data inicial/final)                   |
| `E110` | `TB_736_PR_EFD_REGISTRO_E110_APURACAO_ICMS_OPERACOES_PROPRIAS` | E110         | apuração do ICMS — operações próprias, com os**totais** de ajuste |
| `E111` | `TB_738_PR_EFD_REGISTRO_E111_AJUSTES_OUTROS_CREDITOS_DEBITOS`  | E111         | **detalhe** de cada ajuste (zero ou mais linhas por período)           |

### 2.3 Por que estes tipos de junção

- **`LEFT JOIN` entre `E100` e `E110`:** em tese a relação é 1:1 obrigatória (todo período apurado tem uma apuração própria). Usar `LEFT` em vez de assumir `INNER` **prova** essa obrigatoriedade em vez de pressupô-la: se sobrar alguma linha de `E100` com `E110` nulo no resultado, é uma falha de carga do arquivo, não um "não deveria acontecer". Neste banco, a conferência (seção 2.6) mostra 60 = 60 — a garantia se confirma, mas ela foi **verificada**, não assumida.
- **`LEFT JOIN` entre `E110` e `E111`:** o registro E111 é opcional e pode se repetir — um período pode não ter nenhum ajuste detalhado, e outro pode ter vários. `LEFT` preserva o período mesmo com zero ajustes (necessário para o `SUM`/`COUNT` da agregação abaixo não perder períodos do denominador).

> **Limite do Designer nesta consulta — e como contorná-lo com duas exibições.** A comparação final soma `E111_VL_AJ_APUR` por período (`GROUP BY`) e por isso o Designer consegue montar o esqueleto das duas junções e até ligar "Totais" nas colunas agregadas pela grade de Critérios — mas o Designer **não representa** a subtração final entre os dois totais dentro do mesmo `SELECT` agregado sem reescrita manual. Em vez de terminar a subtração à mão no editor (como uma consulta com subconsulta na cláusula `FROM`), este roteiro divide o problema em **duas exibições encadeadas**: a primeira materializa só a agregação (100% representável no Designer, porque termina no `GROUP BY`, sem nenhuma conta depois); a segunda é aberta **sobre a primeira** e, como já não tem `GROUP BY`, o cálculo de `DIFERENCA` e o filtro de tolerância voltam a ser simples colunas e critérios — também representáveis no Designer. É a mesma técnica da Etapa 3 de [roteiro_visoes.MD](roteiro_visoes.MD) (uma view construída sobre outras views já salvas), aplicada aqui para transformar "o Designer não desenha isso" em duas etapas que ele desenha perfeitamente.

### 2.4 Passo a passo no Designer de Consultas

#### Parte A — view interna: agregação por período (`fisc.VW_AUD_APURACAO_ICMS_TOTAIS`)

**Passo 2.1** — `Ctrl+Shift+Q` (ou Pesquisador de Objetos → **Exibições** → **Nova Exibição…**) → aba **Tabelas** → adicione, nesta ordem: `TB_734_PR_EFD_REGISTRO_E100_INFORMACAO_PERIODO_APURACAO_ICMS`, `TB_736_PR_EFD_REGISTRO_E110_APURACAO_ICMS_OPERACOES_PROPRIAS`, `TB_738_PR_EFD_REGISTRO_E111_AJUSTES_OUTROS_CREDITOS_DEBITOS`.

**Passo 2.2** — Desenhe as junções arrastando `REG0_PERIODO_DECLARACAO` e `REG0_IE` entre `E100`↔`E110` e entre `E110`↔`E111` (quatro linhas ao todo — duas por par de tabelas).

**Passo 2.3** — Botão direito na linha `E100`↔`E110` → **Tipo de Junção…** → **"Incluir TODAS as linhas de TB_734_..."** (LEFT a partir de `E100`). Repita na linha `E110`↔`E111`, agora marcando **"Incluir TODAS as linhas de TB_736_..."** (LEFT a partir de `E110`).

**Passo 2.4** — Marque as colunas: de `E110` → `REG0_PERIODO_DECLARACAO`, `E110_VL_TOT_AJ_CREDITOS`, `E110_VL_TOT_AJ_DEBITOS`; de `E111` → `E111_VL_AJ_APUR`. Na grade, edite a célula **Coluna** de `E111_VL_AJ_APUR` para `ISNULL(E111_VL_AJ_APUR;0)` — o Designer aceita a função escrita diretamente na célula.

**Passo 2.5** — No painel Critérios, clique com o botão direito na grade → **"Totais"** para exibir a coluna de agregação. Na coluna `ISNULL(...)`, troque `Group By` por `Sum`; nas demais colunas (`REG0_PERIODO_DECLARACAO`, `E110_VL_TOT_AJ_CREDITOS`, `E110_VL_TOT_AJ_DEBITOS`), mantenha `Group By`. Preencha os **Alias**: `PERIODO`, `CREDITOS_DECLARADOS`, `DEBITOS_DECLARADOS`, `SOMA_AJUSTES_E111`.

**Passo 2.6** — `Ctrl+R` para conferir a amostra por período. Confira o painel SQL contra o script da seção 2.5.1 e salve com **Ctrl+S** como `VW_AUD_APURACAO_ICMS_TOTAIS` (ajuste o schema para `fisc` depois, se o SSMS salvar em `dbo`). Note que **não há nenhuma conta pós-agregação nesta view** — é exatamente o que permite ao Designer desenhar o `SELECT` inteiro sem reclamar.

#### Parte B — view externa: diferença e filtro de tolerância (`fisc.VW_AUD_APURACAO_ICMS_DIVERGENTE`)

**Passo 2.7** — Nova Exibição novamente, mas agora na janela "Adicionar Tabela" vá à aba **Exibições** (não Tabelas) e adicione `VW_AUD_APURACAO_ICMS_TOTAIS` — a view criada na Parte A aparece ali como qualquer tabela, porque para o Designer uma view salva é apenas mais uma fonte de linhas.

**Passo 2.8** — No painel Diagrama, marque todas as colunas de `VW_AUD_APURACAO_ICMS_TOTAIS`. Na grade de Critérios, acrescente uma linha nova e digite na célula **Coluna**: `(CREDITOS_DECLARADOS + DEBITOS_DECLARADOS) - SOMA_AJUSTES_E111`, com **Alias** `DIFERENCA`. Como a fonte agora é uma view sem `GROUP BY`, isso é uma expressão de linha comum — o Designer representa sem problema.

**Passo 2.9** — Em uma segunda linha auxiliar, digite a mesma expressão dentro de `ABS(...)` e preencha o **Filtro** com `> 0.05`; desmarque "Saída" dessa linha auxiliar para que ela participe só do `WHERE`, não do `SELECT`. Se o Designer não aceitar a função dentro da célula de filtro da sua versão do SSMS, digite essa única linha no painel SQL — é a única sobra manual, e agora é uma condição, não a consulta inteira.

**Passo 2.10** — `Ctrl+R` para confirmar que só aparecem os períodos fora da tolerância. Salve como `VW_AUD_APURACAO_ICMS_DIVERGENTE`.

### 2.5 Consulta final: duas exibições encadeadas

#### 2.5.1 View interna — agregação por período

```sql
USE [933000081200000173202662_20260127_104141];
GO

CREATE OR ALTER VIEW fisc.VW_AUD_APURACAO_ICMS_TOTAIS
AS
/*  Uma linha por período: total de ajustes declarado no cabeçalho da
    apuração (E110) e soma dos ajustes individualmente detalhados (E111).
    Fontes: E100 (período), E110 (cabeçalho), E111 (detalhe, 0..N por período). */
SELECT
    E100.REG0_PERIODO_DECLARACAO         AS PERIODO,
    E110.E110_VL_TOT_AJ_CREDITOS         AS CREDITOS_DECLARADOS,
    E110.E110_VL_TOT_AJ_DEBITOS          AS DEBITOS_DECLARADOS,
    SUM(ISNULL(E111.E111_VL_AJ_APUR, 0)) AS SOMA_AJUSTES_E111
FROM fisc.TB_734_PR_EFD_REGISTRO_E100_INFORMACAO_PERIODO_APURACAO_ICMS AS E100
LEFT JOIN fisc.TB_736_PR_EFD_REGISTRO_E110_APURACAO_ICMS_OPERACOES_PROPRIAS AS E110
    ON E110.REG0_PERIODO_DECLARACAO = E100.REG0_PERIODO_DECLARACAO
   AND E110.REG0_IE                 = E100.REG0_IE
LEFT JOIN fisc.TB_738_PR_EFD_REGISTRO_E111_AJUSTES_OUTROS_CREDITOS_DEBITOS AS E111
    ON E111.REG0_PERIODO_DECLARACAO = E110.REG0_PERIODO_DECLARACAO
   AND E111.REG0_IE                 = E110.REG0_IE
GROUP BY E100.REG0_PERIODO_DECLARACAO, E110.E110_VL_TOT_AJ_CREDITOS, E110.E110_VL_TOT_AJ_DEBITOS;
GO
```

#### 2.5.2 View externa — diferença e filtro de tolerância

```sql
CREATE OR ALTER VIEW fisc.VW_AUD_APURACAO_ICMS_DIVERGENTE
AS
/*  Sobre a view de totais (sem GROUP BY aqui): calcula a diferença entre o
    declarado no E110 e o somado no E111, e mantém só os períodos fora da
    tolerância de R$ 0,05.                                                     */
SELECT
    T.PERIODO,
    T.CREDITOS_DECLARADOS,
    T.DEBITOS_DECLARADOS,
    T.SOMA_AJUSTES_E111,
    (T.CREDITOS_DECLARADOS + T.DEBITOS_DECLARADOS) - T.SOMA_AJUSTES_E111 AS DIFERENCA
FROM fisc.VW_AUD_APURACAO_ICMS_TOTAIS AS T
WHERE ABS((T.CREDITOS_DECLARADOS + T.DEBITOS_DECLARADOS) - T.SOMA_AJUSTES_E111) > 0.05;
GO
```

#### 2.5.3 Uso

```sql
SELECT PERIODO, CREDITOS_DECLARADOS, DEBITOS_DECLARADOS, SOMA_AJUSTES_E111, DIFERENCA
FROM fisc.VW_AUD_APURACAO_ICMS_DIVERGENTE
ORDER BY PERIODO;
```

> **Por que isso é melhor do que a subconsulta na cláusula `FROM`.** A definição de "diferença" e a tolerância de R$ 0,05 passam a existir em **um único lugar** (`VW_AUD_APURACAO_ICMS_DIVERGENTE`) — se a coordenação decidir mudar a tolerância para R$ 0,10, ou se outro relatório precisar dos totais sem o filtro, `VW_AUD_APURACAO_ICMS_TOTAIS` já está pronta para ser reaproveitada sozinha. É o mesmo argumento da seção 3.2 de [roteiro_visoes.MD](roteiro_visoes.MD) ("Por que criar uma view em vez de repetir o `SELECT`?") para preferir view a `SELECT` repetido.

### 2.6 Conferência (validada neste banco)


| Verificação                                                                |      Resultado real |
| ------------------------------------------------------------------------------ | --------------------: |
| Períodos declarados no E100                                                 |                  60 |
| Períodos com apuração E110 correspondente (prova do`LEFT` da seção 2.3) | 60 (nenhum órfão) |
| Períodos com pelo menos um ajuste no E111                                   |                  60 |
| Períodos com divergência acima de R$ 0,05 entre declarado e somado         |              **36** |

Amostra do resultado (3 primeiros períodos divergentes por ordem alfabética de período):


| PERIODO | CREDITOS_DECLARADOS | DEBITOS_DECLARADOS | SOMA_AJUSTES_E111 | DIFERENCA |
| --------- | --------------------: | -------------------: | ------------------: | ----------: |
| 1/2021  |            5.102,72 |               0,00 |          5.498,63 |   -395,91 |
| 1/2022  |            8.520,99 |              51,85 |          9.136,36 |   -563,52 |
| 8/2020  |            2.885,41 |               0,00 |          4.010,33 | -1.124,92 |

Consulta de conferência da paridade E100 × E110:

```sql
SELECT
    (SELECT COUNT(*) FROM fisc.TB_734_PR_EFD_REGISTRO_E100_INFORMACAO_PERIODO_APURACAO_ICMS) AS total_e100,
    (SELECT COUNT(*) FROM fisc.TB_736_PR_EFD_REGISTRO_E110_APURACAO_ICMS_OPERACOES_PROPRIAS) AS total_e110;
```

### 2.7 Observações de auditoria

- A diferença é **sempre negativa** nos 36 casos: o valor somado dos ajustes individuais (E111) é sistematicamente **maior** que o total declarado no cabeçalho (E110). Isso sugere um padrão — não um erro isolado — e é o tipo de achado que justifica notificar o contribuinte para retificação da EFD, em vez de apontar má-fé em um único período.
- Não confunda esta consulta com uma questão de perda de linhas: como o `LEFT JOIN` de `E110`→`E111` foi usado, nenhum período com ajuste zero foi descartado — eles simplesmente entram com `SOMA_AJUSTES_E111 = 0` (via `ISNULL`) e não geram divergência falsa.

### 2.8 Variante avançada (opcional) — `FULL OUTER JOIN` entre apuração própria e apuração de ICMS-ST

Diferente de `E100`→`E110` (mesma procedure, sempre pareados), a apuração de ICMS **substituição tributária** (registro **E200**, tabela `fisc.TB_748_PR_EFD_REGISTRO_E200_PERIODO_APURACAO_ICMS_SUBSTITUICAO`) é um bloco **independente**: nada garante que todo período com E100 também tenha E200, nem o contrário. Esse é o cenário canônico de `FULL OUTER JOIN` (mesmo raciocínio da conciliação NF-e × EFD da seção 9 da apostila de junções):

```sql
SELECT
    COALESCE(E100.REG0_PERIODO_DECLARACAO, E200.REG0_PERIODO_DECLARACAO) AS PERIODO,
    CASE
        WHEN E100.REG0_PERIODO_DECLARACAO IS NULL THEN 'SO ICMS-ST'
        WHEN E200.REG0_PERIODO_DECLARACAO IS NULL THEN 'SO ICMS PROPRIO'
        ELSE 'AMBOS'
    END AS SITUACAO
FROM fisc.TB_734_PR_EFD_REGISTRO_E100_INFORMACAO_PERIODO_APURACAO_ICMS AS E100
FULL OUTER JOIN fisc.TB_748_PR_EFD_REGISTRO_E200_PERIODO_APURACAO_ICMS_SUBSTITUICAO AS E200
    ON E200.REG0_PERIODO_DECLARACAO = E100.REG0_PERIODO_DECLARACAO
   AND E200.REG0_IE                 = E100.REG0_IE
ORDER BY PERIODO;
```

**Resultado real neste banco:** os 60 períodos retornam `SITUACAO = 'SO ICMS PROPRIO'` — a tabela `fisc.TB_748_...` está **vazia** para este contribuinte. Isso não é um erro da consulta: é o próprio achado. O auditor deve confirmar se este contribuinte realmente não tem nenhuma responsabilidade por substituição tributária no intervalo carregado, ou se a apuração de ICMS-ST foi omitida da EFD.

---

## Quadro-resumo dos tipos de junção usados


| Junção          | Roteiro      | Tabelas          | Por quê                                                   |
| ------------------- | -------------- | ------------------ | ------------------------------------------------------------ |
| `INNER JOIN`      | 1            | `C100` × `C170` | relação obrigatória (todo item pertence a um documento) |
| `LEFT JOIN`       | 1            | `C170` × `0200` | cadastro do produto pode faltar — antijunção/achado     |
| `LEFT JOIN`       | 2            | `E100` × `E110` | prova a obrigatoriedade em vez de pressupor (`INNER`)      |
| `LEFT JOIN`       | 2            | `E110` × `E111` | ajuste detalhado é zero-a-muitos por período             |
| `FULL OUTER JOIN` | 2 (variante) | `E100` × `E200` | dois universos independentes, sem FK entre si              |

`RIGHT OUTER JOIN` não aparece na consulta final de nenhum roteiro — pelas razões já registradas na apostila de junções (seção 8.3), ele raramente é necessário quando o `FROM` está na ordem certa. Ele só aparece no Roteiro 1 como algo a **reconhecer e reescrever** caso o Designer o gere sozinho ao inverter a ordem das tabelas no diagrama.
