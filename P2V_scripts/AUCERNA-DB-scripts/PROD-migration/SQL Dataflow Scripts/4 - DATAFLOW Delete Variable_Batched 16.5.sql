-----------DELETE Variable definition as well data, resultant data and history for both
-----------Tested against DF 16.5
-----------It is STRONGLY recommended backups are taken prior to executing this script

---Batched delete version for large number of records (helps keep log growth down)

IF IS_ROLEMEMBER('dbo') = 0
BEGIN
	RAISERROR ('This script must be run by a user with the dbo role',16,1)
	RETURN;
END 

DECLARE @VariablesToDelete TABLE(VariableName nvarchar(255), VariableId INT)

INSERT @VariablesToDelete(VariableName)
VALUES--('General.Price Source')--,('Financials.PL.Depreciation') -- Provide variables names in comma separated list e.g. ('var1'),('var2')
('CTY.Kazakhstan.Resources.Input.Liquids.Oil'),
('CTY.Kazakhstan.Resources.Input.Gas.AssocGas'),
('CTY.Kazakhstan.Resources.Input.Gas.AssocGas.Fuel'),
('CTY.Kazakhstan.Resources.Input.Gas.NonAssocGas'),
('CTY.Kazakhstan.Resources.Input.Gas.NonAssocGas.Fuel'),
('CTY.Kazakhstan.Resources.Input.Liquids.Oil.Net'),
('CTY.Kazakhstan.Resources.Input.Gas.AssocGas.Net'),
('CTY.Kazakhstan.Resources.Input.Gas.AssocGas.Fuel.Net'),
('CTY.Kazakhstan.Resources.Input.Gas.NonAssocGas.Net'),
('CTY.Kazakhstan.Resources.Input.Gas.NonAssocGas.Fuel.Net'),
('Opcosts.Other.Other1OLD'),
('Opcosts.GAndA.AdminOLD'),
('CTY.Tunisia.Resources.Input.Liquids.Condensate'),
('CTY.Tunisia.Resources.Input.Liquids.LPG'),
('CTY.Tunisia.Resources.Input.Liquids.Condensate.Net'),
('CTY.Tunisia.Resources.Input.Liquids.LPG.Net'),
('CTY.Libya.Resources.Input.Liquids.Condensate'),
('CTY.Libya.Resources.Input.Liquids.LPG'),
('CTY.Libya.Resources.Input.Liquids.Condensate.Net'),
('CTY.Libya.Resources.Input.Liquids.LPG.Net'),
('CTY.Iraq.Resources.Input.Liquids.Oil'),
('CTY.Iraq.Resources.Input.Liquids.Condensate'),
('CTY.Iraq.Resources.Input.Liquids.LPG'),
('CTY.Iraq.Resources.Input.Liquids.Oil.Net'),
('CTY.Iraq.Resources.Input.Liquids.Condensate.Net'),
('CTY.Iraq.Resources.Input.Liquids.LPG.Net'),
('CTY.Australia.Resources.Input.Liquids.Condensate'),
('CTY.Australia.Resources.Input.Liquids.LPG'),
('CTY.Australia.Resources.Input.Liquids.Condensate.Net'),
('CTY.Australia.Resources.Input.Liquids.LPG.Net'),
('CTY.Mexico.Resources.Input.Liquids.Condensate'),
('CTY.Mexico.Resources.Input.Liquids.LPG'),
('CTY.Mexico.Resources.Input.Liquids.Condensate.Net'),
('CTY.Mexico.Resources.Input.Liquids.LPG.Net'),
('CTY.Malaysia.Resources.Input.Liquids.Condensate'),
('CTY.Malaysia.Resources.Input.Liquids.LPG'),
('CTY.Malaysia.Resources.Input.Liquids.Condensate.Net'),
('CTY.Malaysia.Resources.Input.Liquids.LPG.Net'),
('CTY.New Zealand.Resources.Input.Liquids.Condensate'),
('CTY.New Zealand.Resources.Input.Liquids.LPG'),
('CTY.New Zealand.Resources.Input.Liquids.Condensate.Net'),
('CTY.New Zealand.Resources.Input.Liquids.LPG.Net')


DECLARE @User nvarchar(100) = SYSTEM_USER,
@MachineName nvarchar(255) = HOST_NAME(),
@VariableId int,
@VariableName nvarchar(255),
@BatchSize int = 100000, ------Adjust this number to change the balance between space used and performance
@DeleteCount int = 1

