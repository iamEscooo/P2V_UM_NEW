-- SET this value to 0 if want to apply the normal code rule
-- Set this value to 1 to add prefix at the end of the alias without add the type and unit name.
DECLARE @IsRunningAddPrefix bit = 1, 
-- update this to be 0 to fix the variable
@IsReportOnly bit = 1;
If (@IsReportOnly = 1)
Begin
SELECT  V.VariableName, v.VariableId, V.Alias,  v.IsODataVisible, v.DataType, v.UnitId, v.CustomUnit,r.RegimeName
from CASHDFX.Variable v inner join CASHDFX.RegimeVariable rv on v.VariableId = rv.VariableId
inner join CASHDFX.Regime r on rv.RegimeId = r.RegimeId
WHERE [Alias] IN (SELECT [Alias]
                       FROM (SELECT [Alias], COUNT(*) [Totalcount]
                             FROM CASHDFX.Variable
							 -- enable the following filter if just check the Odata variable alias only
							 Where IsODataVisible = 1
                             GROUP BY [Alias]) [a]
							 WHERE [Totalcount] > 1 and Alias is not null)
Order by VariableName, VariableId
End 
Else
Begin
--------------------------------------------
DECLARE @DataTypeList TABLE
(
                            [TypeName] NVARCHAR(50), 
                            [TypeId]   [INT]
)
DECLARE @UnitList TABLE
(
                        [UnitName] NVARCHAR(50), 
                        [UnitId]   [INT]
)

INSERT INTO @DataTypeList([TypeName], [TypeId])
VALUES('ScalarNumeric', 0), ('ScalarString', 1), ('ScalarYearMonth', 2), ('PeriodicNumeric', 3), ('PeriodicYearMonth', 4), ('LookupTableNumeric', 5), ('LookupTableYearMonth', 6)
		
INSERT INTO @UnitList([UnitName], [UnitId])
VALUES('Custom', 0), ('Area', 1), ('BoePrice', 2), ('BoePriceLastMonth', 3), ('BoeRate', 4), ('BoeVolume', 5), ('BoeVolumeCum', 6), ('BtuPrice', 7), ('CondensatePrice', 8), (
'Currency', 9), ('CurrencyBalance', 10), ('CurrencyClosingBalance', 11), ('CurrencyOpeningBalance', 12), ('Days', 13), ('Density', 14), ('DensityDegressApi', 15), ('Depth', 16), (
'DepthMeters', 17), ('Eps', 18), ('FractionAverage', 19), ('FractionMaximum', 20), ('FractionWeightedAverage', 21), ('GasOilRatio', 22), ('GasPrice', 23), ('GasPriceAverage', 24),
('GasPriceLastMonth', 25), ('GasRate', 26), ('GasRateMetric', 27), ('GasVolume', 28), ('GasVolumeCum', 29), ('GasVolumeMetric', 30), ('GasWaterRatio', 31), ('HeatContent', 32), (
'HeatContentMetric', 33), ('HeatingValue', 34), ('HeatingValueMetric', 35), ('IntegerAverage', 36), ('IntegerMaximum', 37), ('IntegerMinimum', 38), ('LengthFootPerMeter', 39), (
'LiquidHeatContent', 40), ('Months', 41), ('NoUnitsAverage', 42), ('NoUnitsEqualAllocation', 43), ('NoUnitsLastPeriod', 44), ('NoUnitsMaximum', 45), ('NoUnitsSum', 46), (
'NoUnitsWeightedAverage', 47), ('OilGasRatio', 48), ('OilPrice', 49), ('OilPriceAverage', 50), ('OilPriceLastMonth', 51), ('OilRate', 52), ('OilVolume', 53), ('OilVolumeCum', 54),
('PercentAverage', 55), ('PercentBalance', 56), ('PercentMaximum', 57), ('PercentSumMonths', 58), ('PercentWeightedAverage', 59), ('PeriodicCurrency', 60), ('Pressure', 61), (
'PressureAbsolute', 62), ('PressureGradient', 63), ('SharePrice', 64), ('Shares', 65), ('SulphurPrice', 66), ('SulphurRate', 67), ('SulphurVolume', 68), ('Temperature', 69), (
'Tonnes', 70), ('TonnesBalance', 71), ('TonnesCum', 72), ('TonnesPrice', 73), ('TonnesRate', 74), ('WaterGasRatio', 75), ('WaterOilRatio', 76), ('WaterPriceCost', 77), (
'WaterRate', 78), ('WaterVolume', 79), ('Years', 80), ('EnergyPrice', 81), ('ElectricalEnergy', 82), ('EnergyPerBarrel', 83), ('EnergyRatio', 84), ('Power', 85), (
'BoePriceAverage', 86);


IF (@IsRunningAddPrefix = 1)
BEGIN
DECLARE @Alias NVARCHAR(MAX)
DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR     
  SELECT DISTINCT ALIAS FROM
  (SELECT [Alias], COUNT(*) [Totalcount] FROM CASHDFX.Variable where IsODataVisible = 1  GROUP BY [Alias]) DataSet
  WHERE Totalcount > 1
  OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @Alias
