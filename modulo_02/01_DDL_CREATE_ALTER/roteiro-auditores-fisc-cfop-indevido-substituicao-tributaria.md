# Roteiro Prático para Auditores — Crédito de ICMS via CFOP Indevido de Substituição Tributária (schema `fisc`)

**Banco de trabalho:** `933000081200000173202662_20260127_104141`
**Schema:** `fisc`
**Tabelas escolhidas:** `FISC.TB_126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA_01` a `_04`
**Procedure que as alimenta:** `dbo.[126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA]`
**Origem:** procedure existente no banco (não versionada nos scripts do repositório — extraída via `OBJECT_DEFINITION`)

## 1. Existe tabela do schema `fisc` sobre CFOP indevido? Sim

O schema `fisc` desse banco tem um conjunto de tabelas dedicado exatamente a isso: a família **`TB_126`**, que audita **entradas em que a empresa tomou crédito próprio de ICMS sob um CFOP reservado para mercadoria sujeita à Substituição Tributária (ST)** — quando isso ocorre com mercadoria destinada à revenda, o crédito é, em regra, indevido, porque o ICMS daquela mercadoria já foi retido antes, pelo substituto tributário.

Outras tabelas do schema também tocam em CFOP (`TB_224/225/226_PR_SPED_VALORES_TOTAIS_POR_CFOP*`, `TB_534_PR_EFD_REGISTRO_C190_ANALITICO...CFOP...`), mas são apenas extrações de totais por CFOP — não fazem a análise de indevido. A `TB_126` é a única que efetivamente cruza CFOP x ICMS declarado x documento fiscal para apontar a irregularidade.

## 2. A regra fiscal por trás da consulta

Existe um grupo de CFOPs cujo significado é "esta mercadoria já teve o ICMS retido por substituição tributária em etapa anterior da cadeia":

| CFOP entrada | CFOP saída/devolução | Significado |
|---|---|---|
| 1403 | 2403 | Compra para comercialização, mercadoria sujeita ao regime de ST |
| 1407 | 2407 | Compra para uso ou consumo, mercadoria sujeita ao regime de ST |
| 1409 | 2409 | Compra de bem para o ativo imobilizado, mercadoria sujeita ao regime de ST |
| 1411 | 2411 | Devolução de venda de mercadoria sujeita ao regime de ST |
| 1415 | 2415 | Recebimento com fim específico de exportação, mercadoria sujeita ao regime de ST |

Quando uma nota é escriturada com um desses CFOPs, o **ICMS próprio (`VLICMS`)** do item — e o valor correspondente lançado no registro `C190` da EFD — deveria ser, em geral, **zero**: o imposto já foi recolhido antecipadamente pelo substituto. Se o registro mostra `VLICMS > 0` num CFOP desse grupo, é sinal de que a empresa apropriou crédito próprio sobre um imposto que não deveria compor sua apuração — daí "CFOP indevido".

## 3. O que a procedure oficial faz (e por que ela é grande)

A procedure `dbo.[126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA]` recebe `@ANO`, `@PERIODO_DECLARACAO` e `@RELATORIO`. Com `@RELATORIO = 99999` ela:

1. Filtra no registro `EFD_C190` os lançamentos com CFOP dentro do grupo de ST acima e `VLICMS > 0`.
2. Reconstrói, a partir de `EFD_0000` + `EFD_C100`, quais documentos (`SQNFOUTRA`) correspondem a notas **emitidas pela própria empresa auditada** (`TIPO_EMISSAO = 'P'`) e quais são **notas de terceiros escrituradas** (`TIPO_EMISSAO = 'T'`), casando por chave de acesso ou, na ausência dela, por data de emissão + valor + número + série.
3. Junta esses documentos aos itens da NF-e (`ITEM_NFE`, para notas próprias) ou ao registro `EFD_C170` (para notas de terceiros), trazendo CST, base de cálculo, alíquota e valores de ICMS/ICMS-ST por item.
4. Para os CFOPs de devolução (1411/2411), busca a **nota fiscal original referenciada** (`NFE_REF` → `NFE`) para comparar o ICMS da devolução com o da nota que está sendo devolvida.
5. Enriquece com dados de emitente e destinatário (`NFE_HI`, `TPHINFE = 2` emitente / `3` destinatário).
6. Grava o resultado em 4 tabelas de granularidade crescente.

### Estrutura das 4 tabelas de saída

| Tabela | Granularidade | Principais colunas |
|---|---|---|
| `_01` | Resumo por período | `REG0_PERIODO_DECLARACAO`, `TOTAL_C190_VL_ICMS` |
| `_02` | Registro `C190` por nota/CFOP | `NF_CHAVE_ACESSO`, `C190_CFOP`, `C190_VL_ICMS`, `C190_VL_BC_ICMS_ST`, `C190_VL_ICMS_ST` |
| `_03` | Item de NF-e própria | `ITEMNF_CFOP`, `ITEMNF_VLICMS`, `ALERTA_DEVOLUCAO`, `NF_REF_CHAVE_ACESSO`, `NF_REF_VICMS`, emitente/destinatário |
| `_04` | Item de EFD C170 (nota de terceiro) | `C170_CFOP`, `C170_VL_ICMS`, `ALERTA_DEVOLUCAO`, `NF_REF_*`, emitente/destinatário |

