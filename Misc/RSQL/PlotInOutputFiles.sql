USE [TaxiNYC_Sample]
GO

/****** Object:  StoredProcedure [dbo].[PlotInOutputFiles]    Script Date: 10/30/2015 6:17:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'PlotInOutputFiles')
  DROP PROCEDURE PlotInOutputFiles
GO


CREATE PROCEDURE [dbo].[PlotInOutputFiles]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @query nvarchar(max) =
  N'SELECT tipped, tip_amount, fare_amount FROM [TaxiNYC_Sample].[dbo].[nyctaxi_joined_1_percent]'
  EXECUTE sp_execute_external_script @language = N'R',
                                     @script = N'

# Set output directory for files
# Prior to plotting ensure there are no files with same file names as the out files below in the above directory.
setwd(''C:\\temp\\Plots\\'');

# Open a jpeg file and output histogram of tipped variable in that file.
jpeg(filename=''rHistogram_Tipped.jpg'');
hist(InputDataSet$tipped, col = ''lightgreen'', xlab=''Tipped'', ylab = ''Counts'', main = ''Histogram, Tipped'');
dev.off();

# Open a pdf file and output histograms of tip amount and fare amount. 
# Outputs two plots in one row
pdf(file=''rHistograms_Tip_and_Fare_Amount.pdf'', height=4, width=7);
par(mfrow=c(1,2));
hist(InputDataSet$tip_amount, col = ''lightgreen'', xlab=''Tip amount ($)'', ylab = ''Counts'', main = ''Histogram, Tip amount'', xlim = c(0,40), 100);
hist(InputDataSet$fare_amount, col = ''lightgreen'', xlab=''Fare amount ($)'', ylab = ''Counts'', main = ''Histogram, Fare amount'', xlim = c(0,100), 100);
dev.off();

# Open a pdf file and output an xyplot of tip amount vs. fare amount. This uses the lattice package in Rlibrary(lattice);
# Only 10,000 sampled observations are plotted here, otherwise file is large.
pdf(file=''rXYPlots_Tip_vs_Fare_Amount.pdf'', height=4, width=4);
plot(tip_amount ~ fare_amount, data = InputDataSet[sample(nrow(InputDataSet), 10000), ], ylim = c(0,50), xlim = c(0,150), cex=.5, pch=19, col=''darkgreen'',  main = ''Tip amount by Fare amount'', xlab=''Fare Amount ($)'', ylab = ''Tip Amount ($)''); 
dev.off();
',
                                     @input_data_1 = @query
END

GO


