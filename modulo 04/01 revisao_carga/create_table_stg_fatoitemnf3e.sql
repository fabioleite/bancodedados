/*
    Script de criação da tabela de staging para o arquivo
    fatoitemnf3e_09095183000140_202401_20260721_220319.csv

    Curso de Integridade Fiscal — Banco de Dados `curso_integridade_fiscal`
    Complementa os módulos: BULK INSERT · ALTER TABLE · UPDATE e DELETE

    Origem: fato de itens de NF3e (Nota Fiscal de Energia Elétrica),
    200 colunas, delimitador '|', gerado a partir do cabeçalho real do
    arquivo (ver dados/fatoitemnf3e._resumo.csv).

    Por que todas as colunas são VARCHAR?
    Mesmo raciocínio já aplicado em stg_nfe_importacao no exercício
    integrador: este é um arquivo de origem externa, de grande volume
    (~3,9 GB, milhões de linhas), e não há garantia de que todo valor
    numérico/data esteja em formato válido em 100% das linhas. Carregar
    como texto primeiro evita que uma única linha malformada interrompa
    o BULK INSERT no meio da carga. A conversão para tipos definitivos
    (DECIMAL, DATETIME2, INT) deve ser feita depois, em colunas novas,
    validando com TRY_CONVERT — como já foi feito na Parte 2/3 do
    exercício integrador.

    Os tamanhos de VARCHAR foram atribuídos por convenção de nome de
    campo (padrão de tags do schema NF3e):
      - prefixo "v"   -> valor monetário      -> VARCHAR(30)
      - prefixo "p"   -> percentual           -> VARCHAR(20)
      - prefixo "q"   -> quantidade           -> VARCHAR(30)
      - prefixo "d"   -> data/data-hora       -> VARCHAR(30)
      - prefixo "n"   -> número/identificador -> VARCHAR(30)
      - prefixo "tp"  -> tipo/código curto    -> VARCHAR(10)
      - prefixo "ind" -> indicador (S/N/0/1)  -> VARCHAR(5)
      - prefixo "c"   -> código               -> VARCHAR(30)
      - prefixo "mot" -> motivo (texto curto) -> VARCHAR(100)
      - cst, cfop, umed -> códigos fiscais/unidade -> VARCHAR(5-20)
      - xprod, infadprod -> texto descritivo  -> VARCHAR(500)
      - chnf3e -> chave de acesso             -> VARCHAR(60)
    Ajuste os tamanhos após validar com dados reais, se necessário.
*/