WHILE @@FETCH_STATUS = 0
BEGIN 	  
	  ;WITH CTE AS
	  (
	  SELECT V.VariableId ,V.Alias,  v.[Alias]+'_'+ CAST(ROW_NUMBER() OVER(ORDER BY v.[Alias]) AS nvarchar(max)) AS New_Alias	  
      FROM CASHDFX.Variable V Where Alias = @Alias)
	  UPDATE V_Set SET Alias = CTE.New_Alias
	  FROM CASHDFX.Variable V_Set
	  INNER JOIN CTE on V_Set.VariableId = CTE.VariableId 	  
	  print @Alias
  FETCH NEXT FROM MY_CURSOR INTO @Alias
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR
END
ELSE
BEGIN

-- fix the first latest duplicate data
;WITH CTE
     AS (
     SELECT MAX([VariableId]) AS [V_Id], [Alias], [DataType]
     FROM [CASHDFX].[Variable]
     WHERE [Alias] IN (SELECT [Alias]
                       FROM (SELECT [Alias], COUNT(*) [Totalcount]
                             FROM [CASHDFX].[Variable]
							 WHERE IsODataVisible = 1
                             GROUP BY [Alias]) [a]
                       WHERE [Totalcount] > 1)
     GROUP BY [Alias], [DataType])
     UPDATE [data]
       SET [DATA].[Alias] = [DATA].[Alias]+'_'+[U].[UnitName] 
     FROM [CASHDFX].[Variable] [data]
          INNER JOIN [CTE] ON [data].[VariableId] = [CTE].[V_Id]
		  INNER JOIN @UnitList [U] ON [data].[UnitId] = [U].[UnitId]    	 
		  Where data.Alias is not null and len(data.Alias)>0 AND IsODataVisible = 1
-- fix the second latest duplicate data with extra unit name
;WITH CTE
     AS (
     SELECT MAX([VariableId]) AS [V_Id], [Alias], [DataType], [UnitId]
     FROM [CASHDFX].[Variable]
     WHERE [Alias] IN (SELECT [Alias]
                       FROM (SELECT [Alias], COUNT(*) [Totalcount]
                             FROM [CASHDFX].[Variable]
                             GROUP BY [Alias]) [a]
                       WHERE [Totalcount] > 1)
     GROUP BY [Alias], [DataType], [UnitId])
     UPDATE [data]
       --       SET [DATA].[Alias] = [DATA].[Alias]+'_'+[U].[UnitName]+'_'+[T].[TypeName]
	       SET [DATA].[Alias] = [DATA].[Alias]+'_'+[T].[TypeName]
     FROM [CASHDFX].[Variable] [data]
          INNER JOIN [CTE] ON [data].[VariableId] = [CTE].[V_Id]
		  INNER JOIN @UnitList [U] ON [data].[UnitId] = [U].[UnitId]
          INNER JOIN @DataTypeList [T] ON [data].[DataType] = [T].[TypeId]          
	Where data.Alias is not null and len(data.Alias)>0 AND IsODataVisible = 1
-- if there is still more duplicated,  we will need to add the number after the prefix in order 
 -- get the list 
SET @Alias = NULL

DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR     
  SELECT DISTINCT ALIAS FROM
  (SELECT [Alias], COUNT(*) [Totalcount], [DataType], [UnitId] FROM [CASHDFX].[Variable]  GROUP BY [Alias], [DataType], [UnitId]) DataSet
  WHERE Totalcount > 1

  OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @Alias
WHILE @@FETCH_STATUS = 0
BEGIN 	  
	  ;WITH CTE AS
	  (
	  SELECT V.VariableId ,V.Alias,  v.[Alias]+'_'+ CAST(ROW_NUMBER() OVER(ORDER BY v.[Alias],[T].[TypeName],[U].[UnitName]) AS nvarchar(max)) AS New_Alias	  
      FROM CASHDFX.Variable V Inner Join 
					   (SELECT [Alias], COUNT(*) [Totalcount]
                             FROM [CASHDFX].[Variable]
                             GROUP BY [Alias]) [a]
							 ON V.Alias = A.Alias
							 INNER JOIN @UnitList [U] ON V.[UnitId] = [U].[UnitId]
							 INNER JOIN @DataTypeList [T] ON V.[DataType] = [T].[TypeId]          							 

                       WHERE [Totalcount] > 1 and a.Alias = @Alias
					   )
	  UPDATE V_Set SET Alias = CTE.New_Alias
	  FROM CASHDFX.Variable V_Set
	  INNER JOIN CTE on V_Set.VariableId = CTE.VariableId 	  
	  Where V_Set.Alias is not null and len(V_Set.Alias)>0 AND IsODataVisible = 1
	  print @Alias
  FETCH NEXT FROM MY_CURSOR INTO @Alias
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR
END
END

