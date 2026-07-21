USE [933000081200000173202662_20260127_104141]
GO

/****** Objeto:  Table [dbo].[EFD_C170]    Data do Script: 20/07/2026 22:09:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EFD_C170](
	[sqitemnfoutra] [bigint] NOT NULL,
	[sqcfop] [int] NULL,
	[sqidentitem] [bigint] NULL,
	[sqnfoutra] [bigint] NOT NULL,
	[squnidmedida] [int] NULL,
	[sqnatoperacao] [int] NULL,
	[cdcontaanalitica] [nvarchar](10) NULL,
	[cdcsticms] [int] NULL,
	[cdcstcofins] [int] NULL,
	[cdcstipi] [nchar](2) NULL,
	[cdcstpis] [int] NULL,
	[cdenquadramento] [nvarchar](3) NULL,
	[dscomplitemdocfisc] [nvarchar](255) NULL,
	[idapuracaoipi] [nchar](1) NULL,
	[idmovimento] [nchar](1) NULL,
	[nritemdocfisc] [int] NULL,
	[nrpercaliqcofins] [decimal](12, 4) NULL,
	[nrpercaliqpis] [decimal](12, 4) NULL,
	[qtbasecalccofins] [decimal](16, 3) NULL,
	[qtbasecalcpis] [decimal](16, 3) NULL,
	[qtitemdocfisc] [decimal](24, 5) NULL,
	[vlabatnt] [decimal](16, 2) NULL,
	[vlaliquotaicms] [decimal](6, 2) NULL,
	[vlaliquotast] [decimal](6, 2) NULL,
	[vlaliquotacofins] [decimal](16, 4) NULL,
	[vlaliquotaipi] [decimal](16, 2) NULL,
	[vlaliquotapis] [decimal](16, 4) NULL,
	[vlbasecalccofins] [decimal](16, 2) NULL,
	[vlbasecalcipi] [decimal](16, 2) NULL,
	[vlbasecalcpis] [decimal](16, 2) NULL,
	[vlbasecalcicms] [decimal](16, 2) NULL,
	[vlbasecalcicmsst] [decimal](16, 2) NULL,
	[vlcofins] [decimal](16, 2) NULL,
	[vldesconto] [decimal](16, 2) NULL,
	[vlicms] [decimal](16, 2) NULL,
	[vlicmsst] [decimal](16, 2) NULL,
	[vlipi] [decimal](16, 2) NULL,
	[vlitemdocfisc] [decimal](16, 2) NULL,
	[vlpis] [decimal](16, 2) NULL,
	[tsatualizacao] [datetime] NULL,
 CONSTRAINT [PK_EFD_C170] PRIMARY KEY NONCLUSTERED 
(
	[sqitemnfoutra] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[EFD_C170]  WITH NOCHECK ADD  CONSTRAINT [FK_EFD_C170_IDENTITEM] FOREIGN KEY([sqidentitem])
REFERENCES [dbo].[EFD_0200] ([sqidentitem])
GO

ALTER TABLE [dbo].[EFD_C170] CHECK CONSTRAINT [FK_EFD_C170_IDENTITEM]
GO

ALTER TABLE [dbo].[EFD_C170]  WITH NOCHECK ADD  CONSTRAINT [FK_EFD_C170_NATOP] FOREIGN KEY([sqnatoperacao])
REFERENCES [dbo].[EFD_0400] ([sqnatoperacao])
GO

ALTER TABLE [dbo].[EFD_C170] CHECK CONSTRAINT [FK_EFD_C170_NATOP]
GO

ALTER TABLE [dbo].[EFD_C170]  WITH NOCHECK ADD  CONSTRAINT [FK_EFD_C170_OUTRA] FOREIGN KEY([sqnfoutra])
REFERENCES [dbo].[EFD_C100] ([sqnfoutra])
GO

ALTER TABLE [dbo].[EFD_C170] CHECK CONSTRAINT [FK_EFD_C170_OUTRA]
GO

ALTER TABLE [dbo].[EFD_C170]  WITH NOCHECK ADD  CONSTRAINT [FK_EFD_C170_UNIDMEDIDA] FOREIGN KEY([squnidmedida])
REFERENCES [dbo].[EFD_0190] ([squnidmedida])
GO

ALTER TABLE [dbo].[EFD_C170] CHECK CONSTRAINT [FK_EFD_C170_UNIDMEDIDA]
GO


