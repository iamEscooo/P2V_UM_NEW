-----------DELETE Variable definition as well data, resultant data and history for both
-----------Tested against DF 16.5
-----------It is STRONGLY recommended backups are taken prior to executing this script

---Batched delete version for large number of records (helps keep log growth down)

IF IS_ROLEMEMBER('db_owner') = 0
BEGIN
    RAISERROR ('This script must be run by a user with the db owner role',16,1)
    RETURN;
END

DECLARE @VariablesToDelete TABLE(VariableName nvarchar(255), VariableId INT)

INSERT @VariablesToDelete(VariableName)
VALUES--('General.Price Source')--,('Financials.PL.Depreciation') -- Provide variables names in comma separated list e.g. ('var1'),('var2')
('obsolete - please delete')

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



