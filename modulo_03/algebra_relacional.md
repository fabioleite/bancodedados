Para ilustrar o funcionamento da **Álgebra Relacional** e das operações de atualização, utilizaremos os estados iniciais das tabelas presentes no banco de dados de exemplo (*sample database*).

---

### **1. Operação de Seleção ($\sigma$)**
A seleção filtra linhas que atendem a um critério.
*   **Consulta:** Selecionar funcionários que trabalham no departamento 'd3' ($\sigma_{dept\_no='d3'}(employee)$).

**Tabela Original (`employee`):**
| emp_no | emp_fname | emp_lname | dept_no |
| :--- | :--- | :--- | :--- |
| 25348 | Matthew | Smith | d3 |
| 10102 | Ann | Jones | d3 |
| 18316 | John | Barrimore | d1 |
| 29346 | James | James | d2 |

**Resultado da Consulta:**
| emp_no | emp_fname | emp_lname | dept_no |
| :--- | :--- | :--- | :--- |
| 25348 | Matthew | Smith | d3 |
| 10102 | Ann | Jones | d3 |

---

#### **1.2. Exemplo 2: Filtro com Múltiplas Condições (AND)**
Selecionar funcionários que trabalham no departamento 'd3' E têm número de empregado maior que 10102.

*   **Consulta:** $\sigma_{dept\_no='d3' \wedge emp\_no>10102}(employee)$

**Resultado da Consulta:**
| emp_no | emp_fname | emp_lname | dept_no |
| :--- | :--- | :--- | :--- |
| 25348 | Matthew | Smith | d3 |

---

#### **1.3. Exemplo 3: Filtro com OR (Disjunção)**
Selecionar funcionários que trabalham em 'd1' OU em 'd2'.

*   **Consulta:** $\sigma_{dept\_no='d1' \vee dept\_no='d2'}(employee)$

**Resultado da Consulta:**
| emp_no | emp_fname | emp_lname | dept_no |
| :--- | :--- | :--- | :--- |
| 18316 | John | Barrimore | d1 |
| 29346 | James | James | d2 |

---

#### **1.4. Exemplo 4: Seleção com Negação**
Selecionar funcionários que NÃO trabalham no departamento 'd3'.

*   **Consulta:** $\sigma_{dept\_no \neq 'd3'}(employee)$

**Resultado da Consulta:**
| emp_no | emp_fname | emp_lname | dept_no |
| :--- | :--- | :--- | :--- |
| 18316 | John | Barrimore | d1 |
| 29346 | James | James | d2 |

---

#### **1.5. Exemplo 5: Combinando Seleção com Projeção**
Selecionar funcionários do departamento 'd3' e mostrar apenas seus nomes.

*   **Consulta:** $\pi_{emp\_fname, emp\_lname}(\sigma_{dept\_no='d3'}(employee))$

**Resultado da Consulta:**
| emp_fname | emp_lname |
| :--- | :--- |
| Matthew | Smith |
| Ann | Jones |

---

#### **1.6. Exemplo 6: Seleção seguida de Junção**
Selecionar funcionários do departamento 'd3' e unir com a tabela de departamentos.

*   **Consulta:** $\sigma_{dept\_no='d3'}(employee) \ast department$

**Tabela Original (`department`):**
| dept_no | dept_name | location |
| :--- | :--- | :--- |
| d3 | Marketing | Dallas |

**Resultado da Consulta:**
| emp_no | emp_fname | emp_lname | dept_no | dept_name | location |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 25348 | Matthew | Smith | d3 | Marketing | Dallas |
| 10102 | Ann | Jones | d3 | Marketing | Dallas |

---

### **2. Operação de Projeção ($\pi$)**
A projeção reduz a tabela verticalmente, mantendo apenas as colunas especificadas.
*   **Consulta:** Listar apenas o primeiro nome e o sobrenome de todos os funcionários ($\pi_{emp\_fname, emp\_lname}(employee)$).

**Tabela Original (`employee`):**
*(Mesma tabela do exemplo anterior)*

**Resultado da Consulta:**
| emp_fname | emp_lname |
| :--- | :--- |
| Matthew | Smith |
| Ann | Jones |
| John | Barrimore |
| James | James |

---

### **3. Operações de Junção**
Combinam tuplas relacionadas de duas ou mais tabelas baseando-se em atributos comuns. Existem vários tipos de junção:

#### **3.1. Junção Natural ($*$)**
Combina tuplas relacionadas de duas tabelas, unindo automaticamente colunas com o mesmo nome.
*   **Consulta:** $employee \ast department$ (Unir funcionários com seus departamentos).

**Tabelas Originais (`employee` e `department`):**
*Employee:*
| emp_no | emp_fname | dept_no |
| :--- | :--- | :--- |
| 18316 | John | d1 |
| 10102 | Ann | d3 |

