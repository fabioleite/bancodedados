# Roteiro de laboratório — Divergência entre NF-e e EFD com CFOP externo e carga massiva em CSV

**Curso:** Banco de Dados Relacional aplicado à Fiscalização Tributária
**Módulo:** Carga de dados CSV, staging e integração analítica
**SGBD:** Microsoft SQL Server (T-SQL)
**Banco de exemplo:** `curso_integridade_fiscal`
**Base de referência:** [roteiro_subconsultas_tsql.md](roteiro_subconsultas_tsql.md) e o script [modulo_03/banco_fiscal/01_criar_banco.sql](../modulo_03/banco_fiscal/01_criar_banco.sql)

---

## Como usar este roteiro

Este roteiro foi pensado para reproduzir uma situação realista de fiscalização tributária: o auditor recebe uma tabela externa em CSV com informações de operações fiscais e uma tabela de referência com CFOPs, e precisa integrar esse material com a base interna do banco para detectar divergências relevantes entre notas fiscais e EFD.

Cada etapa contém:

- **O que fazer** → a operação ou comando a executar
- **O que observar** → o que a etapa demonstra
- **A armadilha** → o detalhe que costuma gerar confusão

Execute as etapas em sequência e revise os resultados antes de seguir.

### Preparação

```sql
USE curso_integridade_fiscal;
GO

SELECT COUNT(*) AS qtd_contribuintes
FROM dbo.contribuinte;

SELECT COUNT(*) AS qtd_nfe
FROM dbo.nfe;

SELECT COUNT(*) AS qtd_efd_c100
FROM dbo.efd_c100;
GO
```

Antes de iniciar, confirme que o script [modulo_03/banco_fiscal/01_criar_banco.sql](../modulo_03/banco_fiscal/01_criar_banco.sql) já foi executado.

---

## Situação para a fiscalização tributária

Suponha que a Secretaria da Fazenda recebeu um arquivo CSV de outra instância fiscal, contendo documentos de operações com CFOPs e valores de mercadorias que não aparecem de forma consistente na EFD ou nas notas fiscais do contribuinte. O problema não é só a presença de operação, e sim a comparação do que foi declarado no CSV externo com o que foi informado na base interna.

### Arquivo externo recebido

O auditor recebe um arquivo com cerca de 10 mil registros, nomeado assim:

```text
modulo 04/dados/divergencia_nfe_efd_202401.csv
```

Esse arquivo reúne operações em período fiscal e traz as seguintes colunas:

```text
periodo_apuracao;cnpj;uf_origem;uf_destino;cfop;valor_documento;valor_icms;tipo_operacao;numero_doc;chave_acesso;situacao_documento;fonte_dado
```

Exemplo de registros:

```text
202401;12345678000199;SP;PB;6102;18000.00;1800.00;SAIDA;50001;35240112345678000199550010000000011000000011;AUTORIZADA;SISTEMA_EXTERNO
202401;98765432000155;RJ;PB;6108;24500.00;2200.00;SAIDA;50002;35240198765432000155550010000000012000000012;AUTORIZADA;SISTEMA_EXTERNO
202401;11122233000144;MG;PB;5405;9800.00;950.00;ENTRADA;50003;35240111122233000144550010000000013000000013;AUTORIZADA;SISTEMA_EXTERNO
```

### Inspeção rápida dos CSVs no PowerShell

Antes de fazer a carga em massa, vale checar a estrutura e o tamanho do arquivo. No Windows PowerShell, os comandos abaixo ajudam a validar o cabeçalho, a quantidade de registros e a amostra inicial.

#### 1) Quantos campos possui a linha de cabeçalho do arquivo

```powershell
$arquivo = 'C:\projetos\bancodedados\modulo 04\dados\divergencia_nfe_efd_202401.csv'
$linhaCabecalho = Get-Content $arquivo -TotalCount 1
$campos = ($linhaCabecalho -split ';')
$campos.Count
$campos
```

**O que observar:** o resultado deve mostrar 12 colunas no CSV de divergência e 5 colunas no CSV de CFOP.

#### 2) Quantos registros ao todo cada CSV possui

```powershell
$arquivo = 'C:\projetos\bancodedados\modulo 04\dados\divergencia_nfe_efd_202401.csv'
$registros = (Get-Content $arquivo).Count - 1
Write-Host "Total de registros em divergencia_nfe_efd_202401.csv: $registros"

$arquivoCfop = 'C:\projetos\bancodedados\modulo 04\dados\cfop_referencia_externa.csv'
$registrosCfop = (Get-Content $arquivoCfop).Count - 1
Write-Host "Total de registros em cfop_referencia_externa.csv: $registrosCfop"
```

