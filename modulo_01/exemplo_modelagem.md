# Exemplo de Banco de Dados

## Tabela 1-1 — Departamentos

| cod_departamento | nome_departamento | localização |
|------------------|-------------------|-------------|
| d1 | Pesquisa | Dallas |
| d2 | Contabilidade | Seattle |
| d3 | Marketing | Dallas |

---

## Tabela 1-2 — Funcionários

| matrícula | primeiro_nome | sobrenome | cod_departamento |
|-----------|---------------|-----------|------------------|
| 25348 | Matthew | Smith | d3 |
| 10102 | Ann | Jones | d3 |
| 18316 | John | Barrimore | d1 |
| 29346 | James | James | d2 |
| 2581 | Elke | Hansel | d2 |
| 9031 | Elsa | Bertoni | d2 |
| 28559 | Sybill | Moser | d1 |

---

## Tabela 1-3 — Projetos

| cod_projeto | nome_projeto | orçamento |
|-------------|--------------|-----------:|
| P1 | Apollo | 120000 |
| P2 | Gemini | 95000 |
| P3 | Mercury | 186500 |

---

## Tabela 1-4 — Alocação de Funcionários em Projetos

| matrícula | cod_projeto | função | data_entrada |
|-----------|-------------|--------|--------------|
| 10102 | P1 | Analista | 2016-10-01 |
| 10102 | P3 | Gerente | 2018-01-01 |
| 25348 | P2 | Auxiliar | 2017-02-15 |
| 18316 | P2 | NULL | 2017-06-01 |
| 29346 | P2 | NULL | 2016-12-15 |
| 2581 | P3 | Analista | 2017-10-15 |
| 9031 | P1 | Gerente | 2017-04-15 |
| 28559 | P1 | NULL | 2017-08-01 |
| 28559 | P2 | Auxiliar | 2018-02-01 |
| 9031 | P3 | Auxiliar | 2016-11-15 |
| 29346 | P1 | Auxiliar | 2017-01-04 |
