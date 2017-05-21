
/****** Object:  StoredProcedure [dbo].[sp_Load_FullSku] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Muhammad Salahuddin
-- Create date: 05-09-13
-- Description:	This procedure makes all the possible color combinations and populate TblFullSku with the results 
-- =============================================
CREATE PROCEDURE [dbo].[sp_Load_FullSku]
	@SystemId int
AS
BEGIN

	CREATE TABLE #TempSkuFull(
	[SystemId] [int] NULL,
	[SkuId] [int] NULL,
	[FullCode] [varchar](500) NULL,
	[FullSku1] [varchar](500) NULL,
	[FullSku2] [varchar](500) NULL,
	[FullPrice1] [money] NULL,
	[FullPrice2] [money] NULL,
	[FullPrice3] [money] NULL,
	[FullPrice4] [money] NULL,
	[FullPrice5] [money] NULL,
	[FullPrice6] [money] NULL,
	[FullPrice7] [money] NULL,
	[FinishCode1] [varchar](500) NULL,
	[FinishCode2] [varchar](500) NULL,
	[FinishCode3] [varchar](500) NULL,
	[FinishCode4] [varchar](500) NULL,
	[FinishCode5] [varchar](500) NULL,
	[FinishCode6] [varchar](500) NULL,
	[FinishCode7] [varchar](500) NULL,
	[FinishCode8] [varchar](500) NULL,
	[FinishCode9] [varchar](500) NULL,
	[FinishCode10] [varchar](500) NULL
	)

	DECLARE @TempSkuSystemTable Table (ID int IDENTITY (1,1), SkuId int,SystemId int, Processed int)
	DECLARE @TempSkuOptTable Table (ID int IDENTITY (1,1), SkuId int,Opt1Id int,Opt1Position int,Total int,Processed int)

	DECLARE @Query varchar(max)
	DECLARE @MainQuery varchar(max)
	DECLARE @TempSkuSystemCount int
	DECLARE @TempSkuOptCount int
	DECLARE @Num int
	DECLARE @InnerJoin varchar(MAX)
	DECLARE @ReplaceStr varchar(MAX)
	DECLARE @ColumnStr varchar(MAX)
	DECLARE @InsertColumnStr varchar(MAX)


	DECLARE @TempSkuSystemId int
	DECLARE @SkuId int


	DECLARE @TempSkuOptId int	
	DECLARE @Opt1Id int 
	DECLARE @Opt1Position int
	
	TRUNCATE TABLE TblFullSku
	
	EXEC dbo.sp_Load_Raw_SkuPrice @SystemId

	SET @Num = 1
	SET @Query = ''
	SET @MainQuery = ''
	SET @InnerJoin = ''
	SET @ReplaceStr = ''
	SET @ColumnStr = ''
	SET @InsertColumnStr = ''
	
	INSERT INTO @TempSkuSystemTable (SkuId,SystemId)
	SELECT SkuId,SystemId FROM TblSpecifySku 
	WHERE SystemId = @SystemId AND SkuId IS NOT NULL
	GROUP BY SkuId,SystemId
	
	--SELECT * FROM @TempSkuSystemTable
	
	
	SET @TempSkuSystemCount = (SELECT COUNT(*) FROM @TempSkuSystemTable WHERE Processed IS NULL)


	IF (@TempSkuSystemCount > 0)
	BEGIN
		WHILE (SELECT COUNT(*) FROM @TempSkuSystemTable WHERE Processed IS NULL) > 0
		BEGIN -- BEGIN WHILE @TempSkuSystemTable
			
			-- set variables on each iteration through @TempSkuSystemTable
			SET @TempSkuSystemId = (SELECT TOP 1 ID FROM @TempSkuSystemTable WHERE Processed IS NULL)
			SET @SkuId = (SELECT TOP 1 SkuId FROM @TempSkuSystemTable WHERE Processed IS NULL)
			SET @Query = ''
			SET @InnerJoin = ''
			SET @ReplaceStr = ''
			SET @ColumnStr = ''
			SET @InsertColumnStr = ''
			SET @Num = 1
			
			-- delete records from @TempSkuOptTable
			DELETE FROM @TempSkuOptTable
			
			-- insert new records into @TempSkuOptTable
			INSERT INTO @TempSkuOptTable (SkuId,Opt1Id,Opt1Position,Total)
			SELECT SkuId, MIN(opt1Id),Opt1Position, COUNT(*) AS total
			FROM [TblSpecifySku]
			WHERE SkuId = @SkuId
			AND SystemId = @SystemId -- added this on 07-26-13
			GROUP BY SkuId,Opt1Position
			ORDER BY SkuId,Opt1Position
			
			--SELECT * FROM @TempSkuOptTable
			
			SET @TempSkuOptCount = (SELECT COUNT(*) FROM @TempSkuOptTable WHERE Processed IS NULL)
			If (@TempSkuOptCount > 0)
			BEGIN
				While (SELECT COUNT(*) FROM @TempSkuOptTable WHERE Processed IS NULL) > 0
				BEGIN -- BEGIN WHILE @TempSkuOptTable
				
					-- set variables on each iteration through @TempSkuOptTable
					SET @TempSkuOptId = (SELECT TOP 1 ID FROM @TempSkuOptTable WHERE Processed IS NULL)
					SET @Opt1Id = (SELECT TOP 1 Opt1Id FROM @TempSkuOptTable WHERE Processed IS NULL)
					SET @InsertColumnStr +=',FinishCode'+ltrim(rtrim(cast(@Num as CHAR)));
					SET @ColumnStr +=',Table'+ltrim(rtrim(cast(@Num as CHAR)))+'.FinishCode'+ltrim(rtrim(cast(@Num as CHAR)))+' AS FinishCode'+ltrim(rtrim(cast(@Num as CHAR))); 
					SET @ReplaceStr += '+Table'+ltrim(rtrim(cast(@Num as CHAR)))+'.FinishCode'+ltrim(rtrim(cast(@Num as CHAR)))
					if(@Num <> 1)
					BEGIN
						SET @InnerJoin +=' INNER JOIN Table'+ltrim(rtrim(cast(@Num as CHAR)))+' ON Table'+ltrim(rtrim(cast(@Num as CHAR)))+'.SkuId = Table1.SkuId'
					END
					SET @Query +=',Table'+ltrim(rtrim(cast(@Num as CHAR)))+' (FinishCode'+ltrim(rtrim(cast(@Num as CHAR)))+',SkuId,Opt1Id,Opt1Position,FullSku1,FullSku2,Price1,Price2,Price3,Price4,Price5,Price6,Price7)'
					+' AS'
					+' (SELECT FinishCode as FinishCode'+ltrim(rtrim(cast(@Num as CHAR)))+',SkuId,Opt1Id,Opt1Position,FullSku1,FullSku2,Price1,Price2,Price3,Price4,Price5,Price6,Price7'
					+' FROM [ColorSkuView]'
					+' WHERE SkuId = '''+ltrim(rtrim(cast(@SkuId as CHAR)))+''' AND SystemId = '''+ltrim(rtrim(cast(@SystemId as CHAR)))+''' AND Opt1Id = '''+ltrim(rtrim(cast(@Opt1Id as CHAR)))+''')'
				
					UPDATE @TempSkuOptTable SET Processed = 1 WHERE ID = @TempSkuOptId
					SET @Num = @Num +1 
				END-- END WHILE @TempSkuOptTable
				
				SET @ReplaceStr = SUBSTRING(@ReplaceStr,2,LEN(@ReplaceStr)-1)
				SET @Query = SUBSTRING(@Query,2,LEN(@Query)-1)
				
				SET @MainQuery +=' WITH '+ @Query
				+' INSERT INTO #TempSkuFull (SystemId,SkuId,FullCode,FullSku1,FullSku2,FullPrice1,FullPrice2,FullPrice3,FullPrice4,FullPrice5,FullPrice6,FullPrice7'+@InsertColumnStr+')'
				/*+' SELECT DISTINCT'*/
				+' SELECT'
				+' '+ltrim(rtrim(cast(@SystemId as CHAR)))
				+',Table1.SkuId AS SkuId'
				+','+@ReplaceStr
				+',Table1.FullSku1 AS FullSku1'
				+',Table1.FullSku2 AS FullSku2'
				+',Table1.Price1 AS FullPrice1'
				+',Table1.Price2 AS FullPrice2'
				+',Table1.Price3 AS FullPrice3'
				+',Table1.Price4 AS FullPrice4'
				+',Table1.Price5 AS FullPrice5'
				+',Table1.Price6 AS FullPrice6'
				+',Table1.Price7 AS FullPrice7'
				+@ColumnStr
				+' FROM Table1'
				+@InnerJoin
				+';';
				/*+' INNER JOIN TblCategorySku ON TblCategorySku.SkuId = TblSkuMain.SkuId AND TblCategorySku.SystemId = '+ltrim(rtrim(cast(@SystemId as CHAR)))*/
				/*+' LEFT JOIN Raw_SkuPrice ON Raw_SkuPrice.SkuId = TblSkuMain.SkuId'*/
				/*+' WHERE (TblCategorySku.ValidStartDate <= GETDATE()) AND (TblCategorySku.ValidEndDate >= GETDATE() OR dbo.TblCategorySku.ValidEndDate IS NULL)'*/
				/*+' ORDER BY FullSkuCombo DESC;';*/
			END
			
			
			UPDATE @TempSkuSystemTable SET Processed = 1 WHERE ID = @TempSkuSystemId
		END -- END WHILE @TempSkuSystemTable
		
		--SELECT (@MainQuery)
		EXECUTE(@MainQuery);
		--select * from #TempSkuFull;
		
		WITH
		CategorySkuTable (SkuId,SkuAV,SkuSpec,Weight,SkuPrice1,SkuPrice2,SkuPrice3,SkuPrice4,SkuPrice5,SkuPrice6,SkuPrice7)
		AS(
			SELECT 
			TblSkuMain.SkuId,
			TblSkuMain.SkuAV,
			TblSkuMain.SkuSpec,
			TblSkuMain.Weight,
			Raw_SkuPrice.SkuPrice1,
			Raw_SkuPrice.SkuPrice2,
			Raw_SkuPrice.SkuPrice3,
			Raw_SkuPrice.SkuPrice4,
			Raw_SkuPrice.SkuPrice5,
			Raw_SkuPrice.SkuPrice6,
			Raw_SkuPrice.SkuPrice7
			FROM TblCategorySku
			INNER JOIN TblSkuMain ON TblCategorySku.SkuId = TblSkuMain.SkuId
			LEFT JOIN [Raw_SkuPrice] ON Raw_SkuPrice.SkuId = TblCategorySku.SkuId
			WHERE SystemId = @SystemId
			AND (TblCategorySku.ValidStartDate <= GETDATE()) AND (TblCategorySku.ValidEndDate >= GETDATE() OR dbo.TblCategorySku.ValidEndDate IS NULL)
		)
		
		INSERT INTO TblFullSku (SystemId,SkuId,SkuAV,SkuSpec,Weight,SkuPrice1,SkuPrice2,SkuPrice3,SkuPrice4,SkuPrice5,SkuPrice6,SkuPrice7,FullSkuCombo,FullSku1,FullSku2,FullPrice1,FullPrice2,FullPrice3,FullPrice4,FullPrice5,FullPrice6,FullPrice7,FinishCode1,FinishCode2,FinishCode3,FinishCode4,FinishCode5,FinishCode6,FinishCode7,FinishCode8,FinishCode9,FinishCode10)
		SELECT
		@SystemId,
		CategorySkuTable.SkuId,
		CategorySkuTable.SkuAV,
		CategorySkuTable.SkuSpec,
		CategorySkuTable.Weight,
		CategorySkuTable.SkuPrice1,
		CategorySkuTable.SkuPrice2,
		CategorySkuTable.SkuPrice3,
		CategorySkuTable.SkuPrice4,
		CategorySkuTable.SkuPrice5,
		CategorySkuTable.SkuPrice6,
		CategorySkuTable.SkuPrice7,
		CASE CHARINDEX('^',CategorySkuTable.SkuAV) WHEN 0 THEN '' ELSE Replace(CategorySkuTable.SkuAV,'^',#TempSkuFull.FullCode) END AS FullSkuCombo,
		#TempSkuFull.FullSku1,
		#TempSkuFull.FullSku2,
		#TempSkuFull.FullPrice1,
		#TempSkuFull.FullPrice2,
		#TempSkuFull.FullPrice3,
		#TempSkuFull.FullPrice4,
		#TempSkuFull.FullPrice5,
		#TempSkuFull.FullPrice6,
		#TempSkuFull.FullPrice7,
		#TempSkuFull.FinishCode1,
		#TempSkuFull.FinishCode2,
		#TempSkuFull.FinishCode3,
		#TempSkuFull.FinishCode4,
		#TempSkuFull.FinishCode5,
		#TempSkuFull.FinishCode6,
		#TempSkuFull.FinishCode7,
		#TempSkuFull.FinishCode8,
		#TempSkuFull.FinishCode9,
		#TempSkuFull.FinishCode10
		FROM CategorySkuTable
		LEFT JOIN #TempSkuFull 
		ON #TempSkuFull.SkuId = CategorySkuTable.SkuId
		ORDER BY SkuAV
		
	END

END


GO