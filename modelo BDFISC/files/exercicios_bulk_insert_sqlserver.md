# Exercícios Práticos: Inserção de Dados em Massa com BULK INSERT (SQL Server)

**Curso:** Banco de Dados Relacionais aplicado à Administração Tributária
**Público-alvo:** Profissionais da Secretaria de Estado da Fazenda da Paraíba (SEFAZ-PB)
**SGBD utilizado:** Microsoft SQL Server (T-SQL) — ferramenta: SQL Server Management Studio (SSMS)

---

## Sumário

1. [Contexto e Cenário](#1-contexto-e-cenário)
2. [Observações Importantes sobre o BULK INSERT](#2-observações-importantes-sobre-o-bulk-insert)
3. [Arquivos de Dados Fornecidos](#3-arquivos-de-dados-fornecidos)
4. [Preparando o Ambiente](#4-preparando-o-ambiente)
5. [Exercício 1 — Importando um Único Arquivo](#5-exercício-1--importando-um-único-arquivo)
6. [Exercício 2 — Tratando Erros de Importação](#6-exercício-2--tratando-erros-de-importação)
7. [Exercício 3 — Importando Vários Arquivos Automaticamente](#7-exercício-3--importando-vários-arquivos-automaticamente)
8. [Exercício 4 — Validando e Migrando da Staging para a Tabela Definitiva](#8-exercício-4--validando-e-migrando-da-staging-para-a-tabela-definitiva)
9. [Exercício 5 — Desempenho: TABLOCK e BATCHSIZE](#9-exercício-5--desempenho-tablock-e-batchsize)
10. [Exercício 6 (Desafio) — Stored Procedure de Importação de Pasta Completa](#10-exercício-6-desafio--stored-procedure-de-importação-de-pasta-completa)
11. [Checklist de Entrega](#11-checklist-de-entrega)

---

## 1. Contexto e Cenário

A SEFAZ-PB recebe diariamente, de um sistema legado de um posto fiscal, **lotes de arquivos CSV** com cabeçalhos de NF-e recepcionadas. Cada arquivo representa um lote de notas processadas em um determinado momento, e a pasta de recebimento acumula **dezenas de arquivos por semana**.

Sua tarefa, ao longo destes exercícios, é construir a rotina de carga desses arquivos para dentro do banco de dados `curso_integridade_fiscal`, usando o comando **`BULK INSERT`** — o mecanismo nativo do SQL Server para carga em massa de arquivos de texto, sensivelmente mais rápido do que inserir linha a linha via `INSERT`.

Você receberá **6 arquivos de exemplo** (`nfe_lote_001.csv` a `nfe_lote_006.csv`), simulando lotes reais — **incluindo um deles com erros de formatação**, propositalmente inseridos para que você pratique também o diagnóstico e tratamento de falhas de carga, algo extremamente comum quando os arquivos vêm de terceiros.

---

## 2. Observações Importantes sobre o BULK INSERT

Antes de começar, alguns pontos técnicos que costumam gerar confusão:

- **O `BULK INSERT` é executado pelo *serviço* do SQL Server, não pelo SSMS no seu computador.** Isso significa que o caminho do arquivo informado no comando precisa ser **acessível pela conta de serviço do SQL Server** — não basta estar no seu computador local. Em ambiente de treinamento com SQL Server instalado na própria máquina, isso normalmente não é problema; em um servidor remoto, o arquivo precisa estar em um caminho local do servidor ou em um compartilhamento de rede (UNC, `\\servidor\pasta\arquivo.csv`) com permissão de leitura para a conta do serviço.
- É necessária a permissão `ADMINISTER BULK OPERATIONS` (ou a associação do usuário à role `bulkadmin`) para executar `BULK INSERT`.
- O padrão de mercado é carregar o arquivo primeiro em uma **tabela de staging** (todas as colunas como texto, sem constraints rígidas), e só depois validar/converter os dados para a tabela definitiva. É o padrão que seguiremos nestes exercícios.
- `BULK INSERT` não permite usar curinga (`*.csv`) nem variável diretamente no nome do arquivo dentro do mesmo comando estático — para importar vários arquivos, é necessário repetir o comando (uma vez por arquivo) ou usar **SQL dinâmico** dentro de um laço, como faremos no Exercício 3.

---

## 3. Arquivos de Dados Fornecidos

Os 6 arquivos fornecidos seguem todos o mesmo layout:

- Separador de campo: `;` (ponto e vírgula)
- Primeira linha: **cabeçalho** com o nome das colunas (não deve ser importada como dado)
- Codificação: UTF-8
- Uma linha por NF-e

| Coluna | Formato no arquivo | Observação |
|---|---|---|
| `chave_acesso` | 44 dígitos numéricos | Identificador da NF-e |
| `cnpj_emitente` | 14 dígitos numéricos | |
| `cnpj_destinatario` | 14 dígitos numéricos | |
| `numero_nf` | Número inteiro | |
| `serie` | Número inteiro pequeno | |
| `data_emissao` | `dd/mm/aaaa` | Formato brasileiro, atenção na conversão |
| `valor_total` | Número com **vírgula** decimal (ex.: `1234,56`) | Não é um formato numérico direto do T-SQL |
| `situacao` | Texto (`AUTORIZADA` ou `CANCELADA`) | |

Exemplo das primeiras linhas de `nfe_lote_001.csv`:

```
chave_acesso;cnpj_emitente;cnpj_destinatario;numero_nf;serie;data_emissao;valor_total;situacao
25260712345678000199550010000000001001000000;12345678000199;55666777000122;1000;1;03/07/2026;5432,10;AUTORIZADA
...
```

> **Onde encontrar os arquivos:** os 6 arquivos (`nfe_lote_001.csv` a `nfe_lote_006.csv`) foram disponibilizados junto com este material. Copie-os para uma pasta acessível pelo SQL Server no seu ambiente de treinamento — por exemplo, `C:\ImportacaoFiscal\NFe\` — antes de iniciar os exercícios.

---

## 4. Preparando o Ambiente

No SSMS, sobre o banco `curso_integridade_fiscal`, crie a **tabela de staging**, que receberá os dados brutos dos arquivos exatamente como estão no CSV (tudo como texto, sem validação):

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
    nome_arquivo_origem                    VARCHAR(200)  NULL,   -- preenchido pelo processo de carga, não vem do CSV
    data_hora_carga                          DATETIME2     NULL DEFAULT (SYSDATETIME())
);
GO
```

> **Por que todas as colunas são `VARCHAR`?** Porque o `BULK INSERT`, ao encontrar um valor que não se converte para o tipo de dado de destino (ex.: `ABC,00` para uma coluna `NUMERIC`), rejeita a **linha inteira**. Ao usar `VARCHAR` na staging, garantimos que **toda** linha do arquivo entre no banco — mesmo as com erro de conteúdo — para que possamos tratá-las depois, com controle, na migração para a tabela definitiva (Exercício 4).

---

## 5. Exercício 1 — Importando um Único Arquivo

Usando o comando `BULK INSERT`, carregue o conteúdo de `nfe_lote_001.csv` na tabela `stg_nfe_importacao`.

**Requisitos:**

- Use `FIELDTERMINATOR` e `ROWTERMINATOR` adequados ao formato do arquivo.
- Pule a linha de cabeçalho (lembre-se: a primeira linha do arquivo **não** é um dado).
- Use `TABLOCK` para otimizar a carga.
- Após a carga, escreva um `SELECT COUNT(*)` para conferir que **5 linhas** foram importadas (o arquivo `nfe_lote_001.csv` não contém erros).

**Dica:** consulte a documentação da cláusula `BULK INSERT` e preste atenção especialmente nos parâmetros `FIRSTROW`, `FIELDTERMINATOR` e `ROWTERMINATOR`.

---

## 6. Exercício 2 — Tratando Erros de Importação

Repita a importação, desta vez para o arquivo **`nfe_lote_004.csv`** — que contém **duas linhas com problemas propositais**.

1. Primeiro, tente importar o arquivo **exatamente como fez no Exercício 1** (sem nenhum parâmetro adicional de tratamento de erro). Observe a mensagem retornada pelo SSMS.
2. Em seguida, refaça a importação usando o parâmetro **`MAXERRORS`**, permitindo que o SQL Server tolere até 5 linhas rejeitadas sem interromper a carga inteira.
3. Adicione também o parâmetro **`ERRORFILE`**, apontando para um arquivo de log de erros (ex.: `C:\ImportacaoFiscal\NFe\erros_lote_004.log`), e execute novamente.
4. Abra o arquivo gerado por `ERRORFILE` (ou o arquivo `.Error.Txt` complementar que o SQL Server cria) e **identifique manualmente**, olhando o CSV original, **qual problema específico** cada linha rejeitada apresenta.

**Perguntas para responder por escrito:**

a) Sem `MAXERRORS`, o que acontece com a importação inteira quando uma única linha tem erro?
b) Quantas linhas de `nfe_lote_004.csv` foram efetivamente importadas para a `stg_nfe_importacao`?
c) Por que a coluna `valor_total` da tabela de staging já não deveria mais ser `VARCHAR` seria, neste exercício, um problema ainda maior? (Pense no que aconteceria se a coluna de destino já fosse `NUMERIC`.)

---

## 7. Exercício 3 — Importando Vários Arquivos Automaticamente

Até aqui, você importou arquivos **um de cada vez**, repetindo manualmente o comando. Na prática, com dezenas ou centenas de arquivos por semana, isso não escala.

**Sua tarefa:** escrever um script T-SQL que:

1. Liste automaticamente todos os arquivos `.csv` de uma pasta (dica: pesquise sobre o procedimento de sistema `xp_dirtree` ou `xp_cmdshell` combinado com `dir`, e sobre as permissões necessárias para habilitá-los).
2. Para **cada arquivo encontrado**, monte e execute dinamicamente (usando **SQL dinâmico**, isto é, uma string de comando `BULK INSERT` montada em uma variável `NVARCHAR(MAX)` e executada com `sp_executesql` ou `EXEC`) o comando de importação para a tabela `stg_nfe_importacao`.
3. Preencha a coluna `nome_arquivo_origem` de cada linha importada com o nome do arquivo de onde ela veio (isso é essencial para rastreabilidade — se um lote tiver problema, você precisa saber de qual arquivo ele veio).
4. Ao final, exiba quantas linhas foram importadas **por arquivo** (`GROUP BY nome_arquivo_origem`).

**Requisitos técnicos:**

- Use `MAXERRORS` e `ERRORFILE` (um arquivo de erro **diferente para cada CSV processado**, para não misturar os problemas de arquivos diferentes).
- O script deve funcionar **sem precisar editar manualmente** o nome de cada arquivo no código — a lista de arquivos deve vir de uma consulta (`xp_dirtree`), não de uma lista digitada à mão.

**Dica:** por que o `BULK INSERT` não aceita `FROM @variavel_com_caminho` diretamente? Porque essa cláusula exige uma **constante literal**, não uma variável — daí a necessidade de montar o comando inteiro como texto e executá-lo dinamicamente.

---

## 8. Exercício 4 — Validando e Migrando da Staging para a Tabela Definitiva

Depois de carregar todos os lotes em `stg_nfe_importacao` (Exercício 3), é hora de migrar os dados **validados** para uma tabela definitiva, com tipos de dados corretos e constraints.

**Passo 1** — Crie a tabela definitiva:

```sql
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
```

**Passo 2** — Escreva o `INSERT ... SELECT` que migra os dados de `stg_nfe_importacao` para `nfe_importada`, resolvendo:

- A conversão de `data_emissao` do formato `dd/mm/aaaa` (texto) para `DATE`.
- A conversão de `valor_total` do formato com vírgula (ex.: `1677,81`) para `NUMERIC`, trocando a vírgula por ponto.
- **A exclusão automática** de linhas que não conseguirem ser convertidas (isto é, as duas linhas problemáticas de `nfe_lote_004.csv` **não devem** travar a migração inteira nem gerar erro — elas devem ser identificadas e tratadas separadamente).

**Dica:** pesquise sobre a função `TRY_CONVERT` (em contraste com `CONVERT`) — ela retorna `NULL` em vez de lançar um erro quando a conversão falha, o que é exatamente o comportamento necessário para filtrar linhas problemáticas com um `WHERE ... IS NOT NULL`.

**Passo 3** — Crie uma tabela `nfe_importacao_rejeitada` e escreva uma segunda consulta que **capture exatamente as linhas que falharam** na migração do Passo 2 (aquelas que o `TRY_CONVERT` não conseguiu converter), registrando o motivo textual da rejeição.

---

## 9. Exercício 5 — Desempenho: TABLOCK e BATCHSIZE

Considerando que, na produção real, um único arquivo pode ter **milhões de linhas** (por exemplo, a consolidação mensal de NF-e de todo o estado):

a) Pesquise e explique, em poucas frases, a diferença entre executar o `BULK INSERT` **com** e **sem** a opção `TABLOCK`.
b) Pesquise o parâmetro `BATCHSIZE` (ou `ROWS_PER_BATCH`) e explique por que dividir a carga de um arquivo muito grande em lotes menores pode ser importante — tanto para desempenho quanto para o log de transações.
c) Refaça o `BULK INSERT` do Exercício 1, agora incluindo `TABLOCK` e um `BATCHSIZE` de 2 (apenas para fins didáticos, já que nossos arquivos de exemplo são pequenos) e observe se o resultado final (contagem de linhas importadas) muda.

---

## 10. Exercício 6 (Desafio) — Stored Procedure de Importação de Pasta Completa

Encapsule toda a lógica dos Exercícios 3 e 4 em uma **stored procedure** chamada `sp_importar_pasta_nfe`, que:

- Receba como parâmetro o caminho da pasta (`@caminho_pasta NVARCHAR(260)`).
- Localize e importe **todos** os arquivos `.csv` da pasta para a staging.
- Execute a migração validada para `nfe_importada`, registrando rejeições em `nfe_importacao_rejeitada`.
- Ao final, retorne (via `SELECT` de resumo) três números: **total de arquivos processados**, **total de linhas migradas com sucesso** e **total de linhas rejeitadas**.

**Requisito adicional:** a procedure deve poder ser executada **repetidamente sobre a mesma pasta** sem duplicar dados já importados anteriormente (pense em como impedir isso — por exemplo, registrando quais arquivos já foram processados com sucesso em uma tabela de controle, e pulando-os em execuções futuras).

---

## 11. Checklist de Entrega

Ao final destes exercícios, você deve ser capaz de entregar:

- [ ] Script de criação da tabela de staging (`stg_nfe_importacao`).
- [ ] Comando `BULK INSERT` funcional para um único arquivo (Exercício 1).
- [ ] Evidência (print ou log) do tratamento de erro com `MAXERRORS`/`ERRORFILE` (Exercício 2).
- [ ] Script dinâmico de importação de múltiplos arquivos via `xp_dirtree` (Exercício 3).
- [ ] Script de migração validada com `TRY_CONVERT` para `nfe_importada`, e tabela de rejeitados (Exercício 4).
- [ ] Respostas escritas às perguntas de desempenho (Exercício 5).
- [ ] Stored procedure `sp_importar_pasta_nfe` completa (Exercício 6, desafio).

---

*Material elaborado para uso interno no curso de Banco de Dados Relacionais — Exercícios de BULK INSERT — SEFAZ-PB.*
