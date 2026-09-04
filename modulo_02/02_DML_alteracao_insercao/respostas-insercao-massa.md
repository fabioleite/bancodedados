# Respostas e Explicações — Inserção em Massa (Multi-row, BULK)

Este documento responde passo a passo ao roteiro de exercícios, explicando decisões técnicas e fornecendo exemplos SQL e comandos.

---

## Exercício 1 — INSERT de múltiplas linhas
### Solução (exemplo)
```sql
CREATE TABLE fiscal.NFE_TEST (
  sqnfe BIGINT NOT NULL,
  tpnfe INT NOT NULL,
  nrchaveacesso CHAR(44) NOT NULL,
  vltotalnota DECIMAL(16,2) NOT NULL,
  dtemissao DATE NOT NULL,
  stnfe CHAR(1) NOT NULL,
  CONSTRAINT PK_NFE_TEST PRIMARY KEY (sqnfe, tpnfe)
);

INSERT INTO fiscal.NFE_TEST (sqnfe, tpnfe, nrchaveacesso, vltotalnota, dtemissao, stnfe)
VALUES
 (1001,1,'000000000000000000000000000000000000000001',100.00,'2026-07-01','A'),
 (1002,1,'000000000000000000000000000000000000000002',200.50,'2026-07-01','A'),
 (1003,1,'000000000000000000000000000000000000000003',50.00,'2026-07-02','A'),
 (1004,1,'000000000000000000000000000000000000000004',1200.00,'2026-07-02','C'),
 (1005,1,'000000000000000000000000000000000000000005',79.99,'2026-07-03','A');
```

### Explicações
- Usamos `CHAR(44)` para chave de acesso porque o tamanho é fixo; isso economiza espaço e melhora indexação.
- Multi-row `INSERT` reduz round-trips ao servidor comparado a múltiplos `INSERT` individuais.
- Verificar plano de execução (`SET SHOWPLAN_TEXT ON` / `EXPLAIN`) ajuda a confirmar se o DB usa abordagem eficiente.

---

## Exercício 2 — INSERT ... SELECT
### Solução (exemplo)
```sql
-- tabela staging
CREATE TABLE staging.raw_nfe (
  raw_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  nrchave NVARCHAR(100),
  vltotal NVARCHAR(50),
  dtemissao NVARCHAR(50),
  stnfe NVARCHAR(5),
  imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);

-- mover validos
INSERT INTO fiscal.NFE (sqnfe, tpnfe, nrchaveacesso, vltotalnota, dtemissao, stnfe)
SELECT NEXT VALUE FOR seq_nfe, 1,
       LEFT(r.nrchave,44) AS nrchaveacesso,
       TRY_CAST(REPLACE(r.vltotal,',','.') AS DECIMAL(16,2)) AS vltotalnota,
       TRY_CAST(r.dtemissao AS DATE) AS dtemissao,
       LEFT(r.stnfe,1) AS stnfe
FROM staging.raw_nfe r
WHERE LEN(r.nrchave) >= 44
  AND TRY_CAST(REPLACE(r.vltotal,',','.') AS DECIMAL(16,2)) IS NOT NULL
  AND TRY_CAST(r.dtemissao AS DATE) IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM fiscal.NFE n WHERE n.nrchaveacesso = LEFT(r.nrchave,44));

-- rejeitados
INSERT INTO staging.nfe_rejeitadas (raw_id, motivo)
SELECT raw_id, 'Formato invalido' FROM staging.raw_nfe r
WHERE NOT (LEN(r.nrchave) >= 44 AND TRY_CAST(REPLACE(r.vltotal,',','.') AS DECIMAL(16,2)) IS NOT NULL);
```

### Explicação
- `TRY_CAST` e `REPLACE` ajudam a converter formatos diferentes (vírgula/ponto decimal).
- `INSERT ... SELECT` é eficiente pois a conversão é feita no servidor com set-based operations.
- Registar rejeitados permite reprocessamento sem perder a linha original.

---

## Exercício 3 — CTE + INSERT
### Solução (exemplo)
```sql
WITH cleaned AS (
  SELECT DISTINCT
    LEFT(r.nrchave,44) AS nrchaveacesso,
    TRY_CAST(REPLACE(r.vltotal,',','.') AS DECIMAL(16,2)) AS vltotalnota,
    TRY_CAST(r.dtemissao AS DATE) AS dtemissao,
    LEFT(r.stnfe,1) AS stnfe
  FROM staging.raw_nfe r
  WHERE LEN(r.nrchave) >= 44
)
INSERT INTO fiscal.NFE (sqnfe, tpnfe, nrchaveacesso, vltotalnota, dtemissao, stnfe)
SELECT NEXT VALUE FOR seq_nfe, 1, nrchaveacesso, vltotalnota, dtemissao, stnfe
FROM cleaned c
WHERE vltotalnota IS NOT NULL;
```

