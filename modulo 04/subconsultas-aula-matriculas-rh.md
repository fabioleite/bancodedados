# Subconsultas em T-SQL — Aula (exemplos: matrículas acadêmicas e RH/projetos)

> Mesma trilha de conceitos de [subconsultas-aula.md](subconsultas-aula.md), com exemplos trocados para dois domínios: sistema de matrículas universitárias e gestão de funcionários/projetos (salário calculado pelas horas de participação).

**Pré-requisito:** `SELECT`, `JOIN`, `GROUP BY`/`HAVING`.

**Esquema de referência:**

```
academico.aluno(id_aluno, nome, curso)
academico.disciplina(id_disciplina, nome, carga_horaria)
academico.matricula(id_matricula, id_aluno, id_disciplina, periodo, situacao, nota_final)
                     -- situacao: 'ATIVA' | 'APROVADO' | 'CANCELADA'

rh.departamento(id_departamento, nome)
rh.funcionario(id_funcionario, nome, id_departamento, valor_hora)
rh.projeto(id_projeto, nome, id_departamento)
rh.participacao_projeto(id_funcionario, id_projeto, horas_trabalhadas)
                     -- salário do funcionário = SUM(horas_trabalhadas * valor_hora)
```

---

## 1. O que é uma subconsulta

```sql
SELECT nome
FROM academico.aluno
WHERE id_aluno IN (
    SELECT m.id_aluno
    FROM academico.matricula AS m
    JOIN academico.disciplina AS d ON d.id_disciplina = m.id_disciplina
    WHERE d.carga_horaria > 80
);
```

- **Consulta externa** filtra usando o resultado da **consulta interna**.
- Sempre entre `( )`. Não aceita `ORDER BY` (exceto com `TOP`).

---

## 2. Duas classificações rápidas

| Retorno | Exemplo de uso |
|---|---|
| **Escalar** (1 linha, 1 coluna) | após `=`, `>`, em `SELECT`/`SET` |
| **Tabela** (N linhas/colunas) | em `FROM`, com `IN`/`EXISTS` |

| Dependência | Característica |
|---|---|
| **Independente** | roda uma vez, não olha a linha externa |
| **Correlacionada** | referencia coluna da consulta externa — "reavaliada por linha" |

---

## 3. Escalar — cuidado com "mais de 1 linha"

```sql
SELECT nome
FROM rh.funcionario
WHERE id_funcionario = (
    SELECT TOP (1) id_funcionario
    FROM rh.participacao_projeto
    ORDER BY horas_trabalhadas DESC
);
```

Sem `TOP (1)` + `ORDER BY` determinístico, o SQL Server lança erro se vier mais de uma linha.

---

## 4. `IN` / `NOT IN`

```sql
-- alunos com alguma matrícula cancelada
WHERE id_aluno IN (
    SELECT id_aluno FROM academico.matricula
    WHERE situacao = 'CANCELADA'
);

-- alunos que NUNCA tiveram matrícula cancelada
WHERE id_aluno NOT IN (
    SELECT id_aluno FROM academico.matricula
    WHERE situacao = 'CANCELADA'
);
```

⚠️ **Guardar para a seção 7 — a armadilha do `NOT IN` com `NULL`.**

---

## 5. `EXISTS` / `NOT EXISTS` (a forma recomendada)

```sql
SELECT a.nome
FROM academico.aluno AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM academico.matricula AS m
    WHERE m.id_aluno = a.id_aluno
      AND m.situacao = 'CANCELADA'
);
```

- Testa só **se existe linha** — `SELECT 1` é convenção, sem custo extra.
- É **correlacionada** (usa `a.id_aluno` da linha externa).
- **Imune** ao problema de `NULL` que afeta `NOT IN`.

---

## 6. Correlacionada — exemplo direto (horas → salário)

```sql
SELECT
    f.nome,
    (SELECT SUM(pp.horas_trabalhadas)
     FROM rh.participacao_projeto AS pp
     WHERE pp.id_funcionario = f.id_funcionario) AS total_horas
FROM rh.funcionario AS f;
```

