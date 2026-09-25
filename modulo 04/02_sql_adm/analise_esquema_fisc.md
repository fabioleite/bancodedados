# Análise do Esquema `fisc` — BDFISC

**Fonte:** `bdfisc.sql` (script de geração, 20/08/2026)
**Objetos analisados:** 329 tabelas no esquema `fisc`

---

## 1. Anatomia do esquema

As 329 tabelas não são 329 assuntos. São **três camadas** com propósitos distintos, e confundi-las é a causa mais comum de consulta escrita contra a tabela errada.

### Camada 1 — Base EFD (118 tabelas, `TB_400` a `TB_8xx`)

Espelho estruturado da escrituração entregue pelo contribuinte. Uma tabela por registro do SPED Fiscal, numeradas em sequência que segue a ordem dos blocos: `TB_4xx` = blocos 0 e C (documentos), `TB_6xx` = bloco D (transporte), `TB_7xx` = bloco E (apuração), `TB_8xx` = blocos H e K (inventário e produção).

Esta é a camada que se consulta. As outras duas derivam dela.

### Camada 2 — Extração de XML e SPED (33 tabelas, `TB_2xx`)

`TB_201` a `TB_225`. Trazem o que o **documento eletrônico autorizado** diz, em contraste com o que a escrituração declara. Inclui grupos que a EFD não carrega: duplicatas, faturas, formas de pagamento, veículos, transportadora, documentos referenciados.

É a camada que permite a pergunta mais valiosa da fiscalização — *o que foi autorizado bate com o que foi escriturado?* — porque contém a versão do fato que **não** passou pelas mãos do contribuinte.

### Camada 3 — Resultados de rotinas de fiscalização (178 tabelas, `TB_1xx`)

Saída materializada de auditorias já codificadas. O nome descreve a irregularidade, e o sufixo `_01` a `_06` indica etapas de uma mesma rotina.

Distribuição por família:

| Família | Rotinas | Objeto |
|---|---|---|
| `ENTRADAS` | 55 | Crédito indevido, valor contábil, CT-e |
| `SAIDAS` / `SAIDA` | 60 | Débito a menor, alíquota, DIFAL, TARE, sucata |
| `XML` | 24 | Confronto documento autorizado × escriturado |
| `FALTA` | 17 | Documento autorizado e não lançado |
| `AUSENCIA` | 11 | EFD não entregue, quebra de sequencial |
| `SPED` | 9 | Totalizações por CFOP e CST |
| `APURACAO` | 8 | Transporte de saldos, E111 → E110, CIAP |
| `TARE` | 2 | Regime especial de atacadista |

**Leia os nomes desta camada antes de escrever qualquer consulta nova.** `TB_112_..._ENTRADAS_LANCADAS_COM_CREDITO_A_MAIOR_C190` e `TB_126_..._ENTRADAS_CREDITO_C190_CFOP_SUBST_TRIBUT_MERCADORIAS_REVENDA` já respondem boa parte do que se costuma reescrever do zero.

---

## 2. Quais registros a fiscalização mais usa

Medida objetiva: quantas rotinas da Camada 3 nomeiam cada registro EFD como seu objeto.

| Registro | Rotinas | O que a rotina examina |
|---|---|---|
| **C100** | 23 | Documento fiscal — valor, situação, duplicidade, período |
| **C190** | 15 | Analítico por CST/CFOP/alíquota — débito e crédito |
| D100 | 11 | CT-e — conhecimento de transporte |
| D190 | 9 | Analítico do CT-e |
| E111 | 6 | Ajustes de apuração |
| E110 | 3 | Apuração consolidada do ICMS |
| C170 | 1 | Item do documento |

C100 e C190 dominam com folga. Nenhuma surpresa: são o cabeçalho e o resumo tributário de toda nota fiscal escriturada.

---

## 3. As 4 tabelas propostas

A contagem acima responde "quais são mais usadas". A pergunta de cruzamento é diferente, e a divergência merece ser explicitada.

**Por frequência de uso**, o quarteto seria C100, C190, D100, D190. Mas D100 e D190 são o ramo de **transporte** — 20 rotinas especializadas em CT-e, um assunto lateral para quem audita circulação de mercadoria. Eles aparecem muito porque o crédito de frete gera muita irregularidade, não porque sejam o eixo da base.

**Para análise e cruzamento**, proponho trocar o ramo de transporte pelo eixo vertical que vai do item até a apuração. As quatro tabelas abaixo cobrem o ciclo completo — mercadoria → documento → tributo → imposto a recolher — e é entre elas que estão os cruzamentos de maior retorno.

### 3.1 `fisc.TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL`

**36 colunas. O eixo documental.**

