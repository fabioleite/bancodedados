# Roteiro Prático para Auditores — Painel de Inconsistências Fiscais (schema `fisc`)

**Banco de trabalho:** `933000081200000173202662_20260127_104141`
**Schema:** `fisc`
**Tabela escolhida:** `FISC.TB_100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS_01`
**Procedure que a alimenta:** `dbo.[100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS]`
**Origem:** [`SET ANSI_NULLS ON.sql`](SET%20ANSI_NULLS%20ON.sql)

## Por que essa tabela

Dentro do schema `fisc` desse banco existem dezenas de tabelas `TB_<código>_PR_<descrição>`, cada uma o resultado de uma consulta de auditoria fiscal específica (créditos indevidos, saídas sem lançamento, divergências de EFD, CT-e, CIAP, FAIN etc.). A `TB_100` é a única tabela do schema cuja *stored procedure* de criação está disponível por completo no repositório — e é justamente um **painel de triagem**: ela varre a existência e o conteúdo de todas as demais tabelas `PR_1xx` e produz um resumo de uma linha por consulta, indicando se há ou não dado para o auditor analisar. É o ponto de entrada natural do trabalho de campo: em vez de abrir 30+ tabelas uma a uma, o auditor lê primeiro o sumário e prioriza.

## 1. Estrutura da tabela

```sql
CREATE TABLE FISC.TB_100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS_01 (
    NUMERO_CONSULTA    INTEGER      NOT NULL,  -- código do programa de auditoria (101, 111, 133...)
    DESCRICAO_CONSULTA VARCHAR(100) NOT NULL,  -- nome da consulta/tabela de origem
    INFOR_DADOS        NVARCHAR(40) NOT NULL   -- 'CONSULTA CONTEM DADOS PARA ANALISE' ou 'CONSULTA NAO CONTEM DADOS PARA ANALISE'
);
```

Não há chave primária declarada — a tabela é reconstruída (`DROP` + `CREATE`) a cada execução da procedure, então cada rodada reflete o estado atual dos dados carregados no banco.

## 2. Como o sumário é gerado

A procedure `dbo.[100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS]` recebe um parâmetro `@RELATORIO`:

- `@RELATORIO = 99999` → recria a `TB_100` e, para cada uma das ~34 tabelas `PR_1xx`, verifica com `OBJECT_ID(...) IS NOT NULL` se a tabela existe; se existir, conta as linhas (`COUNT(*)`) e insere no sumário se contém ou não dado.
- `@RELATORIO IS NULL` → apenas faz `SELECT * FROM FISC.TB_100_...01 ORDER BY NUMERO_CONSULTA`, ou seja, reaproveita o sumário já gerado.

Execução típica em campo:

```sql
USE [933000081200000173202662_20260127_104141];
GO
EXEC dbo.[100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS] @RELATORIO = 99999; -- gera o sumário
EXEC dbo.[100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS];                   -- só lê o sumário já gerado
```

Alguns códigos (115 e 118) têm **duas tabelas de apoio** (`_01` e `_02`); nesses casos a procedure soma as contagens das duas antes de decidir o status. Isso é pista de que a mesma inconsistência foi originalmente separada em duas consultas complementares (ex.: uma para bens do ativo fixo, outra para consumo).

## 3. Catálogo dos programas de auditoria referenciados

