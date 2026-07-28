# Respostas passo a passo — Modelagem Física para Fiscalização Tributária

Este documento contém as respostas e explicações passo a passo para o `roteiro-exercicios-modelagem-fisica.md` presente no mesmo diretório. Cada seção traz o raciocínio por trás das escolhas (tipos, constraints, índices, ações referenciais), exemplos SQL e justificativas aplicadas ao contexto de fiscalização tributária.

---

## 1. Projeto inicial do banco fiscal

Decisão principal:
- Nome do banco: `SEFAZ_FISCAL` (exemplo). Objetivo: deixar explícito o propósito.
- Separei arquivos de dados e log para reduzir contenção I/O e possibilitar políticas distintas de backup/retention.

Comando exemplo:

```sql
CREATE DATABASE SEFAZ_FISCAL
ON PRIMARY (
  NAME = 'SEFAZ_FISCAL_DATA',
  FILENAME = 'C:\Dados\SEFAZ_FISCAL.mdf',
  SIZE = 500MB,
  FILEGROWTH = 100MB
)
LOG ON (
  NAME = 'SEFAZ_FISCAL_LOG',
  FILENAME = 'D:\Logs\SEFAZ_FISCAL.ldf',
  SIZE = 200MB,
  FILEGROWTH = 50MB
);
```

Justificativa:
- Dados e logs em discos distintos reduzem latência e o risco de perda simultânea por falha no disco; logs em disco com melhor throughput melhoram recuperação e checkpoints.
- Tamanhos iniciais evitam autogrowth frequente em cargas grandes (EFD/NF-e).

---

## 2. Organização por schemas

Decisões:
- `fiscal`: tabelas finais (EFD, NFE, ITEM_NFE).
- `staging`: área para cargas/importações; sem constraints rígidas para permitir ingestão rápida.
- `auditoria`: tabelas de logs e histórico; acessos restritos.

Exemplos:

```sql
CREATE SCHEMA fiscal;
CREATE SCHEMA staging;
CREATE SCHEMA auditoria;

CREATE TABLE staging.raw_nfe (
  raw_line NVARCHAR(MAX),
  import_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
```

Justificativa:
- Schemas organizam responsabilidades e facilitam GRANT/REVOKE. Em fiscal, separar staging evita que processos de ingestão afetem as tabelas finais e facilita rollback/retentativa.

---

## 3. Definição de tabelas físicas

Decisões gerais de tipo:
- Identificadores sequenciais: `BIGINT` quando esperado grande volume; `INT` quando volume controlado.
- Chave de acesso NF-e: `CHAR(44)` (tamanho fixo evita espaço extra e melhora comparação).
- CNPJ: `CHAR(14)` (campo fixo sem formatação) ou `VARCHAR(14)` se quiser armazenar com pontuação.
- Valores monetários: `DECIMAL(16,2)` para evitar erros de arredondamento.
- Datas: `DATE` quando só data; `DATETIME2` para timestamp precisos.

Exemplo de criação (simplificado):

```sql
CREATE TABLE fiscal.EFD_0000 (
  sqcontrib INT NOT NULL PRIMARY KEY,
  nrcnpj CHAR(14) NOT NULL,
  sguf CHAR(2) NOT NULL,
  dtinicial DATE NOT NULL,
  dtfinal DATE NOT NULL,
  stregistro TINYINT NOT NULL DEFAULT 1
);

CREATE TABLE fiscal.NFE (
  sqnfe BIGINT NOT NULL,
  tpnfe INT NOT NULL,
  nrchaveacesso CHAR(44) NOT NULL,
  vltotalnota DECIMAL(16,2) NOT NULL,
  stnfe CHAR(1) NOT NULL,
  dtemissao DATE NOT NULL,
  CONSTRAINT PK_NFE PRIMARY KEY (sqnfe, tpnfe),
  CONSTRAINT UQ_NFE_CHAVE UNIQUE (nrchaveacesso)
);

CREATE TABLE fiscal.ITEM_NFE (
  sqitemnfe BIGINT IDENTITY(1,1) PRIMARY KEY,
  sqnfe BIGINT NOT NULL,
  tpnfe INT NOT NULL,
  cdncm VARCHAR(10) NULL,
  vlproduto DECIMAL(16,2) NOT NULL,
  CONSTRAINT FK_ITEM_NFE_NFE FOREIGN KEY (sqnfe, tpnfe)
    REFERENCES fiscal.NFE (sqnfe, tpnfe)
);

CREATE TABLE fiscal.EFD_C100 (
  sqnfoutra BIGINT NOT NULL PRIMARY KEY,
  sqcontrib INT NOT NULL,
  nrchavenfe CHAR(44) NULL,
  vltotalnf DECIMAL(16,2) NOT NULL,
  CONSTRAINT FK_EFD_C100_EFD FOREIGN KEY (sqcontrib)
    REFERENCES fiscal.EFD_0000 (sqcontrib)
);
```