#### 3) Exibir as 10 primeiras linhas no PowerShell

```powershell
Get-Content 'C:\projetos\bancodedados\modulo 04\dados\divergencia_nfe_efd_202401.csv' -TotalCount 11
```

```powershell
Get-Content 'C:\projetos\bancodedados\modulo 04\dados\cfop_referencia_externa.csv' -TotalCount 11
```

**A armadilha:** se o cabeçalho estiver quebrado, a contagem de colunas e a carga em massa podem falhar mesmo antes do `BULK INSERT`.

### Tabela de referência externa com CFOP

Além do arquivo de operação, o auditor também recebe uma tabela de referência com os CFOPs cadastrados naquele sistema externo. Essa tabela é essencial para validar a natureza da operação e classificar o tipo de movimento.

Arquivo:

```text
modulo 04/dados/cfop_referencia_externa.csv
```

Estrutura:

```text
cfop;descricao_cfop;tipo_operacao;natureza;aliquota_ref
6102;Venda de mercadoria para fora do estado;SAIDA;INTERESTADUAL;18
6108;Venda de mercadoria para consumidor final;SAIDA;INTERESTADUAL;18
5405;Compra de mercadoria para industrializacao;ENTRADA;INTERESTADUAL;12
```

### Objetivo da análise

A análise busca responder questões como:

- há divergência entre o valor informado no CSV externo e o valor declarado nas NF-e do contribuinte?
- existe diferença entre as operações declaradas na EFD e as operações reportadas no sistema externo?
- os CFOPs informados estão consistentes com a natureza da operação?
- quais contribuintes estão com risco de omissão, sobredeclaração ou divergência fiscal?

Essa é uma situação muito próxima do trabalho real de auditoria fiscal, em que o banco interno precisa ser combinado com dados vindos de fora para detectar anomalias.

---

## Etapa 1 — Criar as tabelas de staging

A primeira etapa é receber os dados brutos em tabelas de staging. A ideia é evitar alterar a estrutura principal da base antes da validação.

### 1.1 Tabela de staging para as operações externas

```sql
DROP TABLE IF EXISTS dbo.stg_divergencia_nfe_efd;
GO

CREATE TABLE dbo.stg_divergencia_nfe_efd (
    periodo_apuracao       CHAR(6)        NOT NULL,
    cnpj                   CHAR(14)       NOT NULL,
    uf_origem              CHAR(2)        NOT NULL,
    uf_destino             CHAR(2)        NOT NULL,
    cfop                   CHAR(4)        NOT NULL,
    valor_documento        DECIMAL(15,2)  NOT NULL,
    valor_icms             DECIMAL(15,2)  NOT NULL,
    tipo_operacao          VARCHAR(20)    NOT NULL,
    numero_doc             INT            NOT NULL,
    chave_acesso           VARCHAR(60)    NOT NULL,
    situacao_documento     VARCHAR(20)    NOT NULL,
    fonte_dado             VARCHAR(50)    NOT NULL
);
GO
```

**Atenção:** a chave do arquivo gerado neste laboratório pode ultrapassar 44 caracteres em alguns exemplos de geração automática. Por isso, em staging, o campo `chave_acesso` deve ser `VARCHAR(60)` para evitar o erro de truncamento no `BULK INSERT` (`Mensagem 4863`). Se a fonte for uma chave NF-e real e padronizada, você pode usar `CHAR(44)` ou `VARCHAR(44)`, mas no material didático do CSV gerado é melhor deixar um espaço maior.

### 1.2 Tabela de staging para CFOPs externos

```sql
DROP TABLE IF EXISTS dbo.stg_cfop_externo;
GO

CREATE TABLE dbo.stg_cfop_externo (
    cfop                   CHAR(4)        NOT NULL,
    descricao_cfop         VARCHAR(120)   NOT NULL,
    tipo_operacao          VARCHAR(20)    NOT NULL,
    natureza               VARCHAR(40)    NOT NULL,
    aliquota_ref           DECIMAL(5,2)   NOT NULL
);
GO
```

**O que observar:** as tables de staging mantêm o dado bruto e permitem avaliações de integridade antes da análise.

**A armadilha:** não se deve usar a tabela principal para consumo de dados externos antes de validar consistência, qualidade e período fiscal.

---

## Etapa 2 — Carregar os dados via `BULK INSERT`

A carga em massa é a forma mais apropriada para este tipo de arquivo, principalmente quando há dezenas de milhares de registros.

### 2.1 Arquivo grande de divergência

