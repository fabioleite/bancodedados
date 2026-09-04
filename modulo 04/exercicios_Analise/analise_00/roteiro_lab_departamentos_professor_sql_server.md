# Roteiro de Laboratorio - Gabarito do Professor (SQL Server)

## Tema
Views de folha salarial, trigger de integridade e procedure de cadastro no schema `departamentos`.

## Ordem recomendada de execucao em aula
1. Restaurar base (estrutura e dados).
2. Resolver Questao 1 (view por departamento).
3. Resolver Questao 2 (view por divisao).
4. Resolver Questao 3 (trigger de integridade).
5. Resolver Questao 4 (procedure de cadastro).
6. Executar testes finais integrados.

---

## Preparacao do ambiente

```sql
-- Conferencia basica de dados
SELECT 'departamento' AS tabela, COUNT(*) AS qtd FROM departamentos.departamento
UNION ALL
SELECT 'divisao', COUNT(*) FROM departamentos.divisao
UNION ALL
SELECT 'empregado', COUNT(*) FROM departamentos.empregado
UNION ALL
SELECT 'empregado_vencimento', COUNT(*) FROM departamentos.empregado_vencimento
UNION ALL
SELECT 'empregado_desconto', COUNT(*) FROM departamentos.empregado_desconto;
```

---

## Questao 1 - View de salarios agregados por departamento

Observacao didatica: nao existe chave estrangeira direta de `empregado` para `departamento`.
O relacionamento correto para agregacao e `empregado -> divisao -> departamento`.

```sql
CREATE OR ALTER VIEW departamentos.vw_salarios_departamento
AS
WITH venc_por_emp AS (
    SELECT
        ev.id_empregado,
        SUM(v.valor) AS total_vencimentos
    FROM departamentos.empregado_vencimento ev
    JOIN departamentos.vencimento v
      ON v.id_vencimento = ev.id_vencimento
    GROUP BY ev.id_empregado
),
desc_por_emp AS (
    SELECT
        ed.id_empregado,
        SUM(d.valor) AS total_descontos
    FROM departamentos.empregado_desconto ed
    JOIN departamentos.desconto d
      ON d.id_desconto = ed.id_desconto
    GROUP BY ed.id_empregado
),
salario_emp AS (
    SELECT
        e.id_empregado,
        dv.id_departamento,
        ISNULL(vpe.total_vencimentos, 0) AS salario_bruto,
        ISNULL(dpe.total_descontos, 0) AS total_descontos,
        ISNULL(vpe.total_vencimentos, 0) - ISNULL(dpe.total_descontos, 0) AS salario_liquido
    FROM departamentos.empregado e
    JOIN departamentos.divisao dv
      ON dv.id_divisao = e.id_divisao
    LEFT JOIN venc_por_emp vpe
      ON vpe.id_empregado = e.id_empregado
    LEFT JOIN desc_por_emp dpe
      ON dpe.id_empregado = e.id_empregado
)
SELECT
    d.id_departamento,
    d.nome AS departamento,
    ROUND(SUM(se.salario_bruto), 2) AS total_salario_bruto,
    ROUND(SUM(se.salario_liquido), 2) AS total_salario_liquido,
    ROUND(AVG(se.salario_liquido), 2) AS media_salarial,
    COUNT(*) AS quantidade_empregados
FROM salario_emp se
JOIN departamentos.departamento d
  ON d.id_departamento = se.id_departamento
GROUP BY d.id_departamento, d.nome;
GO
```

Teste:

```sql
SELECT *
FROM departamentos.vw_salarios_departamento
ORDER BY id_departamento;
```

---

## Questao 2 - View de salarios agregados por divisao

