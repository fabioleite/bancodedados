# Roteiro de carga, limpeza e auditoria fiscal para tabela do Anexo 5 da SEFAZ

## 1. Objetivo

Este arquivo trata de uma tabela fiscal de referencia do Anexo 5, com dados de CEST, NCM/SH, descrição, legislação e parâmetros de MVA/aliquota. Ele é útil para:

- validar o enquadramento tributário de produtos;
- comparar NCM/CEST com legislação vigente;
- identificar inconsistências de MVA e alíquotas;
- integrar a tabela oficial em uma análise fiscal de tributação.

O arquivo em análise é:

- `tabela_anexo_5_sefaz.csv`

---

## 2. Diagnóstico da estrutura do arquivo

A estrutura dos primeiros registros mostra que o arquivo é um CSV de texto em formato de tabela, com separador `|` e sem evidência de problema grave de encoding.

### Primeiros registros observados

```text
Tabela_CEST|ITEM|CEST|NCM/SH|DESCRICAO|Legislacao|Vigencia_inicial|Vigencia_final|Aliq_Interna|MVA_Original|...
01|1.0|01.001.00|38151210|Catalisadores em colmeia cerâmica ou metálica para conversão catalítica de gases de escape de veículos e outros catalisadores|DECRETO ICMS/PB Nº 39.158|2019-05-07 00:00:00||0.18|0.00|0.7178|...
01|1.0|01.001.00|38151290|Catalisadores em colmeia cerâmica ou metálica para conversão catalítica de gases de escape de veículos e outros catalisadores|DECRETO ICMS/PB Nº 39.158|2019-05-07 00:00:00||0.18|0.00|0.7178|...
01|2.0|01.002.00|3917|Tubos e seus acessórios (por exemplo, juntas, cotovelos, flanges, uniões), de plásticos|DECRETO ICMS/PB Nº 39.158|2019-05-07 00:00:00||0.18|0.00|0.7178|...
```

### Inspeção rápida do CSV no PowerShell

Antes de carregar o arquivo em massa, vale verificar a estrutura e o tamanho do CSV. No Windows PowerShell, os comandos abaixo ajudam a validar o cabeçalho, a quantidade de registros e a amostra inicial.

#### 1) Quantos campos possui a linha de cabeçalho do arquivo

```powershell
$arquivo = 'C:\projetos\bancodedados\modulo_05\roteiro_integrador_bdfisc\tabela_anexo_5_sefaz.csv'
$linhaCabecalho = Get-Content $arquivo -TotalCount 1
$campos = ($linhaCabecalho -split '\|')
$campos.Count
$campos
```

**O que observar:** o resultado deve mostrar a quantidade real de colunas do cabeçalho. Como o separador do arquivo é `|`, o número esperado tende a ser maior do que em arquivos CSV com `;`.

#### 2) Quantos registros ao todo o arquivo possui

```powershell
$arquivo = 'C:\projetos\bancodedados\modulo_05\roteiro_integrador_bdfisc\tabela_anexo_5_sefaz.csv'
$registros = (Get-Content $arquivo).Count - 1
Write-Host "Total de registros em tabela_anexo_5_sefaz.csv: $registros"
```

#### 3) Exibir as 10 primeiras linhas no PowerShell

```powershell
Get-Content 'C:\projetos\bancodedados\modulo_05\roteiro_integrador_bdfisc\tabela_anexo_5_sefaz.csv' -TotalCount 11
```

**A armadilha:** se o separador estiver incorreto, a contagem de colunas e a carga em massa podem falhar antes mesmo do `BULK INSERT`.

### Observações importantes

- o separador é `|`;
- existe uma linha de cabeçalho;
- os valores de data vêm em formato com hora, por exemplo `2019-05-07 00:00:00`;
- campos como `MVA_Original`, `Aliq_Interna`, `MVA_Original_S/Fid` e demais colunas de MVA são numéricos decimais;
- há campos vazios (`||`) em algumas posições, o que exige tratamento antes da análise;
- o arquivo é um cadastro auxiliar de legislação tributária e não um arquivo de documento fiscal direto.

---

## 3. Caso de uso fiscal proposto

### 3.1 Contexto da tabela do Anexo 5

O Anexo 5 da SEFAZ não é um arquivo de movimentação de comércio, e sim uma tabela normativa de referência. Sua finalidade é materializar as regras tributárias que definem como o ICMS deve ser aplicado sobre determinados produtos, principalmente quando há substituição tributária, operações interestaduais e diferenciação por NCM/CEST.

Em termos práticos, essa base serve como “mecanismo de validação” para responder as seguintes perguntas:

- o produto está corretamente codificado no CEST/NCM?
- qual alíquota interna deve ser aplicada?
- qual MVA deve incidir sobre a operação?
- a regra é válida para o período da operação?
- o mesmo produto, em diferentes regimes, deve receber tratamento diferente?

Como o arquivo reúne uma grande quantidade de combinações de produto, porcentagem, faixa de alíquota e vigência, ele se torna uma referência central para auditoria tributária e para validação de impactos sobre crédito, cálculo e cadastro.