Justificativa:
- Chaves compostas em `NFE` (`sqnfe, tpnfe`) permitem diferenciar tipos/partições de notas quando necessário.
- `CHAR(44)` para chave de acesso garante comparação rápida e uso eficiente de índices.
- `IDENTITY` em `ITEM_NFE` facilita referência a itens individuais.

---

## 4. Implementação de constraints fiscais

Decisões sobre constraints:
- `PRIMARY KEY` para garantir unicidade e performance de joins.
- `FOREIGN KEY` para integridade referencial: evita itens órfãos.
- `UNIQUE` na chave de acesso impede duplicidade de nota eletrônica.
- `CHECK` para regras simples de negócio (status, valores não-negativos, UFs válidas).
- `DEFAULT` para facilitar inserções e manter valores esperados.

Exemplos de `CHECK` e `DEFAULT`:

```sql
ALTER TABLE fiscal.NFE
ADD CONSTRAINT CK_NFE_STATUS CHECK (stnfe IN ('A','C','D','I','O','U'));

ALTER TABLE fiscal.NFE
ADD CONSTRAINT CK_NFE_VALOR CHECK (vltotalnota >= 0);

ALTER TABLE fiscal.EFD_0000
ADD CONSTRAINT CK_EFD_UF CHECK (sguf IN ('PB','SP','RJ', /*...*/ 'AC'));
```

Justificativa:
- `CHECK` executa validação no banco, evitando que regras simples sejam deixadas apenas na aplicação; isso é crucial em ambientes onde múltiplos ingestores alimentam o DB.
- Evitar regras complexas em `CHECK` que exijam joins; usar procedures/triggers para validações multi-linha.

---

## 5. Relacionamentos e ações referenciais

Decisões sobre ações `ON DELETE` / `ON UPDATE`:
- Padrão recomendado: `ON DELETE NO ACTION` / `ON UPDATE NO ACTION`.
- Motivo: em fiscalização, excluir registros pode destruir evidências; preferir proibir exclusões encadeadas.
- `ON DELETE SET NULL` pode ser usado em tabelas de histórico/archival onde referenciamento pode ser quebrado sem perda total do registro.
- `ON DELETE CASCADE` é arriscado em tabelas fiscais principais porque exclusões em cascata podem apagar grandes volumes e evidências.

Exemplo:

```sql
ALTER TABLE fiscal.ITEM_NFE
ADD CONSTRAINT FK_ITEM_NFE_NFE
  FOREIGN KEY (sqnfe, tpnfe) REFERENCES fiscal.NFE(sqnfe, tpnfe)
  ON DELETE NO ACTION ON UPDATE NO ACTION;
```

Justificativa:
- Protege integridade histórica e garante que exclusões sejam ações deliberadas, não automáticas.

---

## 6. Índices para consultas fiscais

Decisões de indexação:
- Índices em colunas frequentemente filtradas: `nrchaveacesso`, `sqcontrib`, `dtemissao`, `stnfe`.
- Índices compostos quando consultas filtram por múltiplas colunas (por ex.: `WHERE nrchaveacesso = ? AND stnfe = ?`).
- Evitar índices excessivos em tabelas com alta taxa de escrita (inserções em lote), equilibrando leitura x escrita.

Exemplo de índice:

```sql
CREATE NONCLUSTERED INDEX IX_NFE_CHAVE_STATUS ON fiscal.NFE (nrchaveacesso, stnfe);
CREATE NONCLUSTERED INDEX IX_EFD_CONTRIB_PERIODO ON fiscal.EFD_0000 (sqcontrib, dtinicial, dtfinal);
```

Justificativa:
- Índices melhoram velocidade de busca para auditorias e cruzamentos; índices cobrem consultas críticas, reduzindo leituras de página.
- Para cargas massivas (ETL), planejar criação de índices após carga inicial ou usar índices desabilitados/filtrados.

---

## 7. Tabela de staging e validação de carga

Decisões:
- `staging` recebe dados tal quais, sem constraints, para permitir ingestão rápida.
- Validações (scripts/procedures) aplicam regras e movem apenas registros válidos para schemas finais.

Exemplo de `staging` e rotina simples:

```sql
CREATE TABLE staging.nfe_raw (
  raw_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  nrchave NVARCHAR(100),
  vltotal NVARCHAR(50),
  imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);

-- Pseudo-rotina de validação:
-- 1. Converter tipos (CHAR->CHAR, DECIMAL->DECIMAL)
-- 2. Verificar consistência (chave duplicada, formatos)
-- 3. Inserir em fiscal.NFE somente registros validados

INSERT INTO fiscal.NFE (sqnfe, tpnfe, nrchaveacesso, vltotalnota, stnfe, dtemissao)
SELECT NEXT VALUE FOR seq_nfe, 1, SUBSTRING(nrchave,1,44), TRY_CAST(vltotal AS DECIMAL(16,2)), 'A', CAST(imported_dt AS DATE)
FROM staging.nfe_raw r
WHERE ISDATE(r.imported_dt) = 1
  AND LEN(r.nrchave) = 44
  AND TRY_CAST(vltotal AS DECIMAL(16,2)) IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM fiscal.NFE n WHERE n.nrchaveacesso = SUBSTRING(r.nrchave,1,44));
```

Justificativa:
- Separar ingestão e validação reduz retrabalho; `TRY_CAST`/`ISDATE` ajudam a filtrar linhas inválidas.

---

## 8. Análise de dados com falhas intencionais

Exemplos de inserts com erros e explicação das failures:

1) NULL em campo obrigatório:

```sql
-- tenta inserir sem nrchaveacesso (NOT NULL)
INSERT INTO fiscal.NFE (sqnfe, tpnfe, vltotalnota, stnfe, dtemissao)
VALUES (1001, 1, 100.00, 'A', '2026-07-01');
-- Falha: nrchaveacesso é NOT NULL/UNIQUE => constraint falha
```

2) Duplicidade de chave única:

```sql
-- se já existe nrchaveacesso = 'ABC' então:
INSERT INTO fiscal.NFE (sqnfe, tpnfe, nrchaveacesso, vltotalnota, stnfe, dtemissao)
VALUES (1002,1,'ABC',200.00,'A','2026-07-02');
-- Falha: UNIQUE constraint UQ_NFE_CHAVE
```

3) Valor negativo:

```sql
INSERT INTO fiscal.NFE (sqnfe, tpnfe, nrchaveacesso, vltotalnota, stnfe, dtemissao)
VALUES (1003,1,'DEF',-50.00,'A','2026-07-03');
-- Falha: CHECK CK_NFE_VALOR (vltotalnota >= 0)
```

Correção:
- Ajustar os dados na tabela `staging` ou via `UPDATE` antes de mover para tabelas finais; então reexecutar o `INSERT`.

---

## 9. Caso prático de fiscalização tributária

Objetivo: detectar itens sem nota, notas com soma de itens divergente e NF-e com status inválido.

Consultas exemplo:

1) Itens sem nota correspondente:

```sql
SELECT i.sqitemnfe, i.sqnfe, i.tpnfe
FROM fiscal.ITEM_NFE i
LEFT JOIN fiscal.NFE n
  ON n.sqnfe = i.sqnfe AND n.tpnfe = i.tpnfe
WHERE n.sqnfe IS NULL;
```

2) Notas com soma dos itens diferente do valor total:

```sql
SELECT n.sqnfe, n.tpnfe, n.vltotalnota, SUM(i.vlproduto) AS soma_itens
FROM fiscal.NFE n
JOIN fiscal.ITEM_NFE i
  ON i.sqnfe = n.sqnfe AND i.tpnfe = n.tpnfe
GROUP BY n.sqnfe, n.tpnfe, n.vltotalnota
HAVING SUM(i.vlproduto) <> n.vltotalnota;
```

3) NF-e com status inválido (fora do conjunto esperado):

```sql
SELECT * FROM fiscal.NFE WHERE stnfe NOT IN ('A','C','D','I','O','U');
```

Justificativa:
- Essas consultas são diretas e eficientes se houver índices em `sqnfe/tpnfe`, `nrchaveacesso` e `stnfe`.
- Resultados servem como evidência para processos de auditoria e gatilhos de investigação.

---

## 10. Entrega final — checklist e justificativas

O aluno deve entregar:
- `CREATE DATABASE` e rationale (I/O e backup);
- `CREATE SCHEMA` e explicação de separação de responsabilidades;
- `CREATE TABLE` com tipos escolhidos e justificativas para cada coluna;
- Constraints (`PK`, `FK`, `UNIQUE`, `CHECK`, `DEFAULT`) com justificativas de negócio;
- Índices (exemplos e justificativas de custo/benefício);
- Scripts de validação (staging -> final) e consultas de auditoria.

Observações finais:
- Prefira tipos fixos (`CHAR`) para chaves padronizadas (CNPJ, chave NF-e) quando não houver formatação variável, para economizar espaço e melhorar performance.
- Use `DECIMAL` para valores monetários, nunca `FLOAT` ou `REAL`.
- Planeje particionamento por período (ano/mês) em tabelas que crescem sem limites (EFD/NF-e), para manutenção e consultas performáticas.
- Documente todas as decisões em comentários nos scripts SQL para rastreabilidade.

---

Arquivo associado: `roteiro-exercicios-modelagem-fisica.md` (enunciado).

Se quiser, gero a versão em PDF deste arquivo de respostas.