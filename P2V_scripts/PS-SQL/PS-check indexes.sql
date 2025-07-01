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