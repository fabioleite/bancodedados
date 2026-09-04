-- Exemplos de inserção: multi-row, INSERT...SELECT, BULK INSERT, OPENROWSET

-- 1) Multi-row insert
INSERT INTO fiscal.NFE_TEST (sqnfe, tpnfe, nrchaveacesso, vltotalnota, dtemissao, stnfe)
VALUES
 (2001,1,'000000000000000000000000000000000000010001',150.00,'2026-07-10','A'),
 (2002,1,'000000000000000000000000000000000000010002',250.00,'2026-07-10','A');

-- 2) INSERT ... SELECT (from staging)
INSERT INTO fiscal.NFE (sqnfe, tpnfe, nrchaveacesso, vltotalnota, dtemissao, stnfe)
SELECT NEXT VALUE FOR seq_nfe, 1, LEFT(r.nrchave,44),
       TRY_CAST(REPLACE(r.vltotal,',','.') AS DECIMAL(16,2)),
       TRY_CAST(r.dtemissao AS DATE), LEFT(r.stnfe,1)
FROM staging.raw_nfe r
WHERE LEN(r.nrchave) >= 44;

-- 3) BULK INSERT example (adapt path accordingly)
-- BULK INSERT staging.nfe_bulk
-- FROM 'C:\cargas\nfe_sample.csv'
-- WITH (FIELDTERMINATOR=';', ROWTERMINATOR='\n', FIRSTROW=2, CODEPAGE='65001');

-- 4) OPENROWSET(BULK) example
-- SELECT * FROM OPENROWSET(BULK 'C:\cargas\nfe_sample.csv', FORMAT='CSV') as t

-- 5) Query to detect items without parent NFE
SELECT i.sqitemnfe, i.sqnfe
FROM fiscal.ITEM_NFE i
LEFT JOIN fiscal.NFE n ON n.sqnfe = i.sqnfe AND n.tpnfe = i.tpnfe
WHERE n.sqnfe IS NULL;
