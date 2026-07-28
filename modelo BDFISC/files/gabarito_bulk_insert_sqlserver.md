# Gabarito Explicado: Inserção de Dados em Massa com BULK INSERT (SQL Server)

**Curso:** Banco de Dados Relacionais aplicado à Administração Tributária
**Público-alvo:** Instrutor / Profissionais da SEFAZ-PB
**Documento:** Gabarito comentado dos exercícios de `BULK INSERT`

> Este gabarito assume que os 6 arquivos `nfe_lote_001.csv` a `nfe_lote_006.csv` foram copiados para `C:\ImportacaoFiscal\NFe\` no servidor onde o SQL Server está instalado. Ajuste o caminho conforme o ambiente real de cada turma.

---

## Sumário

1. [Preparando o Ambiente](#1-preparando-o-ambiente)
2. [Gabarito — Exercício 1](#2-gabarito--exercício-1)
3. [Gabarito — Exercício 2](#3-gabarito--exercício-2)
4. [Gabarito — Exercício 3](#4-gabarito--exercício-3)
5. [Gabarito — Exercício 4](#5-gabarito--exercício-4)
6. [Gabarito — Exercício 5](#6-gabarito--exercício-5)
7. [Gabarito — Exercício 6 (Desafio)](#7-gabarito--exercício-6-desafio)
8. [Erros Comuns Observados em Turma](#8-erros-comuns-observados-em-turma)

---

## 1. Preparando o Ambiente

```sql
USE curso_integridade_fiscal;
GO

CREATE TABLE stg_nfe_importacao (
    chave_acesso        VARCHAR(44)   NULL,
    cnpj_emitente         VARCHAR(14)   NULL,
    cnpj_destinatario       VARCHAR(14)   NULL,
    numero_nf                 VARCHAR(20)   NULL,
    serie                        VARCHAR(10)   NULL,
    data_emissao                   VARCHAR(10)   NULL,
    valor_total                       VARCHAR(20)   NULL,
    situacao                            VARCHAR(20)   NULL,
    nome_arquivo_origem                    VARCHAR(200)  NULL,
    data_hora_carga                          DATETIME2     NULL DEFAULT (SYSDATETIME())
);
GO
```

Nenhuma novidade aqui em relação ao enunciado — esta é a base para todos os exercícios seguintes.

---

## 2. Gabarito — Exercício 1

```sql
BULK INSERT stg_nfe_importacao
FROM 'C:\ImportacaoFiscal\NFe\nfe_lote_001.csv'
WITH (
    FIRSTROW = 2,                  -- pula a linha de cabeçalho (linha 1)
    FIELDTERMINATOR = ';',         -- separador de campo usado no CSV
    ROWTERMINATOR = '\n',          -- fim de linha (em arquivos gerados no Linux/Python)
    TABLOCK,                       -- otimiza a carga, bloqueando a tabela inteira
    CODEPAGE = '65001'              -- UTF-8, evita problemas de acentuação
);
GO