No diretório do projeto, foi gerado um arquivo de exemplo com aproximadamente 10 mil registros. A estrutura do CSV é a seguinte:

```text
periodo_apuracao;cnpj;uf_origem;uf_destino;cfop;valor_documento;valor_icms;tipo_operacao;numero_doc;chave_acesso;situacao_documento;fonte_dado
202401;12345678000199;SP;PB;6102;18000.00;1800.00;SAIDA;50001;35240112345678000199550010000000011000000011;AUTORIZADA;SISTEMA_EXTERNO
...
```

O arquivo completo foi gerado em:

```text
modulo 04/dados/divergencia_nfe_efd_202401.csv
```

### 2.2 Comando de carga do CSV de divergência

> Se o arquivo gerado no laboratório estiver com chaves maiores do que 44 caracteres, ajuste o tipo do campo `chave_acesso` do staging para `VARCHAR(60)` antes de executar o `BULK INSERT`. Isso evita a falha de truncamento `Mensagem 4863`.

```sql
BULK INSERT dbo.stg_divergencia_nfe_efd
FROM 'C:\dados_fiscais\divergencia_nfe_efd_202401.csv'
WITH (
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    KEEPNULLS,
    TABLOCK,
    CODEPAGE = '65001'
);
GO
```

### 2.3 Comando de carga da tabela de CFOP externa

```sql
BULK INSERT dbo.stg_cfop_externo
FROM 'C:\dados_fiscais\cfop_referencia_externa.csv'
WITH (
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    KEEPNULLS,
    TABLOCK,
    CODEPAGE = '65001'
);
GO
```

**O que observar:** o comando `BULK INSERT` lê milhares de linhas em uma única operação, o que é muito útil na rotina de auditoria.

**A armadilha:** sempre verificar o caminho do arquivo, o delimitador e o cabeçalho do CSV. Em arquivos grandes, um detalhe simples pode quebrar toda a carga.

### Validação inicial

```sql
SELECT TOP (10)
    periodo_apuracao,
    cnpj,
    uf_origem,
    uf_destino,
    cfop,
    valor_documento,
    valor_icms,
    tipo_operacao
FROM dbo.stg_divergencia_nfe_efd;
GO
```

```sql
SELECT
    COUNT(*) AS qtd_registros,
    SUM(valor_documento) AS total_documentos,
    SUM(valor_icms) AS total_icms
FROM dbo.stg_divergencia_nfe_efd;
GO
```

```sql
SELECT *
FROM dbo.stg_cfop_externo;
GO
```

---

## Etapa 3 — Normalização e validação do staging

Antes de usar a carga em auditoria, vale fazer uma padronização dos campos para evitar inconsistências de texto e período.

```sql
SELECT
    periodo_apuracao,
    cnpj,
    UPPER(uf_origem) AS uf_origem_norm,
    UPPER(uf_destino) AS uf_destino_norm,
    cfop,
    CAST(valor_documento AS DECIMAL(15,2)) AS valor_documento_norm,
    CAST(valor_icms AS DECIMAL(15,2)) AS valor_icms_norm,
    UPPER(tipo_operacao) AS tipo_operacao_norm,
    situacao_documento
FROM dbo.stg_divergencia_nfe_efd;
GO
```

### Ajustes possíveis

```sql
UPDATE dbo.stg_divergencia_nfe_efd
SET uf_origem = UPPER(LTRIM(RTRIM(uf_origem))),
    uf_destino = UPPER(LTRIM(RTRIM(uf_destino))),
    tipo_operacao = UPPER(LTRIM(RTRIM(tipo_operacao))),
    situacao_documento = UPPER(LTRIM(RTRIM(situacao_documento)));
GO
```

**A armadilha:** mesmo quando o volume de dados for grande, a auditoria exige consistência. Corrigir a normalização antes da análise reduz ruído e aumenta a confiabilidade da hipótese fiscal.

---

## Etapa 4 — Construção da visão integrada com NF-e, EFD e CFOP externo

Agora vamos comparar a base interna com os dados externos e a referência de CFOP. O objetivo é identificar divergências em base fiscal.

### 4.1 Visão de auditoria fiscal em 3 etapas

A ideia aqui é quebrar o problema em partes menores para facilitar a leitura e a manutenção da lógica. Em vez de montar uma única consulta grande, vamos construir 3 visões simples e, ao final, integrar tudo em uma visão final.

#### Etapa 1 — Agregar as NF-e por contribuinte e mês

Primeiro, resumimos as NF-e internas por mês. Assim, a base interna fica pronta para ser comparada com o valor informado no arquivo externo.