Uma linha por nota fiscal escriturada. Carrega a chave de acesso (`C100_CHV_NFE`, 44 posições) — o identificador que liga esta tabela a todas as outras e às camadas de XML.

Colunas decisivas:
- `C100_IND_OPER` e `C100_IND_EMIT` — separam entrada de saída, emissão própria de terceiros. Quase todo filtro começa aqui.
- `REG0150_CNPJ_PART`, `REG0150_IE_PART` — identificam a contraparte, o que permite cruzamento **entre contribuintes**.
- `C100_COD_SIT` — situação do documento. `varchar(76)` descritivo (`'2 - DOCUMENTO CANCELADO'`), não numérico.
- `C100_VL_DOC`, `C100_VL_MERC`, `C100_VL_FRT`, `C100_VL_ICMS`, `C100_VL_ICMS_ST` — totalizadores.

### 3.2 `fisc.TB_534_PR_EFD_REGISTRO_C190_..._CST_CFOP_ALIQ_ICMS`

**24 colunas. O eixo tributário.**

Várias linhas por nota, uma para cada combinação CST + CFOP + alíquota. É aqui que o imposto aparece na forma em que a apuração o consome.

Colunas decisivas: `C190_CST_ICMS` e `C190_CFOP` (ambas `int`), `C190_ALIQ_ICMS`, `C190_VL_OPR`, `C190_VL_BC_ICMS`, `C190_VL_ICMS`, `C190_VL_RED_BC`.

`C190_VL_RED_BC` é subutilizada e merece atenção: redução de base de cálculo é benefício fiscal, e benefício aplicado fora de hipótese é achado de auditoria com valor alto.

### 3.3 `fisc.TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL`

**45+ colunas. O eixo da mercadoria.**

Uma linha por item. Aparece em **uma única** rotina da Camada 3 — e essa escassez é justamente o argumento para incluí-la.

C170 é a única tabela que carrega `REG0200_COD_NCM` no nível da operação. Sem ela não existe cruzamento com o Anexo 5, com o inventário H010, nem com o cadastro 0200. Toda análise por mercadoria — e não por documento — passa obrigatoriamente por aqui.

Colunas decisivas: `REG0200_COD_NCM`, `REG0200_TIPO_ITEM`, `C170_CST_ICMS` e `C170_CFOP` (`int`), `C170_ALIQ_ICMS`, `C170_VL_ITEM`, `C170_QTD` (`decimal(24,5)`), `C170_VL_ICMS`, `C170_VL_ICMS_ST`.

Cuidado registrado: `REG0200_COD_NCM` é `nvarchar(8)` e pode conter o literal `'-'` no lugar de `NULL`, resquício do `CASE WHEN ... THEN '-'` usado na criação.

### 3.4 `fisc.TB_736_PR_EFD_REGISTRO_E110_APURACAO_ICMS_OPERACOES_PROPRIAS`

**20 colunas. O eixo da apuração.**

Uma linha por contribuinte por período. É a declaração final do imposto — o número que virou (ou não) recolhimento.

Colunas decisivas: `E110_VL_TOT_DEBITOS`, `E110_VL_TOT_CREDITOS`, `E110_VL_AJ_DEBITOS`, `E110_VL_AJ_CREDITOS`, `E110_VL_SLD_CREDOR_ANT`, `E110_VL_SLD_APURADO`, `E110_VL_ICMS_RECOLHER`, `E110_VL_SLD_CREDOR_TRANSPORTAR`.

A inclusão do E110 é o que transforma o conjunto em ciclo fechado. Sem ele, encontra-se divergência documental sem saber se ela chegou a afetar o imposto devido. Com ele, a pergunta "qual o valor do crédito tributário?" tem resposta.

---

## 4. Como as quatro se ligam

```
        TB_736  E110  ── apuração do período
                 │      (REG0_IE + REG0_PERIODO_DECLARACAO)
                 │
        TB_534  C190  ── analítico por CST/CFOP/alíquota
                 │      (C100_CHV_NFE)
                 │
        TB_474  C100  ── documento fiscal
                 │      (C100_CHV_NFE)
                 │
        TB_506  C170  ── item da nota
                        (+ REG0200_COD_NCM → Anexo 5, 0200, H010)
```

**Duas chaves, e só duas.**

`C100_CHV_NFE` liga C100, C170 e C190. É a única ligação segura entre elas: `C100_NUM_DOC + C100_SER` se repete entre contribuintes diferentes e produz produto cartesiano.

`REG0_IE + REG0_PERIODO_DECLARACAO` liga o nível documental ao E110. Note que `REG0_PERIODO_DECLARACAO` é `varchar(25)` no formato `M/AAAA` sem zero à esquerda — `'1/2025'`, `'12/2025'`. Ordenação alfabética dessa coluna coloca outubro antes de fevereiro; converta antes de qualquer comparação cronológica.

