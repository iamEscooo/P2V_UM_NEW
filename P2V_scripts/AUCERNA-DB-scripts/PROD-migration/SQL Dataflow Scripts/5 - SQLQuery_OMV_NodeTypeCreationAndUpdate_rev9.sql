-- This script created for OMV insert two new nodes and update one existing node
-- Please make sure to back up the database before running the script 
-- Make sure to use the correct database
-- Use [Database Name]
-- Go
-- showing the node type list before the update
SELECT *
FROM DATAFLOW.NodeType
--1. create a new node type (insert without parent node)
DECLARE @nodeInsertList TABLE
(orderId         INT, 
 TypeName        NVARCHAR(20), 
 TypeDescription NVARCHAR(20), 
 imageKey        NVARCHAR(20), 
 parentNodeName  NVARCHAR(50)
)
DECLARE @User NVARCHAR(100)= System_USER, @MachineName NVARCHAR(255)= HOST_NAME()
INSERT INTO @nodeInsertList
(orderId, 
 TypeName, 
 TypeDescription, 
 imageKey, 
 parentNodeName
)
       SELECT *
       FROM(VALUES
       (1, 
        N'Consolidation Group', 
        N'Consolidation Group', 
        N'Region', 
        N'Legal Entity'
       ),
       (2, 
        N'Field Group', 
        N'Field Group', 
        N'Region', 
        N'Contract Area'
       )) dataset(id, TypeName, TypeDescription, imageKey, parentNodeName)
DECLARE @TypeName NVARCHAR(MAX), @TypeDescription NVARCHAR(MAX), @imageKey NVARCHAR(MAX), @parentNodeName NVARCHAR(MAX), @insertedDocId [DATAFLOW].[Identities], @updatedDocId [DATAFLOW].[Identities], @updatedNodeId [DATAFLOW].[Identities]
DECLARE MY_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR SELECT TypeName, 
           TypeDescription, 
           imageKey, 
           parentNodeName
    FROM @nodeInsertList
    ORDER BY orderId
OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @TypeName, @TypeDescription, @imageKey, @parentNodeName 
WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION
            DECLARE @parentNodeId INT, @childNodeId INT, @newNodeId [DATAFLOW].[Identities], @duplicated_node_id INT
            -- get the parent node id	
            SELECT @parentNodeId = nodetypeid
            FROM DATAFLOW.NodeType
            WHERE TypeName = @parentNodeName	
            -- get the child node id, this is only pick up one id based on OMV data struture	
            SELECT @childNodeId = nodetypeid
            FROM DATAFLOW.NodeType
            WHERE ParentNodeTypeId = @parentNodeId
            SELECT @duplicated_node_id = nodetypeid
            FROM DATAFLOW.NodeType
            WHERE TypeName = @TypeName
            IF(@parentNodeId IS NULL
               OR @duplicated_node_id IS NOT NULL)
                BEGIN
                    IF(@parentNodeId IS NULL)
                        PRINT N'ParentNode does not exit'
                    IF(@duplicated_node_id IS NOT NULL)
                        PRINT N'NodeType Name: ' + @TypeName + ' Duplicated'
            END
                ELSE
                BEGIN

				    Declare @docTemplateId int 
					select top 1 @docTemplateId = Templateid from DATAFLOW.DocumentTemplate 

                    -- insert the data without update the child node	
                    INSERT INTO DATAFLOW.NodeType
                    (TypeName, 
                     TypeDescription, 
                     imageKey, 
                     ParentNodeTypeId, 
                     DefaultTemplateId
                    )
                    OUTPUT INSERTED.NodeTypeId
                           INTO @newNodeId
                    VALUES
                    (@TypeName, 
                     @TypeDescription, 
                     @imageKey, 
                     @parentNodeId, 
                     @docTemplateId
                    )
                    DECLARE @nodeId INT
                    SELECT @nodeid = Identifier
                    FROM @newNodeId
                    --2. create new document for the node (create document and documentversion,.assign for the new node), multiple documents across versions and parent documents		
                    -- get a list of parent document and replicate them with the new type id	
                    DECLARE @documentId TABLE
                    (newDocumentId    INT, 
                     parentDocumentId INT, 
					 parentDocumentVersionId INT, 
					 VersionId INT
                    )
                    DECLARE @MaxDocumentId INT
                    SELECT @MaxDocumentId = MAX(documentId)
                    FROM DATAFLOW.Document
                    -- get a list of documentid		
                    INSERT INTO @documentId
                    (newDocumentId, 
                     parentDocumentId, 
					 parentDocumentVersionId,
					 VersionId
                    )
                           SELECT DISTINCT ROW_NUMBER() OVER(
                                  ORDER BY DocumentId ASC) + @MaxDocumentId, 
                                  DocumentId, DocumentVersionId, VersionId
                           FROM DATAFLOW.DocumentVersion
                           WHERE EntityTypeId = @parentNodeId
                                 
                    SET IDENTITY_INSERT [DATAFLOW].[Document] ON
                    -- create document
                    INSERT INTO DATAFLOW.Document(DocumentId)
                           SELECT newDocumentId
                           FROM @documentId
                    SET IDENTITY_INSERT [DATAFLOW].[Document] OFF

					
                    -- create document version
                    INSERT INTO DATAFLOW.DocumentVersion
                    (DocumentId, 
                     TemplateId, 
                     VersionId, 
                     EntityTypeId, 
                     ParentDocumentVersionId, 
                     DocumentName, 
                     Description, 
                     IsDeleted, 
                     IsInactive					 
                    )
                    OUTPUT INSERTED.DocumentVersionId
                           INTO @insertedDocId
                           SELECT distinct d.newDocumentId, 
                                  @docTemplateId, 
                                  dv.VersionId, 
                                  @nodeId, 
                                  dv.DocumentVersionId, 
                                  dv.DocumentName + ' (' + @TypeName + ')', 
                                  dv.[Description] + ' (' + @TypeName + ')', 
                                  dv.isDeleted,                                 
                                  dv.IsInactive
                           FROM DATAFLOW.DocumentVersion dv
                                INNER JOIN @documentId d ON dv.DocumentVersionId = d.parentDocumentVersionId and dv.DocumentId = d.parentDocumentId and dv.VersionId = d.VersionId                                                                                      

                    -- update the parnent link for the existing child
                    UPDATE dvc
                      SET 
                          ParentDocumentVersionId = dvp.DocumentVersionId
                    OUTPUT inserted.DocumentVersionId
                           INTO @updatedDocId
                    FROM DATAFLOW.DocumentVersion dv
                         INNER JOIN @documentId d ON dv.DocumentId = d.parentDocumentId and dv.DocumentVersionId = d.parentDocumentVersionId
                         INNER JOIN DATAFLOW.DocumentVersion dvc ON dv.DocumentVersionId = dvc.ParentDocumentVersionId and dv.VersionId = dvc.VersionId
                         INNER JOIN DATAFLOW.DocumentVersion dvp ON dvp.DocumentId = d.newDocumentId AND dvp.versionId = dvc.VersionId
                    WHERE dvc.EntityTypeId = @childNodeId

                    --3. update the current node tree with inserted node type
                    -- update the current child node to the new node	
                    UPDATE nt
                    SET    ParentNodeTypeId = @nodeId
                    FROM   dataflow.nodetype nt
                    WHERE  ParentNodeTypeId = @parentNodeId AND NodeTypeId <> @nodeId

                    --4, create audit log
                    DECLARE @auditLogTable AS [COMMON].[AuditLogTableType]
                    INSERT INTO @auditLogTable
                    ([PermissionContextId], 
                     [EntityTypeId], 
                     [EntityId], 
                     [EntityName], 
                     [Action], 
                     [Comment], 
                     [EntityTypeName]
                    )
                           SELECT 18, 
                                  0, 
                                  Identifier, 
                                  @TypeName, 
                                  0, 
                                  N'Node Created', 
                                  N'Node Type'
                           FROM @newNodeId

                    -- inserted Document
                    INSERT INTO @auditLogTable
                    ([PermissionContextId], 
                     [EntityTypeId], 
                     [EntityId], 
                     [EntityName], 
                     [Action], 
                     [Comment], 
                     [EntityTypeName]
                    )
                           SELECT 18, 
                                  0, 
                                  Identifier, 
                                  DocumentName, 
                                  0, 
                                  N'Node Type Document Created', 
                                  N'Document'
                           FROM @insertedDocId d
                                INNER JOIN DATAFLOW.DocumentVersion dv ON d.Identifier = dv.DocumentVersionId

                    -- updated Document
                    INSERT INTO @auditLogTable
                    ([PermissionContextId], 
                     [EntityTypeId], 
                     [EntityId], 
                     [EntityName], 
                     [Action], 
                     [Comment], 
                     [EntityTypeName]
                    )
                           SELECT 18, 
                                  0, 
                                  Identifier, 
                                  DocumentName, 
                                  1, 
                                  N'Node Type Document Updated', 
                                  N'Document'
                           FROM @updatedDocId d
                                INNER JOIN DATAFLOW.DocumentVersion dv ON d.Identifier = dv.DocumentVersionId
                    EXEC [COMMON].[InsertAuditLogs] 
                         @auditLogTable, 
                         @User, 
                         @MachineName


                   -- user and workgroup for the parent node
				   Insert COMMON.EntityUserPermission (EntityTypeId, Permission, UserId, PermissionContextId)
				   select @nodeId, Permission, UserId, PermissionContextId from COMMON.EntityUserPermission where PermissionContextId = 6 and EntityTypeId = @parentNodeId
				   			   

				   Insert COMMON.EntityWorkgroupPermission (EntityTypeId, Permission, WorkgroupId, PermissionContextId)
				   select @nodeId, Permission, WorkgroupId, PermissionContextId from COMMON.EntityWorkgroupPermission where PermissionContextId = 6 and EntityTypeId = @parentNodeId


				   -- user and workgroup for the parent node document
				   Insert COMMON.InstanceWorkgroupPermission (EntityTypeId,InstanceId,WorkgroupId,Permission,PermissionContextId)
				   select @nodeId,dv.DocumentVersionId, WorkgroupId, Permission, PermissionContextId from COMMON.InstanceWorkgroupPermission workgroup inner join DATAFLOW.DocumentVersion dv on workgroup.InstanceId = dv.ParentDocumentVersionId			
				   where PermissionContextId = 6 and workgroup.EntityTypeId = @parentNodeId				   			


				   Insert COMMON.InstanceUserPermission (EntityTypeId,InstanceId,UserId,Permission,PermissionContextId)
				   select @nodeId,dv.DocumentVersionId, UserId, Permission, PermissionContextId from COMMON.InstanceUserPermission workgroup inner join DATAFLOW.DocumentVersion dv on workgroup.InstanceId = dv.ParentDocumentVersionId			
				   where PermissionContextId = 6 and workgroup.EntityTypeId = @parentNodeId			   			
				   					 

                    -- clean up
                    DELETE FROM @documentId
                    DELETE FROM @newNodeId
                    DELETE FROM @auditLogTable
                    PRINT N'Node Name ' + @TypeName + ' inserted'
            END
            COMMIT TRANSACTION
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION

            -- Raise an error with the details of the exception
            DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT
            SELECT @ErrMsg = ERROR_MESSAGE(), 
                   @ErrSeverity = ERROR_SEVERITY()
            RAISERROR(@ErrMsg, @ErrSeverity, 1)
        END CATCH
        FETCH NEXT FROM MY_CURSOR INTO @TypeName, @TypeDescription, @imageKey, @parentNodeName
    END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR
DECLARE @updateFromNodeName NVARCHAR(150)= 'Asset', @updateToNodeName NVARCHAR(150)= 'Field', @TypeDesc NVARCHAR(150)= 'Field', @updateNodeId INT, @duplicatedUpdateNodeId INT
SELECT @updateNodeId = NodeTypeId
FROM [DATAFLOW].[NodeType]
WHERE TypeName = @updateFromNodeName
SELECT @duplicatedUpdateNodeId = NodeTypeId
FROM [DATAFLOW].[NodeType]
WHERE TypeName = @updateToNodeName
IF(@updateNodeId IS NULL
   OR @duplicatedUpdateNodeId IS NOT NULL)
    BEGIN
        IF(@updateNodeId IS NULL)
            PRINT N'Node to be updated does not exit'
        IF(@duplicatedUpdateNodeId IS NOT NULL)
            PRINT N'Updated to node type name: ' + @TypeName + ' Duplicated'
END
    ELSE
    BEGIN
        -- update the node name
        UPDATE [DATAFLOW].[NodeType]
          SET 
              TypeName = @updateToNodeName, 
              TypeDescription = @TypeDesc
        OUTPUT deleted.NodeTypeId
               INTO @updatedNodeId
        WHERE NodeTypeId = @updateNodeId

        -- aduit log
        INSERT INTO @auditLogTable
        ([PermissionContextId], 
         [EntityTypeId], 
         [EntityId], 
         [EntityName], 
         [Action], 
         [Comment], 
         [EntityTypeName]
        )
        VALUES
        (18, 
         0, 
         @updateNodeId, 
         'Field', 
         1, 
         'Node Name Updated', 
         'Node Type'
        )
        EXEC [COMMON].[InsertAuditLogs] 
             @auditLogTable, 
             @User, 
             @MachineName
        PRINT 'Node Name ' + @updateFromNodeName + ' updated to ' + @updateToNodeName