```sql
CREATE VIEW dbo.vw_nfe_por_mes_contribuinte AS
SELECT
    n.id_emitente AS id_contribuinte,
    CAST(LEFT(CONVERT(VARCHAR(7), n.data_emissao, 120), 4) + '-' + SUBSTRING(CONVERT(VARCHAR(7), n.data_emissao, 120), 6, 2) + '-01' AS DATE) AS data_inicio_mes,
    SUM(n.valor_total) AS valor_nfe_no_banco,
    COUNT(DISTINCT n.id_nfe) AS qtd_nfe_relacionadas
FROM dbo.nfe AS n
GROUP BY
    n.id_emitente,
    CAST(LEFT(CONVERT(VARCHAR(7), n.data_emissao, 120), 4) + '-' + SUBSTRING(CONVERT(VARCHAR(7), n.data_emissao, 120), 6, 2) + '-01' AS DATE);
GO
```

Alternativa para o design:

```sql
CREATE VIEW dbo.vw_nfe_por_mes_contribuinte_design AS
    SELECT id_emitente AS id_contribuinte, format(data_emissao, 'yyyyMM') AS data_inicio_mes, --format(data_emissao; 'yyyyMM')
      SUM(valor_total) AS valor_nfe_no_banco, 
      COUNT(DISTINCT id_nfe) AS qtd_nfe_relacionadas
    FROM  dbo.nfe AS n
    GROUP BY id_emitente, format(data_emissao, 'yyyyMM') --format(data_emissao; 'yyyyMM')
```

#### Etapa 2 — Agregar o EFD por contribuinte e mês

Depois, fazemos o mesmo para o EFD. Essa visão representa a base fiscal contabilizada no SGBD, por período e contribuinte.

```sql
CREATE VIEW dbo.vw_efd_por_mes_contribuinte AS
SELECT
    efd.id_contribuinte,
    CAST(LEFT(efd.periodo_apuracao, 4) + '-' + SUBSTRING(efd.periodo_apuracao, 5, 2) + '-01' AS DATE) AS data_inicio_mes,
    SUM(efd.valor_documento) AS valor_efd_no_banco,
    COUNT(DISTINCT efd.id_c100) AS qtd_efd_relacionadas
FROM dbo.efd_c100 AS efd
GROUP BY
    efd.id_contribuinte,
    CAST(LEFT(efd.periodo_apuracao, 4) + '-' + SUBSTRING(efd.periodo_apuracao, 5, 2) + '-01' AS DATE);
GO
```

Alternativa para o design:

```sql
CREATE VIEW dbo.vw_efd_por_mes_contribuinte AS
SELECT
    efd.id_contribuinte,
    periodo_apuracao AS data_inicio_mes,
    SUM(efd.valor_documento) AS valor_efd_no_banco,
    COUNT(DISTINCT efd.id_c100) AS qtd_efd_relacionadas
FROM dbo.efd_c100 AS efd
GROUP BY
    efd.id_contribuinte,
    periodo_apuracao;
GO
```

#### Etapa 3 — Enriquecer o staging com dados do contribuinte e do CFOP

Nesta etapa, o staging fica pronto para comparação. Aqui ligamos os dados externos com os dados cadastrais e com a tabela de referência de CFOP.

```sql
CREATE VIEW dbo.vw_operacao_externa_enriquecida AS
SELECT
    stg.periodo_apuracao,
    c.id_contribuinte,
    c.cnpj,
    c.razao_social,
    c.regime_tributario,
    stg.uf_origem,
    stg.uf_destino,
    stg.cfop,
    cfop.descricao_cfop,
    cfop.natureza,
    stg.tipo_operacao,
    stg.valor_documento AS valor_operacao_externa,
    stg.fonte_dado
FROM dbo.stg_divergencia_nfe_efd AS stg
LEFT JOIN dbo.contribuinte AS c
    ON c.cnpj = stg.cnpj
LEFT JOIN dbo.stg_cfop_externo AS cfop
    ON cfop.cfop = stg.cfop;
GO
```

#### Visão final — integração das três fontes

Agora reunimos as três visões: a operação externa, o agregado de NF-e e o agregado do EFD. Assim, a análise fica clara e mantida em blocos menores.