UPDATE @VariablesToDelete
SET VariableId = dt.VariableId
FROM DATAFLOW.VariableDefinition dt
WHERE [@VariablesToDelete].VariableName = dt.VariableName

DECLARE VariablesToDeleteCur Cursor
FOR
SELECT VariableId FROM @VariablesToDelete

OPEN VariablesToDeleteCur

FETCH NEXT FROM VariablesToDeleteCur INTO @VariableId
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'Delete linklookup'
	WHILE @DeleteCount >= 1
	BEGIN
		DELETE TOP (@BatchSize) FROM DATAFLOW.LinkLookup
		WHERE VariableId = @VariableId
		SET @DeleteCount = @@ROWCOUNT
		IF @DeleteCount >= 1
		BEGIN
			CHECKPOINT 
		END
	END 
	SET @DeleteCount = 1

	PRINT 'Delete VariableHistoryRevisionResultantLink'
	WHILE @DeleteCount >= 1
	BEGIN
		DELETE TOP (@BatchSize) FROM DATAFLOW.VariableHistoryRevisionResultantLink
		WHERE HistoryId IN (SELECT HistoryId FROM DATAFLOW.VariableResultantDataHistory 
								WHERE VariableId = @VariableId) 
		SET @DeleteCount = @@ROWCOUNT
		IF @DeleteCount >= 1
		BEGIN
			CHECKPOINT
		END
	END  
	SET @DeleteCount = 1
	
	PRINT 'Delete VariableResultantDataHistory'
	WHILE @DeleteCount >= 1
	BEGIN
		DELETE TOP (@BatchSize) FROM DATAFLOW.VariableResultantDataHistory
		WHERE VariableId = @VariableId 
		SET @DeleteCount = @@ROWCOUNT
		IF @DeleteCount >= 1
		BEGIN
			CHECKPOINT
		END
	END  
	SET @DeleteCount = 1

	PRINT 'Delete VariableResultantData'
	WHILE @DeleteCount >= 1
	BEGIN
		DELETE TOP (@BatchSize) FROM DATAFLOW.VariableResultantData
		WHERE VariableId = @VariableId
		SET @DeleteCount = @@ROWCOUNT
		IF @DeleteCount >= 1
		BEGIN
			CHECKPOINT
		END
	END  
	SET @DeleteCount = 1

	PRINT 'Delete VariableHistoryRevisionLink'
	WHILE @DeleteCount >= 1
	BEGIN
		DELETE TOP (@BatchSize) FROM [DATAFLOW].[VariableHistoryRevisionLink]
		WHERE HistoryId IN (SELECT HistoryId FROM DATAFLOW.VariableDataHistory
							WHERE VariableId = @VariableId)
		SET @DeleteCount = @@ROWCOUNT
		IF @DeleteCount >= 1
		BEGIN
			CHECKPOINT
		END
	END  
	SET @DeleteCount = 1

	PRINT 'Delete VariableDataHistory'
	WHILE @DeleteCount >= 1
	BEGIN
		DELETE TOP (@BatchSize) FROM DATAFLOW.VariableDataHistory
		WHERE VariableId = @VariableId
		SET @DeleteCount = @@ROWCOUNT
		IF @DeleteCount >= 1
		BEGIN
			CHECKPOINT
		END
	END  
	SET @DeleteCount = 1

	PRINT 'Delete VariableData'
	WHILE @DeleteCount >= 1
	BEGIN
		DELETE TOP (@BatchSize) FROM DATAFLOW.VariableData
		WHERE VariableId = @VariableId
		SET @DeleteCount = @@ROWCOUNT
		IF @DeleteCount >= 1
		BEGIN
			CHECKPOINT
		END
	END  
	SET @DeleteCount = 1

	PRINT 'Delete VariableDefinition'
	WHILE @DeleteCount >= 1
	BEGIN
		DELETE TOP (@BatchSize) FROM DATAFLOW.VariableDefinition
		WHERE VariableId = @VariableId
 		SET @DeleteCount = @@ROWCOUNT
		IF @DeleteCount >= 1
		BEGIN
			CHECKPOINT
		END	
	END  
	SET @DeleteCount = 1
	 
	SELECT @VariableName = VariableName FROM VariableDefinition WHERE VariableId = @VariableId 
	EXEC [COMMON].[InsertAuditLog] 18, 0, @VariableId, @VariableName, @User, 1 ,'Variable deleted',@MachineName, 'Variable'
		  
	FETCH NEXT FROM VariablesToDeleteCur INTO @VariableId
	
END
CLOSE VariablesToDeleteCur
DEALLOCATE VariablesToDeleteCur