*Department:*
| dept_no | dept_name | location |
| :--- | :--- | :--- |
| d1 | Research | Dallas |
| d3 | Marketing | Dallas |

**Resultado da Junção Natural:**
| emp_no | emp_fname | dept_no | dept_name | location |
| :--- | :--- | :--- | :--- | :--- |
| 18316 | John | d1 | Research | Dallas |
| 10102 | Ann | d3 | Marketing | Dallas |

---

#### **3.2. Junção Interna ($\bowtie$)**
Seleciona apenas linhas onde há correspondência entre as duas tabelas (similar à junção natural, mas com critério explícito).
*   **Consulta:** $employee \bowtie_{employee.dept\_no = department.dept\_no} department$

**Resultado da Junção Interna:**
| emp_no | emp_fname | dept_no | dept_name | location |
| :--- | :--- | :--- | :--- | :--- |
| 18316 | John | d1 | Research | Dallas |
| 10102 | Ann | d3 | Marketing | Dallas |

---

#### **3.3. Junção Externa à Esquerda (LEFT OUTER JOIN)**
Inclui todas as linhas da tabela esquerda, mesmo que não tenham correspondência na tabela direita.
*   **Consulta:** Listar todos os funcionários, mesmo que alguns não tenha departamento atribuído.

**Tabela `employee` (modificada):**
| emp_no | emp_fname | dept_no |
| :--- | :--- | :--- |
| 18316 | John | d1 |
| 10102 | Ann | d3 |
| 25348 | Matthew | NULL |

**Resultado da Junção Externa à Esquerda:**
| emp_no | emp_fname | dept_no | dept_name | location |
| :--- | :--- | :--- | :--- | :--- |
| 18316 | John | d1 | Research | Dallas |
| 10102 | Ann | d3 | Marketing | Dallas |
| 25348 | Matthew | NULL | NULL | NULL |

---

#### **3.4. Junção Externa à Direita (RIGHT OUTER JOIN)**
Inclui todas as linhas da tabela direita, mesmo que não tenham correspondência na tabela esquerda.
*   **Consulta:** Listar todos os departamentos, mesmo que alguns não tenha funcionários.

**Tabela `department` (modificada):**
| dept_no | dept_name | location |
| :--- | :--- | :--- |
| d1 | Research | Dallas |
| d2 | Sales | New York |
| d3 | Marketing | Dallas |

**Resultado da Junção Externa à Direita:**
| emp_no | emp_fname | dept_no | dept_name | location |
| :--- | :--- | :--- | :--- | :--- |
| 18316 | John | d1 | Research | Dallas |
| 10102 | Ann | d3 | Marketing | Dallas |
| NULL | NULL | d2 | Sales | New York |

---

#### **3.5. Junção Externa Completa (FULL OUTER JOIN)**
Inclui todas as linhas de ambas as tabelas, mesmo que não haja correspondência.
*   **Consulta:** Listar todos os funcionários e todos os departamentos, preenchendo com NULL onde não há correspondência.

**Resultado da Junção Externa Completa:**
| emp_no | emp_fname | dept_no | dept_name | location |
| :--- | :--- | :--- | :--- | :--- |
| 18316 | John | d1 | Research | Dallas |
| 10102 | Ann | d3 | Marketing | Dallas |
| 25348 | Matthew | NULL | NULL | NULL |
| NULL | NULL | d2 | Sales | New York |

---

#### **3.6. Junção Cruzada (CROSS JOIN)**
Produz o produto cartesiano entre duas tabelas (todas as combinações possíveis).
*   **Consulta:** $employee \times department$ (Todas as combinações entre funcionários e departamentos).

**Tabelas Originais (simplificadas):**
*Employee:*
| emp_no | emp_fname |
| :--- | :--- |
| 18316 | John |
| 10102 | Ann |

*Department:*
| dept_no | dept_name |
| :--- | :--- |
| d1 | Research |
| d3 | Marketing |

**Resultado da Junção Cruzada:**
| emp_no | emp_fname | dept_no | dept_name |
| :--- | :--- | :--- | :--- |
| 18316 | John | d1 | Research |
| 18316 | John | d3 | Marketing |
| 10102 | Ann | d1 | Research |
| 10102 | Ann | d3 | Marketing |

---

#### **3.7. Junção em Múltiplos Atributos**
Combina tabelas usando mais de um critério de correspondência.
*   **Consulta:** Unir `employee` e `project_assignment` usando `emp_no` E `dept_no`.

**Tabelas Originais:**
*Employee:*
| emp_no | emp_fname | dept_no |
| :--- | :--- | :--- |
| 18316 | John | d1 |
| 10102 | Ann | d3 |