```sql
CREATE VIEW dbo.vw_divergencia_nfe_efd_cfop AS
SELECT
    ext.periodo_apuracao,
    ext.id_contribuinte,
    ext.cnpj,
    ext.razao_social,
    ext.regime_tributario,
    ext.uf_origem,
    ext.uf_destino,
    ext.cfop,
    ext.descricao_cfop,
    ext.natureza,
    ext.tipo_operacao,
    ext.valor_operacao_externa,
    ISNULL(nfe.valor_nfe_no_banco, 0) AS valor_nfe_no_banco,
    ISNULL(efd.valor_efd_no_banco, 0) AS valor_efd_no_banco,
    ext.valor_operacao_externa - ISNULL(nfe.valor_nfe_no_banco, 0) AS diferenca_nfe,
    ext.valor_operacao_externa - ISNULL(efd.valor_efd_no_banco, 0) AS diferenca_efd,
    CASE
        WHEN ext.id_contribuinte IS NULL THEN 'CONTRIBUINTE NAO CADASTRADO'
        WHEN ext.cfop IS NULL THEN 'CFOP NAO ENCONTRADO NA REFERENCIA'
        WHEN ABS(ext.valor_operacao_externa - ISNULL(nfe.valor_nfe_no_banco, 0)) > 0 THEN 'DIVERGENCIA NF-E'
        WHEN ABS(ext.valor_operacao_externa - ISNULL(efd.valor_efd_no_banco, 0)) > 0 THEN 'DIVERGENCIA EFD'
        ELSE 'CONSISTENTE'
    END AS situacao_diferenca,
    ISNULL(nfe.qtd_nfe_relacionadas, 0) AS qtd_nfe_relacionadas,
    ISNULL(efd.qtd_efd_relacionadas, 0) AS qtd_efd_relacionadas,
    ext.fonte_dado
FROM dbo.vw_operacao_externa_enriquecida AS ext
LEFT JOIN dbo.vw_nfe_por_mes_contribuinte AS nfe
    ON nfe.id_contribuinte = ext.id_contribuinte
   AND nfe.data_inicio_mes = CAST(LEFT(ext.periodo_apuracao, 4) + '-' + SUBSTRING(ext.periodo_apuracao, 5, 2) + '-01' AS DATE)
LEFT JOIN dbo.vw_efd_por_mes_contribuinte AS efd
    ON efd.id_contribuinte = ext.id_contribuinte
   AND efd.data_inicio_mes = CAST(LEFT(ext.periodo_apuracao, 4) + '-' + SUBSTRING(ext.periodo_apuracao, 5, 2) + '-01' AS DATE);
GO
```

Alternativa para o design:

```sql
CREATE VIEW dbo.vw_divergencia_nfe_efd_cfop AS
SELECT
    ext.periodo_apuracao,
    ext.id_contribuinte,
    ext.cnpj,
    ext.razao_social,
    ext.regime_tributario,
    ext.uf_origem,
    ext.uf_destino,
    ext.cfop,
    ext.descricao_cfop,
    ext.natureza,
    ext.tipo_operacao,
    ext.valor_operacao_externa,
    ISNULL(nfe.valor_nfe_no_banco, 0) AS valor_nfe_no_banco,
    ISNULL(efd.valor_efd_no_banco, 0) AS valor_efd_no_banco,
    ext.valor_operacao_externa - ISNULL(nfe.valor_nfe_no_banco, 0) AS diferenca_nfe,
    ext.valor_operacao_externa - ISNULL(efd.valor_efd_no_banco, 0) AS diferenca_efd,
    CASE
        WHEN ext.id_contribuinte IS NULL THEN 'CONTRIBUINTE NAO CADASTRADO'
        WHEN ext.cfop IS NULL THEN 'CFOP NAO ENCONTRADO NA REFERENCIA'
        WHEN ABS(ext.valor_operacao_externa - ISNULL(nfe.valor_nfe_no_banco, 0)) > 0 THEN 'DIVERGENCIA NF-E'
        WHEN ABS(ext.valor_operacao_externa - ISNULL(efd.valor_efd_no_banco, 0)) > 0 THEN 'DIVERGENCIA EFD'
        ELSE 'CONSISTENTE'
    END AS situacao_diferenca,
    ISNULL(nfe.qtd_nfe_relacionadas, 0) AS qtd_nfe_relacionadas,
    ISNULL(efd.qtd_efd_relacionadas, 0) AS qtd_efd_relacionadas,
    ext.fonte_dado
FROM dbo.vw_operacao_externa_enriquecida AS ext
LEFT JOIN dbo.vw_nfe_por_mes_contribuinte_design AS nfe
    ON nfe.id_contribuinte = ext.id_contribuinte
   AND nfe.data_inicio_mes = ext.periodo_apuracao
LEFT JOIN dbo.vw_efd_por_mes_contribuinte AS efd
    ON efd.id_contribuinte = ext.id_contribuinte
   AND efd.data_inicio_mes = ext.periodo_apuracao;
GO
```