### 3.2 Caso de uso: auditoria de enquadramento tributário e validação de MVA por CEST/NCM

O objetivo da análise é validar se a mercadoria informada pela empresa, na operação real, está sendo tributada de acordo com a regra oficial vigente no estado. Essa comparação é feita cruzando:

1. o produto cadastrado na empresa;
2. o CEST e o NCM do item;
3. a descrição da mercadoria;
4. a alíquota interna e as percentagens de MVA da tabela;
5. a data da operação e a vigência da regra.

Esse tipo de auditoria é especialmente importante quando há risco de:

- cadastro indevido do produto;
- uso de CEST/NCM equivocado;
- tributação com base de cálculo diferente da regra oficial;
- mercadorias sujeitas à substituição tributária sendo tratadas como venda comum;
- divergência entre operação real e base legal do estado.

### 3.3 Regras fiscais com exemplos práticos

#### 3.3.1 Regra 1: CEST/NCM corretamente enquadrado

A primeira regra fiscal é que cada item deve ter o CEST e o NCM compatíveis com a descrição do produto. Se a empresa informa um CEST de uma categoria diferente da mercadoria, haverá risco de cálculo fiscal incorreto.

Exemplo:

- NCM/SH: 3917
- CEST: 01.002.00
- Descrição: “Tubos e seus acessórios de plásticos”

Se a empresa estiver vendendo uma mercadoria totalmente diferente, como um componente eletrônico ou catalisador automotivo, mas estiver com o CEST de plástico, o motivo técnico da classificação deve ser revisado. O auditor precisa verificar se o produto do banco da empresa corresponde à descrição da tabela de referência.

Impacto fiscal:

- Alíquota interna pode ser aplicada de forma errada;
- MVA aplicada pode não refletir o produto real;
- tendência de divergência no ICMS, substituição tributária e crédito.

#### 3.3.2 Regra 2: alíquota interna válida para o período

A coluna `Aliq_Interna` representa a alíquota interna aplicada ao produto. Esse valor precisa ser identificado e comparado com o período da operação. Sempre que a operação ocorrer em um período diferente da vigência da regra, o auditor deve verificar se houve alteração legislativa.

Exemplo:

- `Aliq_Interna = 0.18`
- `Vigencia_inicial = 2019-05-07 00:00:00`
- `Vigencia_final = NULL`

Isso indica que, a partir daquela data, o produto passou a ser tributado pela alíquota interna de 18%, desde que a regra continuasse vigente. Se a operação da empresa for de um período posterior, pode haver mudança legislativa que invalidou ou alterou essa regra.

Impacto fiscal:

- alíquota aplicada em NF-e pode estar acima ou abaixo do correto;
- o auditor deve validar se a empresa usou a alíquota correta no momento da operação.

#### 3.3.3 Regra 3: MVA aplicada conforme o regime tributário

As colunas de MVA representam a margem de valor agregado que será adicionada à base de cálculo em operações sujeitas a substituição tributária ou também em outras regras do ICMS. A MVA altera a base de cálculo, e não apenas o imposto final.

Exemplo:

- `MVA_Original = 0.00`
- `MVA_Original_S/Fid = 0.7178`
- `MVA_S/Fid_Aliq_7% = 0.9482`

Aqui o auditor observa que há diferentes formas de estrutura de MVA conforme o regime produto e a situação da mercadoria. O valor 0,7178 significa que a base de cálculo pode ter um incremento de 71,78% sobre o preço do produto, dependendo do regime e da regra aplicável.

Em termos práticos:

- o mesmo item pode ter MVA diferente conforme o regime específico;
- a MVA incide na base de cálculo, e não somente na operação final;
- a comparação da operação da empresa com o valor administrativo de referência é essencial para detectar divergência.

Impacto fiscal:

- se a empresa usar MVA diferente da regra vigente, a base de cálculo ficará incorreta;
- o valor do ICMS recolhido ou creditado pode sofrer distorção relevante.

#### 3.3.4 Regra 4: vigência de regras fiscais e dados temporais

A vigência da regra é um componente crítico. O mesmo NCM ou CEST pode ter uma regra diferente dependendo do período. Quando a regra muda, o arquivo pode ter mais de uma linha para a mesma mercadoria, com períodos distintos.

Exemplo:

- linha 1: vigência de 2019-05-07 até 2020-12-31;
- linha 2: vigência a partir de 2021-01-01.

Se a empresa operar em 2020, ela deve usar a linha antiga. Se operar em 2021, precisa usar a nova regra. O auditor precisa sempre filtrar pela data da operação.

Impacto fiscal:

- comparar um item em um período sem considerar a vigência pode gerar conclusão falsa;
- a correção da base fiscal depende do período correto da regra.

#### 3.3.5 Regra 5: dados nulos ou incompletos

Em arquivos de legislação, campos vazios podem indicar risco de integridade ou de regra ainda não definida. O arquivo tem campos com sequência vazia (`||`), o que exige cuidado na carga e na validação.

Exemplo:

