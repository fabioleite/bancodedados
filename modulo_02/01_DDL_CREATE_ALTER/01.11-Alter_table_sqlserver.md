# Módulo: Alteração de Tabelas em Bancos de Dados Relacionais (ALTER TABLE)

**Curso:** Banco de Dados Relacionais aplicado à Administração Tributária
**Público-alvo:** Profissionais da Secretaria de Estado da Fazenda da Paraíba (SEFAZ-PB)
**SGBD utilizado:** Microsoft SQL Server (T-SQL) — ferramenta: SQL Server Management Studio (SSMS)
**Carga horária sugerida:** 8 horas (4h teoria + 4h prática)

---

## Sumário

1. [Objetivos do Módulo](#1-objetivos-do-módulo)
2. [Por que Alterar Tabelas em Produção é Diferente de Criar do Zero](#2-por-que-alterar-tabelas-em-produção-é-diferente-de-criar-do-zero)
3. [Visão Geral do Comando ALTER TABLE](#3-visão-geral-do-comando-alter-table)
4. [Adicionando Colunas (ADD)](#4-adicionando-colunas-add)
5. [Removendo Colunas (DROP COLUMN)](#5-removendo-colunas-drop-column)
6. [Alterando Tipo e Definição de Coluna (ALTER COLUMN)](#6-alterando-tipo-e-definição-de-coluna-alter-column)
7. [Renomeando Colunas e Tabelas (sp_rename)](#7-renomeando-colunas-e-tabelas-sp_rename)
8. [Adicionando e Removendo Constraints](#8-adicionando-e-removendo-constraints)
9. [Constraints "Não Confiáveis": WITH NOCHECK e o Otimizador](#9-constraints-não-confiáveis-with-nocheck-e-o-otimizador)
10. [Cuidados Operacionais em Bases de Produção Fiscal](#10-cuidados-operacionais-em-bases-de-produção-fiscal)
11. [Roteiro Prático Completo](#11-roteiro-prático-completo)
12. [Exercícios Práticos](#12-exercícios-práticos)
13. [Glossário](#13-glossário)
14. [Referências](#14-referências)

---

## 1. Objetivos do Módulo

Ao final deste módulo, o participante será capaz de:

- Utilizar o comando `ALTER TABLE` para adicionar, remover e modificar colunas de uma tabela já existente e populada com dados reais.
- Renomear colunas e tabelas usando o procedimento `sp_rename`, entendendo suas limitações.
- Adicionar e remover `CONSTRAINT`s (`CHECK`, `DEFAULT`, `UNIQUE`, `FOREIGN KEY`, `PRIMARY KEY`) em tabelas que já contêm dados, tratando eventuais violações existentes.
- Compreender a diferença entre uma constraint **confiável (trusted)** e **não confiável (not trusted)**, e por que isso importa para a integridade e para o desempenho de consultas fiscais.
- Reconhecer os riscos operacionais de executar `ALTER TABLE` em tabelas fiscais de grande volume (bloqueios, reescrita de dados, indisponibilidade), e as boas práticas para mitigá-los.

---

## 2. Por que Alterar Tabelas em Produção é Diferente de Criar do Zero

Nos módulos anteriores, sempre criamos as tabelas do zero, já com a estrutura final definida. Na vida real de um sistema fiscal em operação, isso quase nunca acontece — o esquema do banco **evolui continuamente**, motivado por:

- **Mudanças na legislação tributária**: uma nova obrigação acessória passa a exigir a captura de um dado que antes não era registrado (ex.: informar o regime de tributação do contribuinte).
- **Correções de modelagem**: um campo foi definido pequeno demais, ou com o tipo de dado errado, e precisa ser ajustado sem perder o histórico já armazenado.
- **Descontinuação de funcionalidades**: um campo deixa de fazer sentido e precisa ser removido, mas a tabela já tem milhões de linhas com dados reais.
- **Novos relacionamentos**: um cruzamento de dados que não existia antes passa a ser necessário, exigindo uma nova chave estrangeira.

**A diferença fundamental:** ao criar uma tabela nova (`CREATE TABLE`), não há dados existentes para se preocupar. Ao **alterar** uma tabela já populada (`ALTER TABLE`), toda mudança precisa responder a uma pergunta adicional: **"o que acontece com os dados que já estão lá?"** Uma coluna nova `NOT NULL` precisa de um valor para as linhas existentes; uma nova `CHECK` pode ser violada por dados históricos; reduzir o tamanho de uma coluna pode truncar informação já gravada. Este módulo trata exatamente desse cuidado adicional.

---

## 3. Visão Geral do Comando ALTER TABLE

| Operação | Sintaxe básica em T-SQL | Uso típico |
|---|---|---|
| Adicionar coluna | `ALTER TABLE t ADD coluna tipo` | Nova informação exigida por lei |
| Remover coluna | `ALTER TABLE t DROP COLUMN coluna` | Campo obsoleto |
| Alterar tipo/nulidade de coluna | `ALTER TABLE t ALTER COLUMN coluna novo_tipo [NULL\|NOT NULL]` | Corrigir tamanho, tipo ou obrigatoriedade |
| Renomear coluna ou tabela | `EXEC sp_rename 'objeto', 'novo_nome', 'COLUMN'` | Corrigir nomenclatura |
| Adicionar constraint | `ALTER TABLE t ADD CONSTRAINT nome ...` | Nova regra de integridade |
| Remover constraint | `ALTER TABLE t DROP CONSTRAINT nome` | Regra revogada ou substituída |
| Habilitar/desabilitar constraint | `ALTER TABLE t NOCHECK/CHECK CONSTRAINT nome` | Suspender temporariamente uma regra |

Todas essas variações partem da mesma palavra-chave (`ALTER TABLE`), seguida do nome da tabela e da ação específica desejada.

---

## 4. Adicionando Colunas (ADD)

### 4.1 Coluna simples, permitindo NULO

A forma mais simples de adicionar uma coluna: como as linhas existentes não têm valor para o novo atributo, ele **precisa aceitar `NULL`** (a menos que se use `DEFAULT`, como veremos a seguir).

**Cenário fiscal:** a Secretaria decide passar a registrar um telefone de contato adicional do contribuinte, mas essa informação será preenchida aos poucos, à medida que os contribuintes atualizarem seus cadastros.

```sql
ALTER TABLE contribuinte
ADD telefone_contato_adicional VARCHAR(20) NULL;
```

### 4.2 Coluna obrigatória (NOT NULL) com valor padrão para linhas já existentes

Quando a nova coluna deve ser **obrigatória**, é preciso informar um `DEFAULT` — caso contrário, o SQL Server não saberia o que colocar nas linhas que já existem.

**Cenário fiscal:** uma resolução da SEFAZ-PB passa a exigir que todo contribuinte tenha seu **regime de tributação** classificado (`SIMPLES_NACIONAL`, `LUCRO_PRESUMIDO`, `LUCRO_REAL`). Por padrão, todo contribuinte já cadastrado deve ser inicialmente classificado como `LUCRO_PRESUMIDO` (regime mais comum), sujeito à correção posterior caso-a-caso.

```sql
ALTER TABLE contribuinte
ADD regime_tributario VARCHAR(20) NOT NULL
    CONSTRAINT df_contribuinte_regime DEFAULT ('LUCRO_PRESUMIDO');
```

> **Como isso funciona internamente:** ao executar este comando **com um valor constante** de `DEFAULT` (como `'LUCRO_PRESUMIDO'`), o SQL Server (a partir da versão 2012) realiza essa operação como uma **mudança apenas de metadados** — ou seja, ele **não precisa reescrever fisicamente** todas as linhas da tabela para preencher o valor padrão, tornando a operação quase instantânea, mesmo em tabelas com milhões de linhas. Isso deixa de ser verdade se o `DEFAULT` for uma expressão não determinística (como `GETDATE()` ou `NEWID()`), caso em que o SQL Server **precisa, sim, reescrever cada linha** — discutiremos isso com mais detalhe na seção 10.

Em seguida, é comum também adicionar uma `CHECK` para restringir o domínio do novo campo (assunto do módulo de Restrições e Integridade):

```sql
ALTER TABLE contribuinte
ADD CONSTRAINT ck_contribuinte_regime
    CHECK (regime_tributario IN ('SIMPLES_NACIONAL','LUCRO_PRESUMIDO','LUCRO_REAL'));
```

### 4.3 Adicionando várias colunas de uma vez

É possível adicionar mais de uma coluna em um único comando `ALTER TABLE`, separando-as por vírgula:

```sql
ALTER TABLE auto_infracao
ADD
    id_unidade_fiscal      INT           NULL,
    data_ultima_atualizacao   DATETIME2     NOT NULL CONSTRAINT df_auto_data_atualizacao DEFAULT (SYSDATETIME());
```

---

## 5. Removendo Colunas (DROP COLUMN)

Remover uma coluna é uma operação **destrutiva e irreversível** (os dados daquela coluna são perdidos) — deve ser tratada com o mesmo cuidado que uma exclusão de dados.

### 5.1 O problema das dependências

Antes de remover uma coluna, é preciso verificar se ela está associada a alguma **constraint** (`DEFAULT`, `CHECK`, `UNIQUE`, `FOREIGN KEY`) ou é referenciada por algum **índice**, **view** ou **coluna computada**. O SQL Server **não remove automaticamente** essas dependências — é preciso removê-las explicitamente antes de remover a coluna.

**Cenário fiscal:** a Secretaria decide descontinuar o campo `situacao_cadastral_anterior` da tabela `contribuinte`, um campo textual mantido por compatibilidade com um sistema legado que não é mais usado.

**Passo 1 — Verificar dependências** (constraints associadas à coluna):

```sql
-- Localiza constraints DEFAULT associadas à coluna
SELECT dc.name AS nome_constraint, dc.type_desc
FROM sys.default_constraints dc
JOIN sys.columns c
    ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE dc.parent_object_id = OBJECT_ID('contribuinte')
  AND c.name = 'situacao_cadastral_anterior';

-- Localiza constraints CHECK associadas à coluna
SELECT cc.name AS nome_constraint
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID('contribuinte')
  AND cc.definition LIKE '%situacao_cadastral_anterior%';
```

**Passo 2 — Remover as dependências encontradas, e só então a coluna:**

```sql
ALTER TABLE contribuinte DROP CONSTRAINT df_situacao_cadastral_anterior;  -- exemplo de nome encontrado no passo 1
GO

ALTER TABLE contribuinte DROP COLUMN situacao_cadastral_anterior;
GO
```

> **Boa prática antes de qualquer `DROP COLUMN` em produção:** faça um `SELECT` de amostra dos dados da coluna antes de excluí-la, e considere exportar um backup lógico (ex.: para uma tabela de arquivo morto) se houver qualquer dúvida sobre a necessidade futura daquele dado — especialmente em contexto fiscal, onde certas informações podem ter valor probatório ou de auditoria mesmo após deixarem de ser usadas operacionalmente.

---

## 6. Alterando Tipo e Definição de Coluna (ALTER COLUMN)

`ALTER COLUMN` permite mudar o **tipo de dado**, o **tamanho** ou a **obrigatoriedade** (`NULL`/`NOT NULL`) de uma coluna existente.

### 6.1 Aumentando o tamanho de uma coluna de texto

**Cenário fiscal:** a razão social de determinados contribuintes (especialmente holdings e consórcios) começou a ultrapassar o limite de 150 caracteres originalmente previsto.

```sql
ALTER TABLE contribuinte
ALTER COLUMN razao_social VARCHAR(250) NOT NULL;
```

> **Aumentar** o tamanho de uma coluna de texto ou o número de dígitos de uma coluna numérica é uma operação **segura** — nenhum dado existente pode ser "grande demais" para o novo tamanho, já que o novo limite é maior que o anterior.

### 6.2 Reduzindo o tamanho de uma coluna — risco de truncamento

**Cenário (a evitar sem verificação prévia):** reduzir `descricao` de `tipo_infracao` de `VARCHAR(200)` para `VARCHAR(100)`.

```sql
-- Antes de reduzir, é OBRIGATÓRIO verificar se algum dado já ultrapassa o novo limite:
SELECT id_tipo_infracao, descricao, LEN(descricao) AS tamanho_atual
FROM tipo_infracao
WHERE LEN(descricao) > 100;
```

Se a consulta acima retornar alguma linha, o comando `ALTER COLUMN` para `VARCHAR(100)` **falhará** com um erro de truncamento de dados — o que é, na verdade, um comportamento **desejável**: o SQL Server protege você de perder dados silenciosamente. **Nunca** reduza o tamanho de uma coluna em produção sem antes rodar essa verificação.

### 6.3 Alterando a obrigatoriedade (NULL → NOT NULL)

**Cenário fiscal:** o campo `data_encerramento` de `ordem_servico_fiscalizacao`, inicialmente opcional (`NULL`, pois a fiscalização podia estar em andamento), agora precisa se tornar obrigatório para ordens de serviço já concluídas — mas apenas depois de garantir que nenhuma ordem "concluída" ficou, por erro, sem data de encerramento.

```sql
-- Passo 1: localizar inconsistências antes de tornar a coluna obrigatória
SELECT id_ordem_servico
FROM ordem_servico_fiscalizacao
WHERE status = 'CONCLUIDA' AND data_encerramento IS NULL;

-- Passo 2 (após corrigir/preencher as exceções encontradas): alterar a coluna
ALTER TABLE ordem_servico_fiscalizacao
ALTER COLUMN data_encerramento DATE NOT NULL;
```

> **Atenção:** `ALTER COLUMN ... NOT NULL` falhará imediatamente se existir **qualquer** linha com `NULL` na coluna, independentemente da condição de negócio (`status = 'CONCLUIDA'`) que motivou a mudança — o SQL Server não sabe distinguir "NULO porque ainda está em andamento" de "NULO por erro"; cabe ao desenvolvedor investigar e decidir caso a caso antes de rodar o comando.

> **Redigitar a definição completa da coluna:** repare que, em T-SQL, `ALTER COLUMN` sempre exige que você **redeclare o tipo de dado inteiro** da coluna (`DATE`, no exemplo acima), mesmo que você só queira mudar a obrigatoriedade. Não é possível alterar apenas a nulidade sem repetir o tipo.

---

## 7. Renomeando Colunas e Tabelas (sp_rename)

O SQL Server **não** possui uma cláusula `ALTER TABLE ... RENAME COLUMN` (diferentemente de outros SGBDs). A renomeação é feita através do procedimento de sistema **`sp_rename`**.

### 7.1 Renomeando uma coluna

**Cenário fiscal:** a coluna `situacao` existe em várias tabelas (`nfe`, `nfce`, `cte`, `auto_infracao`), o que gera ambiguidade em relatórios que unem essas tabelas. Decide-se renomear `nfe.situacao` para `situacao_nfe`, tornando o nome autoexplicativo.

```sql
EXEC sp_rename 'nfe.situacao', 'situacao_nfe', 'COLUMN';
```

### 7.2 Renomeando uma tabela

```sql
EXEC sp_rename 'efd_registro_c100', 'efd_documento_fiscal_c100';
```

### 7.3 Cuidados ao renomear

- **`sp_rename` não atualiza automaticamente** o código de *views*, *stored procedures*, *triggers* ou aplicações que referenciam o nome antigo — isso é responsabilidade do desenvolvedor. Após renomear, é indispensável localizar e corrigir todas as referências:

```sql
-- Localizar objetos que mencionam o nome antigo em sua definição
SELECT DISTINCT o.name, o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%situacao%' AND o.type IN ('V','P','TR','FN');
```

- **Nomes de constraints não são renomeados junto** — se uma `CHECK` se chama `ck_nfe_situacao` e referenciava a coluna antiga, o nome da constraint **continua o mesmo** após o `sp_rename` da coluna (apenas a coluna muda de nome); considere renomear a constraint também, por clareza, usando `sp_rename` novamente com o parâmetro `'OBJECT'`.
- Microsoft recomenda cautela redobrada com `sp_rename` em bases de produção — a orientação oficial é preferir, sempre que possível, planejar a nomenclatura correta desde a criação da tabela, reservando a renomeação para correções pontuais e bem testadas em ambiente de homologação antes de aplicar em produção.

---

## 8. Adicionando e Removendo Constraints

### 8.1 Adicionando uma constraint a uma tabela já populada

Como estudado no módulo de Restrições e Integridade, adicionar uma `CHECK` ou `FOREIGN KEY` a uma tabela **já populada** exige que os dados existentes **satisfaçam** a nova regra — caso contrário, o SQL Server rejeita o comando.

**Cenário fiscal:** decide-se impor a regra de que o `valor_multa_aplicado` de um `auto_infracao` nunca pode ser inferior à metade do `valor_multa_base` do tipo de infração correspondente (uma regra de dosimetria mínima).

```sql
-- Passo 1: detectar violações ANTES de tentar criar a constraint
SELECT a.id_auto_infracao, a.valor_multa_aplicado, t.valor_multa_base
FROM auto_infracao a
JOIN tipo_infracao t ON t.id_tipo_infracao = a.id_tipo_infracao
WHERE a.valor_multa_aplicado < (t.valor_multa_base * 0.5);
```

Se essa consulta retornar linhas, existem duas estratégias possíveis:

**Estratégia A — Corrigir os dados primeiro (preferível):**
```sql
-- Após analisar caso a caso e decidir a correção adequada (exemplo simplificado):
UPDATE auto_infracao
SET valor_multa_aplicado = (SELECT t.valor_multa_base * 0.5
                             FROM tipo_infracao t
                             WHERE t.id_tipo_infracao = auto_infracao.id_tipo_infracao)
WHERE id_auto_infracao IN (/* lista de IDs identificados no passo 1, após validação manual */);
```

**Estratégia B — "Perdoar" os dados antigos, aplicando a regra só daqui para frente (uso excepcional):**
```sql
ALTER TABLE auto_infracao WITH NOCHECK
ADD CONSTRAINT ck_auto_multa_minima
    CHECK (valor_multa_aplicado >= 0.5 * (SELECT 1)); -- CHECK simples não pode ter subconsulta; ver nota abaixo
```

> **Nota técnica importante:** uma `CHECK CONSTRAINT` em T-SQL **não pode conter uma subconsulta** referenciando outra tabela (diferentemente do que o exemplo conceitual acima sugere) — o `CHECK` só pode avaliar expressões sobre colunas da **própria linha** da própria tabela. Regras que dependem de **outra tabela** (como comparar `valor_multa_aplicado` com `tipo_infracao.valor_multa_base`) exigem uma **TRIGGER**, no mesmo padrão estudado no módulo de Restrições e Integridade. O exemplo acima foi propositalmente simplificado para introduzir a cláusula `WITH NOCHECK`; veja a versão tecnicamente correta, com `TRIGGER`, no Roteiro Prático (seção 11).

### 8.2 Removendo uma constraint

```sql
ALTER TABLE auto_infracao
DROP CONSTRAINT ck_auto_multa_minima;
```

> Para remover uma `FOREIGN KEY` ou `PRIMARY KEY`, a sintaxe é idêntica — `DROP CONSTRAINT` seguido do nome dado à constraint na criação.

---

## 9. Constraints "Não Confiáveis": WITH NOCHECK e o Otimizador

A cláusula `WITH NOCHECK`, usada na seção anterior, tem uma implicação que vai **além** de simplesmente "pular a verificação dos dados existentes" — ela também marca a constraint como **"não confiável" (not trusted)** no catálogo do SQL Server.

### 9.1 O que significa uma constraint "não confiável"

Quando uma constraint é `NOT TRUSTED`:

- O SQL Server **não pode garantir** que todos os dados da tabela realmente respeitam aquela regra (afinal, os dados antigos nunca foram verificados).
- O **otimizador de consultas** deixa de usar aquela constraint como base para certas otimizações — por exemplo, o otimizador poderia, em uma `FOREIGN KEY` confiável, evitar verificar novamente a existência do "pai" em determinadas consultas (sabendo que a integridade já está garantida); com uma constraint não confiável, essa otimização é desabilitada.
- Isso pode ter **impacto real de desempenho** em relatórios de fiscalização que dependem de junções pesadas entre tabelas grandes.

### 9.2 Verificando quais constraints estão "não confiáveis"

```sql
-- CHECK constraints não confiáveis
SELECT name, is_not_trusted
FROM sys.check_constraints
WHERE is_not_trusted = 1;

-- FOREIGN KEY constraints não confiáveis
SELECT name, is_not_trusted
FROM sys.foreign_keys
WHERE is_not_trusted = 1;
```

### 9.3 Tornando uma constraint confiável novamente

Se, em um momento posterior, os dados antigos forem corrigidos (ou se a Secretaria decidir validar retroativamente), é possível **revalidar** a constraint sem precisar recriá-la:

```sql
ALTER TABLE auto_infracao
WITH CHECK CHECK CONSTRAINT ck_auto_multa_minima;
```

> Sim, `CHECK CHECK` está correto — a primeira palavra-chave (`WITH CHECK`) indica que a operação deve **validar** os dados; a segunda (`CHECK CONSTRAINT`) é o verbo que indica "habilitar a constraint" (em oposição a `NOCHECK CONSTRAINT`, que a desabilita). Após este comando, se todos os dados passarem na validação, a constraint volta a ser `is_not_trusted = 0`.

> **Recomendação para bases fiscais:** `WITH NOCHECK` deve ser tratado como uma **exceção temporária e documentada**, nunca como prática padrão. Toda constraint marcada como não confiável representa um ponto cego na garantia de integridade dos dados — em um contexto de auditoria e fiscalização, isso é particularmente delicado, pois significa que a própria base de dados da SEFAZ-PB pode conter, sem alarme algum, registros que violam suas próprias regras de negócio.

---

## 10. Cuidados Operacionais em Bases de Produção Fiscal

### 10.1 Operações de metadados × operações de reescrita de dados

Nem todo `ALTER TABLE` tem o mesmo custo. É importante que o profissional saiba distinguir:

| Tipo de operação | Custo típico | Exemplos |
|---|---|---|
| **Somente metadados** (rápida, quase instantânea) | Baixo, independente do tamanho da tabela | Adicionar coluna `NULL`; adicionar coluna `NOT NULL` com `DEFAULT` de valor **constante** (SQL Server 2012+); aumentar tamanho de `VARCHAR` |
| **Reescrita de dados** (proporcional ao tamanho da tabela) | Alto em tabelas grandes | Reduzir tamanho de coluna; mudar tipo de dado incompatível (ex.: `VARCHAR` para `INT`); adicionar coluna `NOT NULL` com `DEFAULT` **não determinístico** (`GETDATE()`, `NEWID()`); reconstruir índice após `ALTER COLUMN` |

> Em uma tabela fiscal com dezenas de milhões de linhas (por exemplo, um histórico plurianual de NF-e), a diferença entre uma operação de metadados e uma de reescrita pode significar a diferença entre **milissegundos** e **horas** de execução — e, mais importante, entre **nenhum bloqueio perceptível** e uma **tabela inacessível** durante toda a operação.

### 10.2 Bloqueios (locking) durante o ALTER TABLE

A maioria das operações de `ALTER TABLE` exige um bloqueio exclusivo de *schema* (`Sch-M`) sobre a tabela durante sua execução — o que significa que **nenhuma outra sessão consegue ler ou escrever** naquela tabela enquanto o comando roda, mesmo que a alteração em si seja rápida. Em uma tabela muito usada (como `nfe`, consultada o tempo todo por auditores e sistemas de cruzamento fiscal), isso pode gerar uma fila de bloqueios (*blocking*) que afeta toda a operação da Secretaria.

**Boas práticas recomendadas:**

- Executar alterações estruturais em **janelas de manutenção**, fora do horário de maior uso.
- Testar previamente a operação em ambiente de **homologação**, com um volume de dados representativo, para estimar o tempo de execução real.
- Sempre que possível, envolver a alteração em uma transação explícita (`BEGIN TRANSACTION` / `COMMIT`), permitindo um `ROLLBACK` controlado em caso de problema — embora, para operações de metadados simples, isso raramente seja necessário.
- Realizar **backup** antes de alterações estruturais relevantes, especialmente `DROP COLUMN` (operação destrutiva).
- Em versões Enterprise do SQL Server, algumas operações de índice e de reconstrução podem ser executadas com a opção `ONLINE = ON`, reduzindo (mas não eliminando totalmente) o impacto de bloqueio — vale consultar a equipe de infraestrutura sobre a edição do SQL Server em uso antes de assumir essa possibilidade.

### 10.3 Ordem recomendada de execução em uma mudança de esquema

1. Testar em homologação.
2. Verificar dependências (constraints, índices, views, procedures) e volume de dados afetado.
3. Rodar consultas de **detecção de violação** (como nas seções 6.2, 6.3 e 8.1) antes de qualquer `ALTER COLUMN` ou `ADD CONSTRAINT` restritiva.
4. Executar a alteração em janela de manutenção, com backup recente disponível.
5. Validar o resultado (`sys.columns`, `sys.check_constraints`, contagem de linhas) após a execução.
6. Atualizar a documentação do esquema e comunicar a mudança às equipes que consultam aquela tabela.

---

## 11. Roteiro Prático Completo

**Objetivo:** aplicar, em sequência, todas as técnicas estudadas neste módulo sobre o banco `curso_integridade_fiscal`.

```sql
USE curso_integridade_fiscal;
GO

-- 1. ADICIONANDO COLUNA COM DEFAULT (metadados apenas, valor constante)
ALTER TABLE contribuinte
ADD regime_tributario VARCHAR(20) NOT NULL
    CONSTRAINT df_contribuinte_regime DEFAULT ('LUCRO_PRESUMIDO');
GO

ALTER TABLE contribuinte
ADD CONSTRAINT ck_contribuinte_regime
    CHECK (regime_tributario IN ('SIMPLES_NACIONAL','LUCRO_PRESUMIDO','LUCRO_REAL'));
GO

-- 2. VERIFICANDO DEPENDÊNCIAS ANTES DE REMOVER UMA COLUNA HIPOTÉTICA
-- (supondo que 'contribuinte' tenha uma coluna obsoleta 'sistema_legado_id')
ALTER TABLE contribuinte ADD sistema_legado_id INT NULL;   -- criada apenas para fins didáticos deste roteiro
GO

SELECT dc.name AS nome_constraint
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE dc.parent_object_id = OBJECT_ID('contribuinte') AND c.name = 'sistema_legado_id';
GO

ALTER TABLE contribuinte DROP COLUMN sistema_legado_id;
GO

-- 3. AUMENTANDO O TAMANHO DE UMA COLUNA DE TEXTO (operação segura)
ALTER TABLE contribuinte
ALTER COLUMN razao_social VARCHAR(250) NOT NULL;
GO

-- 4. VERIFICANDO VIOLAÇÕES ANTES DE TORNAR UMA COLUNA OBRIGATÓRIA
SELECT id_ordem_servico
FROM ordem_servico_fiscalizacao
WHERE status = 'CONCLUIDA' AND data_encerramento IS NULL;
GO
-- (Corrigir manualmente eventuais exceções encontradas antes de prosseguir)

ALTER TABLE ordem_servico_fiscalizacao
ALTER COLUMN data_encerramento DATE NOT NULL;
GO

-- 5. RENOMEANDO UMA COLUNA AMBÍGUA
EXEC sp_rename 'nfe.situacao', 'situacao_nfe', 'COLUMN';
GO

-- 6. REGRA DE NEGÓCIO ENTRE TABELAS: TRIGGER (não CHECK) para validar multa mínima
CREATE TRIGGER trg_valida_multa_minima
ON auto_infracao
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN tipo_infracao t ON t.id_tipo_infracao = i.id_tipo_infracao
        WHERE i.valor_multa_aplicado < (t.valor_multa_base * 0.5)
    )
    BEGIN
        RAISERROR('Valor de multa aplicado abaixo do mínimo permitido (50%% da multa-base).', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 7. ADICIONANDO UMA FK COM WITH NOCHECK (cenário: dados históricos "perdoados")
ALTER TABLE auto_infracao
ADD id_unidade_fiscal INT NULL;
GO

ALTER TABLE auto_infracao WITH NOCHECK
ADD CONSTRAINT fk_auto_unidade_fiscal
    FOREIGN KEY (id_unidade_fiscal) REFERENCES unidade_fiscal (id_unidade_fiscal);
GO

-- Verificando se a FK ficou marcada como não confiável
SELECT name, is_not_trusted FROM sys.foreign_keys WHERE name = 'fk_auto_unidade_fiscal';
GO

-- Preenchendo os dados históricos e revalidando a constraint
-- UPDATE auto_infracao SET id_unidade_fiscal = ... WHERE ...   (preenchimento real, fora do escopo deste roteiro)

ALTER TABLE auto_infracao
WITH CHECK CHECK CONSTRAINT fk_auto_unidade_fiscal;
GO

SELECT name, is_not_trusted FROM sys.foreign_keys WHERE name = 'fk_auto_unidade_fiscal';
GO
```

---

## 12. Exercícios Práticos

### Exercício 1 — Adicionando uma coluna obrigatória com DEFAULT
A SEFAZ-PB passou a exigir que toda `nfe` registre um campo `canal_recepcao` (`WEBSERVICE`, `CONTINGENCIA`, `IMPORTACAO_LOTE`), com valor padrão `'WEBSERVICE'` para as notas já existentes.
a) Escreva o `ALTER TABLE` que adiciona essa coluna como `NOT NULL` com o `DEFAULT` apropriado.
b) Adicione, em seguida, uma `CHECK` restringindo o domínio aos três valores previstos.
c) Essa operação, no seu banco, seria classificada como "somente metadados" ou "reescrita de dados"? Justifique com base na seção 10.1.

### Exercício 2 — Removendo uma coluna com segurança
A tabela `cte` possui um campo `observacoes_internas_obsoleto`, não utilizado há anos.
a) Escreva as consultas de verificação de dependências (constraints `DEFAULT` e `CHECK`) antes de removê-la.
b) Escreva o `ALTER TABLE ... DROP COLUMN` correspondente.
c) Que cuidado adicional (fora do próprio comando SQL) você recomendaria antes de executar essa remoção em produção?

### Exercício 3 — Reduzindo o tamanho de uma coluna com segurança
Um colega quer reduzir `nfce.chave_acesso` de `CHAR(44)` para `CHAR(40)`, por engano.
a) Escreva a consulta que você rodaria **antes** de aceitar essa mudança, para verificar se ela é segura.
b) Com base no que você sabe sobre o layout da NF-e/NFC-e (módulos anteriores), essa alteração deveria ser aprovada? Justifique.

### Exercício 4 — Renomeação e suas consequências
Você precisa renomear a tabela `efd_registro_c100` para `efd_documento_fiscal`.
a) Escreva o comando `sp_rename` correspondente.
b) Escreva uma consulta que ajude a localizar *views*, *procedures* ou *triggers* que ainda mencionem o nome antigo da tabela, para correção manual.
c) Por que o `sp_rename`, sozinho, não é suficiente para garantir que o sistema continue funcionando corretamente após a renomeação?

### Exercício 5 — Constraint entre tabelas: por que não um CHECK?
Um colega tenta escrever o seguinte comando e recebe um erro do SQL Server:

```sql
ALTER TABLE efd_registro_c170
ADD CONSTRAINT ck_item_cfop_valido
    CHECK (cfop IN (SELECT cfop_valido FROM tabela_cfop_vigente));
```

a) Por que este comando falha?
b) Qual mecanismo (estudado neste módulo e no de Restrições e Integridade) deveria ser usado para implementar essa regra corretamente?

### Exercício 6 — Diagnosticando uma constraint não confiável
Após um `ALTER TABLE ... WITH NOCHECK ADD CONSTRAINT`, um colega reclama que um relatório de cruzamento entre `auto_infracao` e `unidade_fiscal` ficou mais lento do que antes.
a) Escreva a consulta que verifica se a `FOREIGN KEY` envolvida está marcada como `is_not_trusted`.
b) Explique, em suas próprias palavras, a relação entre esse "não confiável" e a lentidão observada.
c) Descreva os passos necessários para corrigir a situação, incluindo qualquer preparação de dados que possa ser necessária antes.