**O que observar:** essa abordagem deixa a lógica pedagógica e fácil de depurar. Cada visão responde a uma pergunta:

1. Quantas NF-e existem por empresa e mês?
2. Quanto o EFD registra por empresa e mês?
3. Qual operação externa foi recebida e qual o contexto dela?
4. Por fim, o que diverge entre o arquivo externo e os dados internos?

**A armadilha:** a comparação por valor bruto pode não mostrar tudo. Em auditoria fiscal, vale complementar a análise com período, UF, CFOP e tipo de operação antes de concluir que há erro.

### 4.2 Consulta de amostra da visão

```sql
SELECT TOP (50)
    periodo_apuracao,
    cnpj,
    razao_social,
    cfop,
    descricao_cfop,
    valor_operacao_externa,
    valor_nfe_no_banco,
    valor_efd_no_banco,
    diferenca_nfe,
    diferenca_efd,
    situacao_diferenca
FROM dbo.vw_divergencia_nfe_efd_cfop
WHERE situacao_diferenca <> 'CONSISTENTE'
ORDER BY ABS(diferenca_nfe) DESC;
GO
```

---

## Etapa 5 — Materializar a visão em tabela para auditoria operacional

Uma visão é boa para análise ad hoc, mas em rotina de fiscalização é útil materializar o resultado em uma tabela de auditoria. Isso facilita relatórios, filtros, revisão posterior e priorização de ações.

```sql
DROP TABLE IF EXISTS dbo.tb_divergencia_nfe_efd_cfop;
GO

SELECT
    periodo_apuracao,
    id_contribuinte,
    cnpj,
    razao_social,
    regime_tributario,
    uf_origem,
    uf_destino,
    cfop,
    descricao_cfop,
    natureza,
    tipo_operacao,
    valor_operacao_externa,
    valor_nfe_no_banco,
    valor_efd_no_banco,
    diferenca_nfe,
    diferenca_efd,
    situacao_diferenca,
    qtd_nfe_relacionadas,
    qtd_efd_relacionadas,
    fonte_dado
INTO dbo.tb_divergencia_nfe_efd_cfop
FROM dbo.vw_divergencia_nfe_efd_cfop;
GO
```

**O que observar:** a tabela materializada conserva um snapshot em um momento específico. Isso permite ao auditor produzir relatórios e revisitar a análise sem recalcular a junção em tempo real.

**A armadilha:** se o processo for repetido para múltiplos períodos, deve haver controle de atualização do snapshot para não misturar períodos diferentes.

---

## Etapa 6 — Stored procedure para automatizar a carga, a visão e a materialização

A etapa final automatiza todo o fluxo: limpeza da tabela de staging, carga dos CSVs, comparação dos dados e materialização da tabela de auditoria.

Para deixar o código mais claro e evitar `EXEC` dinâmico, a visão é criada separadamente e a procedure apenas carrega os dados e materializa o resultado do período solicitado.

