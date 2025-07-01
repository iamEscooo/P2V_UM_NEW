--WT -
--Following script will delete the user which does not have any current reference with Palantir DB objects
--!Please backup the database before run the script
--0: Use Correct Database
USE [DATABASE]
GO

--Display the users are going to be deleted
SELECT [UserId], [UserName] FROM [COMMON].[User]  WHERE [IsDeactivated] = 1
-- Declare Variable
DECLARE @ReasonId INT, @ReasonToDelete NVARCHAR(MAX), @User NVARCHAR(128)= SYSTEM_USER, @MachineName NVARCHAR(255)= HOST_NAME()
DECLARE @cursor CURSOR
SET @cursor = CURSOR STATIC
FOR SELECT [UserId], [UserName] FROM [COMMON].[User]  WHERE [IsDeactivated] = 1	
DECLARE @userId INT, @userName NVARCHAR(MAX)
OPEN @cursor
WHILE 1 = 1
BEGIN
    FETCH NEXT FROM @cursor INTO @userId, @userName
    IF @@fetch_status <> 0
    BEGIN
        BREAK
    END   
    
        SET @ReasonId = @userId;
        SET @ReasonToDelete = @userName;
		PRINT 'Hard Delete User ID: '+CAST(@userId AS NVARCHAR(MAX));	      
		-- print the reason
        IF EXISTS (SELECT 1 FROM [CASHDFX].[DocumentLock] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'CASHDFX.DocumentLock'
            DELETE FROM [CASHDFX].[DocumentLock] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'CASHDFX.DocumentLock'
        END;
        IF EXISTS (SELECT 1 FROM [CASHDFX].[ResultSets] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'CASHDFX.ResultSets'
            DELETE FROM [CASHDFX].[ResultSets] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'CASHDFX.ResultSets'

        END;
        IF EXISTS (SELECT 1 FROM [COMMON].[DocumentLock] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'COMMON.DocumentLock'
            DELETE FROM [COMMON].[DocumentLock] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'COMMON.DocumentLock'
        END;

        IF EXISTS (SELECT 1 FROM [COMMON].[EntityUserPermission] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'COMMON.EntityUserPermission'
            DELETE FROM [COMMON].[EntityUserPermission] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'COMMON.EntityUserPermission'
        END;

        IF EXISTS (SELECT 1 FROM [COMMON].[InstanceUserPermission] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'COMMON.InstanceUserPermission'
            DELETE FROM [COMMON].[InstanceUserPermission]  WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'COMMON.InstanceUserPermission'
        END;
        IF EXISTS (SELECT 1 FROM [COMMON].[WorkgroupUser] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'COMMON.WorkgroupUser'
            DELETE FROM [COMMON].[WorkgroupUser] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'COMMON.WorkgroupUser'
        END;

        IF EXISTS (SELECT 1 FROM [DATAFLOW].[DocumentLock] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'DATAFLOW.DocumentLock'
            DELETE FROM [DATAFLOW].[DocumentLock] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'DATAFLOW.DocumentLock'

        END;

        IF EXISTS (SELECT 1 FROM [dbo].[DocumentLockInfo] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'dbo.DocumentLockInfo'
            DELETE FROM [dbo].[DocumentLockInfo] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'dbo.DocumentLockInfo'
        END;
        IF EXISTS (SELECT 1 FROM [dbo].[EntityUserPermission] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'dbo.EntityUserPermission'
            DELETE FROM [dbo].[EntityUserPermission]  WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'dbo.EntityUserPermission'
        END;
        IF EXISTS (SELECT 1 FROM [dbo].[InstanceUserPermission] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'dbo.InstanceUserPermission'
            DELETE FROM [dbo].[InstanceUserPermission] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'dbo.InstanceUserPermission'

        END;
        IF EXISTS (SELECT 1 FROM [DFDFX].[IntegrationEvent] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'DFDFX.IntegrationEvent'
            DELETE FROM [DFDFX].[IntegrationEvent] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'DFDFX.IntegrationEvent'

        END;
        IF EXISTS (SELECT 1 FROM [DFDFX].[MappingSettings] WHERE [UserId] = @userId) 
        BEGIN

			PRINT 'DFDFX.EntityLink'
            DELETE FROM [DFDFX].[EntityLink] WHERE  [MappingSettingsId] IN
			(SELECT MappingSettingsId FROM	[DFDFX].[MappingSettings] WHERE [UserId] = @userId)
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'DFDFX.EntityLink'

            PRINT 'DFDFX.MappingSettings'
            DELETE FROM [DFDFX].[MappingSettings] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'DFDFX.MappingSettings'
        END;
        IF EXISTS (SELECT 1 FROM [DFFIN].[IntegrationEvent] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'DFFIN.IntegrationEvent'
            DELETE FROM [DFFIN].[IntegrationEvent] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'DFFIN.IntegrationEvent'
        END;
        IF EXISTS (SELECT 1 FROM [DFFIN].[MappingSettings] WHERE [UserId] = @userId) 
        BEGIN
			PRINT 'DFFIN.EntityLink'
            DELETE FROM [DFFIN].[EntityLink] WHERE  [MappingSettingsId] IN
			(SELECT MappingSettingsId FROM	[DFFIN].[MappingSettings] WHERE [UserId] = @userId)
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'DFFIN.EntityLink'

            PRINT 'DFFIN.MappingSettings'
            DELETE FROM [DFFIN].[MappingSettings]    WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'DFFIN.MappingSettings'

        END;
        IF EXISTS (SELECT 1 FROM [FINANCIALS].[DocumentLock] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'FINANCIALS.DocumentLock'
            DELETE FROM [FINANCIALS].[DocumentLock] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'FINANCIALS.DocumentLock'
        END;
        IF EXISTS (SELECT 1 FROM [FINANCIALS].[ResultSets] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'FINANCIALS.ResultSets'
            DELETE FROM [FINANCIALS].[ResultSets] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'FINANCIALS.ResultSets'

        END;		


		IF EXISTS (SELECT 1 FROM [DECLINE].[DocumentLock] WHERE [UserId] = @userId) 
        BEGIN
            PRINT 'DECLINE.DocumentLock'
            DELETE FROM [DECLINE].[DocumentLock] WHERE [UserId] = @userId
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'DECLINE.DocumentLock'

        END;		

		IF EXISTS (SELECT 1 FROM [RESERVES].[EntityLockInfo] WHERE [UserName] = @userName) 
        BEGIN
            PRINT 'RESERVES.EntityLockInfo'
            DELETE FROM [RESERVES].[EntityLockInfo] WHERE [UserName] = @userName
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'RESERVES.EntityLockInfo'

        END;		

		IF EXISTS (SELECT 1 FROM [COMMON].[ConfigurationData] WHERE [UserName] = @userName) 
        BEGIN
            PRINT 'COMMON.ConfigurationData'
            DELETE FROM [COMMON].[ConfigurationData] WHERE [UserName] = @userName
            EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'COMMON.ConfigurationData'

        END;		

		-- Final Step: Delete User
        DELETE FROM [common].[user] WHERE [userid] = @userId
        EXEC [COMMON].[InsertAuditLog] 16, 
                                           0, 
                                           @ReasonId, 
                                           @ReasonToDelete, 
                                           @User, 
                                           1, 
                                           'User Deleted', 
                                           @MachineName, 
                                           'User'
   
END
CLOSE @cursor
DEALLOCATE @cursor
GO
-- End Of Script