USE [933000081200000173202662_20260127_104141]
GO

/****** Objeto:  Table [dbo].[EFD_0000]    Data do Script: 20/07/2026 21:58:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EFD_0000](
	[sqcontrib] [int] NOT NULL,
	[sqmunicipio] [int] NULL,
	[cdfinalidade] [int] NULL,
	[cdversao] [int] NULL,
	[dsobservacao] [nvarchar](255) NULL,
	[dtinicial] [date] NULL,
	[dtfinal] [date] NULL,
	[idativo] [nchar](1) NULL,
	[idatividade] [int] NULL,
	[idindiceipm] [nchar](1) NULL,
	[idperfil] [nchar](1) NULL,
	[nocontribuinte] [nvarchar](150) NULL,
	[nrcnpj] [nvarchar](14) NULL,
	[nrcpf] [nvarchar](12) NULL,
	[nrinscrestadual] [nvarchar](14) NULL,
	[nrinscrsuframa] [nvarchar](10) NULL,
	[nrinscrmunicipal] [nvarchar](20) NULL,
	[sguf] [nchar](2) NULL,
	[stregistro] [int] NULL,
	[tsatualizacao] [datetime] NULL,
 CONSTRAINT [PK_EFD_0000] PRIMARY KEY NONCLUSTERED 
(
	[sqcontrib] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[EFD_0000] ADD  DEFAULT ('S') FOR [idativo]
GO

ALTER TABLE [dbo].[EFD_0000] ADD  DEFAULT ((1)) FOR [stregistro]
GO

ALTER TABLE [dbo].[EFD_0000]  WITH NOCHECK ADD  CONSTRAINT [FK_EFD_0000_MUNICIPIO] FOREIGN KEY([sqmunicipio])
REFERENCES [dbo].[EFD_CAD_UNIDADEGEOG] ([squnidadegeog])
GO

ALTER TABLE [dbo].[EFD_0000] CHECK CONSTRAINT [FK_EFD_0000_MUNICIPIO]
GO

ALTER TABLE [dbo].[EFD_0000]  WITH NOCHECK ADD CHECK  (([idativo]='S' OR [idativo]='N' OR [idativo]='I' OR [idativo]='F' OR [idativo]='C' OR [idativo]='A'))
GO

ALTER TABLE [dbo].[EFD_0000]  WITH NOCHECK ADD CHECK  (([idindiceipm]='S' OR [idindiceipm]='N'))
GO

ALTER TABLE [dbo].[EFD_0000]  WITH NOCHECK ADD CHECK  (([stregistro]=(1) OR [stregistro]=(0)))
GO


