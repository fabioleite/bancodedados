## Projeto de Carga — Fluxo completo de staging → validação → tabela final
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