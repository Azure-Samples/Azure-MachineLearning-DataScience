USE [TaxiNYC_Sample]
GO

/****** Object:  StoredProcedure [dbo].[PlotHistogram]    Script Date: 10/29/2015 4:37:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PlotHistogram]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @query nvarchar(max) =
  N'SELECT tipped FROM nyctaxi_joined_1_percent'
  EXECUTE sp_execute_external_script @language = N'R',
                                     @script = N'
image_file = tempfile();
jpeg(filename = image_file);
#Plot histogram
rxHistogram(~tipped, data=InputDataSet, col=''lightgreen'', title = ''Tip Histogram'', xlab =''Tipped or not'', ylab =''Counts'');
dev.off();
OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6));
',
                                     @input_data_1 = @query
  WITH RESULT SETS ((plot varbinary(max)));
END
GO