```sql
CREATE OR ALTER VIEW departamentos.vw_salarios_divisao
AS
WITH venc_por_emp AS (
    SELECT
        ev.id_empregado,
        SUM(v.valor) AS total_vencimentos
    FROM departamentos.empregado_vencimento ev
    JOIN departamentos.vencimento v
      ON v.id_vencimento = ev.id_vencimento
    GROUP BY ev.id_empregado
),
desc_por_emp AS (
    SELECT
        ed.id_empregado,
        SUM(d.valor) AS total_descontos
    FROM departamentos.empregado_desconto ed
    JOIN departamentos.desconto d
      ON d.id_desconto = ed.id_desconto
    GROUP BY ed.id_empregado
),
salario_emp AS (
    SELECT
        e.id_empregado,
        e.id_divisao,
        ISNULL(vpe.total_vencimentos, 0) AS salario_bruto,
        ISNULL(dpe.total_descontos, 0) AS total_descontos,
        ISNULL(vpe.total_vencimentos, 0) - ISNULL(dpe.total_descontos, 0) AS salario_liquido
    FROM departamentos.empregado e
    LEFT JOIN venc_por_emp vpe
      ON vpe.id_empregado = e.id_empregado
    LEFT JOIN desc_por_emp dpe
      ON dpe.id_empregado = e.id_empregado
)
SELECT
    dv.id_divisao,
    dv.nome AS divisao,
    dv.id_departamento,
    ROUND(SUM(se.salario_bruto), 2) AS total_salario_bruto,
    ROUND(SUM(se.salario_liquido), 2) AS total_salario_liquido,
    ROUND(AVG(se.salario_liquido), 2) AS media_salarial,
    COUNT(*) AS quantidade_empregados
FROM salario_emp se
JOIN departamentos.divisao dv
  ON dv.id_divisao = se.id_divisao
GROUP BY dv.id_divisao, dv.nome, dv.id_departamento;
GO
```

Teste:

```sql
SELECT *
FROM departamentos.vw_salarios_divisao
ORDER BY id_divisao;
```

---

## Questao 3 - Trigger de integridade

### Regra
Nao permitir que departamento fique sem divisao.

### Solucao
- Trigger em `departamento` para criar divisao default no insert.
- Trigger em `divisao` para repor divisao default quando a ultima divisao for removida/movida.

```sql
CREATE OR ALTER TRIGGER departamentos.trg_departamento_cria_divisao_default
ON departamentos.departamento
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO departamentos.divisao (
        nome,
        id_departamento,
        id_chefe,
        endereco_rua,
        endereco_numero,
        endereco_bairro,
        endereco_cidade,
        endereco_cep,
        endereco_uf
    )
    SELECT
        CONCAT('Divisao Default - Depto ', i.id_departamento),
        i.id_departamento,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    FROM inserted i;
END;
GO
```

```sql
CREATE OR ALTER TRIGGER departamentos.trg_divisao_garante_minimo_uma_por_departamento
ON departamentos.divisao
AFTER DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH dept_afetado AS (
        SELECT d.id_departamento
        FROM deleted d
        LEFT JOIN inserted i
          ON i.id_divisao = d.id_divisao
        WHERE i.id_divisao IS NULL
           OR i.id_departamento <> d.id_departamento
    )
    INSERT INTO departamentos.divisao (
        nome,
        id_departamento,
        id_chefe,
        endereco_rua,
        endereco_numero,
        endereco_bairro,
        endereco_cidade,
        endereco_cep,
        endereco_uf
    )
    SELECT
        CONCAT('Divisao Default - Depto ', da.id_departamento),
        da.id_departamento,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    FROM (
        SELECT DISTINCT id_departamento
        FROM dept_afetado
        WHERE id_departamento IS NOT NULL
    ) da
    WHERE NOT EXISTS (
        SELECT 1
        FROM departamentos.divisao dv
        WHERE dv.id_departamento = da.id_departamento
    );
END;
GO
```

Testes sugeridos:

```sql
-- 1) Insert de departamento: deve gerar divisao default
INSERT INTO departamentos.departamento (nome, data_inicio_gestao)
VALUES ('Departamento Teste Integridade', CAST(GETDATE() AS DATE));

SELECT TOP 1 id_departamento
FROM departamentos.departamento
WHERE nome = 'Departamento Teste Integridade'
ORDER BY id_departamento DESC;

SELECT d.id_departamento, d.nome AS departamento, dv.id_divisao, dv.nome AS divisao
FROM departamentos.departamento d
LEFT JOIN departamentos.divisao dv
  ON dv.id_departamento = d.id_departamento
WHERE d.nome = 'Departamento Teste Integridade';
```

```sql
-- 2) Remocao da unica divisao de um departamento: trigger deve repor
DELETE FROM departamentos.divisao
WHERE id_departamento = (
    SELECT TOP 1 id_departamento
    FROM departamentos.departamento
    WHERE nome = 'Departamento Teste Integridade'
    ORDER BY id_departamento DESC
);

SELECT d.id_departamento, d.nome AS departamento, dv.id_divisao, dv.nome AS divisao
FROM departamentos.departamento d
JOIN departamentos.divisao dv
  ON dv.id_departamento = d.id_departamento
WHERE d.nome = 'Departamento Teste Integridade';
```