### Explicação
- CTE melhora legibilidade e separa a transformação da inserção.
- `DISTINCT` evita duplicatas no staging; decisões como `DISTINCT` devem ser ponderadas conforme requisitos.

---

## Exercício 4 — BULK INSERT (T-SQL)
### Exemplo de CSV (`nfe_sample.csv`)
```csv
nrchaveacesso;vltotalnota;dtemissao;stnfe;sqnfe;tpnfe
000000000000000000000000000000000000000001;100.00;2026-07-01;A;1001;1
000000000000000000000000000000000000000002;200.50;2026-07-01;A;1002;1
```

### Script de criação da tabela staging
```sql
CREATE TABLE staging.nfe_bulk (
  nrchaveacesso CHAR(44) primary key,
  vltotalnota DECIMAL(16,2),
  dtemissao DATE,
  stnfe CHAR(1),
  sqnfe BIGINT,
  tpnfe INT
);
```

### Comando BULK INSERT
```sql
BULK INSERT staging.nfe_bulk
FROM 'C:\cargas\nfe_sample.csv'
WITH (
  FIELDTERMINATOR=';',
  ROWTERMINATOR='\n',
  FIRSTROW=2,
  CODEPAGE='65001',
  MAXERRORS=0
);
```

### Explicações
- `CODEPAGE='65001'` garante UTF-8; ajuste conforme origem do CSV.
- `FIRSTROW=2` pula cabeçalho.
- Depois de carregar em `staging`, utilizar `INSERT ... SELECT` com validações.

---

## Exercício 5 — OPENROWSET(BULK) e PolyBase
### OPENROWSET exemplo
```sql
SELECT *
FROM OPENROWSET(
  BULK 'C:\cargas\nfe_sample.csv',
  FORMAT='CSV',
  PARSER_VERSION='2.0'
) AS t;
```

### Observações
- `OPENROWSET(BULK...)` permite leitura ad-hoc sem objeto persistente.
- PolyBase oferece external tables e é recomendado para grandes volumes e integração com HDFS/ADLS.

---

## Exercício 6 — BCP e SqlBulkCopy
### Comando BCP (exemplo)
```powershell
bcp "staging.nfe_bulk" in "C:\cargas\nfe_sample.csv" -S myserver -d SEFAZ_FISCAL -T -c -t";" -r"\n"
```

### SqlBulkCopy (C# minimal)
```csharp
using (var bulk = new SqlBulkCopy(connString)) {
  bulk.DestinationTableName = "staging.nfe_bulk";
  bulk.WriteToServer(dataTable);
}
```

### Explicação
- `bcp` é leve e rápido para cargas; `SqlBulkCopy` é programático e permite transformação em memória antes da carga.

---

## Exercício 7 — Estratégia de carga para 10M linhas
### Roteiro resumido
1. Particionar fonte em arquivos por mês (por exemplo `nfe_2026_07.csv`).
2. Para cada arquivo:
   - `BULK INSERT` para `staging` (sem índices);
   - Validar e transformar em lotes (10k-100k) via `INSERT ... SELECT` transacional;
   - Recriar índices e atualizar estatísticas;
3. Monitorar `tempdb` e I/O; usar `TABLOCK` em cargas massivas para melhorar throughput.

### Riscos/mitigações
- Risco: locks longos — mitigar com batches e menor transaction scope.
- Risco: consumo de log — usar recuperação em massa e planejar backups.

---

## Exercício 8 — Tratamento de erros e auditoria
### Procedure de exemplo (esqueleto)
```sql
CREATE PROCEDURE staging.LoadNfeFile @FilePath NVARCHAR(4000)
AS
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION;
    BULK INSERT staging.nfe_bulk FROM @FilePath WITH (FIELDTERMINATOR=';', FIRSTROW=2);
    -- validação e movimentação
    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION;
    INSERT INTO auditoria.load_errors (file_path, error_message, error_time)
    VALUES (@FilePath, ERROR_MESSAGE(), SYSUTCDATETIME());
    THROW;
  END CATCH
END
```

### Explicação
- Registrar erros com `ERROR_MESSAGE()` facilita reprocessamento e auditoria.
- Transações garantem atomicidade por arquivo/lote.

---

## Observações finais e justificativas de design
- Use `DECIMAL` para valores financeiros; evitar `FLOAT`.
- Prefira CSV com delimitador `;` em ambientes que usam `,` como decimal separator; documente e normalize antes da carga.
- Crie índices apenas após carga inicial para evitar overhead em inserções massivas.
- Sempre manter um `staging` imutável (raw) para poder reprocesar sem perda de origem.

---

Arquivos relacionados:
- `roteiro-insercao-massa.md` (enunciado)
- `nfe_sample.csv` (exemplo de carga)
- `insercao-exemplos.sql` (coleção de exemplos SQL)