```sql
CREATE VIEW dbo.vw_divergencia_nfe_efd_cfop AS
WITH nfe_agg AS (
    SELECT
        n.id_emitente AS id_contribuinte,
        CAST(LEFT(CONVERT(VARCHAR(7), n.data_emissao, 120), 4) + '-' + SUBSTRING(CONVERT(VARCHAR(7), n.data_emissao, 120), 6, 2) + '-01' AS DATE) AS data_inicio_mes,
        SUM(n.valor_total) AS valor_nfe_no_banco,
        COUNT(DISTINCT n.id_nfe) AS qtd_nfe_relacionadas
    FROM dbo.nfe AS n
    GROUP BY
        n.id_emitente,
        CAST(LEFT(CONVERT(VARCHAR(7), n.data_emissao, 120), 4) + '-' + SUBSTRING(CONVERT(VARCHAR(7), n.data_emissao, 120), 6, 2) + '-01' AS DATE)
),
efd_agg AS (
    SELECT
        efd.id_contribuinte,
        CAST(LEFT(efd.periodo_apuracao, 4) + '-' + SUBSTRING(efd.periodo_apuracao, 5, 2) + '-01' AS DATE) AS data_inicio_mes,
        SUM(efd.valor_documento) AS valor_efd_no_banco,
        COUNT(DISTINCT efd.id_c100) AS qtd_efd_relacionadas
    FROM dbo.efd_c100 AS efd
    GROUP BY
        efd.id_contribuinte,
        CAST(LEFT(efd.periodo_apuracao, 4) + '-' + SUBSTRING(efd.periodo_apuracao, 5, 2) + '-01' AS DATE)
)
SELECT
    stg.periodo_apuracao,
    c.id_contribuinte,
    c.cnpj,
    c.razao_social,
    c.regime_tributario,
    stg.uf_origem,
    stg.uf_destino,
    stg.cfop,
    cfop.descricao_cfop,
    cfop.natureza,
    stg.tipo_operacao,
    stg.valor_documento AS valor_operacao_externa,
    ISNULL(nfe.valor_nfe_no_banco, 0) AS valor_nfe_no_banco,
    ISNULL(efd.valor_efd_no_banco, 0) AS valor_efd_no_banco,
    stg.valor_documento - ISNULL(nfe.valor_nfe_no_banco, 0) AS diferenca_nfe,
    stg.valor_documento - ISNULL(efd.valor_efd_no_banco, 0) AS diferenca_efd,
    CASE
        WHEN c.id_contribuinte IS NULL THEN 'CONTRIBUINTE NAO CADASTRADO'
        WHEN cfop.cfop IS NULL THEN 'CFOP NAO ENCONTRADO NA REFERENCIA'
        WHEN ABS(stg.valor_documento - ISNULL(nfe.valor_nfe_no_banco, 0)) > 0 THEN 'DIVERGENCIA NF-E'
        WHEN ABS(stg.valor_documento - ISNULL(efd.valor_efd_no_banco, 0)) > 0 THEN 'DIVERGENCIA EFD'
        ELSE 'CONSISTENTE'
    END AS situacao_diferenca,
    ISNULL(nfe.qtd_nfe_relacionadas, 0) AS qtd_nfe_relacionadas,
    ISNULL(efd.qtd_efd_relacionadas, 0) AS qtd_efd_relacionadas,
    stg.fonte_dado
FROM dbo.stg_divergencia_nfe_efd AS stg
LEFT JOIN dbo.contribuinte AS c
    ON c.cnpj = stg.cnpj
LEFT JOIN dbo.stg_cfop_externo AS cfop
    ON cfop.cfop = stg.cfop
LEFT JOIN nfe_agg AS nfe
    ON nfe.id_contribuinte = c.id_contribuinte
   AND nfe.data_inicio_mes = CAST(LEFT(stg.periodo_apuracao, 4) + '-' + SUBSTRING(stg.periodo_apuracao, 5, 2) + '-01' AS DATE)
LEFT JOIN efd_agg AS efd
    ON efd.id_contribuinte = c.id_contribuinte
   AND efd.data_inicio_mes = CAST(LEFT(stg.periodo_apuracao, 4) + '-' + SUBSTRING(stg.periodo_apuracao, 5, 2) + '-01' AS DATE);
GO
```

```sql
CREATE OR ALTER PROCEDURE dbo.usp_integrar_divergencia_nfe_efd
    @arquivo_externo NVARCHAR(400),
    @arquivo_cfop NVARCHAR(400),
    @periodo CHAR(6)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- 1. Limpa staging
        TRUNCATE TABLE dbo.stg_divergencia_nfe_efd;
        TRUNCATE TABLE dbo.stg_cfop_externo;

        -- 2. Carrega dados externos
        BULK INSERT dbo.stg_divergencia_nfe_efd
        FROM @arquivo_externo
        WITH (
            FIELDTERMINATOR = ';',
            ROWTERMINATOR = '\n',
            FIRSTROW = 2,
            KEEPNULLS,
            TABLOCK,
            CODEPAGE = '65001'
        );

        BULK INSERT dbo.stg_cfop_externo
        FROM @arquivo_cfop
        WITH (
            FIELDTERMINATOR = ';',
            ROWTERMINATOR = '\n',
            FIRSTROW = 2,
            KEEPNULLS,
            TABLOCK,
            CODEPAGE = '65001'
        );

        -- 3. Normaliza campos
        UPDATE dbo.stg_divergencia_nfe_efd
        SET uf_origem = UPPER(LTRIM(RTRIM(uf_origem))),
            uf_destino = UPPER(LTRIM(RTRIM(uf_destino))),
            tipo_operacao = UPPER(LTRIM(RTRIM(tipo_operacao))),
            situacao_documento = UPPER(LTRIM(RTRIM(situacao_documento)));

        -- 4. Materializa snapshot do período solicitado
        IF OBJECT_ID('dbo.tb_divergencia_nfe_efd_cfop', 'U') IS NOT NULL
            DROP TABLE dbo.tb_divergencia_nfe_efd_cfop;

        SELECT
            periodo_apuracao,
            id_contribuinte,
            cnpj,
            razao_social,
            regime_tributario,
            uf_origem,
            uf_destino,
            cfop,
            descricao_cfop,
            natureza,
            tipo_operacao,
            valor_operacao_externa,
            valor_nfe_no_banco,
            valor_efd_no_banco,
            diferenca_nfe,
            diferenca_efd,
            situacao_diferenca,
            qtd_nfe_relacionadas,
            qtd_efd_relacionadas,
            fonte_dado
        INTO dbo.tb_divergencia_nfe_efd_cfop
        FROM dbo.vw_divergencia_nfe_efd_cfop AS v
        WHERE v.periodo_apuracao = @periodo;

        PRINT 'Processo de integração concluido com sucesso.';
    END TRY
    BEGIN CATCH
        PRINT 'Erro na carga e materializacao: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO
```