- `Vigencia_final` vazio;
- `MVA_Original` nulo;
- `Lista` ou `UF_Signataria` vazio;
- `Legislacao` ausente.

Isso pode querer dizer:

- regra ainda válida até constante revisão;
- dado não informado e que precisa ser conferido;
- base importada incompleta ou com linhas não padronizadas.

Impacto fiscal:

- a linha pode estar incompleta para decisão automatizada;
- em auditoria, isso exige revisão manual ou tratamento específico para não gerar falso positivo.

#### 3.3.6 Regra 6: CEST repetido ou registro conflitante

Quando o mesmo CEST aparece com diferentes valores de NCM, MVA ou alíquota no mesmo período, isso pode indicar:

- duplicidade no arquivo;
- atualização parcial do cadastro;
- regra nova no mesmo item sem substituição correta da antiga;
- erro de integração da tabela oficial.

Exemplo:

- `CEST 01.001.00` aparece em duas linhas;
- a primeira está vinculada ao NCM 38151210;
- a segunda ao NCM 38151290;
- ambas têm diferentes descrições, mas a mesma regra base.

Se a empresa usar um desses NCMs indevidamente, pode haver enquadramento enganoso. O auditor deve verificar se o registro não é apenas uma duplicidade legítima por variação de produto, mas sim uma regra distinta aplicação da mesma família tributária.

Impacto fiscal:

- a empresa pode estar tributando o produto de forma inconsistente;
- a base de dados precisa identificar a relação correta entre CEST, NCM e regra aplicada.

#### 3.3.7 Regra 7: origem e disponibilidade da regra

Campos como `Origem_Arquivo` e `Nome_Aba_Planilha` servem para rastrear a origem do dado. Em auditoria, isso é importante para provar que a regra foi extraída de uma tabela oficial, de uma planilha do órgão ou de uma revisão específica.

Exemplo:

- `Origem_Arquivo = Anexo_5_Autopeças (1).xlsx`
- `Nome_Aba_Planilha = AutoPecas`

Isso mostra que o dado foi importado de uma planilha específica. Se a empresa usa uma regra diferente da planilha oficial, esse histórico é útil para demonstrar a origem da base e a evidência da regra aplicada.

Impacto fiscal:

- reforça a rastreabilidade da análise;
- permite ao auditor justificar a decisão técnica em documento de diligência.

### 3.4 Exemplo de caso realista de auditoria

Imagine uma empresa que vende uma peça automotiva com o NCM 3917 e CEST 01.002.00. Quando a operação está sendo fiscalizada, o auditor consulta a tabela do Anexo 5 e verifica:

- o produto está classificado corretamente;
- a alíquota interna é de 18%;
- a MVA está de acordo com a regra vigente;
- a vigência da regra corresponde ao período da operação;
- o regime da mercadoria não exige tratamento especial.

Se a empresa usou uma alíquota diferente, ou se o NCM foi informado incorretamente, o auditor pode concluir que houve:

- divergência na tributação;
- risco de recolhimento indevido;
- necessidade de ajuste de saldo de ICMS ou de crédito tributário.

### 3.5 O que a auditoria está validando

Em resumo, a análise fiscal desta tabela procura responder quatro perguntas principais:

1. O produto está classificado no código certo?
2. A regra aplicada corresponde ao período correto?
3. A alíquota e a MVA estão de acordo com a legislação vigente?
4. A operação da empresa reflete essa regra, ou há divergência?

Essas são as perguntas centrais da auditoria fiscal baseada em tabelas oficiais e em dados de referência.

---

## 4. Estratégia de carga

A melhor prática é separar em camadas:

1. `staging` para carga bruta;
2. tabela normalizada para conversão de tipos;
3. tabela analítica para auditoria fiscal.

### 4.1 Tabela de staging