**Alerta de granularidade.** C100 : C170 : C190 é 1 : N : M. Juntar as três num único `FROM` e agregar produz fan-out silencioso — cada valor de C190 multiplicado pela quantidade de itens. Agregue cada ramo em CTE separada, na granularidade do documento, antes de juntar.

---

## 5. Cruzamentos propostos

### 5.1 Coerência vertical — C170 → C190 → E110

Percorre o ciclo inteiro em três confrontos encadeados:

1. Soma de `C170_VL_ICMS` por nota × `C190_VL_ICMS` por nota
2. Soma de `C190_VL_ICMS` (CFOP de saída) por período × `E110_VL_TOT_DEBITOS`
3. Soma de `C190_VL_ICMS` (CFOP de entrada) por período × `E110_VL_TOT_CREDITOS`

Cada degrau isola um tipo de erro: o primeiro pega erro de escrituração do item, o segundo e o terceiro pegam erro de transporte para a apuração. Quando os três fecham, a escrituração é internamente consistente — o que não a torna correta, apenas coerente.

### 5.2 Coerência horizontal — mercadoria × regra normativa

C170 fornece o NCM; o Anexo 5 fornece o regime aplicável. É o cruzamento construído no roteiro de carga, e a razão de a C170 estar nesta lista.

Extensão natural: C170 × `TB_418` (0200) para conferir se o CEST declarado no cadastro corresponde ao NCM movimentado.

### 5.3 Coerência entre contribuintes — saída de A × entrada de B

`REG0150_CNPJ_PART` em C100 permite localizar a mesma nota nos dois lados: na escrituração de quem emitiu e na de quem recebeu. Divergência de valor, de CFOP ou ausência de um dos lados é achado forte, porque a prova não depende de interpretação — são duas declarações contraditórias sobre o mesmo fato.

A rotina `TB_132_PR_SAIDAS_COMPARATIVO_POR_DESTINATARIO` já explora isso.

### 5.4 Coerência com o mundo físico — C170 × H010

`TB_802` (H010, inventário) contra o saldo calculado a partir de entradas menos saídas por item em C170. Estoque negativo é impossível: significa saída sem entrada correspondente, ou seja, compra sem nota.

É o cruzamento de maior peso probatório dos quatro, e o mais caro de montar, porque exige tratar unidade de medida (`REG0190_UNID`) e conversões.

---

## 6. Antes de escrever a primeira consulta

**Confira os tipos.** As tabelas da Camada 1 nasceram de `SELECT ... INTO` com expressões `CASE WHEN col IS NULL THEN '-' ELSE col END`. A precedência de tipos do SQL Server resolveu cada caso de um jeito, e o resultado é heterogêneo — colunas numéricas que viraram texto, colunas com `'-'` no lugar de `NULL`, colunas descritivas onde se esperava código.

```sql
SELECT o.name AS tabela, c.name AS coluna, t.name AS tipo, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.types   t ON t.user_type_id = c.user_type_id
WHERE o.schema_id = SCHEMA_ID('fisc')
  AND o.name IN (
      'TB_474_PR_EFD_REGISTRO_C100_IDENTIFICACAO_DOC_FISCAL',
      'TB_506_PR_EFD_REGISTRO_C170_ITEM_DOC_FISCAL',
      'TB_534_PR_EFD_REGISTRO_C190_ANALITICO_DOC_FISCAL_CST_CFOP_ALIQ_ICMS',
      'TB_736_PR_EFD_REGISTRO_E110_APURACAO_ICMS_OPERACOES_PROPRIAS')
ORDER BY o.name, c.column_id;
```

**Verifique a indexação.** Não encontrei índices declarados sobre as quatro tabelas no script. Se isso se confirmar no servidor, `C100_CHV_NFE` e o par `REG0_IE + REG0_PERIODO_DECLARACAO` são os candidatos óbvios — são exatamente as chaves de junção da seção 4.

```sql
SELECT o.name AS tabela, i.name AS indice, i.type_desc
FROM sys.indexes i
JOIN sys.objects o ON o.object_id = i.object_id
WHERE o.schema_id = SCHEMA_ID('fisc')
  AND o.name LIKE 'TB_[45][0-9][0-9]%';
```

**Note o que a Camada 1 não tem.** Nenhuma chave primária, nenhuma chave estrangeira, nenhuma constraint. São tabelas de análise reconstruídas a cada carga, não um modelo transacional. Isso significa que **nada garante** que toda linha de C170 tenha um C100 correspondente — e a consulta que assume isso, com `INNER JOIN`, descarta em silêncio justamente os órfãos que deveriam ser reportados.