### Executando a procedure oficial

```sql
USE [933000081200000173202662_20260127_104141];
GO
EXEC dbo.[126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA]
     @RELATORIO = 99999;              -- gera as 4 tabelas
GO
EXEC dbo.[126_PR_ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA]
     @ANO = 2021, @PERIODO_DECLARACAO = '05/2021';   -- lê o resultado já gerado, filtrado por período
```

**Aviso operacional:** ao executar `@RELATORIO = 99999` neste ambiente de treino, a procedure falha com:

```
Msg 208, Level 16, State 1
Nome de objeto 'BI_DW_CORPORATIVO_FISC.DBO.TBCAD_CONTRIBUINTE' inválido.
```

Ela depende de um banco corporativo vinculado (`BI_DW_CORPORATIVO_FISC`) — cadastro de contribuintes e tabela de legislação de CFOP — que só existe no ambiente de produção da SEFAZ, não neste laboratório. Ou seja: **as tabelas `TB_126_01..04` deste banco estão vazias** e não podem ser recriadas por aqui. Isso não impede o roteiro: as tabelas-fonte (`dbo.NFE`, `dbo.ITEM_NFE`, `dbo.NFE_HI`, `dbo.NFE_REF`) estão carregadas e com dado real, então o passo a passo abaixo reproduz a mesma lógica de auditoria com consultas autocontidas.

## 4. Passo a passo do auditor (consultas autocontidas, testadas neste banco)

### Passo 1 — Panorama: quantos itens existem por CFOP de ST e quantos têm ICMS próprio cobrado

```sql
SELECT
    I.cdcfop,
    COUNT(*)                                            AS qtd_itens,
    SUM(CASE WHEN I.vlicms > 0 THEN 1 ELSE 0 END)       AS itens_com_icms_proprio,
    FORMAT(SUM(I.vlicms), 'N2', 'pt-BR')                AS soma_vlicms
FROM dbo.NFE N
INNER JOIN dbo.ITEM_NFE I ON N.sqnfe = I.sqnfe AND N.tpnfe = I.tpnfe
WHERE I.cdcfop IN (1403,1407,1409,1411,1415,2403,2407,2409,2411,2415)
  AND N.tpoperacao = '0'          -- entrada
  AND N.stnfe IN ('A','O')        -- autorizada (dentro ou fora do prazo)
GROUP BY I.cdcfop
ORDER BY I.cdcfop;
```

Isso já separa os CFOPs sem ocorrência dos que têm itens com `vlicms > 0` — candidatos a crédito indevido.

### Passo 2 — Listar os itens suspeitos com o documento fiscal

```sql
SELECT
    N.nrchaveacesso,
    N.dhemissao,
    I.cdcfop,
    I.cdcst,
    I.vlbasecalcicms,
    I.vlicms,
    I.vlbasecalcicmsst,
    I.vlicmsst,
    I.vlproduto
FROM dbo.NFE N
INNER JOIN dbo.ITEM_NFE I ON N.sqnfe = I.sqnfe AND N.tpnfe = I.tpnfe
WHERE I.cdcfop IN (1403,1407,1409,1411,1415,2403,2407,2409,2411,2415)
  AND N.tpoperacao = '0' AND N.stnfe IN ('A','O')
  AND I.vlicms > 0
ORDER BY I.vlicms DESC;
```

### Passo 3 — Drill-down com emitente e destinatário

```sql
SELECT
    N.nrchaveacesso,
    N.dhemissao,
    I.cdcfop,
    I.vlicms,
    EM.norazaosocial AS emitente,
    COALESCE(EM.nrcnpj, EM.nrcpf) AS doc_emitente,
    EM.sguf           AS uf_emitente,
    DE.norazaosocial  AS destinatario,
    DE.sguf           AS uf_destinatario
FROM dbo.NFE N
INNER JOIN dbo.ITEM_NFE I ON N.sqnfe = I.sqnfe AND N.tpnfe = I.tpnfe
LEFT JOIN dbo.NFE_HI EM ON EM.sqnfe = N.sqnfe AND EM.tpnfe = N.tpnfe AND EM.tphinfe = 2
LEFT JOIN dbo.NFE_HI DE ON DE.sqnfe = N.sqnfe AND DE.tpnfe = N.tpnfe AND DE.tphinfe = 3
WHERE I.cdcfop IN (1403,1407,1409,1411,1415,2403,2407,2409,2411,2415)
  AND N.tpoperacao = '0' AND N.stnfe IN ('A','O') AND I.vlicms > 0
ORDER BY I.vlicms DESC;
```