END



-- update expression data
	DECLARE @xml XML, @documentTemplateHistory NVARCHAR(50), @templateID INT
	DECLARE V_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR SELECT DT.DocumentTemplateHistoryId, 
				dt.TemplateName, 
				CAST(templateContent AS XML) AS XMLCOL
		FROM DATAFLOW.DocumentTemplate dt
				INNER JOIN DATAFLOW.DocumentTemplateHistory h ON dt.DocumentTemplateHistoryId = h.DocumentTemplateHistoryId
	OPEN V_CURSOR
	FETCH NEXT FROM V_CURSOR INTO @templateId, @documentTemplateHistory, @xml
	WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @i INT, @nodeCount INT
			DECLARE @value NVARCHAR(50)
			DECLARE @oldvalue NVARCHAR(50)
			SET @value = N'GETHIERARCHYPART([Hierarchy Location],"Field")'
			SET @oldvalue = N'GETHIERARCHYPART([Hierarchy Location],"Asset")'
			SET @i = 1
			SELECT @nodeCount = @xml.value('count(/DocumentTemplate/Expressions/TemplateExpression/@Expression[.=sql:variable("@oldvalue")])[1]', 'nvarchar(1000)')
			PRINT 'Number of nodes found: ' + STR(@nodeCount)
			WHILE(@i <= @nodeCount)
				BEGIN
					SET @xml.modify('replace value of (/DocumentTemplate/Expressions/TemplateExpression/@Expression[.=sql:variable("@oldvalue")])[1] with sql:variable("@value")')
					SET @i = @i + 1
				END
			UPDATE DATAFLOW.DocumentTemplateHistory
				SET 
					TemplateContent = CAST(@xml AS NVARCHAR(MAX))
			WHERE DocumentTemplateHistoryId = @templateID
			FETCH NEXT FROM V_CURSOR INTO @templateId, @documentTemplateHistory, @xml
		END
	CLOSE V_CURSOR
	DEALLOCATE V_CURSOR
	Declare @documentTemplatePendingId int 
	-- document template pending table 
	DECLARE V_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR SELECT DT.DocumentTemplatePendingId, 							   
				CAST(templateContent AS XML) AS XMLCOL
		FROM DATAFLOW.DocumentTemplatePending dt							 
	OPEN V_CURSOR
	FETCH NEXT FROM V_CURSOR INTO @documentTemplatePendingId, @xml
	WHILE @@FETCH_STATUS = 0
		BEGIN							
			SET @value = N'GETHIERARCHYPART([Hierarchy Location],"Field")'
			SET @oldvalue = N'GETHIERARCHYPART([Hierarchy Location],"Asset")'
			SET @i = 1
			SELECT @nodeCount = @xml.value('count(/DocumentTemplate/Expressions/TemplateExpression/@Expression[.=sql:variable("@oldvalue")])[1]', 'nvarchar(1000)')
			PRINT 'Number of nodes found: ' + STR(@nodeCount)
			WHILE(@i <= @nodeCount)
				BEGIN
					SET @xml.modify('replace value of (/DocumentTemplate/Expressions/TemplateExpression/@Expression[.=sql:variable("@oldvalue")])[1] with sql:variable("@value")')
					SET @i = @i + 1
				END
			UPDATE DATAFLOW.DocumentTemplatePending
				SET 
					TemplateContent = CAST(@xml AS NVARCHAR(MAX))
			WHERE DocumentTemplatePendingId = @documentTemplatePendingId
			FETCH NEXT FROM V_CURSOR INTO  @documentTemplatePendingId, @xml
		END
	CLOSE V_CURSOR
	DEALLOCATE V_CURSOR
	   
-- show final node type name
SELECT *
FROM DATAFLOW.NodeType

-- report the updates
Select * from COMMON.AuditLog where Comment like 'Node%'