### Exercício 7 (Desafio) — Planejando uma mudança de esquema completa
A Secretaria decidiu que o campo `valor_frete` de `cte`, atualmente `NUMERIC(15,2)`, deve passar a ser `NUMERIC(18,2)` (para suportar operações de frete internacional de valores muito altos), e que essa coluna deve se tornar obrigatoriamente maior ou igual a zero (`CHECK`) — regra que, hoje, **não** existe na tabela.
Escreva o **plano completo** de execução dessa mudança, na ordem correta, incluindo:
- As consultas de verificação que devem ser rodadas antes de cada alteração.
- Os comandos `ALTER TABLE` necessários.
- Uma justificativa de por que essa sequência específica (e não outra) minimiza o risco de falha ou de dados inconsistentes.

---

## 13. Glossário

| Termo | Definição |
|---|---|
| **DDL (Data Definition Language)** | Subconjunto de comandos SQL que definem/alteram a estrutura do banco (`CREATE`, `ALTER`, `DROP`) |
| **Operação de metadados** | Alteração de esquema que não exige reescrever fisicamente os dados existentes, sendo executada quase instantaneamente |
| **Operação de reescrita de dados** | Alteração de esquema cujo custo é proporcional ao volume de dados da tabela |
| **Bloqueio de schema (Sch-M)** | Tipo de bloqueio exclusivo aplicado durante alterações estruturais, impedindo acesso concorrente à tabela |
| **Constraint confiável (trusted)** | Constraint cuja validade o SQL Server garante para todos os dados da tabela, podendo ser usada pelo otimizador de consultas |
| **Constraint não confiável (not trusted)** | Constraint adicionada com `WITH NOCHECK` sobre dados não verificados, ou cuja validade não pôde ser confirmada |
| **sp_rename** | Procedimento de sistema usado para renomear tabelas, colunas e outros objetos no SQL Server |
| **Janela de manutenção** | Período de baixa utilização do sistema, reservado para alterações estruturais de maior risco |

---

## 14. Referências

- Documentação oficial da Microsoft — "ALTER TABLE (Transact-SQL)": https://learn.microsoft.com/sql/t-sql/statements/alter-table-transact-sql
- Documentação oficial da Microsoft — "sp_rename (Transact-SQL)": https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-rename-transact-sql
- Documentação oficial da Microsoft — "Disable Foreign Key Constraints and Check Constraints": https://learn.microsoft.com/sql/relational-databases/tables/disable-foreign-key-constraints-and-check-constraints
- Documentação oficial da Microsoft — "sys.check_constraints" e "sys.foreign_keys" (catálogo do sistema): https://learn.microsoft.com/sql/relational-databases/system-catalog-views/sys-check-constraints-transact-sql
- ELMASRI, R.; NAVATHE, S. *Sistemas de Banco de Dados*. 7ª ed. Pearson.

---

*Material elaborado para uso interno no curso de Banco de Dados Relacionais — Módulo Alteração de Tabelas (ALTER TABLE) — SEFAZ-PB.*