```sql
CREATE SCHEMA staging;
GO

CREATE TABLE staging.anexo5_sefaz_raw (
    Tabela_CEST NVARCHAR(50) NULL,
    ITEM NVARCHAR(50) NULL,
    CEST NVARCHAR(50) NULL,
    NCM_SH NVARCHAR(50) NULL,
    DESCRICAO NVARCHAR(2000) NULL,
    Legislacao NVARCHAR(2000) NULL,
    Vigencia_inicial NVARCHAR(100) NULL,
    Vigencia_final NVARCHAR(100) NULL,
    Aliq_Interna NVARCHAR(50) NULL,
    MVA_Original NVARCHAR(50) NULL,
    MVA_Original_S_Fid NVARCHAR(50) NULL,
    MVA_S_Fid_Aliq_4 NVARCHAR(50) NULL,
    MVA_S_Fid_Aliq_7 NVARCHAR(50) NULL,
    MVA_S_Fid_Aliq_12 NVARCHAR(50) NULL,
    MVA_Original_C_Fid NVARCHAR(50) NULL,
    MVA_C_Fid_Aliq_4 NVARCHAR(50) NULL,
    MVA_C_Fid_Aliq_7 NVARCHAR(50) NULL,
    MVA_C_Fid_Aliq_12 NVARCHAR(50) NULL,
    Funcep NVARCHAR(50) NULL,
    Pauta_Fiscal NVARCHAR(200) NULL,
    MVA_Aliq_4 NVARCHAR(50) NULL,
    MVA_Aliq_7 NVARCHAR(50) NULL,
    MVA_Aliq_12 NVARCHAR(50) NULL,
    Funcep_Bebidas_Gaseificada NVARCHAR(200) NULL,
    MVA_Original_deriv_Petr NVARCHAR(50) NULL,
    MVA_deriv_Petr_Aliq_4 NVARCHAR(50) NULL,
    MVA_deriv_Petr_Aliq_7 NVARCHAR(50) NULL,
    MVA_deriv_Petr_Aliq_12 NVARCHAR(50) NULL,
    MVA_Original_N_deriv_Petr NVARCHAR(50) NULL,
    MVA_N_deriv_Petr_Aliq_4 NVARCHAR(50) NULL,
    MVA_N_deriv_Petr_Aliq_7 NVARCHAR(50) NULL,
    MVA_N_deriv_Petr_Aliq_12 NVARCHAR(50) NULL,
    MVA_Original_Outros_Prod NVARCHAR(50) NULL,
    MVA_Outros_Prod_Aliq_4 NVARCHAR(50) NULL,
    MVA_Outros_Prod_Aliq_7 NVARCHAR(50) NULL,
    MVA_Outros_Prod_Aliq_12 NVARCHAR(50) NULL,
    Funcep_Consumo_maior_100Kw_h NVARCHAR(50) NULL,
    Lista NVARCHAR(50) NULL,
    UF_Signataria NVARCHAR(50) NULL,
    Exterior_UF_nao_Signat NVARCHAR(50) NULL,
    Ato_Cotepe NVARCHAR(200) NULL,
    Origem_Arquivo NVARCHAR(200) NULL,
    Nome_Aba_Planilha NVARCHAR(200) NULL
);
GO
```

---

## 5. BULK INSERT

Como o separador é `|`, o comando de carga em massa deve usar esse delimitador e ignorar a primeira linha.

```sql
BULK INSERT staging.anexo5_sefaz_raw
FROM 'C:\dados\staging\tabela_anexo_5_sefaz.csv'
WITH (
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    DATAFILETYPE = 'char',
    CODEPAGE = '65001',
    TABLOCK,
    MAXERRORS = 100
);
```

### Observações

- o arquivo parece estar em UTF-8 e em texto puro;
- se houver problema de acesso ao arquivo, copie para um diretório acessível pelo serviço do SQL Server;
- a primeira linha tem o cabeçalho, por isso `FIRSTROW = 2`.

---

## 6. Normalização dos dados

### Tabela normalizada

```sql
CREATE TABLE dbo.anexo5_sefaz_normalizado (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Tabela_CEST NVARCHAR(50) NULL,
    ITEM DECIMAL(18,4) NULL,
    CEST NVARCHAR(50) NULL,
    NCM_SH NVARCHAR(50) NULL,
    DESCRICAO NVARCHAR(2000) NULL,
    Legislacao NVARCHAR(2000) NULL,
    Vigencia_inicial DATETIME NULL,
    Vigencia_final DATETIME NULL,
    Aliq_Interna DECIMAL(18,4) NULL,
    MVA_Original DECIMAL(18,4) NULL,
    MVA_Original_S_Fid DECIMAL(18,4) NULL,
    MVA_S_Fid_Aliq_4 DECIMAL(18,4) NULL,
    MVA_S_Fid_Aliq_7 DECIMAL(18,4) NULL,
    MVA_S_Fid_Aliq_12 DECIMAL(18,4) NULL,
    MVA_Original_C_Fid DECIMAL(18,4) NULL,
    MVA_C_Fid_Aliq_4 DECIMAL(18,4) NULL,
    MVA_C_Fid_Aliq_7 DECIMAL(18,4) NULL,
    MVA_C_Fid_Aliq_12 DECIMAL(18,4) NULL,
    Funcep DECIMAL(18,4) NULL,
    Pauta_Fiscal NVARCHAR(200) NULL,
    MVA_Aliq_4 DECIMAL(18,4) NULL,
    MVA_Aliq_7 DECIMAL(18,4) NULL,
    MVA_Aliq_12 DECIMAL(18,4) NULL,
    Funcep_Bebidas_Gaseificada NVARCHAR(200) NULL,
    MVA_Original_deriv_Petr DECIMAL(18,4) NULL,
    MVA_deriv_Petr_Aliq_4 DECIMAL(18,4) NULL,
    MVA_deriv_Petr_Aliq_7 DECIMAL(18,4) NULL,
    MVA_deriv_Petr_Aliq_12 DECIMAL(18,4) NULL,
    MVA_Original_N_deriv_Petr DECIMAL(18,4) NULL,
    MVA_N_deriv_Petr_Aliq_4 DECIMAL(18,4) NULL,
    MVA_N_deriv_Petr_Aliq_7 DECIMAL(18,4) NULL,
    MVA_N_deriv_Petr_Aliq_12 DECIMAL(18,4) NULL,
    MVA_Original_Outros_Prod DECIMAL(18,4) NULL,
    MVA_Outros_Prod_Aliq_4 DECIMAL(18,4) NULL,
    MVA_Outros_Prod_Aliq_7 DECIMAL(18,4) NULL,
    MVA_Outros_Prod_Aliq_12 DECIMAL(18,4) NULL,
    Funcep_Consumo_maior_100Kw_h DECIMAL(18,4) NULL,
    Lista NVARCHAR(50) NULL,
    UF_Signataria NVARCHAR(50) NULL,
    Exterior_UF_nao_Signat NVARCHAR(50) NULL,
    Ato_Cotepe NVARCHAR(200) NULL,
    Origem_Arquivo NVARCHAR(200) NULL,
    Nome_Aba_Planilha NVARCHAR(200) NULL
);
GO
```

