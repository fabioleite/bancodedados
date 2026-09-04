# Gabarito — Exercício Integrador (Carga de Dados, ALTER TABLE e UPDATE)

**Referência:** `exercicio_integrador.md`
**Banco:** `curso_integridade_fiscal`

> Este gabarito apresenta uma solução de referência para cada item. Em alguns exercícios (especialmente os de nível desafio), existe mais de um caminho correto — o importante é que o resultado final produza a mesma classificação dos registros.

---

## Parte 2 — ALTER TABLE

### 6.1

```sql
ALTER TABLE stg_nfe_importacao ADD status_validacao      VARCHAR(10) NOT NULL DEFAULT 'PENDENTE';
ALTER TABLE stg_nfe_importacao ADD motivo_rejeicao       VARCHAR(200) NULL;
ALTER TABLE stg_nfe_importacao ADD data_analise          DATE NULL;
ALTER TABLE stg_nfe_importacao ADD auditor_responsavel   VARCHAR(150) NULL;
```

**Comentário:** `status_validacao` recebe `NOT NULL DEFAULT 'PENDENTE'` porque todo registro precisa nascer com um status definido — não faz sentido um registro sem classificação. As demais colunas são naturalmente nulas até que a análise ocorra.

### 6.2

```sql
ALTER TABLE stg_nfe_importacao ADD valor_total_num DECIMAL(15,2) NULL;
ALTER TABLE stg_nfe_importacao ADD data_emissao_dt DATE NULL;
```

### 6.3

```sql
ALTER TABLE stg_nfe_importacao
ADD CONSTRAINT ck_status_validacao
CHECK (status_validacao IN ('PENDENTE', 'VALIDO', 'INVALIDO'));
```

**Comentário:** como a coluna já existe com dados (`'PENDENTE'` em todas as linhas neste momento), a constraint pode ser adicionada normalmente, pois nenhum valor existente viola a regra. Se a coluna já tivesse valores fora da lista, seria necessário corrigi-los antes, ou usar `WITH NOCHECK` (não recomendado em ambiente de produção fiscal, pois permite dados inconsistentes).

---

## Parte 3 — UPDATE

### 7.1

```sql
UPDATE stg_nfe_importacao
SET status_validacao = 'INVALIDO',
    motivo_rejeicao = 'CNPJ com formato invalido'
WHERE LEN(cnpj_emitente) <> 14;
```

### 7.2

```sql
UPDATE stg_nfe_importacao
SET status_validacao = 'INVALIDO',
    motivo_rejeicao = 'Valor total zerado ou negativo'
WHERE TRY_CONVERT(DECIMAL(15,2), valor_total) <= 0;
```

**Comentário:** usar `TRY_CONVERT` em vez de `CONVERT` evita que a instrução falhe caso `valor_total` contenha algo não numérico — ele simplesmente retorna `NULL`, e a comparação `NULL <= 0` é falsa, então essas linhas não seriam pegas por este `WHERE`. Isso é intencional: registros com valor não numérico já não existem neste lote, mas a prática é uma boa defesa geral.

### 7.3

```sql
UPDATE stg_nfe_importacao
SET valor_total_num = TRY_CONVERT(DECIMAL(15,2), valor_total)
WHERE status_validacao <> 'INVALIDO'
  AND TRY_CONVERT(DECIMAL(15,2), valor_total) > 0;
```

### 7.4

```sql
UPDATE stg_nfe_importacao
SET data_emissao_dt = TRY_CONVERT(DATE, data_emissao, 23)
WHERE status_validacao <> 'INVALIDO';

UPDATE stg_nfe_importacao
SET status_validacao = 'INVALIDO',
    motivo_rejeicao = 'Data de emissao invalida'
WHERE status_validacao <> 'INVALIDO'
  AND data_emissao_dt IS NULL;
```

**Comentário:** o estilo `23` em `TRY_CONVERT(DATE, data_emissao, 23)` corresponde ao formato ISO `AAAA-MM-DD`, que é o formato em que as datas válidas do arquivo foram gravadas. Datas como `'32/13/2026'` não correspondem a esse padrão nem a uma data real, então a conversão retorna `NULL`.

### 7.5

```sql
UPDATE stg_nfe_importacao
SET status_validacao = 'INVALIDO',
    motivo_rejeicao = 'CFOP fora da tabela de codigos validos'
WHERE status_validacao <> 'INVALIDO'
  AND cfop NOT IN ('5101','5102','5405','5949','6101','6102','6108','6403');
```

### 7.6

Esta solução evita CTE, `JOIN` e `ROW_NUMBER()`, usando apenas construções já vistas nos módulos anteriores: `ALTER TABLE`, agregação (`GROUP BY`/`HAVING`/`MIN`) e subconsulta. O preço é precisar de uma coluna que sirva de critério de ordem — a tabela de staging não tem chave primária nem identidade, e sem alguma coluna assim não há como distinguir "a primeira ocorrência" de qualquer outra.

**Passo 1 — criar uma coluna de identidade para estabelecer uma ordem.** Ao ser adicionada a uma tabela já populada, a `IDENTITY` preenche automaticamente cada linha existente com um número sequencial:

```sql
ALTER TABLE stg_nfe_importacao
ADD id_linha INT IDENTITY(1,1);
```

**Passo 2 — conferir, com um SELECT simples, quais chaves estão duplicadas e qual `id_linha` deve ser preservado.** Antes de atualizar qualquer coisa, vale enxergar o que será considerado "a primeira ocorrência": o menor `id_linha` dentro de cada grupo de `chave_acesso` repetida.

```sql
SELECT chave_acesso,
       MIN(id_linha)   AS primeira_ocorrencia,
       COUNT(*)        AS qtd_ocorrencias
FROM stg_nfe_importacao
GROUP BY chave_acesso
HAVING COUNT(*) > 1;
```

**Passo 3 — atualizar tudo o que não for a primeira ocorrência de cada chave.** O `UPDATE` faz, em uma única instrução, o que o `SELECT` do passo 2 revelou: marcar como inválida toda linha cujo `id_linha` não seja o menor do seu grupo.

```sql
UPDATE stg_nfe_importacao
SET status_validacao = 'INVALIDO',
    motivo_rejeicao = 'Chave de acesso duplicada no lote'
WHERE id_linha NOT IN (
    SELECT MIN(id_linha)
    FROM stg_nfe_importacao
    GROUP BY chave_acesso
);
```

**Comentário:** a subconsulta `SELECT MIN(id_linha) FROM stg_nfe_importacao GROUP BY chave_acesso` devolve, para cada `chave_acesso` (repetida ou não), o menor `id_linha` do grupo — a lista de "linhas para preservar". O `UPDATE` marca como inválida qualquer linha cujo `id_linha` não esteja nessa lista. Chaves sem duplicata também aparecem na subconsulta (seu único `id_linha` já é o mínimo de um grupo de um elemento só), o que automaticamente as protege de serem marcadas, sem precisar de nenhum filtro adicional para tratá-las à parte.

> **Por que o `NOT IN` é seguro aqui.** A armadilha clássica do `NOT IN` é quando a lista retornada pela subconsulta contém `NULL` — nesse caso a condição inteira deixa de retornar qualquer linha. Isso não acontece aqui porque `id_linha` é uma coluna `IDENTITY`, que nunca é nula; logo `MIN(id_linha)` também nunca é nulo, e o `NOT IN` funciona normalmente.

> **Diferença em relação à versão com CTE e `ROW_NUMBER()`.** A versão com `ROW_NUMBER() OVER (PARTITION BY chave_acesso ORDER BY ...)` numera cada linha dentro do seu grupo (1ª, 2ª, 3ª ocorrência...) e descarta tudo que não for a 1ª — é mais flexível (dispensa uma coluna de ordem física) e mais eficiente em tabelas grandes, mas exige dominar função de janela, CTE e junção. A versão com `GROUP BY` + `MIN()` + `NOT IN` chega ao mesmo resultado com construções mais básicas, ao custo de precisar criar antes uma coluna que sirva de critério de ordem.

### 7.7

```sql
UPDATE stg_nfe_importacao
SET status_validacao = 'VALIDO',
    data_analise = GETDATE(),
    auditor_responsavel = 'Auditoria Automatizada - Triagem Inicial'
WHERE status_validacao = 'PENDENTE';
```

**Comentário:** a condição `WHERE status_validacao = 'PENDENTE'` é a peça-chave deste passo: todos os registros que não foram marcados como `'INVALIDO'` em nenhum dos passos anteriores (7.1 a 7.6) ainda estão com o valor padrão `'PENDENTE'` definido em 6.1. Isso evita ter que repetir manualmente todas as condições de validação — basta aproveitar o que já foi filtrado nos passos anteriores.

### 7.8

```sql
SELECT
    status_validacao,
    motivo_rejeicao,
    COUNT(*) AS quantidade
FROM stg_nfe_importacao
GROUP BY status_validacao, motivo_rejeicao
ORDER BY status_validacao, quantidade DESC;
```

**Comentário:** agrupar por `status_validacao` e `motivo_rejeicao` ao mesmo tempo produz automaticamente o resumo pedido: para `status_validacao = 'VALIDO'`, `motivo_rejeicao` será `NULL` numa única linha (contagem total de válidos); para `'INVALIDO'`, o resultado se abre em uma linha por motivo, permitindo visualizar qual regra de negócio mais rejeitou registros no lote — informação valiosa para um auditor entender a qualidade geral dos dados recebidos.

---

## Verificação final sugerida

Após rodar todos os passos, nenhum registro deve permanecer com `status_validacao = 'PENDENTE'`:

```sql
SELECT COUNT(*) AS pendentes_restantes
FROM stg_nfe_importacao
WHERE status_validacao = 'PENDENTE';
-- Resultado esperado: 0
```

Se esse resultado não for zero, é sinal de que algum registro não se encaixou em nenhuma regra de invalidação nem foi coberto pelo passo 7.7 — vale revisar as condições `WHERE` aplicadas.
