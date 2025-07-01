  DECLARE 
                   @isReportOnly          BIT          = 1, 
                 @fillFactor            INT          = NULL, 
                 @isPageDataCompression BIT          = 0, 
                 @pageCounter           INT          = 0, 
                 @schema                NVARCHAR(50) = NULL, 
                 @table                 NVARCHAR(50) = NULL, 
                 @index                 NVARCHAR(50) = NULL


   BEGIN
        DECLARE @tableName NVARCHAR(MAX);
        DECLARE @indexName NVARCHAR(MAX);
        DECLARE @fragPercentage FLOAT;
        DECLARE @pageCount INT;
        DECLARE @rebuildList TABLE
(
                                   [SchemaName]     NVARCHAR(MAX), 
                                   [TableName]      NVARCHAR(MAX), 
                                   [IndexName]      NVARCHAR(MAX), 
                                   [FragPercentage] FLOAT, 
                                   [PagesCount]     INT
)
        INSERT INTO @rebuildList
               ([SchemaName], 
                [TableName], 
                [IndexName], 
                [FragPercentage], 
                [PagesCount]
               )
SELECT DISTINCT 
               [dbschemas].[name] AS 'Schema', 
               [dbtables].[name] AS 'Table', 
               [indexstats].[name] AS 'Index', 
               [indexstats].[avg_fragmentation_in_percent], 
               [indexstats].[page_count]
        FROM [sys].[tables] [dbtables]
             INNER JOIN [sys].[schemas] [dbschemas] ON [dbtables].schema_id = [dbschemas].schema_id
             CROSS APPLY (SELECT [avg_fragmentation_in_percent], 
                                 [page_count], 
                                 [dbindexes].[name], 
                                 [database_id]
                          FROM [sys].[indexes] [dbindexes]
                               INNER JOIN [sys].[dm_db_index_physical_stats](DB_ID(), NULL, NULL, NULL, NULL) [st] ON [dbindexes].object_id = [st].object_id
                          WHERE [st].object_id = [dbtables].object_id
                                AND [st].[index_id] = [dbindexes].[index_id]) [indexstats]
        WHERE [indexstats].[database_id] = DB_ID()
              AND [indexstats].[avg_fragmentation_in_percent] >5 
			  AND [indexstats].[page_count] >= 500
        ORDER BY [indexstats].[avg_fragmentation_in_percent] DESC, 
                 [indexstats].[page_count] DESC
  
        IF @isReportOnly = 0
        BEGIN
            DECLARE myCursor CURSOR
            FOR SELECT N'['+[SchemaName]+N'].['+[TableName]+N']', 
                       N'['+[IndexName]+N']', 
                       [FragPercentage], 
                       [PagesCount]
                FROM @rebuildList
                WHERE [PagesCount] >= @pageCounter
            OPEN myCursor
            FETCH NEXT FROM myCursor INTO @tableName, @indexName, @fragPercentage, @pageCount
            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @command NVARCHAR(MAX)
                DECLARE @fillfactorCommand NVARCHAR(MAX)
                DECLARE @pageDataCompressionCommand NVARCHAR(MAX)
                SELECT @indexName = isnull(@indexName, 'ALL')
                SET @command = N'ALTER INDEX '+@indexname+N' ON '+@tableName+N' REBUILD'
                IF @fillFactor > 0
                   AND @fillFactor < 100
                BEGIN
                    SET @fillfactorCommand = N' FILLFACTOR = '+CAST(@fillFactor AS NVARCHAR)
                END
                IF @isPageDataCompression = 1
                BEGIN
                    SET @pageDataCompressionCommand = N' DATA_COMPRESSION = PAGE '
                END
                IF @fillfactorCommand IS NOT NULL
                   AND @pageDataCompressionCommand IS NOT NULL
                BEGIN
                    SET @command = @command+N' WITH ('+@fillfactorCommand+N', '+@pageDataCompressionCommand+')'
                END
                ELSE
                BEGIN
                    IF @fillfactorCommand IS NULL
                       AND @pageDataCompressionCommand IS NOT NULL
                    BEGIN
                        SET @command = @command+N' WITH ('+@pageDataCompressionCommand+')'
                    END
                    ELSE
                    BEGIN
                        IF @fillfactorCommand IS NOT NULL
                           AND @pageDataCompressionCommand IS NULL
                        BEGIN
                            SET @command = @command+N' WITH ('+@fillfactorCommand+')'
                        END
                    END
                END
                IF @tableName LIKE 'DATAFLOWVersion.%'
                BEGIN
                    SET @command = @command+N' UPDATE STATISTICS '+@tableName+' '+@indexname+''
                END
                EXEC (@command)
                FETCH NEXT FROM myCursor INTO @tableName, @indexName, @fragPercentage, @pageCount
            END
            CLOSE myCursor
            DEALLOCATE myCursor
        END
        SELECT *
        FROM @rebuildList
        DELETE FROM @rebuildList
    END
  
  
  
  