CREATE TABLE stg_fatoitemnf3e (
    id_fatoitemnf3e                                            VARCHAR(20),
    infnf3e_sqn                                                VARCHAR(20),
    infprot_chnf3e                                             VARCHAR(60),
    infnf3e_nfdet_det_nitem                                    VARCHAR(30),
    infnf3e_nfdet_det_gajustenf3eant_tpajuste                  VARCHAR(10),
    infnf3e_nfdet_det_gajustenf3eant_motajuste                 VARCHAR(100),
    infnf3e_nfdet_det_detitemant_vitem                         VARCHAR(30),
    infnf3e_nfdet_det_detitemant_qfaturada                     VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vprod                         VARCHAR(30),
    infnf3e_nfdet_det_detitemant_cclass                        VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vbc                           VARCHAR(30),
    infnf3e_nfdet_det_detitemant_picms                         VARCHAR(20),
    infnf3e_nfdet_det_detitemant_vicms                         VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vfcp                          VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vbcst                         VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vicmsst                       VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vpis                          VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vpisefet                      VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vcofins                       VARCHAR(30),
    infnf3e_nfdet_det_detitemant_vcofinsefet                   VARCHAR(30),
    infnf3e_nfdet_det_detitemant_rettrib_vretpis               VARCHAR(30),
    infnf3e_nfdet_det_detitemant_rettrib_vretcofins            VARCHAR(30),
    infnf3e_nfdet_det_detitemant_rettrib_vretcsll              VARCHAR(30),
    infnf3e_nfdet_det_detitemant_rettrib_vbcirrf               VARCHAR(30),
    infnf3e_nfdet_det_detitemant_rettrib_virrf                 VARCHAR(30),
    infnf3e_nfdet_det_detitemant_rettrib_nitemant              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif1_dinitarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif1_dfimtarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif1_tpato                    VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif1_nato                     VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif1_anoato                   VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif1_tptarif                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif1_cpostarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif1_umed                     VARCHAR(20),
    infnf3e_nfdet_det_detitem_gtarif1_vtarifhom                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif1_vtarifaplic              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif2_dinitarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif2_dfimtarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif2_tpato                    VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif2_nato                     VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif2_anoato                   VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif2_tptarif                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif2_cpostarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif2_umed                     VARCHAR(20),
    infnf3e_nfdet_det_detitem_gtarif2_vtarifhom                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif2_vtarifaplic              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif3_dinitarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif3_dfimtarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif3_tpato                    VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif3_nato                     VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif3_anoato                   VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif3_tptarif                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif3_cpostarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif3_umed                     VARCHAR(20),
    infnf3e_nfdet_det_detitem_gtarif3_vtarifhom                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif3_vtarifaplic              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif4_dinitarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif4_dfimtarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif4_tpato                    VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif4_nato                     VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif4_anoato                   VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif4_tptarif                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif4_cpostarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif4_umed                     VARCHAR(20),
    infnf3e_nfdet_det_detitem_gtarif4_vtarifhom                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif4_vtarifaplic              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif5_dinitarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif5_dfimtarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif5_tpato                    VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif5_nato                     VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif5_anoato                   VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif5_tptarif                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif5_cpostarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif5_umed                     VARCHAR(20),
    infnf3e_nfdet_det_detitem_gtarif5_vtarifhom                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif5_vtarifaplic              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif6_dinitarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif6_dfimtarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif6_tpato                    VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif6_nato                     VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif6_anoato                   VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif6_tptarif                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gtarif6_cpostarif                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif6_umed                     VARCHAR(20),
    infnf3e_nfdet_det_detitem_gtarif6_vtarifhom                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gtarif6_vtarifaplic              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband1_diniadband              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband1_dfimadband              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband1_tpband                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gadband1_vadband                 VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband1_vadbandaplic            VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband1_motdifband              VARCHAR(100),
    infnf3e_nfdet_det_detitem_gadband2_diniadband              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband2_dfimadband              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband2_tpband                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gadband2_vadband                 VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband2_vadbandaplic            VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband2_motdifband              VARCHAR(100),
    infnf3e_nfdet_det_detitem_gadband3_diniadband              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband3_dfimadband              VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband3_tpband                  VARCHAR(10),
    infnf3e_nfdet_det_detitem_gadband3_vadband                 VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband3_vadbandaplic            VARCHAR(30),
    infnf3e_nfdet_det_detitem_gadband3_motdifband              VARCHAR(100),
    infnf3e_nfdet_det_detitem_prod_indorigemqtd                VARCHAR(5),
    infnf3e_nfdet_det_detitem_prod_gmedicao_nmed               VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_ncontrat           VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_tpgrmed    VARCHAR(10),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_cpostarif  VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_umed       VARCHAR(20),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_vmedant    VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_vmedatu    VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_vconst     VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_vmed       VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_pperdatran VARCHAR(20),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_vperdatran VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_gmedida_vperdatec  VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_gmedicao_tpmotnaoleitura    VARCHAR(10),
    infnf3e_nfdet_det_detitem_prod_cprod                       VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_xprod                       VARCHAR(500),
    infnf3e_nfdet_det_detitem_prod_cclass                      VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_cfop                        VARCHAR(10),
    infnf3e_nfdet_det_detitem_prod_umed                        VARCHAR(20),
    infnf3e_nfdet_det_detitem_prod_qfaturada                   VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_vitem                       VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_vprod                       VARCHAR(30),
    infnf3e_nfdet_det_detitem_prod_inddevolucao                VARCHAR(5),
    infnf3e_nfdet_det_detitem_prod_indprecoacl                 VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_icms00_cst               VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_icms00_vbc               VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms00_picms             VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_icms00_vicms             VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms00_pfcp              VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_icms00_vfcp              VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms10_cst               VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_icms10_vbcst             VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms10_picmsst           VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_icms10_vicmsst           VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms10_pfcpst            VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_icms10_vfcpst            VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms20_cst               VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_icms20_predbc            VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_icms20_vbc               VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms20_picms             VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_icms20_vicms             VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms20_vicmsdeson        VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms20_cbenef            VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms20_pfcp              VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_icms20_vfcp              VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms40_cst               VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_icms40_vicmsdeson        VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms40_cbenef            VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms51_cst               VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_icms51_vicmsdeson        VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms51_cbenef            VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms90_cst               VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_icms90_vbc               VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_icms90_picms             VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_icms90_vicms             VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_pis_cst                  VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_pis_vbc                  VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_pis_ppis                 VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_pis_vpis                 VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_pisefet_vbcpisefet       VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_pisefet_ppisefet         VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_pisefet_vpisefet         VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_cofins_cst               VARCHAR(5),
    infnf3e_nfdet_det_detitem_imposto_cofins_vbc               VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_cofins_pcofins           VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_cofins_vcofins           VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_cofinsefet_vbccofinsefet VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_cofinsefet_pcofinsefet   VARCHAR(20),
    infnf3e_nfdet_det_detitem_imposto_cofinsefet_vcofinsefet   VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_rettrib_vretpis          VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_rettrib_vretcofins       VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_rettrib_vretcsll         VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_rettrib_vbcirrf          VARCHAR(30),
    infnf3e_nfdet_det_detitem_imposto_rettrib_virrf            VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_vitem                   VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_qfaturada               VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_vprod                   VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_inddevolucao            VARCHAR(5),
    infnf3e_nfdet_det_detitem_gprocref_vbc                     VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_picms                   VARCHAR(20),
    infnf3e_nfdet_det_detitem_gprocref_vicms                   VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_pfcp                    VARCHAR(20),
    infnf3e_nfdet_det_detitem_gprocref_vfcp                    VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_vbcst                   VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_picmsst                 VARCHAR(20),
    infnf3e_nfdet_det_detitem_gprocref_vicmsst                 VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_pfcpst                  VARCHAR(20),
    infnf3e_nfdet_det_detitem_gprocref_vfcpst                  VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_vpis                    VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_vpisefet                VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_vcofins                 VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_vcofinsefet             VARCHAR(30),
    infnf3e_nfdet_det_detitem_gprocref_gproc_tpproc            VARCHAR(10),
    infnf3e_nfdet_det_detitem_gprocref_gproc_nprocesso         VARCHAR(30),
    infnf3e_nfdet_det_detitem_infadprod                        VARCHAR(500),
    infnf3e_nfdet_det_detitem_nitemant                         VARCHAR(30)
);
GO

/*
    Carga do arquivo real na tabela de staging.
    Ajuste o caminho do FROM se o arquivo não estiver acessível
    pela instância do SQL Server no caminho local do usuário.
*/
BULK INSERT stg_fatoitemnf3e
FROM 'C:\dados\fatoitemnf3e._resumo.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO


-- Conferência pós-carga
--
--select id_fatonfatoitemnf3e AS sq_nf3e_item
SELECT COUNT(*) AS total_linhas
FROM stg_fatoitemnf3e;

select * from stg_fatoitemnf3e
where infnf3e_nfdet_det_detitem_prod_cprod = '00000000000000000000'