| Código | Descrição | Área fiscal |
|---|---|---|
| 101 | Ausência de apresentação de EFD | Obrigação acessória |
| 102 | Ausência de sequencial dentro da série de NFC-e | Numeração de documentos |
| 103 | Ausência de sequencial dentro da série de NF-e | Numeração de documentos |
| 111 | Entradas lançadas C100 com valor contábil a menor | Entradas / créditos |
| 112 | Entradas lançadas com crédito a maior (C190) | Entradas / créditos |
| 113 | Entrada de nota cancelada lançada como autorizada (C100) | Entradas / créditos |
| 114 | Entradas de notas lançadas em mais de um período (C100) | Entradas / créditos |
| 115 | Apropriação de crédito indevido — uso/consumo x ativo fixo | Entradas / créditos |
| 116–117 | Entradas: créditos de saídas não tributadas — itens para análise / extração selecionada | Entradas / créditos |
| 118 | Entradas: crédito de CT-e com itens de NF-e próprios/terceiros | CT-e |
| 119 | Entradas: crédito de CT-e com frete CIF sobre NF de saída | CT-e |
| 120 | Entradas: crédito de CT-e com itens NF-e próprios/terceiros e substituição tributária | CT-e |
| 121 | Entradas: crédito de CT-e — tomador do frete é outro contribuinte | CT-e |
| 122 | Entradas: crédito de CT-e lançado a maior (D190) | CT-e |
| 123 | Entradas: CT-e cancelado lançado como autorizado (D100) | CT-e |
| 125 | Entradas: crédito E111 (ICMS garantido) x confronto de pagamento | Apuração |
| 126 | Entradas: crédito C190 em CFOP de substituição tributária — mercadoria para revenda | Entradas / créditos |
| 133 | Saídas destinadas a pessoa física com possível vínculo a empresa na Paraíba | Saídas / simulação de PF |
| 134 | Saídas lançadas C190 com débito de ICMS a menor | Saídas / débitos |
| 135 | Saídas lançadas com valor contábil a maior (C100) | Saídas / débitos |
| 136 | Saídas com uso de alíquota interestadual em operação interna | Saídas / débitos |
| 137 | Saídas autorizadas lançadas como canceladas (C100) | Saídas / débitos |
| 138–139 | Saídas: itens para análise / extração de itens selecionados | Saídas / débitos |
| 141 | Saídas CT-e lançadas D190 com débito de ICMS a menor | CT-e |
| 142 | Saída de CT-e autorizado lançado como cancelado (D100) | CT-e |
| 143 | Saída de sucata para indústria com pagamento de ICMS diferido | Saídas / benefício fiscal |
| 144 | Saída de sucata para outra UF com pagamento de ICMS diferido | Saídas / benefício fiscal |
| 151 | Apuração: divergência de transporte de débitos/créditos do E111 para E110 | Apuração EFD |
| 152 | Apuração: divergência de transporte — saldo credor | Apuração EFD |
| 153 | Apuração: divergência de transporte do valor de ICMS (entradas/saídas) para E110 | Apuração EFD |
| 154 | Apuração: créditos de CIAP (E111) sem informação no bloco G | CIAP |
| 156 | Apuração: crédito FAIN com saldo credor em conta corrente | Benefício fiscal (FAIN) |
| 157 | Apuração: valor de recolhimento mínimo — atacadista TARE | Benefício fiscal (TARE) |
| 171 | Falta de lançamento ou divergência de NF na EFD acessória | Obrigação acessória |
| 172 | Falta de lançamento de NF na EFD — obrigação principal, entradas | Obrigação acessória |
| 173 | Falta de lançamento de NF na EFD — obrigação principal, saídas | Obrigação acessória |
| 174 | Falta de lançamento de CT-e (D100) — obrigação principal, saídas | Obrigação acessória |

## 4. Passo a passo do auditor

### Passo 1 — Gerar e ler o sumário

```sql
EXEC dbo.[100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS] @RELATORIO = 99999;

SELECT NUMERO_CONSULTA, DESCRICAO_CONSULTA, INFOR_DADOS
FROM FISC.TB_100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS_01
ORDER BY NUMERO_CONSULTA;
```

### Passo 2 — Priorizar o que tem achado

```sql
SELECT NUMERO_CONSULTA, DESCRICAO_CONSULTA
FROM FISC.TB_100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS_01
WHERE INFOR_DADOS = 'CONSULTA CONTEM DADOS PARA ANALISE'
ORDER BY NUMERO_CONSULTA;
```

Isso reduz o trabalho de campo às tabelas que realmente têm inconsistência — nem toda consulta terá dado em todo período de apuração.

### Passo 3 — Classificar por área antes de aprofundar

