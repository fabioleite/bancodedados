# Roteiro de Exercícios — Modelagem Física para Fiscalização Tributária

Este roteiro conecta os conceitos de modelagem física em SQL Server ao contexto de fiscalização tributária, com foco em EFD, NF-e, integridade referencial e desempenho.

## 1. Projeto inicial do banco fiscal

1. Defina o banco de dados para armazenar os dados fiscais de uma SEFAZ, incluindo EFD e NF-e.
2. Escreva o comando `CREATE DATABASE` com:
   - nome do banco;
   - definição de arquivos de dados e log (`PRIMARY`, `LOG ON`);
   - tamanho inicial e filegrowth.
3. Explique por escrito por que é recomendável separar os arquivos de dados e de log em discos distintos em um ambiente fiscal.

## 2. Organização por schemas

1. Crie três schemas: `dbo`, `fiscal` e `staging`.
2. Para cada schema, descreva o papel no projeto:
   - `fiscal` para tabelas finais de EFD e NF-e;
   - `staging` para carga inicial e validação;
   - `dbo` para objetos auxiliares e administração.
3. Escreva um exemplo de comando `CREATE SCHEMA` e uma tabela `CREATE TABLE` dentro de cada schema.

## 3. Definição de tabelas físicas

1. Crie as seguintes tabelas com `CREATE TABLE` no SQL Server:
   - `fiscal.EFD_0000`
   - `fiscal.EFD_C100`
   - `fiscal.NFE`
   - `fiscal.ITEM_NFE`
2. Para cada coluna, escolha o tipo de dado mais adequado:
   - `CNPJ` → `CHAR(14)` ou `VARCHAR(14)`;
   - `chave de acesso NF-e` → `CHAR(44)`;
   - valores monetários → `DECIMAL(16,2)`;
   - datas → `DATE` ou `DATETIME2`;
   - identificadores → `INT` ou `BIGINT`.
3. Inclua `NOT NULL` nas colunas obrigatórias e `NULL` apenas onde houver justificativa.

## 4. Implementação de constraints fiscais

1. Aplique `PRIMARY KEY` em cada tabela para garantir unicidade.
2. Defina `FOREIGN KEY` para:
   - `EFD_C100(sqcontrib)` → `EFD_0000(sqcontrib)`;
   - `ITEM_NFE(sqnfe, tpnfe)` → `NFE(sqnfe, tpnfe)`.
3. Adicione `UNIQUE` em campos críticos:
   - `NFE(nrchaveacesso)`.
4. Crie `CHECK` para regras fiscais, por exemplo:
   - `stnfe IN ('A','C','D','I','O','U')`;
   - `vltotalnota >= 0`;
   - `uf` válida entre as UFs brasileiras.
5. Use `DEFAULT` para valores padrão como `stregistro`, `DataCadastro` ou `Status`.

## 5. Relacionamentos e ações referenciais

1. Identifique a cardinalidade entre as tabelas:
   - `NFE` e `ITEM_NFE` → 1:N;
   - `EFD_0000` e `EFD_C100` → 1:N.
2. Explique qual ação referencial é mais adequada para cada relacionamento:
   - `ON DELETE NO ACTION` para evitar exclusão acidental;
   - `ON UPDATE NO ACTION` para manter consistência;
   - quando `SET NULL` pode ser aceitável.
3. Justifique por que `ON DELETE CASCADE` deve ser usado com muito cuidado em bases fiscais.

## 6. Índices para consultas fiscais

1. Crie índices não clusterizados em colunas usadas em auditorias:
   - `nrchaveacesso`, `sqcontrib`, `dtinicial`, `dtfinal`, `stnfe`, `tpnfe`.
2. Escreva um exemplo de `CREATE NONCLUSTERED INDEX` para otimizar consultas de NF-e por status e período.
3. Explique em poucas linhas como um índice melhora consultas de cruzamento de EFD e NF-e.

## 7. Tabela de staging e validação de carga

1. Crie uma tabela de staging para importação de registros de EFD e NF-e.
2. Mostre o `CREATE TABLE` da tabela de staging com tipos genéricos e sem constraints rígidas.
3. Escreva uma rotina SQL (ou pseudo-SQL) para:
   - validar os dados de staging;
   - inserir apenas registros válidos nas tabelas finais.

## 8. Análise de dados com falhas intencionais

1. Insira registros demonstrando erros comuns:
   - `NULL` em campo obrigatório;
   - duplicidade de chave única;
   - valor negativo em campo monetário.
2. Explique quais constraints impedem cada erro.
3. Ajuste os dados e reimporte corretamente.

## 9. Caso prático de fiscalização tributária

1. Modele uma solução para o cenário:
   - “Empresa envia EFD de julho com NF-e cancelada e itens não relacionados.”
2. Crie as tabelas e constraints necessárias para detectar:
   - itens de NF-e sem nota correspondente;
   - notas com soma de itens diferente do valor total;
   - NF-e com status inválido.
3. Escreva consultas de validação para cada tipo de inconsistência.

## 10. Entrega final

1. Entregue os scripts SQL:
   - `CREATE DATABASE`;
   - `CREATE SCHEMA`;
   - `CREATE TABLE`;
   - `ALTER TABLE` para constraints/índices se necessário.
2. Inclua explicações breves sobre:
   - escolha de tipos de dados;
   - uso de schemas;
   - lógica das constraints;
   - impacto do índice no desempenho.
3. Inclua pelo menos duas consultas SQL de auditoria fiscal.