### Transformação dos campos principais

Os valores numéricos do arquivo podem usar ponto como separador decimal, como `1.011082926829268`, ou vírgula em arquivos exportados no padrão brasileiro, como `1,011082926829268`. A conversão anterior removia todos os pontos antes de converter o valor. Assim, `1.011082926829268` virava `1011082926829268`, excedia a precisão de `DECIMAL(18,4)` e o `TRY_CONVERT` retornava `NULL`.

Na transformação abaixo, a regra é:

- quando houver vírgula, os pontos são tratados como separadores de milhar e a vírgula é convertida para ponto;
- quando não houver vírgula, o ponto é preservado como separador decimal;
- o símbolo `%` é removido quando existir;
- campos vazios continuam sujeitos ao tratamento de `TRY_CONVERT`.

```sql
INSERT INTO dbo.anexo5_sefaz_normalizado (
    Tabela_CEST,
    ITEM,
    CEST,
    NCM_SH,
    DESCRICAO,
    Legislacao,
    Vigencia_inicial,
    Vigencia_final,
    Aliq_Interna,
    MVA_Original,
    MVA_Original_S_Fid,
    MVA_S_Fid_Aliq_4,
    MVA_S_Fid_Aliq_7,
    MVA_S_Fid_Aliq_12,
    MVA_Original_C_Fid,
    MVA_C_Fid_Aliq_4,
    MVA_C_Fid_Aliq_7,
    MVA_C_Fid_Aliq_12,
    Funcep,
    Pauta_Fiscal,
    MVA_Aliq_4,
    MVA_Aliq_7,
    MVA_Aliq_12,
    Origem_Arquivo,
    Nome_Aba_Planilha
)
SELECT
    LTRIM(RTRIM(Tabela_CEST)),
    TRY_CONVERT(DECIMAL(18,4), ITEM),
    LTRIM(RTRIM(CEST)),
    LTRIM(RTRIM(NCM_SH)),
    LTRIM(RTRIM(DESCRICAO)),
    LTRIM(RTRIM(Legislacao)),
    TRY_CONVERT(DATETIME, Vigencia_inicial),
    TRY_CONVERT(DATETIME, Vigencia_final),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', Aliq_Interna) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Aliq_Interna)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(Aliq_Interna)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Original) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Original_S_Fid) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original_S_Fid)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original_S_Fid)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_S_Fid_Aliq_4) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_4)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_4)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_S_Fid_Aliq_7) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_7)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_7)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_S_Fid_Aliq_12) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_12)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_12)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Original_C_Fid) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original_C_Fid)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original_C_Fid)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_C_Fid_Aliq_4) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_4)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_4)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_C_Fid_Aliq_7) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_7)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_7)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_C_Fid_Aliq_12) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_12)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_12)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', Funcep) > 0 THEN REPLACE(LTRIM(RTRIM(FUNCEP)), ',', '.') ELSE LTRIM(RTRIM(FUNCEP)) END),
    LTRIM(RTRIM(Pauta_Fiscal)),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Aliq_4) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_4)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_4)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Aliq_7) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_7)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_7)), '%', ''), ',', '') END),
    TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Aliq_12) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_12)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_12)), '%', ''), ',', '') END),
    LTRIM(RTRIM(Origem_Arquivo)),
    LTRIM(RTRIM(Nome_Aba_Planilha))
FROM staging.anexo5_sefaz_raw;
```

---

## 7. Auditoria fiscal sugerida

A seção 3 definiu as regras fiscais que devem orientar a análise. Agora, esta seção transforma esses princípios em verificações concretas sobre as tabelas geradas no esquema `fisc` pelo próprio script do BDFISC. As consultas abaixo usam objetos reais do banco, como `fisc.anexo5_sefaz_normalizado` e as tabelas produzidas pelas procedures, como `fisc.TB_138_PR_SAIDAS_ITENS_PARA_ANALISE_REGISTROS` e `fisc.TB_134_PR_SAIDAS_LANCADAS_C190_COM_DEBITO_A_MENOR_ICMS_02`.

### 7.1 Auditoria de produto com alíquota ou MVA nula

Conectando com a seção 3.3.2 e 3.3.5:

- a alíquota interna precisa estar correta para a regra vigente;
- a MVA precisa existir quando o produto estiver em substituição tributária ou em regime da tabela;
- campos nulos podem indicar regra incompleta, falha de importação ou classificação ainda não validada.

```sql
SELECT
    CEST,
    NCM_SH,
    DESCRICAO,
    Aliq_Interna,
    MVA_Original,
    Vigencia_inicial,
    Vigencia_final
FROM fisc.anexo5_sefaz_normalizado
WHERE Aliq_Interna IS NULL
   OR MVA_Original IS NULL
   OR CEST IS NULL
   OR NCM_SH IS NULL;
```

#### Explicação da auditoria

Essa consulta localiza registros da tabela de referência do Anexo 5 que podem comprometer a legalidade do cálculo tributário. Se um item tiver `Aliq_Interna` nula, a empresa não terá base para identificar a alíquota aplicável. Se a `MVA_Original` estiver nula em um caso em que há expectativa de substituição tributária, pode haver regra incompleta, classificação errada ou falha de importação.

Em termos de risco fiscal, isso pode levar a:

- tributação indevida;
- base de cálculo inconsistente;
- inconsistência entre operação real e regra normativa;
- perda de evidência para defesa do contribuinte ou da fiscalização.

---

### 7.2 Auditoria de vigência inconsistente

Conectando com a seção 3.3.4:

- a regra tributária muda com o tempo;
- o mesmo NCM ou CEST pode ter regra diferente em períodos distintos;
- a vigência da regra deve sempre ser validada antes da comparação com a operação.

```sql
SELECT
    CEST,
    NCM_SH,
    DESCRICAO,
    Vigencia_inicial,
    Vigencia_final
FROM fisc.anexo5_sefaz_normalizado
WHERE Vigencia_inicial IS NULL
   OR (Vigencia_final IS NOT NULL AND Vigencia_final < Vigencia_inicial);
```

#### Explicação da auditoria

Essa auditoria valida se as datas da regra têm consistência temporal. Se a vigência final for anterior à inicial, ou se a data inicial for nula, a regra está problemática. Isso é relevante porque o mesmo item pode ser tributado de maneira diferente em diferentes datas.

Exemplo prático:

- operação em 2020;
- regra validada no arquivo para 2021;
- sem correção de vigência, o auditor pode comparar o produto com a regra errada.

Em auditoria fiscal isso é importante porque o cálculo do imposto depende do período em que a regra entrou em vigor e da regra aplicável naquele momento. A comparação sem considerar vigência pode gerar conclusões falsas.

---

### 7.3 Auditoria de duplicidade do CEST para o mesmo NCM com valores conflitantes

Conectando com a seção 3.3.6:

- CEST duplicado pode indicar regra conflitante;
- a mesma mercadoria não deve aparecer com MVA ou alíquota simultaneamente divergentes sem justificativa;
- conflitos são sinais de atualização incompleta ou cadastro inconsistentes.

```sql
SELECT
    CEST,
    NCM_SH,
    COUNT(*) AS Qtde_Registros,
    MIN(Aliq_Interna) AS Aliq_Min,
    MAX(Aliq_Interna) AS Aliq_Max,
    MIN(MVA_Original) AS MVA_Min,
    MAX(MVA_Original) AS MVA_Max
FROM fisc.anexo5_sefaz_normalizado
GROUP BY CEST, NCM_SH
HAVING COUNT(*) > 1;
```

#### Explicação da auditoria

Essa consulta verifica se o mesmo CEST/NCM aparece mais de uma vez com parâmetros diferentes. Quando isso ocorre, pode haver mais de um cenário de tributação para o mesmo produto, o que só pode ser aceitável se houver diferença real de vigência, situação tributária ou regra específica.

Exemplo:

- um mesmo CEST aparece em dois registros;
- primeiro registro tem MVA 0,7178;
- segundo registro tem MVA 0,5000;
- ambos parecem válidos, mas sem diferença de vigência ou regime explícito.

Nesse caso, o auditor deve investigar se houve:

- atualização da regra sem exclusão do registro antigo;
- erro de importação;
- classificação da mercadoria em regra diferente sem ajuste do produto;
- falha de rastreabilidade da tabela oficial.

Esse tipo de problema pode gerar risco de tributação inconsistente e de sua base de cálculo ser aplicada de maneira incorreta.

---

### 7.4 Auditoria de enquadramento do produto por CEST/NCM e descrição

Conectando com a seção 3.3.1:

- a descrição da mercadoria precisa coincidir com o seu enquadramento tributário;
- o mesmo CEST/NCM deve representar a categoria correta do produto;
- o auditor usa a descrição para validar o código fiscal escolhido pela empresa.

A regra aqui é qualitativa e normalmente é aplicada em cruzamento entre a tabela do Anexo 5 e a tabela de itens gerada pela procedure fiscal.

#### Exemplo de validação com tabela gerada pela procedure