**O que observar:** a criação da visão ficou fora da procedure para deixar a leitura mais simples. A procedure passa a ter uma responsabilidade clara: carregar os dados e materializar a auditoria para o período solicitado.

**A armadilha:** a `CREATE VIEW` não deve depender de parâmetro da procedure. O filtro por período fica na consulta final, quando a tabela materializada é montada.

### Fluxo da procedure

A leitura do bloco acima pode ser feita da seguinte forma:

1. limpar o staging;
2. carregar o arquivo externo em massa;
3. carregar a tabela de referência de CFOP;
4. padronizar texto e campos de apoio;
5. materializar o resultado do período informado em uma tabela analítica;
6. manter a visão separada para facilitar leitura e reutilização.

Essa estrutura é mais clara para aula porque separa bem as responsabilidades do processo: ingestão, limpeza, integração e materialização.

### Verificação final

```sql
SELECT TOP (20)
    periodo_apuracao,
    cnpj,
    razao_social,
    cfop,
    descricao_cfop,
    valor_operacao_externa,
    valor_nfe_no_banco,
    valor_efd_no_banco,
    diferenca_nfe,
    diferenca_efd,
    situacao_diferenca
FROM dbo.tb_divergencia_nfe_efd_cfop
ORDER BY ABS(diferenca_nfe) DESC;
GO
```

```sql
SELECT
    COUNT(*) AS qtd_registros,
    SUM(CASE WHEN situacao_diferenca <> 'CONSISTENTE' THEN 1 ELSE 0 END) AS registros_com_divergencia
FROM dbo.tb_divergencia_nfe_efd_cfop;
GO
```

**O que observar:** a rotina automatizada produz um histórico da auditoria em uma única tabela, permitindo priorização e revisão por divergência.

**A armadilha:** em produção, a stored procedure deve fazer validação de integridade e controle de período. O objetivo aqui é didático, mas a lógica é muito próxima da rotina real de auditoria tributária.

## Etapa 8 — Exercícios práticos

1. Crie uma consulta para listar os contribuintes com divergência maior que 10% entre o valor do CSV externo e a NF-e.
2. Reescreva a consulta para filtrar apenas CFOPs de SAÍDA com natureza interestadual.
3. Identifique contribuintes com `CFOP` inválido ou fora da referência externa.
4. Faça um ranking dos contribuintes com maior diferença entre o valor externo e a EFD.
5. Ajuste a `stored procedure` para registrar a data/hora da carga em uma tabela de log.

---

## Etapa 9 — Regra prática para a sala de aula

- Use `staging` para receber dados externos crus.
- Use `BULK INSERT` para grandes arquivos CSV.
- Faça validação e normalização antes da análise.
- Combine dados externos com NF-e e EFD antes de inferir divergência.
- Use `CFOP` como referência para contextualizar a natureza da operação.
- Materialize a visão quando a análise for recorrente e de auditoria operacional.
- Automatize a rotina com `stored procedure` para produtividade e consistência.

---

## Resumo da aprendizagem

Neste roteiro, o aluno teve a oportunidade de:

- receber dados externos em CSV em grande volume;
- carregar registros com `BULK INSERT`;
- criar e validar tabela de staging;
- integrar dados externos com NF-e e EFD;
- usar referência externa de CFOP para contextualizar a operação;
- materializar a visão em tabela analítica;
- automatizar o processo com `stored procedure`.

Esse fluxo é muito útil para um cenário real de fiscalização tributária, em que o auditor precisa comparar o que chegou por canal externo com o que foi declarado na base fiscal interna para detectar divergências e priorizar ações de fiscalização.

### Consulta de validação da visão

```sql
SELECT
    periodo_apuracao,
    cnpj,
    razao_social,
    uf_origem,
    ncm,
    valor_operacao_csv,
    valor_nfe_no_banco,
    diferenca_valor,
    situacao_auditoria
FROM dbo.vw_auditoria_risco_operacoes
ORDER BY diferenca_valor DESC;
GO
```
