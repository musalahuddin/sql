/****** Object:  StoredProcedure [dbo].[sp_Load_Raw_SkuPrice] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Muhammad Salahuddin
-- Create date: 05-09-13
-- Description:	This procedure loads sku prices into Raw_SkuPrice
-- =============================================
CREATE PROCEDURE [dbo].[sp_Load_Raw_SkuPrice]
	@SystemId int
AS
BEGIN
	DECLARE @TempPriceTypeTable Table (ID int IDENTITY (1,1),PriceTypeId int,Processed int)
	DECLARE @TempPriceTypeCount int;
	DECLARE @TempPriceTypeId int;
	DECLARE @PriceTypeId int;
	DECLARE @Num int;
	DECLARE @PriceTypeStr varchar(4000);
	DECLARE @Query varchar(Max);
	DECLARE @ColumnStr varchar(MAX);
	
	SET @PriceTypeStr = '';
	SET @ColumnStr = '';
	SET @Num = 1;
	
	TRUNCATE TABLE Raw_SkuPrice
	
	INSERT INTO @TempPriceTypeTable(PriceTypeId)
	SELECT 
	DISTINCT PriceTypeId
	FROM TblSkuPriceSystem
	WHERE SystemId = @SystemId
	ORDER BY PriceTypeId
	
	--SELECT * FROM @TempPriceTypeTable
	
	SET @TempPriceTypeCount = (SELECT COUNT(*) FROM @TempPriceTypeTable WHERE Processed IS NULL)
	IF (@TempPriceTypeCount > 0)
	BEGIN
		While (SELECT COUNT(*) FROM @TempPriceTypeTable WHERE Processed IS NULL) > 0
		BEGIN -- BEGIN WHILE @TempPriceTypeTable
		
			SET @TempPriceTypeId = (SELECT TOP 1 ID FROM @TempPriceTypeTable WHERE Processed IS NULL)
			SET @PriceTypeId = (SELECT TOP 1 PriceTypeId FROM @TempPriceTypeTable WHERE Processed IS NULL)
			
			--SELECT @PriceTypeId
			SET @ColumnStr += ',SkuPrice'+ltrim(rtrim(cast(@Num as CHAR)));
			SET @PriceTypeStr += ',['+ltrim(rtrim(cast(@PriceTypeId as CHAR)))+']'
			UPDATE @TempPriceTypeTable SET Processed = 1 WHERE ID = @TempPriceTypeId
			SET @Num = @Num +1
		END -- END WHILE @TempPriceTypeTable
		
		SET @PriceTypeStr = SUBSTRING(@PriceTypeStr,2,LEN(@PriceTypeStr)-1);
		
		set @Query = '
		DECLARE @TempSkuPrice as TABLE (
		 SkuId int,
		 PriceTypeId int,
		 SkuPrice money
		);
		
		INSERT INTO @TempSkuPrice(skuid, PriceTypeId, SkuPrice)
		SELECT 
		[skuId]
		,[PriceTypeId]
		,[skuPrice]
	      
		FROM [TblSkuPriceSystem]
		WHERE SystemId = '+ltrim(rtrim(cast(@SystemId as CHAR)))+'
		ORDER BY SkuId,PriceTypeId;
	  
		INSERT INTO Raw_SkuPrice (SkuId'+@ColumnStr+')
		SELECT [Skuid],'+@PriceTypeStr+'
		from  @TempSkuPrice c
		pivot (
		 MIN(skuprice)
		 for PriceTypeId in ('+@PriceTypeStr+')
		) pvt ';
		
		--SELECT(@Query)
		EXECUTE(@Query)
	END

END



GO


