USE [TaxiNYC_Sample]
GO
/****** Object:  StoredProcedure [dbo].[PersistModel]    Script Date: 11/05/2015 23:04:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'PersistModel')
  DROP PROCEDURE PersistModel
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: Store model in database. Input is a binary representation of R Model object passed as Hex string
-- =============================================
CREATE PROCEDURE [dbo].[PersistModel]
@m nvarchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	insert into nyc_taxi_models (model) values (convert(varbinary(max),@m,2))
END
GO
