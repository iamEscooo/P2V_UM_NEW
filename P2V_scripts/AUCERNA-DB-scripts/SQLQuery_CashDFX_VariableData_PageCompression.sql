
/********************************************************************************************************************/
/*                                                                                                                  */
/* IMPORTANT NOTICE: Using this script will cause non-reversible changes to the content of your PlanningSpace       */
/* databases.                                                                                                       */
/*                                                                                                                  */
/* Before proceeding please ensure that:                                                                            */
/*  1. The script will be deployed by a competent database administrator, with a full understanding of              */
/*     the database operations that will be executed, and the consequences of those operations.                     */
/*     Please contact Aucerna Support if you have any uncertainties or questions.                                   */
/*  2. All databases to be modified have been securely backed-up, in accordance with your company's operational     */
/*     security protocols.                                                                                          */
/*                                                                                                                  */
/* DISCLAIMER: Aucerna will not accept liability for any direct or indirect damages (including, but not limited to, */
/* loss of data or business interruption) resulting from the use of this script.                                    */
/*                                                                                                                  */
/********************************************************************************************************************/

-- this script will rebuild partition and update the ResultSetVariableData tables data compression to page

DECLARE @Name VARCHAR(50);
DECLARE CUR_TEST CURSOR FAST_FORWARD
FOR SELECT 'CASHDFXResults.' + name
    FROM sys.tables
    WHERE schema_id = SCHEMA_ID('CASHDFXResults')
          AND name LIKE 'ResultSetVariableData%';
OPEN CUR_TEST;
FETCH NEXT FROM CUR_TEST INTO @Name;
WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @cmd NVARCHAR(1000)= 'ALTER TABLE ' + @Name + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)';
        --print @cmd
        EXECUTE sp_executesql 
                @cmd;
        FETCH NEXT FROM CUR_TEST INTO @Name;
    END;
CLOSE CUR_TEST;
DEALLOCATE CUR_TEST;
GO