-- This script is to report the variable without regime or is Orphaned data and set IsODataVisible = 0, Alias = NULL 
-- when  @IsReportOnly bit = 1 is to produce a report of variable with reason and set @IsReportOnly bit = 0 to update & remove the orphaned vairables
DECLARE @IsReportOnly BIT= 1;
DECLARE @tableName NVARCHAR(MAX);
DECLARE @schemaName NVARCHAR(MAX);
CREATE TABLE #tempTable(VariableId INT);
CREATE TABLE #tempReportTable
(VariableId     INT, 
 VariableName   NVARCHAR(MAX), 
 UnitId         INT, 
 DataType       INT, 
 Prompt         NVARCHAR(MAX), 
 Alias          NVARCHAR(MAX), 
 IsODataVisible BIT, 
 Reason         NVARCHAR(50)
);
DECLARE myCursor CURSOR
FOR SELECT t.name AS 'TableName', 
           SCHEMA_NAME(t.schema_id)
    FROM sys.columns c
         JOIN sys.tables t ON c.object_id = t.object_id
    WHERE c.name = 'VariableID'
          AND SCHEMA_NAME(t.schema_id) LIKE 'CashDFX%'
          AND t.name <> 'Variable'
    ORDER BY TableName;
OPEN myCursor;
FETCH NEXT FROM myCursor INTO @tableName, @schemaName;
WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @command NVARCHAR(MAX);
        SET @command = 'Select Distinct variableId from  [' + @schemaName + '].[' + @tableName + ']';
        INSERT INTO #tempTable
        EXEC (@command);
        PRINT @command;
        FETCH NEXT FROM myCursor INTO @tableName, @schemaName;
    END;
CLOSE myCursor;
DEALLOCATE myCursor;
INSERT INTO #tempReportTable
(VariableId, 
 VariableName, 
 Prompt, 
 UnitId, 
 DataType, 
 Alias, 
 IsODataVisible, 
 Reason
)
       SELECT VariableId, 
              VariableName, 
              Prompt, 
              UnitId, 
              DataType, 
              Alias, 
              IsODataVisible, 
              'Orphaned Variable'
       FROM CASHDFX.Variable
       WHERE VariableId NOT IN
       (
           SELECT DISTINCT 
                  VariableId
           FROM #tempTable
       );
INSERT INTO #tempReportTable
(VariableId, 
 VariableName, 
 Prompt, 
 UnitId, 
 DataType, 
 Alias, 
 IsODataVisible, 
 Reason
)
       SELECT v.VariableId, 
              VariableName, 
              v.Prompt, 
              UnitId, 
              DataType, 
              Alias, 
              IsODataVisible, 
              'Variable Without Regime'
       FROM CASHDFX.Variable v
            LEFT JOIN CASHDFX.RegimeVariable rv ON v.VariableId = rv.VariableId
            LEFT JOIN CASHDFX.Regime r ON rv.RegimeId = r.RegimeId
       WHERE rv.RegimeId IS NULL
             AND Alias IS NOT NULL
             AND IsODataVisible = 1
             AND v.VariableId NOT IN
       (
           SELECT VariableId
           FROM #tempTable
       );
IF(@IsReportOnly = 0)
    BEGIN
        UPDATE v
          SET 
              IsODataVisible = 0, 
              Alias = NULL
        FROM CASHDFX.Variable v
             LEFT JOIN CASHDFX.RegimeVariable rv ON v.VariableId = rv.VariableId
             LEFT JOIN CASHDFX.Regime r ON rv.RegimeId = r.RegimeId
        WHERE rv.RegimeId IS NULL;
END;
IF(@IsReportOnly = 1)
    BEGIN
        SELECT *
        FROM #tempReportTable;
END;
    ELSE
    BEGIN
        DECLARE @deleteCursor CURSOR, @deleteId INT;
        SET @deleteCursor = CURSOR STATIC
        FOR SELECT VariableId
            FROM #tempReportTable
            WHERE Reason = 'Orphaned Variable';
        OPEN @deleteCursor;
        WHILE 1 = 1
            BEGIN
                FETCH NEXT FROM @deleteCursor INTO @deleteId;
                IF @@fetch_status <> 0
                    BREAK;
                PRINT 'Remove Variable:' + CAST(@deleteId AS NVARCHAR(10));
                -- Remove Variable
                DELETE FROM CASHDFX.Variable  WHERE VariableId = @deleteId;
END;
        CLOSE @deleteCursor;
        DEALLOCATE @deleteCursor;
        SELECT *,
               CASE
                   WHEN Reason = 'Orphaned Variable'
                   THEN 'Removed Orphaned Variable'
                   ELSE 'Updated Variable Without Regime, update the Alias and set Odata Visible = false'
               END AS ActionStatement
        FROM #tempReportTable;
END;
DROP TABLE #tempTable;
DROP TABLE #tempReportTable;
GO