A subconsulta não roda sozinha: depende de `f.id_funcionario`, que muda a cada linha. É a base para calcular o salário (`total_horas * valor_hora`).

---

## 7. ⚠️ A armadilha do `NOT IN` com `NULL`

```sql
-- Suponha que projeto.id_departamento aceite NULL
-- (projeto multidepartamental criado antes da definição do responsável)
SELECT nome
FROM rh.departamento
WHERE id_departamento NOT IN (
    SELECT id_departamento FROM rh.projeto
);
```

Se **um único** `NULL` aparecer em `projeto.id_departamento`, a consulta **não retorna nenhuma linha** — mesmo havendo departamentos claramente sem projeto. Motivo: `NOT IN` vira uma cadeia de `AND (valor <> x)`, e `valor <> NULL` é `UNKNOWN`.

**Correção (regra prática da equipe): use `NOT EXISTS`.**

```sql
WHERE NOT EXISTS (
    SELECT 1 FROM rh.projeto AS p
    WHERE p.id_departamento = rh.departamento.id_departamento
);
```

---

## 8. `FROM` (derived table) — folha de pagamento por departamento

```sql
SELECT resumo.id_departamento, resumo.total_folha
FROM (
    SELECT
        f.id_departamento,
        SUM(pp.horas_trabalhadas * f.valor_hora) AS total_folha
    FROM rh.funcionario AS f
    JOIN rh.participacao_projeto AS pp ON pp.id_funcionario = f.id_funcionario
    GROUP BY f.id_departamento
) AS resumo                         -- alias obrigatório
WHERE resumo.total_folha > 50000;
```

Alias é **obrigatório**. Útil para filtrar/reagrupar um resultado já agregado (aqui, o custo de horas já convertido em salário).

---

## 9. `APPLY` — quando a subconsulta correlacionada precisa de várias linhas

```sql
SELECT f.nome, top3.nome AS projeto, top3.horas_trabalhadas
FROM rh.funcionario AS f
CROSS APPLY (
    SELECT TOP (3) p.nome, pp.horas_trabalhadas
    FROM rh.participacao_projeto AS pp
    JOIN rh.projeto AS p ON p.id_projeto = pp.id_projeto
    WHERE pp.id_funcionario = f.id_funcionario
    ORDER BY pp.horas_trabalhadas DESC
) AS top3;
```

Para **cada funcionário**, traz os **3 projetos com mais horas trabalhadas** — impossível com subconsulta escalar tradicional.

| | Sem linhas na subconsulta |
|---|---|
| `CROSS APPLY` | descarta a linha externa (como `INNER JOIN`) — funcionário sem projeto some do resultado |
| `OUTER APPLY` | mantém, com `NULL` (como `LEFT JOIN`) — funcionário sem projeto aparece mesmo assim |

---

## 10. Regra prática: subconsulta x JOIN x CTE

- **"Existe?"** (aluno está matriculado? funcionário está em algum projeto?) → `EXISTS`/`NOT EXISTS`.
- **Preciso trazer colunas da outra tabela** (nome da disciplina, nome do projeto) → `JOIN`.
- **Vou reaproveitar o mesmo resultado intermediário várias vezes, ou preciso de recursão** (ex.: hierarquia de departamentos) → CTE (`WITH`).
- **Mais de 2–3 níveis de subconsulta aninhada** → decompor em CTE.

---

## 11. Exercícios rápidos (para praticar em aula)

1. Liste alunos matriculados em disciplinas com `carga_horaria > 80`, usando `IN`.
2. Reescreva o exercício 1 com `EXISTS` (correlacionada).
3. Liste funcionários que nunca participaram de nenhum projeto, usando `NOT EXISTS`.
4. Use `CROSS APPLY` para trazer os 2 projetos com mais horas de cada funcionário.
5. **Demonstração ao vivo:** monte um `NOT IN` com `NULL` em `projeto.id_departamento` e mostre o resultado vazio; corrija com `NOT EXISTS`.
6. Calcule, com subconsulta correlacionada no `SELECT`, o salário de cada funcionário (`total_horas * valor_hora`).