```sql
SELECT
    CASE
        WHEN NUMERO_CONSULTA IN (101,171,172,173,174)        THEN 'Obrigação acessória / EFD'
        WHEN NUMERO_CONSULTA IN (102,103)                     THEN 'Numeração de documentos'
        WHEN NUMERO_CONSULTA BETWEEN 118 AND 123               THEN 'CT-e'
        WHEN NUMERO_CONSULTA BETWEEN 111 AND 126               THEN 'Entradas / créditos'
        WHEN NUMERO_CONSULTA BETWEEN 133 AND 144               THEN 'Saídas / débitos'
        WHEN NUMERO_CONSULTA BETWEEN 151 AND 157               THEN 'Apuração / benefício fiscal'
        ELSE 'Outros'
    END AS area_fiscal,
    COUNT(*) AS qtde_consultas,
    SUM(CASE WHEN INFOR_DADOS = 'CONSULTA CONTEM DADOS PARA ANALISE' THEN 1 ELSE 0 END) AS com_achado
FROM FISC.TB_100_PR_SUMARIO_DADOS_CONSULTAS_INCONSISTENCIAS_01
GROUP BY
    CASE
        WHEN NUMERO_CONSULTA IN (101,171,172,173,174)        THEN 'Obrigação acessória / EFD'
        WHEN NUMERO_CONSULTA IN (102,103)                     THEN 'Numeração de documentos'
        WHEN NUMERO_CONSULTA BETWEEN 118 AND 123               THEN 'CT-e'
        WHEN NUMERO_CONSULTA BETWEEN 111 AND 126               THEN 'Entradas / créditos'
        WHEN NUMERO_CONSULTA BETWEEN 133 AND 144               THEN 'Saídas / débitos'
        WHEN NUMERO_CONSULTA BETWEEN 151 AND 157               THEN 'Apuração / benefício fiscal'
        ELSE 'Outros'
    END
ORDER BY com_achado DESC;
```

Ajuda a decidir se a diligência do dia foca em créditos indevidos de entrada, em saídas subfaturadas, ou em obrigação acessória.

### Passo 4 — Drill-down na tabela de detalhe

Para cada código com achado, existe a tabela de detalhe correspondente. Exemplo com o código 133 (saídas para pessoa física com possível vínculo a empresa):

```sql
SELECT TOP 50 *
FROM FISC.TB_133_PR_SAIDAS_DESTINADAS_PESSOA_FISICA_COM_POSSIBILIDADE_DE_VINCULACAO_A_EMPRESA_NA_PARAIBA_01;
```

Regra prática: o nome da tabela de detalhe é sempre `FISC.TB_<mesmo número>_<mesma descrição da linha do sumário>_01` (e `_02` quando o código tiver duas partes, como 115 e 118).

### Passo 5 — Registrar o achado

Para cada consulta com `'CONSULTA CONTEM DADOS PARA ANALISE'`, documentar: quantidade de registros, contribuinte(s) envolvido(s), período de apuração e valor estimado de ICMS em risco — informação que normalmente já está nas colunas `VL_*` de cada tabela de detalhe.

## 5. Exercício de revisão de qualidade — "auditando o próprio painel"

Antes de confiar no sumário, vale a pena revisar a procedure com o mesmo rigor que se audita o contribuinte. O script contém pelo menos duas inconsistências reais, boas para prática de leitura crítica de código:

1. **Linha ~169** — no ramo `ELSE` do código 126, quando a tabela `FISC.TB_126_...` não existe, a procedure insere `SELECT 125, '126_PR_ENTRADAS_CREDITO_C190_...'` — usa o número **125** com a descrição do código **126** (erro de copiar/colar). Resultado: o sumário pode reportar duas linhas com `NUMERO_CONSULTA = 125` e nenhuma com `126` nesse cenário.
2. **Linha ~509** — no bloco do código 154, a existência é verificada na tabela `..._01`, mas a contagem é feita na tabela `..._02` (`SELECT COUNT(*) FROM FISC.TB_154_..._02 WHERE ALERTA_CIAP = 'POSSIVEL CREDITO DO CIAP'`). Se `_01` existir mas `_02` não, a consulta falha ou usa uma tabela que não foi validada.

**Tarefa para o auditor/DBA:** localizar esses dois trechos em [`SET ANSI_NULLS ON.sql`](SET%20ANSI_NULLS%20ON.sql), explicar por escrito o impacto de cada um sobre a confiabilidade do sumário, e propor a correção (`SELECT 126, ...` no primeiro caso; alinhar tabela verificada e tabela consultada no segundo).

## 6. Entrega

1. Print da execução do Passo 1 (sumário completo ordenado por `NUMERO_CONSULTA`).
2. Lista priorizada do Passo 2, com pelo menos 3 códigos aprofundados via Passo 4.
3. Tabela do Passo 3 (contagem de achados por área fiscal).
4. Relato por escrito dos dois bugs do item 5, com a correção proposta em SQL.
