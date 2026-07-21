USE [933000081200000173202662_20260127_104141]
GO

/****** Objeto:  Table [dbo].[NFE]    Data do Script: 20/07/2026 22:15:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[NFE](
	[sqnfe] [bigint] NOT NULL,
	[tpnfe] [int] NOT NULL,
	[cddigestvalue] [nvarchar](50) NULL,
	[cdfinalidade] [int] NULL,
	[cdmodfrete] [int] NULL,
	[cddv] [int] NULL,
	[cdnf] [int] NULL,
	[cdqrcode] [varchar](600) NULL,
	[cduf] [int] NULL,
	[cdprocemi] [int] NULL,
	[cdmunfg] [int] NULL,
	[cdmunicrettansp] [int] NULL,
	[cdverproc] [varchar](30) NULL,
	[dhinclusao] [datetime] NULL,
	[dhrecebimento] [datetime] NULL,
	[dhemissao] [datetime] NULL,
	[dhoperacao] [datetime] NULL,
	[dhcont] [datetime] NULL,
	[dsinfocompl] [text] NULL,
	[dsinfoadcfisc] [text] NULL,
	[dsjust] [varchar](300) NULL,
	[idfinal] [int] NULL,
	[idpres] [int] NULL,
	[idpag] [int] NULL,
	[iddest] [int] NULL,
	[nolocalembarq] [nvarchar](60) NULL,
	[nolocalexp] [varchar](60) NULL,
	[nolocaldespacho] [varchar](60) NULL,
	[nonatoperacao] [nvarchar](255) NULL,
	[nourlchave] [varchar](100) NULL,
	[nrchaveacesso] [nvarchar](50) NULL,
	[nrcfoptransp] [int] NULL,
	[nrnfeletronica] [int] NULL,
	[nrserienfe] [nvarchar](20) NULL,
	[nrversao] [varchar](10) NULL,
	[nrcontratocompra] [varchar](60) NULL,
	[nrnotaempenho] [varchar](22) NULL,
	[nrpedidocompra] [varchar](60) NULL,
	[sguflocalembarq] [nchar](2) NULL,
	[sgufsaidapais] [char](2) NULL,
	[stnfe] [nchar](1) NULL,
	[tpimp] [int] NULL,
	[tpamb] [int] NULL,
	[tpformaemissao] [int] NULL,
	[tpoperacao] [int] NULL,
	[vlaliqrettransp] [decimal](11, 4) NULL,
	[vlbasecalculo] [decimal](16, 2) NULL,
	[vlbasecalcicmsst] [decimal](16, 2) NULL,
	[vlbcrettransp] [decimal](16, 2) NULL,
	[vlcofins] [decimal](16, 2) NULL,
	[vldespaces] [decimal](16, 2) NULL,
	[vldesconto] [decimal](16, 2) NULL,
	[vlicms] [decimal](16, 2) NULL,
	[vlicmsrettransp] [decimal](16, 2) NULL,
	[vlfrete] [decimal](16, 2) NULL,
	[vlicmsdeson] [decimal](16, 2) NULL,
	[vlicmsst] [decimal](16, 2) NULL,
	[vlicmsufremst] [decimal](16, 2) NULL,
	[vlicmsufdestst] [decimal](16, 2) NULL,
	[vlicmsfcpufdestst] [decimal](16, 2) NULL,
	[vlii] [decimal](16, 2) NULL,
	[vlipi] [decimal](16, 2) NULL,
	[vlpis] [decimal](16, 2) NULL,
	[vlretservtransp] [decimal](16, 2) NULL,
	[vltotalnota] [decimal](16, 2) NULL,
	[vltotalprodserv] [decimal](16, 2) NULL,
	[vltotalseguro] [decimal](16, 2) NULL,
	[vltotaltributo] [decimal](16, 2) NULL,
	[cdmodelo] [int] NULL,
 CONSTRAINT [PK_NFE] PRIMARY KEY CLUSTERED 
(
	[sqnfe] ASC,
	[tpnfe] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[NFE] ADD  DEFAULT (getdate()) FOR [dhinclusao]
GO

ALTER TABLE [dbo].[NFE]  WITH CHECK ADD CHECK  (([stnfe]='U' OR [stnfe]='O' OR [stnfe]='I' OR [stnfe]='D' OR [stnfe]='C' OR [stnfe]='A'))
GO

ALTER TABLE [dbo].[NFE]  WITH CHECK ADD CHECK  (([tpformaemissao]=(9) OR [tpformaemissao]=(8) OR [tpformaemissao]=(7) OR [tpformaemissao]=(6) OR [tpformaemissao]=(5) OR [tpformaemissao]=(4) OR [tpformaemissao]=(3) OR [tpformaemissao]=(2) OR [tpformaemissao]=(1)))
GO

ALTER TABLE [dbo].[NFE]  WITH CHECK ADD CHECK  (([tpnfe]=(3) OR [tpnfe]=(2) OR [tpnfe]=(1)))
GO

ALTER TABLE [dbo].[NFE]  WITH CHECK ADD CHECK  (([tpoperacao]=(1) OR [tpoperacao]=(0)))
GO