### Passo 4 — Para devolução (1411/2411), cruzar com a nota original referenciada

Igual à `TB_126_03/04` original: a devolução deve referenciar a nota de venda anterior; o ICMS da devolução deve ser compatível com o da nota original.

```sql
SELECT
    N.nrchaveacesso   AS chave_devolucao,
    I.cdcfop,
    I.vlicms          AS icms_item_devolucao,
    R.nrchaveacesso   AS chave_nf_referenciada,
    ORIG.vlicms       AS icms_nf_original,
    ORIG.vlicmsst     AS icmsst_nf_original
FROM dbo.NFE N
INNER JOIN dbo.ITEM_NFE I ON N.sqnfe = I.sqnfe AND N.tpnfe = I.tpnfe
INNER JOIN dbo.NFE_REF R ON R.sqnfe = N.sqnfe AND R.tpnfe = N.tpnfe
LEFT JOIN dbo.NFE ORIG ON ORIG.nrchaveacesso = R.nrchaveacesso
WHERE I.cdcfop IN (1411, 2411)
  AND N.tpoperacao = '0' AND N.stnfe IN ('A','O')
ORDER BY I.vlicms DESC;
```

Se `icms_nf_original` for muito maior que zero e a devolução (`icms_item_devolucao`) também cobrar ICMS próprio, é forte indício de duplicidade: o imposto já retido na venda original não deveria gerar novo crédito próprio na devolução.

### Passo 5 — Ranking de emitentes por valor total potencialmente indevido

```sql
SELECT
    EM.norazaosocial AS emitente,
    COALESCE(EM.nrcnpj, EM.nrcpf) AS doc_emitente,
    EM.sguf,
    COUNT(*) AS qtd_itens,
    FORMAT(SUM(I.vlicms), 'N2', 'pt-BR') AS total_icms_indevido
FROM dbo.NFE N
INNER JOIN dbo.ITEM_NFE I ON N.sqnfe = I.sqnfe AND N.tpnfe = I.tpnfe
LEFT JOIN dbo.NFE_HI EM ON EM.sqnfe = N.sqnfe AND EM.tpnfe = N.tpnfe AND EM.tphinfe = 2
WHERE I.cdcfop IN (1403,1407,1409,1411,1415,2403,2407,2409,2411,2415)
  AND N.tpoperacao = '0' AND N.stnfe IN ('A','O') AND I.vlicms > 0
GROUP BY EM.norazaosocial, COALESCE(EM.nrcnpj, EM.nrcpf), EM.sguf
ORDER BY SUM(I.vlicms) DESC;
```

Prioriza a diligência: poucos emitentes costumam concentrar a maior parte do valor.

### Passo 6 — Evolução mensal (para saber se é caso isolado ou recorrente)

```sql
SELECT
    FORMAT(N.dhemissao, 'yyyy-MM') AS mes_emissao,
    I.cdcfop,
    COUNT(*) AS qtd_itens,
    FORMAT(SUM(I.vlicms), 'N2', 'pt-BR') AS total_icms
FROM dbo.NFE N
INNER JOIN dbo.ITEM_NFE I ON N.sqnfe = I.sqnfe AND N.tpnfe = I.tpnfe
WHERE I.cdcfop IN (1403,1407,1409,1411,1415,2403,2407,2409,2411,2415)
  AND N.tpoperacao = '0' AND N.stnfe IN ('A','O') AND I.vlicms > 0
GROUP BY FORMAT(N.dhemissao, 'yyyy-MM'), I.cdcfop
ORDER BY mes_emissao, I.cdcfop;
```

## 5. Interpretando o achado — quando é realmente indevido

`VLICMS > 0` num CFOP de ST **não é prova automática de irregularidade**; antes de lavrar qualquer apontamento, o auditor deve descartar hipóteses legítimas:

- Operação com **redução de base de cálculo** ou benefício fiscal que ainda preveja parcela de ICMS próprio;
- Item com **CST** que indique tributação parcial (nem toda mercadoria do documento está, de fato, sob ST);
- Erro de **preenchimento do emitente** (CFOP errado na nota, mas ICMS calculado corretamente pela operação real) — nesse caso a irregularidade é do emitente, não necessariamente crédito indevido do destinatário;
- Valor residual pequeno compatível com arredondamento.

Por isso o Passo 3 (emitente/destinatário) e o Passo 4 (nota referenciada) são obrigatórios antes de qualquer conclusão — o Passo 1 e 2 servem só para triagem.

## 6. Entrega

1. Resultado do Passo 1 (panorama por CFOP) do período sob análise.
2. Lista de documentos do Passo 2/3 com valor de ICMS próprio indevido, ordenada por valor.
3. Para cada CFOP de devolução com achado, o cruzamento do Passo 4 com a nota original.
4. Ranking do Passo 5 com os 5 emitentes de maior valor.
5. Parecer por escrito: para os 3 maiores achados, indicar se há indício real de crédito indevido ou se alguma hipótese do item 5 explica o valor.