SELECT COUNT(*) AS total_importado
FROM stg_nfe_importacao
WHERE nome_arquivo_origem IS NULL;  -- ainda não preenchido neste exercício básico
GO
```

**Explicação linha a linha:**

| Parâmetro | Por que usar |
|---|---|
| `FIRSTROW = 2` | O arquivo tem uma linha de cabeçalho (`chave_acesso;cnpj_emitente;...`); sem este parâmetro, o SQL Server tentaria importar o texto do cabeçalho como se fosse uma linha de dados, o que provavelmente geraria um erro de conversão logo na primeira linha. |
| `FIELDTERMINATOR = ';'` | O CSV fornecido usa ponto e vírgula como separador (comum em exportações de sistemas brasileiros, já que a vírgula é usada como separador decimal). |
| `ROWTERMINATOR = '\n'` | Indica onde termina cada linha. **Atenção:** arquivos gerados no Windows geralmente terminam linhas com `\r\n`; se o arquivo do aluno vier de outra origem e usar apenas `\n`, usar `ROWTERMINATOR = '\r\n'` por engano faz com que **todo o arquivo seja lido como uma única linha gigante**, gerando um erro de conversão logo de cara. Se isso acontecer em sala, oriente o aluno a testar `ROWTERMINATOR = '0x0a'` (equivalente a `\n` em hexadecimal, mais confiável entre plataformas). |
| `TABLOCK` | Aplica um bloqueio de tabela durante a carga, permitindo que o SQL Server otimize a operação (evita bloqueios linha a linha, mais lentos). Será aprofundado no Exercício 5. |
| `CODEPAGE = '65001'` | Garante a interpretação correta de caracteres acentuados, caso existam nos dados (não é estritamente necessário neste arquivo específico, mas é uma boa prática recomendável sempre). |

**Resultado esperado:** `5` linhas importadas (o arquivo `nfe_lote_001.csv` não contém erros).

---

## 3. Gabarito — Exercício 2

### 3.1 Tentativa sem tratamento de erro

```sql
BULK INSERT stg_nfe_importacao
FROM 'C:\ImportacaoFiscal\NFe\nfe_lote_004.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    TABLOCK,
    CODEPAGE = '65001'
);
```

**O que acontece:** o SQL Server tenta importar as 7 linhas de dados (5 corretas + 2 com problema). Como as duas últimas linhas do arquivo têm problemas — uma com `ABC,00` no lugar de um valor numérico esperado *(observe que, como a coluna de staging é `VARCHAR`, esse valor específico até seria aceito sem erro — o problema real desta linha só apareceria mais adiante, na migração do Exercício 4)*, e outra com **um campo a menos** (faltando `situacao`) — a segunda linha (com menos colunas do que o esperado) causa uma mensagem de erro do tipo:

```
Msg 4832, Level 16, State 1
Bulk load data conversion error (type mismatch or invalid character for the specified codepage)
for row 7, column 8 (situacao).
```

Isso ocorre porque, ao faltar o `;` final antes de `situacao`, o parser do `BULK INSERT` tenta interpretar o fim da linha como se fosse o valor daquela coluna, ou simplesmente não encontra a 8ª coluna esperada. **Por padrão (sem `MAXERRORS`), o SQL Server tolera no máximo 10 erros antes de interromper — mas mesmo assim, cada linha rejeitada gera uma mensagem de aviso, e a carga pode parar antes do fim do arquivo dependendo da versão e configuração.**

### 3.2 Com MAXERRORS e ERRORFILE

```sql
TRUNCATE TABLE stg_nfe_importacao;  -- limpar antes de reimportar, para não duplicar
GO

