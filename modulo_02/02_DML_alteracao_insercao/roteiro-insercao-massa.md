# Roteiro de Exercícios — Inserção em Massa (Multi-row, BULK)

Objetivo: praticar técnicas de inserção em massa (multi-row INSERT, INSERT...SELECT, BULK INSERT, OPENROWSET/BCP/SqlBulkCopy) aplicadas a dados fiscais (EFD, NF-e), com foco em desempenho, integridade e auditoria.

## Exercício 1 — INSERT de múltiplas linhas (prático rápido)
1. Crie uma tabela `fiscal.NFE_TEST` com colunas: `sqnfe BIGINT`, `tpnfe INT`, `nrchaveacesso CHAR(44)`, `vltotalnota DECIMAL(16,2)`, `dtemissao DATE`, `stnfe CHAR(1)`.
2. Insira 5 notas via um único `INSERT` multi-row.
3. Verifique a inserção e documente o plano de execução (EXPLAIN/SHOWPLAN).

## Exercício 2 — INSERT ... SELECT para transformar dados
1. Considere uma tabela `staging.raw_nfe` com campos textuais.
2. Realize um `INSERT INTO fiscal.NFE` usando `INSERT ... SELECT` com conversões (`TRY_CAST`/`TRY_CONVERT`) e filtros.
3. Registre as linhas rejeitadas em uma tabela `staging.nfe_rejeitadas`.

## Exercício 3 — CTE + INSERT em massa
1. Use um `WITH cte AS (...)` para pré-processar dados (normalizar campos, remover duplicatas) e insira os resultados em `fiscal.NFE`.
2. Mostre o script e explique porque a CTE ajuda na legibilidade e modularidade.

## Exercício 4 — BULK INSERT (T-SQL)
1. Prepare um CSV `nfe_sample.csv` com colunas: `nrchaveacesso;vltotalnota;dtemissao;stnfe;sqnfe;tpnfe` (ponto decimal `.` ou vírgula conforme configuração).
2. Crie uma tabela de staging `staging.nfe_bulk` com tipos textuais.
3. Use `BULK INSERT staging.nfe_bulk FROM 'C:\cargas\nfe_sample.csv' WITH (FIELDTERMINATOR=';', ROWTERMINATOR='\n', FIRSTROW=2, CODEPAGE='65001')`.
4. Valide e mova os registros para `fiscal.NFE` com `TRY_CONVERT`.

## Exercício 5 — OPENROWSET(BULK) e PolyBase (se disponível)
1. Mostre como usar `OPENROWSET(BULK...)` para ler CSVs sem criar arquivo físico de staging (ex.: diretório de ingestão).
2. Se PolyBase estiver disponível, descreva os passos para criar external table e consultar diretamente.

## Exercício 6 — BCP (linha de comando) e SqlBulkCopy (C#) — integração
1. Forneça comando `bcp` para importar o CSV diretamente para uma tabela staging.
2. Inclua um exemplo mínimo de uso de `SqlBulkCopy` em C# para enviar um `DataTable` ao SQL Server.

## Exercício 7 — Estratégia de carga para grandes volumes (procedimento)
1. Escreva um roteiro de passos para ingestão de 10 milhões de linhas fiscais:
   - preparar CSVs particionados por mês;
   - carregar em `staging` com `BULK INSERT`/BCP;
   - desabilitar índices e constraints durante carga (quando seguro);
   - executar validação e conversão por lote;
   - inserir em tabelas finais e recriar índices;
   - coletar estatísticas e executar `UPDATE STATISTICS`.
2. Explique riscos e rollback strategies.

## Exercício 8 — Tratamento de erros e auditoria
1. Implemente TRY/CATCH numa procedure que executa o fluxo de carga e grava erro em `auditoria.load_errors` com detalhes do arquivo/linha/mensagem.
2. Mostre um exemplo de registro de erro e como reprocessar apenas linhas com falha.

## Exercício 9 — Fluxo completo de staging → validação → tabela final
1. Use os arquivos CSV de exemplo disponíveis em `exemplos/` para praticar um fluxo completo de ingestão:
   - `staging_nfe_20.csv`
   - `staging_item_nfe_20.csv`
   - `staging_nfce_20.csv`
   - `staging_item_nfce_20.csv`
   - `staging_cte_20.csv`
   - `staging_efd_registro_20.csv`
2. Crie as tabelas de staging sugeridas no script `exemplos/staging_bulk_tabelas.sql`.
3. Faça o `BULK INSERT` de cada CSV para a respectiva tabela de staging, usando `FIELDTERMINATOR=';'`, `ROWTERMINATOR='\n'`, `FIRSTROW=2` e `CODEPAGE='65001'`.
4. Valide os dados carregados em staging com consultas simples, por exemplo:
   - verificar quantidade de linhas por arquivo;
   - identificar valores nulos ou inconsistentes;
   - confirmar se as datas estão no formato esperado.
5. Mova os registros para as tabelas finais com `INSERT ... SELECT` e conversões explícitas:
   - `TRY_CONVERT(DATE, data_emissao)` para datas;
   - `TRY_CONVERT(DECIMAL(15,2), valor_total)` para valores monetários;
   - `TRY_CONVERT(BIGINT, id_nfe)` ou `TRY_CONVERT(BIGINT, id_nfce)` quando necessário.
6. Registre linhas inválidas em uma tabela de rejeição, por exemplo `staging.rejeicoes_bulk`, com colunas: `origem`, `motivo`, `dados_brutos`.
7. Compare o número de linhas carregadas em staging com o número efetivamente inserido nas tabelas finais e explique diferenças.
8. Discuta por que o uso de staging melhora a rastreabilidade, a auditoria e a recuperação de falhas em processos de carga.

## Entregáveis
- Scripts SQL: `CREATE TABLE`, `INSERT` (multi-row), `BULK INSERT`, `INSERT ... SELECT`, CTE scripts.
- Arquivo CSV de exemplo: `nfe_sample.csv`.
- Comando `bcp` e snippet `SqlBulkCopy`.
- Relatório curto (1 página) com justificativas de cada escolha (tipos, delimitador, handling de encoding, uso de índices).