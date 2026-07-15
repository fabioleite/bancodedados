# Exemplo de Banco de Dados

## Table 1-1 — Department Table

| dept_no | dept_name  | location |
|---------|------------|----------|
| d1 | Research | Dallas |
| d2 | Accounting | Seattle |
| d3 | Marketing | Dallas |

---

## Table 1-2 — Employee Table

| emp_no | emp_fname | emp_lname | dept_no |
|--------|-----------|-----------|---------|
| 25348 | Matthew | Smith | d3 |
| 10102 | Ann | Jones | d3 |
| 18316 | John | Barrimore | d1 |
| 29346 | James | James | d2 |
| 2581 | Elke | Hansel | d2 |
| 9031 | Elsa | Bertoni | d2 |
| 28559 | Sybill | Moser | d1 |

---

## Table 1-3 — Project Table

| project_no | project_name | budget |
|------------|--------------|--------:|
| P1 | Apollo | 120000 |
| P2 | Gemini | 95000 |
| P3 | Mercury | 186500 |

---

## Table 1-4 — Employee Project Assignment

| emp_no | project_no | job | enter_date |
|--------|------------|----------|------------|
| 10102 | P1 | Analyst | 2016-10-01 |
| 10102 | P3 | Manager | 2018-01-01 |
| 25348 | P2 | Clerk | 2017-02-15 |
| 18316 | P2 | NULL | 2017-06-01 |
| 29346 | P2 | NULL | 2016-12-15 |
| 2581 | P3 | Analyst | 2017-10-15 |
| 9031 | P1 | Manager | 2017-04-15 |
| 28559 | P1 | NULL | 2017-08-01 |
| 28559 | P2 | Clerk | 2018-02-01 |
| 9031 | P3 | Clerk | 2016-11-15 |
| 29346 | P1 | Clerk | 2017-01-04 |