BULK INSERT stg_nfe_importacao
FROM 'C:\ImportacaoFiscal\NFe\nfe_lote_004.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    TABLOCK,
    CODEPAGE = '65001',
    MAXERRORS = 5,
    ERRORFILE = 'C:\ImportacaoFiscal\NFe\erros_lote_004.log'
);
GO
```

**Explicação:**

- `MAXERRORS = 5` diz ao SQL Server para **tolerar até 5 linhas com erro** sem abortar a carga inteira — como sabemos que há exatamente 2 linhas problemáticas neste arquivo, qualquer valor de `MAXERRORS` maior ou igual a 2 resolveria; usar 5 é apenas uma margem de segurança didática.
- `ERRORFILE` grava as linhas rejeitadas em um arquivo próprio, junto com um segundo arquivo complementar chamado automaticamente `erros_lote_004.log.Error.Txt`, contendo a **descrição do erro** de cada linha rejeitada. **Importante: o arquivo indicado em `ERRORFILE` não pode já existir** — se você rodar o comando duas vezes seguidas apontando para o mesmo nome, o SQL Server retornará erro dizendo que o arquivo já existe. Ou apague o `.log` e o `.log.Error.Txt` entre execuções, ou use um nome novo a cada teste.

### 3.3 Respostas às perguntas

**a) Sem `MAXERRORS`, o que acontece com a importação inteira quando uma única linha tem erro?**
O padrão do SQL Server, quando `MAXERRORS` não é especificado, é **10**. Ou seja, até 10 linhas com erro são silenciosamente ignoradas (não é que a carga inteira seja abortada por um único erro) — mas se o número de linhas rejeitadas ultrapassar esse limite, a operação inteira é revertida (nenhuma linha entra, nem mesmo as que estavam corretas), a menos que `TABLOCK` combinado com certas condições de "carga minimamente registrada" mude esse comportamento em cenários específicos. Na prática pedagógica, o importante é que o aluno perceba que **sem controle explícito, o comportamento diante de erros fica no "padrão" do SQL Server, e não numa decisão consciente do desenvolvedor** — daí a importância de sempre declarar `MAXERRORS` e `ERRORFILE` explicitamente em rotinas de produção.

**b) Quantas linhas de `nfe_lote_004.csv` foram efetivamente importadas para a `stg_nfe_importacao`?**
**7 linhas.** Isso surpreende muitos alunos à primeira vista: como a tabela de staging tem todas as colunas como `VARCHAR`, a linha com `ABC,00` **é importada normalmente** (afinal, `'ABC,00'` é um texto válido para uma coluna `VARCHAR`) — o problema dela só vai aparecer na hora de converter para `NUMERIC`, no Exercício 4. Já a linha com o campo faltando **é, de fato, rejeitada** pelo `BULK INSERT`, pois o número de colunas não bate com o esperado. Portanto: das 7 linhas de dados do arquivo, **6 são importadas com sucesso** para a staging, e **apenas 1** (a de contagem de colunas incorreta) é efetivamente rejeitada pelo `BULK INSERT` em si.

**c) Por que a coluna `valor_total` da tabela de staging já não ser `VARCHAR` seria, neste exercício, um problema ainda maior?**
Se `valor_total` já fosse `NUMERIC` na própria tabela de staging, a linha com `ABC,00` **também seria rejeitada já nesta etapa** (o `BULK INSERT` tentaria converter o texto para número e falharia) — perdendo a chance de capturarmos essa linha de forma controlada e registrar o motivo da rejeição de forma amigável (como faremos no Exercício 4, via `TRY_CONVERT`). Esse é exatamente o argumento central a favor do **padrão de staging "tudo texto"**: ele separa duas responsabilidades diferentes — "o arquivo tem o número de colunas certo?" (responsabilidade do `BULK INSERT`) e "o conteúdo de cada campo é válido?" (responsabilidade da etapa de validação/migração, sob nosso controle total).

---

## 4. Gabarito — Exercício 3

```sql
-- 1. Tabela temporária para receber a lista de arquivos da pasta
IF OBJECT_ID('tempdb..#arquivos') IS NOT NULL DROP TABLE #arquivos;

CREATE TABLE #arquivos (
    subdirectory     NVARCHAR(260),
    depth             INT,
    is_file            BIT
);

INSERT INTO #arquivos
EXEC master.sys.xp_dirtree 'C:\ImportacaoFiscal\NFe\', 1, 1;

-- Mantém apenas arquivos (não subpastas) terminados em .csv
DELETE FROM #arquivos WHERE is_file = 0 OR subdirectory NOT LIKE '%.csv';

-- 2. Percorre cada arquivo e executa o BULK INSERT dinamicamente
DECLARE @nome_arquivo   NVARCHAR(260);
DECLARE @caminho_completo NVARCHAR(500);
DECLARE @sql               NVARCHAR(MAX);
DECLARE @caminho_pasta       NVARCHAR(260) = 'C:\ImportacaoFiscal\NFe\';
DECLARE @caminho_erro          NVARCHAR(500);

DECLARE cursor_arquivos CURSOR FOR
    SELECT subdirectory FROM #arquivos;