```sql
SELECT
    a.CEST,
    a.NCM_SH,
    a.DESCRICAO,
    b.ITEMNF_CPROD,
    b.ITEMNF_XPROD,
    b.ITEMNF_NCM,
    b.ITEMNF_CEST
FROM fisc.anexo5_sefaz_normalizado a
LEFT JOIN fisc.TB_138_PR_SAIDAS_ITENS_PARA_ANALISE_REGISTROS b
    ON a.NCM_SH = b.ITEMNF_NCM
WHERE a.CEST IS NOT NULL
  AND b.ITEMNF_CPROD IS NOT NULL
  AND LOWER(a.DESCRICAO) NOT LIKE '%' + LOWER(b.ITEMNF_XPROD) + '%';
```

#### Explicação da auditoria

Essa auditoria busca itens em que o produto da operação não corresponde à descrição tributária do CEST/NCM. Ela se aplica diretamente ao fluxo da procedure de saídas (`TB_138 ... REGISTROS`), que traz os itens fiscais reais da empresa. Em termos práticos, um produto pode estar sendo classificado por NCM/CEST diferente do que a tabela oficial prevê.

Risco fiscal:

- tributação por categoria errada;
- crédito indevido ou excesso de carga tributária;
- necessidade de ajuste de estoque e de notas fiscais;
- inconsistência em relação à legislação oficial.

---

### 7.5 Auditoria de vigência e regra aplicável ao período da operação

Conectando com a seção 3.3.4 e 3.3.7:

- a regra válida para a operação é aquela que está ativa na data do evento;
- o auditor precisa verificar se o produto foi tributado pela regra correta em cada momento.

A lógica é simples: comparar a data do documento fiscal com a vigência da regra aplicada.

```sql
SELECT
    n.NF_CHAVE_ACESSO,
    n.NF_DHEMI,
    n.ITEMNF_NCM,
    n.ITEMNF_CEST,
    a.CEST AS CEST_TABELA,
    a.Vigencia_inicial,
    a.Vigencia_final,
    a.Aliq_Interna,
    a.MVA_Original
FROM fisc.TB_138_PR_SAIDAS_ITENS_PARA_ANALISE_REGISTROS n
LEFT JOIN fisc.anexo5_sefaz_normalizado a
    ON n.ITEMNF_NCM = a.NCM_SH
WHERE n.NF_DHEMI >= a.Vigencia_inicial
  AND (a.Vigencia_final IS NULL OR n.NF_DHEMI <= a.Vigencia_final)
  AND n.ITEMNF_NCM IS NOT NULL;
```

#### Explicação da auditoria

Essa análise é a peça central da validação fiscal por tempo. Se a operação foi realizada em um período em que a regra vigente era outra, a empresa pode estar recolhendo ou creditando ICMS de forma inadequada. Ela usa a tabela gerada pela procedure de saídas (`TB_138...REGISTROS`) e compara a data da nota com as datas da regra do Anexo 5.

Assim, a regra “vigência correta” se conecta diretamente à regra trazida na seção 3: o imposto depende do momento em que a operação ocorreu.

---

### 7.6 Auditoria de divergência de ICMS em saídas geradas pela procedure fiscal

Além das verificações sobre o Anexo 5, o próprio script do BDFISC já monta tabelas de resultado para auditoria fiscal. Um exemplo clássico é a tabela gerada pela procedure 134, que identifica saídas com ICMS declarado em valor inferior ao informado no C190.

```sql
SELECT
    IDENTIFICADOR_TABELA,
    REG0_PERIODO_DECLARACAO,
    NF_CHAVE_ACESSO,
    NF_NNF,
    NF_SERIE,
    NF_DHEMI,
    NF_VICMS,
    C100_VL_ICMS,
    NF_VICMS_MENOS_C100_VL_ICMS
FROM fisc.TB_134_PR_SAIDAS_LANCADAS_C190_COM_DEBITO_A_MENOR_ICMS_02
WHERE NF_VICMS_MENOS_C100_VL_ICMS < 0
ORDER BY NF_DHEMI DESC;
```

#### Explicação da auditoria

Essa consulta usa uma tabela de resultado diretamente gerada pela procedure fiscal para detectar oportunidades de ajuste e inconsistências de ICMS na saída. O campo `NF_VICMS_MENOS_C100_VL_ICMS` mostra o desvio entre o valor do ICMS da nota e o valor contabilizado no registro C100/C190. Quando esse valor fica negativo, a empresa pode estar reconhecendo menos imposto do que a legislação exige.

Essa é uma boa ilustração do fluxo real do BDFISC: a procedure gera uma tabela de auditoria, e a equipe usa essa tabela como base para análise de risco e revisão contábil/fiscal.

---

### 7.7 Resumo da ligação entre seção 3 e seção 7

A seção 3 definiu os princípios jurídicos e tributários. A seção 7 transforma esses princípios em consultas e indicadores sobre as tabelas resultantes do BDFISC. Em outras palavras:

- regra de alíquota e MVA → auditoria de campos nulos e valores divergentes em `fisc.anexo5_sefaz_normalizado`;
- regra de vigência → auditoria de datas e conflitos temporais no Anexo 5 e em itens de saída (`TB_138...`);
- regra de CEST/NCM correto → auditoria de descrições e cruzamento com os itens fiscais reais da operação;
- regra de duplicidade e inconsistência → auditoria de conflito entre registros da mesma categoria;
- regra de apuração e ICMS → uso das tabelas geradas por procedures, como `TB_134...` e `TB_138...`, como evidência de auditoria e acompanhamento fiscal.

