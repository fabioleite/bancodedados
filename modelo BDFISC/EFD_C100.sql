USE [933000081200000173202662_20260127_104141]
GO

/****** Objeto:  Table [dbo].[EFD_C100]    Data do Script: 20/07/2026 22:05:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EFD_C100](
	[sqnfoutra] [bigint] NOT NULL,
	[sqcontrib] [int] NULL,
	[sqparticip] [int] NULL,
	[cdmoddocfisc] [nchar](2) NULL,
	[cdsitdocfisc] [int] NULL,
	[dtemissao] [date] NULL,
	[dtoperacao] [date] NULL,
	[idemitente] [int] NULL,
	[idoperacao] [int] NULL,
	[idfrete] [nchar](1) NULL,
	[idpagamento] [nchar](1) NULL,
	[nrchavenfe] [nvarchar](44) NULL,
	[nrseriedocfisc] [nvarchar](4) NULL,
	[nrdocfiscal] [int] NULL,
	[vlabatimentont] [decimal](16, 2) NULL,
	[vlbasecalcicms] [decimal](16, 2) NULL,
	[vlbasecalcicmsst] [decimal](16, 2) NULL,
	[vlcofins] [decimal](16, 2) NULL,
	[vlcofinsst] [decimal](16, 2) NULL,
	[vlfrete] [decimal](16, 2) NULL,
	[vlicms] [decimal](16, 2) NULL,
	[vlicmsst] [decimal](16, 2) NULL,
	[vlipi] [decimal](16, 2) NULL,
	[vlmercadoria] [decimal](16, 2) NULL,
	[vloutrasdesp] [decimal](16, 2) NULL,
	[vlpis] [decimal](16, 2) NULL,
	[vlpisst] [decimal](16, 2) NULL,
	[vlseguro] [decimal](16, 2) NULL,
	[vltotaldesc] [decimal](16, 2) NULL,
	[vltotalnf] [decimal](16, 2) NULL,
	[tsatualizacao] [datetime] NULL,
 CONSTRAINT [PK_EFD_C100] PRIMARY KEY NONCLUSTERED 
(
	[sqnfoutra] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[EFD_C100]  WITH NOCHECK ADD  CONSTRAINT [FK_EFD_C100_CONTRIB] FOREIGN KEY([sqcontrib])
REFERENCES [dbo].[EFD_0000] ([sqcontrib])
GO

ALTER TABLE [dbo].[EFD_C100] CHECK CONSTRAINT [FK_EFD_C100_CONTRIB]
GO

ALTER TABLE [dbo].[EFD_C100]  WITH NOCHECK ADD  CONSTRAINT [FK_EFD_C100_PARTICIP] FOREIGN KEY([sqparticip])
REFERENCES [dbo].[EFD_0150] ([sqparticip])
GO

ALTER TABLE [dbo].[EFD_C100] CHECK CONSTRAINT [FK_EFD_C100_PARTICIP]
GO

ALTER TABLE [dbo].[EFD_C100]  WITH NOCHECK ADD CHECK  (([idpagamento]=(9) OR [idpagamento]=(2) OR [idpagamento]=(1) OR [idpagamento]=(0)))
GO