*Project_Assignment:*
| emp_no | dept_no | project_no | hours |
| :--- | :--- | :--- | :--- |
| 18316 | d1 | p1 | 40 |
| 10102 | d3 | p2 | 30 |
| 18316 | d3 | p3 | 20 |

**Resultado da Junção (emp_no AND dept_no):**
*Consulta:* $employee \bowtie_{employee.emp\_no = pa.emp\_no \wedge employee.dept\_no = pa.dept\_no} project\_assignment$

| emp_no | emp_fname | dept_no | project_no | hours |
| :--- | :--- | :--- | :--- | :--- |
| 18316 | John | d1 | p1 | 40 |
| 10102 | Ann | d3 | p2 | 30 |

---

#### **3.8. Junção com Tabela Associativa**
Utiliza uma tabela de junção (associativa) para relacionar duas tabelas em relacionamento muitos-para-muitos.
*   **Cenário:** Funcionários trabalham em múltiplos projetos, e projetos têm múltiplos funcionários.

**Tabelas Originais:**
*Employee:*
| emp_no | emp_fname |
| :--- | :--- |
| 18316 | John |
| 10102 | Ann |

*Project:*
| project_no | project_name | budget |
| :--- | :--- | :--- |
| p1 | Apollo | 120000 |
| p2 | Gemini | 95000 |

*Employee_Project (Tabela Associativa):*
| emp_no | project_no | assignment_date |
| :--- | :--- | :--- |
| 18316 | p1 | 2024-01-15 |
| 18316 | p2 | 2024-02-01 |
| 10102 | p1 | 2024-01-20 |

**Consulta:** Listar funcionários com seus projetos: $\pi_{emp\_fname, project\_name}(employee \ast employee\_project \ast project)$

**Resultado (Employee ⊲⊳ Employee_Project ⊲⊳ Project):**
| emp_fname | project_name |
| :--- | :--- |
| John | Apollo |
| John | Gemini |
| Ann | Apollo |

---

#### **3.9. Junção Múltipla com Tabelas Associativas**
Exemplo mais complexo combinando três tabelas com uma associativa.
*   **Consulta:** Listar funcionários, seus departamentos e projetos.

**Tabelas Originais:**
*Employee:*
| emp_no | emp_fname | dept_no |
| :--- | :--- | :--- |
| 18316 | John | d1 |
| 10102 | Ann | d3 |

*Department:*
| dept_no | dept_name |
| :--- | :--- |
| d1 | Research |
| d3 | Marketing |

*Project:*
| project_no | project_name |
| :--- | :--- |
| p1 | Apollo |
| p2 | Gemini |

*Employee_Project:*
| emp_no | project_no |
| :--- | :--- |
| 18316 | p1 |
| 10102 | p2 |

**Consulta:** $employee \ast department \ast employee\_project \ast project$

**Resultado:**
| emp_no | emp_fname | dept_no | dept_name | project_no | project_name |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 18316 | John | d1 | Research | p1 | Apollo |
| 10102 | Ann | d3 | Marketing | p2 | Gemini |

---

#### **3.10. Junção com Auto-Relacionamento**
Junção de uma tabela consigo mesma para encontrar relacionamentos dentro do mesmo conjunto de dados.
*   **Consulta:** Encontrar pares de funcionários que trabalham no mesmo departamento.

**Tabela `employee`:**
| emp_no | emp_fname | dept_no |
| :--- | :--- | :--- |
| 18316 | John | d1 |
| 25348 | Matthew | d1 |
| 10102 | Ann | d3 |

**Consulta:** $\pi_{e1.emp\_fname, e2.emp\_fname}(\sigma_{e1.dept\_no = e2.dept\_no \wedge e1.emp\_no < e2.emp\_no}(e1 \times e2))$

**Resultado (Pares de funcionários no mesmo departamento):**
| emp_fname_1 | emp_fname_2 | dept_no |
| :--- | :--- | :--- |
| John | Matthew | d1 |

---

### **4. Operações de Conjunto: União ($\cup$)**
Combina os resultados de duas tabelas compatíveis, removendo duplicatas.
*   **Consulta:** Nomes presentes na tabela de alunos OU na de instrutores.

**Tabelas Originais (`STUDENT` e `INSTRUCTOR`):**
*STUDENT:*
| Fn | Ln |
| :--- | :--- |
| Susan | Yao |
| Ramesh | Shah |

*INSTRUCTOR:*
| Fname | Lname |
| :--- | :--- |
| Susan | Yao |
| John | Smith |

**Resultado da União:**
| Fn | Ln |
| :--- | :--- |
| Susan | Yao |
| Ramesh | Shah |
| John | Smith |
*(Note que "Susan Yao" aparece apenas uma vez no resultado final)*