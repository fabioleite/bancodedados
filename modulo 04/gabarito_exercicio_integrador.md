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

```sql
WITH duplicadas AS (
    SELECT
        chave_acesso,
        ROW_NUMBER() OVER (
            PARTITION BY chave_acesso
            ORDER BY (SELECT NULL)
        ) AS ordem_ocorrencia
    FROM stg_nfe_importacao
)
UPDATE d
SET status_validacao = 'INVALIDO',
    motivo_rejeicao = 'Chave de acesso duplicada no lote'
FROM stg_nfe_importacao d
JOIN duplicadas dup
    ON dup.chave_acesso = d.chave_acesso
WHERE dup.ordem_ocorrencia > 1;
```

**Comentário:** como a tabela de staging não possui uma chave primária ou coluna identidade explícita, a CTE usa `ROW_NUMBER() OVER (PARTITION BY chave_acesso ORDER BY (SELECT NULL))` apenas para numerar as ocorrências dentro de cada grupo de `chave_acesso` repetida — a ordem exata entre duplicatas não importa aqui, o que importa é manter uma e marcar as demais. Se a tabela tivesse uma coluna de identidade (`id INT IDENTITY`), o ideal seria ordenar por ela para garantir que a primeira carregada seja sempre a preservada.

> **Variação equivalente:** se preferir manter a explicitamente a *primeira linha carregada*, adicione uma coluna de identidade à tabela de staging antes da carga (`id INT IDENTITY(1,1)`) e troque `ORDER BY (SELECT NULL)` por `ORDER BY id`.

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
