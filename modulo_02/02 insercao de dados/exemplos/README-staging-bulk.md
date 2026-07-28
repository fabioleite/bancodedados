# Arquivos de exemplo para BULK INSERT em staging

Este conjunto de arquivos foi preparado para exercícios de carga em massa com CSVs pequenos e fáceis de revisar.

## Como devem ser as tabelas de staging

As tabelas de staging devem funcionar como área de recepção temporária, com colunas em formato textual ou de fácil conversão. O objetivo é aceitar o arquivo bruto, validar e só depois mover para as tabelas definitivas.

### Regras recomendadas
- usar schema `staging`;
- preferir colunas `NVARCHAR`/`VARCHAR` para os campos que virão do CSV;
- incluir uma coluna `imported_dt` para registrar o momento da carga;
- manter os dados brutos sem transformações complexas na etapa de ingestão;
- usar `TRY_CONVERT`/`TRY_CAST` na etapa de consolidação para as tabelas finais.

### Estrutura sugerida

```sql
CREATE TABLE staging.stg_nfe_bulk (
    chave_acesso NVARCHAR(44) NOT NULL,
    id_contribuinte_emitente NVARCHAR(20) NULL,
    id_contribuinte_destinatario NVARCHAR(20) NULL,
    data_emissao NVARCHAR(10) NULL,
    valor_total NVARCHAR(20) NULL,
    situacao NVARCHAR(20) NULL,
    imported_dt DATETIME2 DEFAULT SYSUTCDATETIME()
);
```

As demais tabelas seguem a mesma ideia, com colunas correspondentes aos arquivos CSV abaixo.

## Como devem ser os dados CSV

- usar `;` como separador de colunas;
- usar `UTF-8`;
- incluir cabeçalho na primeira linha;
- usar `\n` como fim de linha;
- manter datas no formato `YYYY-MM-DD`;
- manter valores monetários com ponto decimal (`100.00`);
- manter 20 registros por arquivo para facilitar a prática.

## Arquivos disponíveis
- [staging_nfe_20.csv](staging_nfe_20.csv)
- [staging_item_nfe_20.csv](staging_item_nfe_20.csv)
- [staging_nfce_20.csv](staging_nfce_20.csv)
- [staging_item_nfce_20.csv](staging_item_nfce_20.csv)
- [staging_cte_20.csv](staging_cte_20.csv)
- [staging_efd_registro_20.csv](staging_efd_registro_20.csv)
- [staging_bulk_tabelas.sql](staging_bulk_tabelas.sql)

## Tabelas finais

As tabelas de staging acima recebem apenas a carga bruta (colunas `NVARCHAR`, sem regras). O esquema definitivo — com tipos corretos, chaves primárias/estrangeiras e `CHECK` de domínio — está em [criar_tabelas_fiscais_finais.sql](criar_tabelas_fiscais_finais.sql) (schema `fiscal`: `CONTRIBUINTE`, `NFE`, `ITEM_NFE`, `NFCE`, `ITEM_NFCE`, `CTE`, `EFD_REGISTRO`).