---

## Questao 4 - Procedure para inserir empregado com base + INSS

```sql
CREATE OR ALTER PROCEDURE departamentos.prc_inserir_empregado_com_base_inss
    @p_matricula       VARCHAR(20),
    @p_nome            VARCHAR(150),
    @p_cpf             CHAR(11),
    @p_endereco_rua    VARCHAR(150),
    @p_endereco_numero VARCHAR(4),
    @p_endereco_bairro VARCHAR(100),
    @p_endereco_cidade VARCHAR(100),
    @p_endereco_cep    CHAR(8),
    @p_endereco_uf     CHAR(2),
    @p_id_divisao      INT,
    @p_data_lotacao    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_id_empregado INT;
    DECLARE @v_id_venc_base INT;
    DECLARE @v_id_desc_inss INT;

    SELECT TOP 1 @v_id_venc_base = v.id_vencimento
    FROM departamentos.vencimento v
    WHERE v.nome = 'Salario Base' OR v.tipo = 'Salario'
    ORDER BY CASE WHEN v.nome = 'Salario Base' THEN 0 ELSE 1 END, v.id_vencimento;

    IF @v_id_venc_base IS NULL
    BEGIN
        THROW 50001, 'Vencimento base nao encontrado.', 1;
    END;

    SELECT TOP 1 @v_id_desc_inss = d.id_desconto
    FROM departamentos.desconto d
    WHERE d.nome = 'Contribuicao INSS' OR d.tipo = 'INSS'
    ORDER BY CASE WHEN d.nome = 'Contribuicao INSS' THEN 0 ELSE 1 END, d.id_desconto;

    IF @v_id_desc_inss IS NULL
    BEGIN
        THROW 50002, 'Desconto INSS nao encontrado.', 1;
    END;

    INSERT INTO departamentos.empregado (
        matricula,
        nome,
        cpf,
        endereco_rua,
        endereco_numero,
        endereco_bairro,
        endereco_cidade,
        endereco_cep,
        endereco_uf,
        data_lotacao,
        id_divisao
    )
    VALUES (
        @p_matricula,
        @p_nome,
        @p_cpf,
        @p_endereco_rua,
        @p_endereco_numero,
        @p_endereco_bairro,
        @p_endereco_cidade,
        @p_endereco_cep,
        @p_endereco_uf,
        ISNULL(@p_data_lotacao, CAST(GETDATE() AS DATE)),
        @p_id_divisao
    );

    SET @v_id_empregado = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO departamentos.empregado_vencimento (id_empregado, id_vencimento)
    VALUES (@v_id_empregado, @v_id_venc_base);

    INSERT INTO departamentos.empregado_desconto (id_empregado, id_desconto)
    VALUES (@v_id_empregado, @v_id_desc_inss);
END;
GO
```

Teste:

```sql
EXEC departamentos.prc_inserir_empregado_com_base_inss
    @p_matricula = '008',
    @p_nome = 'Aluno Teste',
    @p_cpf = '88888888888',
    @p_endereco_rua = 'Rua H',
    @p_endereco_numero = '10',
    @p_endereco_bairro = 'Centro',
    @p_endereco_cidade = 'Cuite',
    @p_endereco_cep = '58043000',
    @p_endereco_uf = 'PB',
    @p_id_divisao = 1,
    @p_data_lotacao = CAST(GETDATE() AS DATE);

SELECT e.id_empregado, e.nome, e.matricula, v.nome AS vencimento, d.nome AS desconto
FROM departamentos.empregado e
LEFT JOIN departamentos.empregado_vencimento ev ON ev.id_empregado = e.id_empregado
LEFT JOIN departamentos.vencimento v ON v.id_vencimento = ev.id_vencimento
LEFT JOIN departamentos.empregado_desconto ed ON ed.id_empregado = e.id_empregado
LEFT JOIN departamentos.desconto d ON d.id_desconto = ed.id_desconto
WHERE e.matricula = '008';
```

---

## Encerramento da aula
Checklist de avaliacao:
- View por departamento criada e retornando valores coerentes.
- View por divisao criada e retornando valores coerentes.
- Trigger(s) de integridade ativos e testados.
- Procedure funcional com insercao do empregado e vinculos automaticos.
- Consultas de validacao executadas com evidencias.
