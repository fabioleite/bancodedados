# Prático Inicial - Banco de Dados

**Professor:** Dr. Fábio Leite  
**Instituição:** Universidade Estadual da Paraíba — UEPB, Campina Grande, PB  

> **SGBDs abordados:** SQL Server · PostgreSQL  

---

## Sumário

1. [Instalação dos SGBDs](#1-instalação-dos-sgbds)  
2. [Criação de Banco de Dados](#2-criação-de-banco-de-dados)  
3. [Esquemas e Tabelas](#3-esquemas-e-tabelas)  
4. [Operações DML](#4-operações-dml)  

---

## 1. Instalação dos SGBDs

> 📋 **Antes de começar:** Verifique se o seu computador tem pelo menos **4 GB de RAM** e **10 GB de espaço livre em disco**. Feche outros programas pesados durante a instalação.

---

### 1.1 SQL Server — Windows

O SQL Server é instalado em duas etapas: primeiro o **servidor de banco de dados**, depois o **SQL Server Management Studio (SSMS)**, que é a interface gráfica usada para interagir com ele.

---

#### Parte A — Instalar o SQL Server

**Passo 1 — Baixar o instalador**

1. Abra o navegador e acesse: **https://www.microsoft.com/pt-br/sql-server/sql-server-downloads**
2. Role a página até a seção **"Ou escolha uma edição gratuita especializada"**.
3. Clique em **"Baixar agora"** abaixo de **Developer**.
   - A edição Developer é gratuita e tem todos os recursos da versão paga — destinada a desenvolvimento e aprendizado.
4. O arquivo `SQL2022-SSEI-Dev.exe` (ou similar) será baixado. Salve na pasta **Downloads**.

**Passo 2 — Executar o instalador**

1. Dê um duplo clique no arquivo baixado.
2. Se o Windows exibir *"Deseja permitir que este aplicativo faça alterações no seu dispositivo?"*, clique em **Sim**.
3. Uma janela com três opções aparecerá. Clique em **Básico**.
4. Na tela de **Termos de Licença**, clique em **Aceitar**.
5. Mantenha o local de instalação padrão e clique em **Instalar**.
6. Aguarde entre 5 e 15 minutos.
7. Quando aparecer **"A instalação foi concluída com êxito!"**, **anote ou tire print** do campo **CADEIA DE CONEXÃO**, que será parecido com:
   ```
   Server=localhost;Database=master;Trusted_Connection=True;
   ```
8. Não feche essa janela ainda.

---

#### Parte B — Instalar o SSMS (interface gráfica)

**Passo 3 — Baixar e instalar o SSMS**

1. Na janela de conclusão da etapa anterior, clique em **"Instalar SSMS"**. O navegador abrirá a página de download.
   - Caso a janela já tenha sido fechada, acesse: **https://aka.ms/ssmsfullsetup**
2. Clique no link de download do SSMS (ex.: **"Baixar o SSMS 20.x"**).
3. Execute o arquivo `SSMS-Setup-PTB.exe` baixado. Clique em **Sim** se solicitado.
4. Clique em **Instalar** e aguarde de 5 a 10 minutos.
5. Ao final, clique em **Fechar**. **Reinicie o computador** se o instalador solicitar.

**Passo 4 — Abrir o SSMS e conectar ao servidor**

1. Abra o menu **Iniciar**, digite **SSMS** e clique no programa.
2. A janela **"Conectar ao Servidor"** abrirá automaticamente. Preencha:
   - **Tipo de servidor:** `Mecanismo de Banco de Dados` *(já vem preenchido)*
   - **Nome do servidor:** `localhost`
   - **Autenticação:** `Autenticação do Windows`
3. Clique em **Conectar**.
4. O painel **Object Explorer** aparecerá à esquerda com o servidor conectado.

> ✅ **Verificando a instalação**
>
> 1. Clique em **Nova Consulta** na barra de ferramentas (ou `Ctrl + N`).
> 2. Na área de texto, digite:
>    ```sql
>    SELECT @@VERSION;
>    ```
> 3. Clique em **Executar** (botão ▶ ou `F5`).
> 4. Na aba **Resultados** (parte inferior), deve aparecer a versão do SQL Server. ✅

**Problemas comuns — SQL Server**

| Problema | Causa provável | Solução |
|----------|----------------|---------|
| SSMS não conecta | Serviço do SQL Server parado | Busque **"Gerenciador de Configurações do SQL Server"** no menu Iniciar. Verifique se **SQL Server (MSSQLSERVER)** está **Em Execução**. Se não estiver, clique com botão direito → **Iniciar**. |
| Mensagem "Login falhou" | Tipo de autenticação errado | Escolha **Autenticação do Windows**, não SQL Server. |
| Instalador trava ou fecha | Pouco espaço em disco | Verifique se há pelo menos 10 GB livres no disco C: e execute o instalador como Administrador (botão direito → *Executar como administrador*). |

---

### 1.2 SQL Server — Linux

> ⚠️ O SQL Server não tem suporte completo para Ubuntu/Debian em ambiente didático. **Alunos com Linux devem usar o PostgreSQL** (seção 1.4).

---

### 1.3 PostgreSQL — Windows

**Passo 1 — Baixar o instalador**

1. Acesse: **https://www.postgresql.org/download/windows**
2. Clique em **"Download the installer"**.
3. Na tabela, localize a versão mais recente (ex.: **16.x**) e clique no ícone de download na coluna **Windows x86-64**.
4. O arquivo `postgresql-16.x-windows-x64.exe` será baixado.

**Passo 2 — Executar o instalador**

1. Dê duplo clique no arquivo. Clique em **Sim** se solicitado.
2. **Boas-vindas:** clique em **Next**.
3. **Diretório de instalação:** mantenha o padrão. Clique em **Next**.
4. **Componentes:** mantenha todos marcados (PostgreSQL Server, pgAdmin 4, Stack Builder, Command Line Tools). Clique em **Next**.
5. **Diretório de dados:** mantenha o padrão. Clique em **Next**.
6. **Senha do superusuário:** defina uma senha para o usuário `postgres`.
   - ⚠️ **ANOTE ESSA SENHA.** Sem ela você não conseguirá acessar o banco. Sugestão: `postgres123`.
7. **Porta:** mantenha `5432`. Clique em **Next**.
8. **Locale:** mantenha o padrão. Clique em **Next** → **Next** → aguarde a instalação.
9. Ao final, **desmarque** *"Launch Stack Builder at exit"* e clique em **Finish**.

**Passo 3 — Abrir o pgAdmin 4 e conectar**

1. Abra o menu **Iniciar**, digite **pgAdmin** e clique em **pgAdmin 4**.
2. O pgAdmin abrirá no navegador padrão (é um aplicativo web local). Aguarde carregar.
3. Na primeira abertura, defina uma **senha mestra do pgAdmin** (protege o próprio pgAdmin) e clique em **OK**.
4. No painel esquerdo (**Browser**), expanda **Servers** → clique em **PostgreSQL 16**.
5. Digite a senha definida no Passo 2. Marque **Save Password**. Clique em **OK**.
6. O servidor aparecerá conectado.

**Passo 4 — Abrir o Query Tool**

1. Expanda **Servers → PostgreSQL 16 → Databases → postgres**.
2. Clique com botão direito em **postgres** → **Query Tool**.
3. Uma aba com área de texto abrirá — é aqui onde você escreverá os comandos SQL.

> ✅ **Verificando a instalação**
>
> 1. Na área de texto do Query Tool, digite:
>    ```sql
>    SELECT version();
>    ```
> 2. Clique em **▶ Execute** (ou `F5`).
> 3. Na aba **Data Output** (parte inferior), deve aparecer a versão do PostgreSQL. ✅

**Problemas comuns — PostgreSQL (Windows)**

| Problema | Causa provável | Solução |
|----------|----------------|---------|
| pgAdmin não abre | Falha no serviço | Reinicie o computador e tente novamente. |
| Erro de senha ao conectar | Senha digitada errada | Confirme a senha criada na instalação. Se esqueceu, será necessário reinstalar. |
| pgAdmin não conecta ao servidor | Serviço parado | `Win + R` → `services.msc` → localize **postgresql-x64-16** → botão direito → **Iniciar**. |
| Porta 5432 ocupada | Outro serviço usando a porta | Reinstale usando a porta `5433` e lembre de configurar o pgAdmin com essa porta. |

---

### 1.4 PostgreSQL — Linux (Ubuntu / Debian)

No Linux, o PostgreSQL é instalado pelo **Terminal** usando o gerenciador de pacotes `apt`.

**Passo 1 — Abrir o Terminal**

Pressione `Ctrl + Alt + T`, ou busque por **Terminal** no menu de aplicativos.

**Passo 2 — Atualizar o sistema**

```bash
sudo apt update
```

O sistema pedirá sua senha de usuário (a mesma do login). Digite e pressione Enter.

**Passo 3 — Instalar o PostgreSQL**

```bash
sudo apt install postgresql postgresql-contrib -y
```

Aguarde o download e a instalação.

**Passo 4 — Verificar se o serviço está rodando**

```bash
sudo systemctl status postgresql
```

Você verá algo parecido com:

```
● postgresql.service - PostgreSQL RDBMS
     Active: active (running) since ...
```

A linha **`Active: active (running)`** confirma que está funcionando. Pressione `Q` para sair.

**Passo 5 — Definir a senha do usuário postgres**

```bash
sudo -i -u postgres
```

O prompt mudará. Agora abra o console do PostgreSQL:

```bash
psql
```

O prompt mudará para `postgres=#`. Defina a senha:

```sql
ALTER USER postgres PASSWORD 'postgres123';
```

> Troque `postgres123` pela senha que preferir. **Anote essa senha.**

Saia do psql e volte ao seu usuário:

```bash
\q
exit
```

**Passo 6 — Instalar o pgAdmin 4**

Execute os comandos abaixo **um de cada vez** no terminal:

```bash
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
```

```bash
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
```

```bash
sudo apt update && sudo apt install pgadmin4-desktop -y
```

Após a instalação, o **pgAdmin 4** aparecerá no menu de aplicativos.

**Passo 7 — Conectar ao servidor no pgAdmin 4**

1. Abra o **pgAdmin 4** pelo menu de aplicativos.
2. Defina a **senha mestra** na primeira abertura. Clique em **OK**.
3. Clique com botão direito em **Servers** → **Register** → **Server**.
4. Aba **General** → **Name:** `PostgreSQL Local`
5. Aba **Connection** → preencha:
   - **Host:** `localhost`
   - **Port:** `5432`
   - **Username:** `postgres`
   - **Password:** a senha do Passo 5 (ex.: `postgres123`)
   - Marque **Save password**
6. Clique em **Save**. O servidor aparecerá conectado.

> ✅ **Verificando a instalação (Linux)**
>
> **Pelo pgAdmin:** expanda **Servers → PostgreSQL Local → Databases → postgres** → clique com botão direito → **Query Tool** → execute:
> ```sql
> SELECT version();
> ```
>
> **Pelo Terminal:**
> ```bash
> psql -U postgres -c "SELECT version();"
> ```
> Digite a senha quando solicitado.

**Problemas comuns — PostgreSQL (Linux)**

| Problema | Causa provável | Solução |
|----------|----------------|---------|
| `sudo: apt: command not found` | Distro diferente | Use `dnf` no lugar de `apt` (Fedora/RHEL). |
| `psql: error: connection refused` | Serviço parado | `sudo systemctl start postgresql` |
| Erro de autenticação no psql | Método `peer` ativo | Sempre acesse com `sudo -i -u postgres` antes de rodar `psql`. |
| pgAdmin não instala | `curl` ausente | Execute `sudo apt install curl -y` e repita o Passo 6. |

---

## 2. Criação de Banco de Dados

Um **banco de dados** é o contêiner principal onde todos os objetos (tabelas, esquemas, views) serão armazenados. Veja como criá-lo em cada SGBD.

### 🗄 SQL Server

**Via SSMS (interface gráfica):**
1. No painel *Object Explorer*, clique com botão direito em **Databases**.
2. Selecione **New Database...**.
3. Digite o nome do banco (ex.: `BancoDeTestes`) e clique em **OK**.

**Via SQL (T-SQL):**
```sql
-- Criar banco de dados
CREATE DATABASE BancoDeTestes;

-- Selecionar o banco para uso
USE BancoDeTestes;

-- Verificar bancos existentes
SELECT name FROM sys.databases;
```

---

### 🐘 PostgreSQL

**Via pgAdmin (interface gráfica):**
1. Expanda o servidor no painel esquerdo do pgAdmin.
2. Clique com botão direito em **Databases** → **Create** → **Database...**.
3. Preencha o campo **Database** com o nome (ex.: `banco_testes`) e clique em **Save**.

**Via SQL:**
```sql
-- Criar banco de dados
CREATE DATABASE banco_testes;

-- Conectar ao banco (no psql terminal)
\c banco_testes

-- Listar bancos existentes
\l

-- Ou via SQL padrão:
SELECT datname FROM pg_database;
```

> 💡 **Convenção de nomes:**  
> No SQL Server é comum usar **PascalCase** (ex.: `BancoDeTestes`).  
> No PostgreSQL, prefira **snake_case** com letras minúsculas (ex.: `banco_testes`), pois o sistema converte identificadores para minúsculas por padrão.

---

## 3. Esquemas e Tabelas

Um **esquema (schema)** é um agrupamento lógico de objetos dentro de um banco de dados — funciona como uma "pasta" que organiza tabelas, views e outros objetos.  
As **tabelas** são onde os dados são efetivamente armazenados, em linhas e colunas.

---

### 3.1 Principais Tipos de Dados

| Tipo             | SQL Server              | PostgreSQL        | Descrição                     |
|------------------|-------------------------|-------------------|-------------------------------|
| Inteiro          | `INT`                   | `INTEGER`         | Números inteiros               |
| Inteiro longo    | `BIGINT`                | `BIGINT`          | Inteiros grandes               |
| Decimal          | `DECIMAL(p,s)`          | `NUMERIC(p,s)`    | Número com casas decimais      |
| Texto fixo       | `CHAR(n)`               | `CHAR(n)`         | Texto de tamanho fixo          |
| Texto variável   | `VARCHAR(n)`            | `VARCHAR(n)`      | Texto até *n* caracteres       |
| Texto longo      | `NVARCHAR(MAX)`         | `TEXT`            | Texto sem limite definido      |
| Data             | `DATE`                  | `DATE`            | Apenas data (AAAA-MM-DD)       |
| Data e hora      | `DATETIME`              | `TIMESTAMP`       | Data e hora                    |
| Booleano         | `BIT` (0 ou 1)          | `BOOLEAN`         | Verdadeiro / Falso             |

---

### 3.2 Criando Esquemas

#### 🗄 SQL Server
```sql
-- Criar esquemas
CREATE SCHEMA Academico;
CREATE SCHEMA Financeiro;

-- Listar esquemas existentes
SELECT name FROM sys.schemas;
```

#### 🐘 PostgreSQL
```sql
-- Criar esquemas
CREATE SCHEMA academico;
CREATE SCHEMA financeiro;

-- Listar esquemas existentes
SELECT schema_name FROM information_schema.schemata;
```

---

### 3.3 Criando Tabelas

As tabelas a seguir são as mesmas usadas no material teórico da disciplina: **Departamento**, **Empregado** e **Dependente**.

#### 🗄 SQL Server
```sql
USE BancoDeTestes;

-- Tabela Departamento
CREATE TABLE Academico.Departamento (
    CodDepto  INT           NOT NULL,
    Nome      VARCHAR(100)  NOT NULL,
    CONSTRAINT PK_Departamento PRIMARY KEY (CodDepto)
);

-- Tabela Empregado
CREATE TABLE Academico.Empregado (
    CodEmp    INT           NOT NULL,
    Nome      VARCHAR(100)  NOT NULL,
    CodDepto  INT           NOT NULL,
    CONSTRAINT PK_Empregado  PRIMARY KEY (CodEmp),
    CONSTRAINT FK_Emp_Depto  FOREIGN KEY (CodDepto)
        REFERENCES Academico.Departamento(CodDepto)
);

-- Tabela Dependente
CREATE TABLE Academico.Dependente (
    CodDep    INT           NOT NULL,
    Nome      VARCHAR(100)  NOT NULL,
    CodEmp    INT           NOT NULL,
    CONSTRAINT PK_Dependente PRIMARY KEY (CodDep),
    CONSTRAINT FK_Dep_Emp    FOREIGN KEY (CodEmp)
        REFERENCES Academico.Empregado(CodEmp)
);
```

#### 🐘 PostgreSQL
```sql
-- Garantir que está no banco certo
\c banco_testes

-- Tabela Departamento
CREATE TABLE academico.departamento (
    cod_depto  INTEGER      NOT NULL,
    nome       VARCHAR(100) NOT NULL,
    CONSTRAINT pk_departamento PRIMARY KEY (cod_depto)
);

-- Tabela Empregado
CREATE TABLE academico.empregado (
    cod_emp    INTEGER      NOT NULL,
    nome       VARCHAR(100) NOT NULL,
    cod_depto  INTEGER      NOT NULL,
    CONSTRAINT pk_empregado  PRIMARY KEY (cod_emp),
    CONSTRAINT fk_emp_depto  FOREIGN KEY (cod_depto)
        REFERENCES academico.departamento(cod_depto)
);

-- Tabela Dependente
CREATE TABLE academico.dependente (
    cod_dep    INTEGER      NOT NULL,
    nome       VARCHAR(100) NOT NULL,
    cod_emp    INTEGER      NOT NULL,
    CONSTRAINT pk_dependente PRIMARY KEY (cod_dep),
    CONSTRAINT fk_dep_emp    FOREIGN KEY (cod_emp)
        REFERENCES academico.empregado(cod_emp)
);
```

> 🔑 **Constraints importantes:**  
> - `PRIMARY KEY` — identifica unicamente cada linha  
> - `NOT NULL` — o campo não pode ficar vazio  
> - `FOREIGN KEY` — garante a integridade referencial entre tabelas  

---

## 4. Operações DML

**DML (Data Manipulation Language)** é o conjunto de comandos SQL usado para manipular os dados dentro das tabelas. As quatro operações fundamentais são:

| Comando | Operação | Descrição |
|---------|----------|-----------|
| `INSERT` | Inserção | Adiciona novas linhas à tabela |
| `SELECT` | Consulta | Recupera dados da tabela |
| `UPDATE` | Atualização | Modifica dados existentes |
| `DELETE` | Remoção | Remove linhas da tabela |

> ⚠️ Os exemplos a seguir usam as tabelas **Departamento**, **Empregado** e **Dependente** criadas no Módulo 3. Execute os INSERTs antes dos SELECTs, UPDATEs e DELETEs.

---

### 4.1 INSERT — Inserindo Dados

O `INSERT` adiciona uma nova linha à tabela. A ordem dos valores deve corresponder à ordem das colunas declaradas.

**Sintaxe:**
```sql
INSERT INTO esquema.Tabela (coluna1, coluna2, ...)
VALUES (valor1, valor2, ...);
```

#### 🗄 SQL Server
```sql
USE BancoDeTestes;

-- Inserindo Departamentos
INSERT INTO Academico.Departamento (CodDepto, Nome) VALUES (1, 'D1');
INSERT INTO Academico.Departamento (CodDepto, Nome) VALUES (2, 'D2');
INSERT INTO Academico.Departamento (CodDepto, Nome) VALUES (3, 'D3');

-- Inserindo Empregados
INSERT INTO Academico.Empregado (CodEmp, Nome, CodDepto) VALUES (1, 'José',  3);
INSERT INTO Academico.Empregado (CodEmp, Nome, CodDepto) VALUES (2, 'Maria', 2);
INSERT INTO Academico.Empregado (CodEmp, Nome, CodDepto) VALUES (3, 'João',  2);
INSERT INTO Academico.Empregado (CodEmp, Nome, CodDepto) VALUES (4, 'João',  1);
INSERT INTO Academico.Empregado (CodEmp, Nome, CodDepto) VALUES (5, 'Pedro', 3);
INSERT INTO Academico.Empregado (CodEmp, Nome, CodDepto) VALUES (6, 'Ana',   2);

-- Inserindo Dependentes
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (1, 'Francisco', 3);
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (2, 'Juliana',   3);
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (3, 'Juliana',   4);
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (4, 'Manuel',    1);
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (5, 'Miguel',    3);
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (6, 'Hugo',      2);
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (7, 'Marcos',    6);
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (8, 'Daniela',   1);
INSERT INTO Academico.Dependente (CodDep, Nome, CodEmp) VALUES (9, 'Marieta',   2);
```

#### 🐘 PostgreSQL
```sql
\c banco_testes

-- Inserindo Departamentos
INSERT INTO academico.departamento (cod_depto, nome) VALUES (1, 'D1');
INSERT INTO academico.departamento (cod_depto, nome) VALUES (2, 'D2');
INSERT INTO academico.departamento (cod_depto, nome) VALUES (3, 'D3');

-- Inserindo Empregados
INSERT INTO academico.empregado (cod_emp, nome, cod_depto) VALUES (1, 'José',  3);
INSERT INTO academico.empregado (cod_emp, nome, cod_depto) VALUES (2, 'Maria', 2);
INSERT INTO academico.empregado (cod_emp, nome, cod_depto) VALUES (3, 'João',  2);
INSERT INTO academico.empregado (cod_emp, nome, cod_depto) VALUES (4, 'João',  1);
INSERT INTO academico.empregado (cod_emp, nome, cod_depto) VALUES (5, 'Pedro', 3);
INSERT INTO academico.empregado (cod_emp, nome, cod_depto) VALUES (6, 'Ana',   2);

-- Inserindo Dependentes
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (1, 'Francisco', 3);
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (2, 'Juliana',   3);
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (3, 'Juliana',   4);
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (4, 'Manuel',    1);
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (5, 'Miguel',    3);
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (6, 'Hugo',      2);
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (7, 'Marcos',    6);
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (8, 'Daniela',   1);
INSERT INTO academico.dependente (cod_dep, nome, cod_emp) VALUES (9, 'Marieta',   2);
```

> 💡 **Atenção à ordem dos INSERTs:** sempre insira primeiro na tabela **pai** antes da **filha**. No exemplo, Departamento → Empregado → Dependente, pois as FKs dependem dessa ordem.

---

### 4.2 SELECT — Consultando Dados

O `SELECT` é o comando mais utilizado em SQL. Permite recuperar dados de uma ou mais tabelas.

**Sintaxe básica:**
```sql
SELECT coluna1, coluna2
FROM esquema.Tabela
WHERE condição;
```

#### 🗄 SQL Server · 🐘 PostgreSQL *(sintaxe idêntica)*

```sql
-- Selecionar todas as colunas de uma tabela
SELECT * FROM Academico.Departamento;

-- Selecionar colunas específicas
SELECT CodEmp, Nome FROM Academico.Empregado;

-- Filtrar com WHERE
SELECT * FROM Academico.Empregado
WHERE CodDepto = 2;

-- Filtrar com múltiplas condições
SELECT * FROM Academico.Empregado
WHERE CodDepto = 2 AND Nome = 'Maria';

-- Ordenar resultados (ASC = crescente, DESC = decrescente)
SELECT * FROM Academico.Empregado
ORDER BY Nome ASC;

-- Contar registros
SELECT COUNT(*) AS TotalEmpregados
FROM Academico.Empregado;

-- JOIN: combinar dados de duas tabelas
SELECT e.CodEmp, e.Nome AS Empregado, d.Nome AS Departamento
FROM Academico.Empregado e
JOIN Academico.Departamento d ON e.CodDepto = d.CodDepto;

-- JOIN triplo: empregado, departamento e seus dependentes
SELECT e.Nome AS Empregado, d.Nome AS Departamento, dep.Nome AS Dependente
FROM Academico.Empregado e
JOIN Academico.Departamento d   ON e.CodDepto = d.CodDepto
JOIN Academico.Dependente   dep ON dep.CodEmp  = e.CodEmp
ORDER BY e.Nome;
```

> 💡 **Dica:** No PostgreSQL, substitua `Academico.` por `academico.` e os nomes de colunas/tabelas por snake_case (ex.: `cod_emp`, `empregado`).

---

### 4.3 UPDATE — Atualizando Dados

O `UPDATE` modifica valores em linhas já existentes. **Sempre use `WHERE`** para não atualizar a tabela inteira por acidente.

**Sintaxe:**
```sql
UPDATE esquema.Tabela
SET coluna1 = novo_valor
WHERE condição;
```

#### 🗄 SQL Server
```sql
-- Alterar o departamento de um empregado
UPDATE Academico.Empregado
SET CodDepto = 1
WHERE CodEmp = 2;

-- Alterar o nome de um departamento
UPDATE Academico.Departamento
SET Nome = 'Tecnologia'
WHERE CodDepto = 1;

-- Verificar o resultado
SELECT * FROM Academico.Empregado WHERE CodEmp = 2;
SELECT * FROM Academico.Departamento WHERE CodDepto = 1;
```

#### 🐘 PostgreSQL
```sql
-- Alterar o departamento de um empregado
UPDATE academico.empregado
SET cod_depto = 1
WHERE cod_emp = 2;

-- Alterar o nome de um departamento
UPDATE academico.departamento
SET nome = 'Tecnologia'
WHERE cod_depto = 1;

-- Verificar o resultado
SELECT * FROM academico.empregado WHERE cod_emp = 2;
SELECT * FROM academico.departamento WHERE cod_depto = 1;
```

> ⚠️ **CUIDADO:** Um `UPDATE` sem `WHERE` atualiza **todas** as linhas da tabela. Execute sempre com cautela.

---

### 4.4 DELETE — Removendo Dados

O `DELETE` remove linhas de uma tabela. Assim como o `UPDATE`, **sempre use `WHERE`** para não apagar todos os registros.

**Sintaxe:**
```sql
DELETE FROM esquema.Tabela
WHERE condição;
```

#### 🗄 SQL Server
```sql
-- Remover um dependente específico
DELETE FROM Academico.Dependente
WHERE CodDep = 9;

-- Remover todos os dependentes de um empregado
DELETE FROM Academico.Dependente
WHERE CodEmp = 3;

-- Verificar o resultado
SELECT * FROM Academico.Dependente;
```

#### 🐘 PostgreSQL
```sql
-- Remover um dependente específico
DELETE FROM academico.dependente
WHERE cod_dep = 9;

-- Remover todos os dependentes de um empregado
DELETE FROM academico.dependente
WHERE cod_emp = 3;

-- Verificar o resultado
SELECT * FROM academico.dependente;
```

> ⚠️ **CUIDADO com FKs:** Não é possível deletar um registro pai enquanto existirem registros filhos referenciando-o. No exemplo, para deletar um Empregado, seus Dependentes devem ser removidos primeiro.

> 💡 **Diferença entre DELETE e TRUNCATE:**
> - `DELETE FROM Tabela WHERE ...` — remove linhas específicas, pode ser desfeito com ROLLBACK.
> - `TRUNCATE TABLE Tabela` — remove **todas** as linhas de uma vez, mais rápido, mas não pode ser filtrado.


---

*Universidade Estadual da Paraíba — UEPB | Prof. Dr. Fábio Leite | fabioleite@servidor.uepb.edu.br | +55 83 99657-7959*