OPEN cursor_arquivos;
FETCH NEXT FROM cursor_arquivos INTO @nome_arquivo;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @caminho_completo = @caminho_pasta + @nome_arquivo;
    SET @caminho_erro = @caminho_pasta + @nome_arquivo + '.errorlog';

    SET @sql = N'
        BULK INSERT stg_nfe_importacao
        FROM ''' + @caminho_completo + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            TABLOCK,
            CODEPAGE = ''65001'',
            MAXERRORS = 20,
            ERRORFILE = ''' + @caminho_erro + N'''
        );';

    BEGIN TRY
        EXEC sp_executesql @sql;

        -- Preenche o nome do arquivo de origem para as linhas recém-importadas
        -- (aquelas ainda sem nome_arquivo_origem preenchido)
        UPDATE stg_nfe_importacao
        SET nome_arquivo_origem = @nome_arquivo
        WHERE nome_arquivo_origem IS NULL;

    END TRY
    BEGIN CATCH
        PRINT 'Falha ao importar o arquivo: ' + @nome_arquivo + ' — ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM cursor_arquivos INTO @nome_arquivo;
END

CLOSE cursor_arquivos;
DEALLOCATE cursor_arquivos;
GO

-- 3. Conferência: quantas linhas vieram de cada arquivo
SELECT nome_arquivo_origem, COUNT(*) AS total_linhas
FROM stg_nfe_importacao
GROUP BY nome_arquivo_origem
ORDER BY nome_arquivo_origem;
```

**Explicação dos pontos-chave:**

- **`xp_dirtree`** é um procedimento de sistema que lista arquivos e pastas de um diretório do servidor. O segundo parâmetro (`1`) indica profundidade 1 (não entra em subpastas), e o terceiro (`1`) pede que a coluna `is_file` seja incluída no resultado, distinguindo arquivos de subpastas. Ele exige que a conta que executa a consulta tenha permissão de leitura no sistema de arquivos do servidor.
- **Por que SQL dinâmico?** A cláusula `FROM` do `BULK INSERT` exige um **literal de string**, não aceita uma variável diretamente (`FROM @caminho` geraria erro de sintaxe). Por isso, construímos o comando inteiro como uma string (`@sql`) e o executamos com `sp_executesql`.
- **`ERRORFILE` diferente por arquivo:** cada iteração do laço usa um nome de arquivo de erro distinto (`@nome_arquivo + '.errorlog'`), evitando o erro "arquivo já existe" e mantendo o rastreamento de qual arquivo gerou qual problema.
- **`nome_arquivo_origem`:** como o `BULK INSERT` não tem uma forma nativa de "carimbar" de qual arquivo cada linha veio, a solução prática é fazer um `UPDATE` logo após cada carga, preenchendo apenas as linhas ainda não identificadas (`WHERE nome_arquivo_origem IS NULL`). Isso funciona corretamente porque processamos um arquivo por vez, em sequência.
- **`TRY...CATCH`:** protege o laço para que, se **um** arquivo falhar catastroficamente (por exemplo, corrompido), os **demais** arquivos da pasta continuem sendo processados — em vez de o script inteiro parar no primeiro problema.

**Resultado esperado:** 6 arquivos processados, com a seguinte contagem de linhas por arquivo (assumindo os arquivos fornecidos): 5 linhas para cada um dos lotes 001, 002, 003, 005 e 006, e **6 linhas** para o lote 004 (5 corretas + 1 com o campo `ABC,00`, que passa pelo `BULK INSERT` mas será tratada no Exercício 4; a sétima linha do arquivo, com coluna faltando, continua sendo rejeitada já nesta etapa).

---

## 5. Gabarito — Exercício 4

```sql
-- Passo 1: tabela definitiva (já apresentada no enunciado)
CREATE TABLE nfe_importada (
    id_nfe             BIGINT IDENTITY(1,1) NOT NULL,
    chave_acesso          CHAR(44)       NOT NULL,
    cnpj_emitente            CHAR(14)       NOT NULL,
    cnpj_destinatario           CHAR(14)       NOT NULL,
    numero_nf                      INT            NOT NULL,
    serie                              SMALLINT       NOT NULL,
    data_emissao                          DATE           NOT NULL,
    valor_total                              NUMERIC(15,2)  NOT NULL,
    situacao                                    VARCHAR(20)    NOT NULL,
    CONSTRAINT pk_nfe_importada PRIMARY KEY (id_nfe),
    CONSTRAINT uq_nfe_importada_chave UNIQUE (chave_acesso),
    CONSTRAINT ck_nfe_importada_valor CHECK (valor_total >= 0),
    CONSTRAINT ck_nfe_importada_situacao CHECK (situacao IN ('AUTORIZADA','CANCELADA','DENEGADA'))
);
GO

CREATE TABLE nfe_importacao_rejeitada (
    id_rejeicao          BIGINT IDENTITY(1,1) NOT NULL,
    chave_acesso            VARCHAR(44)   NULL,
    nome_arquivo_origem        VARCHAR(200)  NULL,
    motivo_rejeicao              VARCHAR(300)  NOT NULL,
    dados_originais_json            NVARCHAR(MAX) NULL,
    CONSTRAINT pk_nfe_importacao_rejeitada PRIMARY KEY (id_rejeicao)
);
GO

-- Passo 2: migração validada, usando TRY_CONVERT
INSERT INTO nfe_importada
    (chave_acesso, cnpj_emitente, cnpj_destinatario, numero_nf, serie,
     data_emissao, valor_total, situacao)
SELECT
    s.chave_acesso,
    s.cnpj_emitente,
    s.cnpj_destinatario,
    TRY_CONVERT(INT, s.numero_nf),
    TRY_CONVERT(SMALLINT, s.serie),
    TRY_CONVERT(DATE, s.data_emissao, 103),           -- estilo 103 = dd/mm/aaaa
    TRY_CONVERT(NUMERIC(15,2), REPLACE(s.valor_total, ',', '.')),
    s.situacao
FROM stg_nfe_importacao s
WHERE
    LEN(s.chave_acesso) = 44
    AND TRY_CONVERT(INT, s.numero_nf) IS NOT NULL
    AND TRY_CONVERT(SMALLINT, s.serie) IS NOT NULL
    AND TRY_CONVERT(DATE, s.data_emissao, 103) IS NOT NULL
    AND TRY_CONVERT(NUMERIC(15,2), REPLACE(s.valor_total, ',', '.')) IS NOT NULL
    AND s.situacao IN ('AUTORIZADA', 'CANCELADA', 'DENEGADA')
    -- evita duplicar NF-e já importadas em execuções anteriores:
    AND NOT EXISTS (
        SELECT 1 FROM nfe_importada n WHERE n.chave_acesso = s.chave_acesso
    );
GO

-- Passo 3: capturando exatamente o que foi rejeitado, com o motivo
INSERT INTO nfe_importacao_rejeitada (chave_acesso, nome_arquivo_origem, motivo_rejeicao, dados_originais_json)
SELECT
    s.chave_acesso,
    s.nome_arquivo_origem,
    CASE
        WHEN LEN(s.chave_acesso) <> 44 THEN 'Chave de acesso com tamanho inválido'
        WHEN TRY_CONVERT(NUMERIC(15,2), REPLACE(s.valor_total, ',', '.')) IS NULL
            THEN 'Valor total não numérico: ' + ISNULL(s.valor_total, '(nulo)')
        WHEN TRY_CONVERT(DATE, s.data_emissao, 103) IS NULL
            THEN 'Data de emissão inválida: ' + ISNULL(s.data_emissao, '(nulo)')
        WHEN s.situacao NOT IN ('AUTORIZADA','CANCELADA','DENEGADA') OR s.situacao IS NULL
            THEN 'Situação fora do domínio esperado: ' + ISNULL(s.situacao, '(nulo/ausente)')
        ELSE 'Motivo não classificado'
    END,
    (SELECT s.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)   -- guarda a linha bruta original, útil para auditoria
FROM stg_nfe_importacao s
WHERE NOT EXISTS (
    SELECT 1 FROM nfe_importada n WHERE n.chave_acesso = s.chave_acesso
);
GO

SELECT * FROM nfe_importacao_rejeitada;
```

**Explicação dos pontos-chave:**

- **`TRY_CONVERT` em vez de `CONVERT`:** a diferença crucial é que `CONVERT` **lança um erro e interrompe a consulta inteira** se qualquer linha falhar na conversão, enquanto `TRY_CONVERT` **retorna `NULL`** para a linha problemática, permitindo que ela seja filtrada com um `WHERE ... IS NOT NULL` sem interromper as demais.
- **`TRY_CONVERT(DATE, s.data_emissao, 103)`:** o terceiro parâmetro (`103`) é o **código de estilo** que informa ao SQL Server que a string de entrada está no formato `dd/mm/aaaa` (formato britânico/brasileiro). Sem esse código de estilo, o SQL Server tentaria interpretar a data com base no idioma padrão da sessão, o que pode gerar conversões erradas (ex.: confundir dia com mês em datas como `03/07/2026`, que poderia virar 3 de julho **ou** 7 de março, dependendo da configuração regional).
- **`REPLACE(s.valor_total, ',', '.')`:** resolve o problema do separador decimal brasileiro antes de tentar a conversão numérica — sem isso, `TRY_CONVERT(NUMERIC(15,2), '1677,81')` retornaria `NULL` (o SQL Server não entende vírgula como separador decimal por padrão).
- **`NOT EXISTS (... WHERE n.chave_acesso = s.chave_acesso)`:** garante **idempotência** — se este script for executado mais de uma vez sobre a mesma staging (por exemplo, sem `TRUNCATE` entre execuções), as NF-e já migradas não são duplicadas.
- **Linhas esperadas em `nfe_importacao_rejeitada`:** a linha `ABC,00` (rejeitada por `valor_total` não numérico) e, dependendo de como o Exercício 3 tratou a linha com coluna faltante — se ela nunca chegou a entrar na staging (por ter sido rejeitada já pelo `BULK INSERT`), ela **não aparecerá aqui**, e sim apenas no arquivo de `ERRORFILE` do Exercício 3. É importante que a turma perceba essa diferença: **existem dois "níveis" de rejeição neste pipeline** — rejeição estrutural (número errado de colunas, tratada pelo `BULK INSERT` e visível só no `ERRORFILE`) e rejeição de conteúdo/domínio (dado com formato ou valor inválido, tratada por nós via `TRY_CONVERT` e visível em `nfe_importacao_rejeitada`).

---

## 6. Gabarito — Exercício 5

**a) Diferença entre `BULK INSERT` com e sem `TABLOCK`:**
Sem `TABLOCK`, o SQL Server aplica bloqueios de granularidade mais fina (geralmente de linha ou de página) durante a carga, permitindo que outras sessões acessem a tabela simultaneamente, mas com **overhead de gerenciamento de bloqueio maior**, tornando a carga mais lenta. Com `TABLOCK`, um único bloqueio é aplicado à tabela inteira durante a operação — a carga fica **significativamente mais rápida**, especialmente em arquivos grandes, mas nenhuma outra sessão consegue ler ou escrever na tabela até a operação terminar. Além disso, `TABLOCK` é um dos **pré-requisitos para que o SQL Server considere a carga como "minimamente registrada" (minimally logged)** sob o modelo de recuperação `BULK_LOGGED` ou `SIMPLE`, o que reduz drasticamente o volume gravado no log de transações.

**b) `BATCHSIZE` / `ROWS_PER_BATCH`:**
Sem esses parâmetros, o SQL Server trata **o arquivo inteiro como uma única transação implícita** — se a carga falhar no meio (por exemplo, na linha 900.000 de um arquivo de 1 milhão de linhas), **toda** a operação é desfeita (rollback), e é preciso recomeçar do zero. Com `BATCHSIZE = N`, o arquivo é dividido em lotes de `N` linhas, cada um committado independentemente — se houver uma falha, apenas o lote em andamento é revertido, preservando os lotes já concluídos. Isso também **evita que o log de transações cresça descontroladamente** durante a carga de arquivos muito grandes, já que cada lote libera espaço de log ao ser committado (dependendo do modelo de recuperação do banco).

**c) Testando `TABLOCK` + `BATCHSIZE = 2` no arquivo do Exercício 1:**

```sql
TRUNCATE TABLE stg_nfe_importacao;
GO

BULK INSERT stg_nfe_importacao
FROM 'C:\ImportacaoFiscal\NFe\nfe_lote_001.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    TABLOCK,
    BATCHSIZE = 2,
    CODEPAGE = '65001'
);
GO

SELECT COUNT(*) FROM stg_nfe_importacao;  -- ainda deve retornar 5
```

O resultado final (5 linhas) **não muda** — `BATCHSIZE` afeta apenas **como** a carga é dividida internamente (em quantos lotes/transações), não **quais** linhas são carregadas. A diferença de comportamento só fica visível em cenários de **falha no meio da carga** (nesse caso, com um arquivo pequeno e sem erros, não há como observar a diferença na prática — vale mencionar isso em turma para não gerar expectativa equivocada de que o resultado mudaria visivelmente).

---

## 7. Gabarito — Exercício 6 (Desafio)

```sql
-- Tabela de controle, para tornar a procedure idempotente
CREATE TABLE controle_importacao_nfe (
    nome_arquivo       VARCHAR(260)  NOT NULL,
    data_hora_processamento   DATETIME2     NOT NULL DEFAULT (SYSDATETIME()),
    linhas_migradas             INT           NOT NULL,
    linhas_rejeitadas             INT           NOT NULL,
    CONSTRAINT pk_controle_importacao_nfe PRIMARY KEY (nome_arquivo)
);
GO

CREATE PROCEDURE sp_importar_pasta_nfe
    @caminho_pasta NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#arquivos_pendentes') IS NOT NULL DROP TABLE #arquivos_pendentes;

    CREATE TABLE #arquivos_pendentes (subdirectory NVARCHAR(260), depth INT, is_file BIT);

    INSERT INTO #arquivos_pendentes
    EXEC master.sys.xp_dirtree @caminho_pasta, 1, 1;

    DELETE FROM #arquivos_pendentes
    WHERE is_file = 0
       OR subdirectory NOT LIKE '%.csv'
       OR subdirectory IN (SELECT nome_arquivo FROM controle_importacao_nfe);  -- pula já processados

    DECLARE @total_arquivos INT = (SELECT COUNT(*) FROM #arquivos_pendentes);
    DECLARE @total_migradas_geral INT = 0;
    DECLARE @total_rejeitadas_geral INT = 0;

    DECLARE @nome_arquivo NVARCHAR(260);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @linhas_antes INT;
    DECLARE @linhas_migradas_arquivo INT;
    DECLARE @linhas_rejeitadas_arquivo INT;

    DECLARE cursor_pendentes CURSOR FOR SELECT subdirectory FROM #arquivos_pendentes;
    OPEN cursor_pendentes;
    FETCH NEXT FROM cursor_pendentes INTO @nome_arquivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'
            BULK INSERT stg_nfe_importacao
            FROM ''' + @caminho_pasta + @nome_arquivo + N'''
            WITH (
                FIRSTROW = 2, FIELDTERMINATOR = '';'', ROWTERMINATOR = ''\n'',
                TABLOCK, CODEPAGE = ''65001'', MAXERRORS = 50,
                ERRORFILE = ''' + @caminho_pasta + @nome_arquivo + N'.errorlog''
            );';

        BEGIN TRY
            EXEC sp_executesql @sql;

            UPDATE stg_nfe_importacao
            SET nome_arquivo_origem = @nome_arquivo
            WHERE nome_arquivo_origem IS NULL;

            -- Migração validada (mesma lógica do Exercício 4), restrita ao arquivo atual
            INSERT INTO nfe_importada
                (chave_acesso, cnpj_emitente, cnpj_destinatario, numero_nf, serie,
                 data_emissao, valor_total, situacao)
            SELECT
                s.chave_acesso, s.cnpj_emitente, s.cnpj_destinatario,
                TRY_CONVERT(INT, s.numero_nf), TRY_CONVERT(SMALLINT, s.serie),
                TRY_CONVERT(DATE, s.data_emissao, 103),
                TRY_CONVERT(NUMERIC(15,2), REPLACE(s.valor_total, ',', '.')),
                s.situacao
            FROM stg_nfe_importacao s
            WHERE s.nome_arquivo_origem = @nome_arquivo
                AND LEN(s.chave_acesso) = 44
                AND TRY_CONVERT(INT, s.numero_nf) IS NOT NULL
                AND TRY_CONVERT(SMALLINT, s.serie) IS NOT NULL
                AND TRY_CONVERT(DATE, s.data_emissao, 103) IS NOT NULL
                AND TRY_CONVERT(NUMERIC(15,2), REPLACE(s.valor_total, ',', '.')) IS NOT NULL
                AND s.situacao IN ('AUTORIZADA','CANCELADA','DENEGADA')
                AND NOT EXISTS (SELECT 1 FROM nfe_importada n WHERE n.chave_acesso = s.chave_acesso);

            SET @linhas_migradas_arquivo = @@ROWCOUNT;

            INSERT INTO nfe_importacao_rejeitada (chave_acesso, nome_arquivo_origem, motivo_rejeicao, dados_originais_json)
            SELECT
                s.chave_acesso, s.nome_arquivo_origem,
                'Falha de conversão de tipo/domínio (ver detalhes no processo de migração)',
                (SELECT s.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
            FROM stg_nfe_importacao s
            WHERE s.nome_arquivo_origem = @nome_arquivo
                AND NOT EXISTS (SELECT 1 FROM nfe_importada n WHERE n.chave_acesso = s.chave_acesso);

            SET @linhas_rejeitadas_arquivo = @@ROWCOUNT;

            INSERT INTO controle_importacao_nfe (nome_arquivo, linhas_migradas, linhas_rejeitadas)
            VALUES (@nome_arquivo, @linhas_migradas_arquivo, @linhas_rejeitadas_arquivo);

            SET @total_migradas_geral = @total_migradas_geral + @linhas_migradas_arquivo;
            SET @total_rejeitadas_geral = @total_rejeitadas_geral + @linhas_rejeitadas_arquivo;

        END TRY
        BEGIN CATCH
            PRINT 'Erro ao processar ' + @nome_arquivo + ': ' + ERROR_MESSAGE();
        END CATCH

        FETCH NEXT FROM cursor_pendentes INTO @nome_arquivo;
    END

    CLOSE cursor_pendentes;
    DEALLOCATE cursor_pendentes;

    SELECT
        @total_arquivos       AS arquivos_processados,
        @total_migradas_geral   AS linhas_migradas_com_sucesso,
        @total_rejeitadas_geral   AS linhas_rejeitadas;
END;
GO

-- Execução:
EXEC sp_importar_pasta_nfe @caminho_pasta = 'C:\ImportacaoFiscal\NFe\';
```

**Pontos de avaliação para o instrutor:**

- A tabela `controle_importacao_nfe` com `nome_arquivo` como `PRIMARY KEY` é o que garante que, numa segunda execução da procedure sobre a mesma pasta, os arquivos já processados sejam **excluídos da lista de pendentes** (`DELETE ... WHERE subdirectory IN (SELECT nome_arquivo FROM controle_importacao_nfe)`) — este é o requisito de idempotência do enunciado.
- Vale discutir com a turma que esta solução **não é a única correta**: alunos mais avançados podem propor mover os arquivos já processados para uma subpasta `\processados\` (manipulação de arquivos via `xp_cmdshell`) em vez de manter uma tabela de controle — ambas as abordagens são válidas e podem ser aceitas, desde que a lógica de "não reprocessar o que já foi processado" esteja presente e corretamente justificada.
- Atenção ao uso de **`xp_cmdshell`** (caso algum aluno opte por essa abordagem): é um recurso **desabilitado por padrão** no SQL Server por motivos de segurança, e sua habilitação exige privilégios de administrador do servidor — mencione isso em turma como um alerta de segurança, e não apenas como um detalhe técnico.

---

## 8. Erros Comuns Observados em Turma

| Erro do aluno | Causa | Como orientar |
|---|---|---|
| `Cannot bulk load. The file "..." does not exist` | O caminho informado é do computador do aluno, não do servidor SQL Server | Reforçar a seção 2 do enunciado: o `BULK INSERT` roda no servidor, não no cliente |
| `The bulk load failed. The column is too long...` | `ROWTERMINATOR` errado (ex.: `\r\n` quando o arquivo só usa `\n`, fazendo o SQL Server ler o arquivo inteiro como uma única linha) | Sugerir testar com `0x0a` no lugar de `'\n'` |
| Erro "arquivo já existe" ao usar `ERRORFILE` | O aluno rodou o mesmo comando duas vezes seguidas sem apagar o log anterior | Apagar manualmente o `.log` e o `.log.Error.Txt`, ou usar nomes de arquivo com timestamp |
| `Msg 229: The user does not have permission to perform this action` | Falta a permissão `ADMINISTER BULK OPERATIONS` ou associação à role `bulkadmin` | Verificar com o DBA/instrutor as permissões do usuário de treinamento |
| Linhas "sumindo" silenciosamente sem mensagem de erro visível | O aluno não usou `ERRORFILE`, então as linhas rejeitadas não deixam rastro nenhum | Reforçar que `ERRORFILE` deveria ser prática obrigatória em qualquer rotina de produção, nunca opcional |

---

*Gabarito elaborado para uso do instrutor no curso de Banco de Dados Relacionais — Exercícios de BULK INSERT — SEFAZ-PB.*