Essas auditorias não são apenas técnicas; elas representam a forma pela qual a empresa e o auditor validam se a tributação está alinhada com a legislação oficial.

---

## 8. Stored procedure para automatizar o processo

```sql
CREATE OR ALTER PROCEDURE dbo.usp_carga_anexo5_sefaz
    @ArquivoCSV NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        TRUNCATE TABLE staging.anexo5_sefaz_raw;

        BULK INSERT staging.anexo5_sefaz_raw
        FROM @ArquivoCSV
        WITH (
            FIELDTERMINATOR = '|',
            ROWTERMINATOR = '\n',
            FIRSTROW = 2,
            DATAFILETYPE = 'char',
            CODEPAGE = '65001',
            TABLOCK,
            MAXERRORS = 100
        );

        INSERT INTO dbo.anexo5_sefaz_normalizado (
            Tabela_CEST,
            ITEM,
            CEST,
            NCM_SH,
            DESCRICAO,
            Legislacao,
            Vigencia_inicial,
            Vigencia_final,
            Aliq_Interna,
            MVA_Original,
            MVA_Original_S_Fid,
            MVA_S_Fid_Aliq_4,
            MVA_S_Fid_Aliq_7,
            MVA_S_Fid_Aliq_12,
            MVA_Original_C_Fid,
            MVA_C_Fid_Aliq_4,
            MVA_C_Fid_Aliq_7,
            MVA_C_Fid_Aliq_12,
            Funcep,
            Pauta_Fiscal,
            MVA_Aliq_4,
            MVA_Aliq_7,
            MVA_Aliq_12,
            Origem_Arquivo,
            Nome_Aba_Planilha
        )
        SELECT
            LTRIM(RTRIM(Tabela_CEST)),
            TRY_CONVERT(DECIMAL(18,4), ITEM),
            LTRIM(RTRIM(CEST)),
            LTRIM(RTRIM(NCM_SH)),
            LTRIM(RTRIM(DESCRICAO)),
            LTRIM(RTRIM(Legislacao)),
            TRY_CONVERT(DATETIME, Vigencia_inicial),
            TRY_CONVERT(DATETIME, Vigencia_final),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', Aliq_Interna) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Aliq_Interna)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(Aliq_Interna)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Original) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_Original)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Original_S_Fid) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original_S_Fid)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_Original_S_Fid)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_S_Fid_Aliq_4) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_4)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_4)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_S_Fid_Aliq_7) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_7)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_7)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_S_Fid_Aliq_12) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_12)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_S_Fid_Aliq_12)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Original_C_Fid) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Original_C_Fid)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_Original_C_Fid)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_C_Fid_Aliq_4) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_4)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_4)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_C_Fid_Aliq_7) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_7)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_7)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_C_Fid_Aliq_12) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_12)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_C_Fid_Aliq_12)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', Funcep) > 0 THEN REPLACE(LTRIM(RTRIM(FUNCEP)), ',', '.') ELSE LTRIM(RTRIM(FUNCEP)) END),
            LTRIM(RTRIM(Pauta_Fiscal)),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Aliq_4) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_4)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_Aliq_4)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Aliq_7) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_7)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_Aliq_7)), '%', '') END),
            TRY_CONVERT(DECIMAL(18,4), CASE WHEN CHARINDEX(',', MVA_Aliq_12) > 0 THEN REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(MVA_Aliq_12)), '%', ''), '.', ''), ',', '.') ELSE REPLACE(LTRIM(RTRIM(MVA_Aliq_12)), '%', '') END),
            LTRIM(RTRIM(Origem_Arquivo)),
            LTRIM(RTRIM(Nome_Aba_Planilha))
        FROM staging.anexo5_sefaz_raw;

        SELECT 'Carga do Anexo 5 concluída com sucesso.' AS Resultado;

    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER() AS NumeroErro,
            ERROR_MESSAGE() AS MensagemErro;
        THROW;
    END CATCH
END;
GO
```

### Execução da procedure

```sql
EXEC dbo.usp_carga_anexo5_sefaz
    @ArquivoCSV = 'C:\dados\staging\tabela_anexo_5_sefaz.csv';
```

---

## 9. Conclusão

O arquivo do Anexo 5 é um excelente material para análise fiscal de enquadramento tributário porque reúne:

- CEST;
- NCM/SH;
- descrição da mercadoria;
- legislação de referência;
- vigência;
- MVA e alíquotas;
- origem do arquivo e aba da planilha.

Esse cenário é ideal para:

- carga em staging;
- `BULK INSERT` em SQL Server;
- normalização de campos numéricos e datas;
- auditoria fiscal de tributos indiretos;
- automação por stored procedure.

Se quiser, o próximo passo pode ser criar um script SQL completo, já pronto para executar no banco, com todas as tabelas e as queries de auditoria montadas em um único bloco.
