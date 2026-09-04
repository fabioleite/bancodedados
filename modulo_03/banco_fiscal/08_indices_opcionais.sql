/* =====================================================================
   Script 08 - Indices de DESEMPENHO (opcional)
   ---------------------------------------------------------------------
   NAO execute este script antes do exercicio de plano de execucao do
   Modulo 10 (bloco D). A graca do exercicio esta em ver a varredura
   completa, ler a sugestao de "indice ausente" e so entao criar o
   indice, comparando o antes e o depois.
   ===================================================================== */
USE curso_integridade_fiscal;
GO

-- Consultas por situacao + periodo de emissao (o caso mais frequente)
CREATE NONCLUSTERED INDEX IX_nfe_situacao_data
    ON dbo.nfe (situacao, data_emissao)
    INCLUDE (chave_acesso, id_emitente, id_destinatario, valor_total, valor_icms);
GO

-- Cruzamento NF-e x EFD pela chave de acesso
CREATE NONCLUSTERED INDEX IX_efd_c100_chave
    ON dbo.efd_c100 (chave_acesso)
    INCLUDE (id_contribuinte, periodo_apuracao, cod_situacao, valor_documento, valor_icms);
GO

-- Consultas por declarante e periodo de apuracao
CREATE NONCLUSTERED INDEX IX_efd_c100_contrib_periodo
    ON dbo.efd_c100 (id_contribuinte, periodo_apuracao, ind_oper, cod_situacao)
    INCLUDE (valor_documento, valor_icms);
GO

-- Analise por NCM e por CFOP no nivel do item
CREATE NONCLUSTERED INDEX IX_nfe_item_ncm  ON dbo.nfe_item (ncm)  INCLUDE (id_nfe, cfop, valor_total_item);
CREATE NONCLUSTERED INDEX IX_nfe_item_cfop ON dbo.nfe_item (cfop) INCLUDE (id_nfe, ncm,  valor_total_item);
GO

-- Emissao por contribuinte dentro de um periodo
CREATE NONCLUSTERED INDEX IX_nfe_emitente_data
    ON dbo.nfe (id_emitente, data_emissao)
    INCLUDE (situacao, tipo_operacao, valor_total, valor_icms);
GO

PRINT 'Script 08 concluido: indices de desempenho criados.';
PRINT 'Para desfazer: DROP INDEX IX_nfe_situacao_data ON dbo.nfe;  (e assim por diante)';
GO
