SET NOCOUNT ON
drop table if exists #issuedata
go

Declare @Isreporting bit = 1, @VariableId int, @LookupDocumentName varchar(200)--= 'Dom3'
Select @VariableId = VariableId
from DATAFLOW.VariableDefinition
where VariableName = 'System.Document.Scenario Definition'
Create table #issuedata
(
    docVersionId int,
    tagname varchar(50),
    tagid int,
    tagnamelist varchar(100),
    conceptname varchar(50),
    versionid int,
    DocumentName varchar(100),
    dvsID int
)

DECLARE @cursor CURSOR;
SET @cursor = CURSOR STATIC FOR
-- Exclude the documents which are copied from another version and it has not been calculated after copying
select DocumentVersionId,
       DocumentName,
       VersionId, SourceDocumentVersionId, SourceRevisionId
from DATAFLOW.DocumentVersion
where isdeleted = 0 
and DocumentName = case when @LookupDocumentName is null then DocumentName else @LookupDocumentName end 
--and SourceDocumentVersionId is null and SourceRevisionId is null

DECLARE @docVersionId INT,
        @VersionId INT,
        @DocumentName varchar(100), 
		@S_DocVersionId int,
		@S_DocRevisionId int
OPEN @cursor;
WHILE 1 = 1
BEGIN
    FETCH NEXT FROM @cursor
    INTO @docVersionId,
         @DocumentName,
         @VersionId,
		 @S_DocVersionId,

		 @S_DocRevisionId
		 ;
    IF @@fetch_status <> 0
    BEGIN
        BREAK;
    END;
    -- print document versionid
    -- print @docVersionId
    Declare @stringToConvert varchar(max),
            @rawstringToConvert varchar(max),
            @dvcID int
    select top 1
        @stringToConvert
            = substring(
                           cast(Data as varchar(max)),
                           CHARINDEX('<?', cast(Data as varchar(max))),
                           LEN(cast(Data as varchar(max)))
                       ),
        @dvcID = DocumentVersionScenarioId
    from DATAFLOW.VariableData
    where VariableId = @VariableId
          and DocumentVersionScenarioId in (
                                               select DocumentVersionScenarioId
                                               from DATAFLOW.DocumentVersionScenario
                                               where DocumentVersionId = @docVersionId
                                           )


	--
	if (len(@stringToConvert) = 0 and @S_DocRevisionId is not null)
	begin
	
	select top 1
        @stringToConvert
            = substring(
                           cast(Data as varchar(max)),
                           CHARINDEX('<?', cast(Data as varchar(max))),
                           LEN(cast(Data as varchar(max)))
                       ),
        @dvcID = DocumentVersionScenarioId
    from DATAFLOW.VariableData
    where VariableId = @VariableId
          and DocumentVersionScenarioId in (
                                               select DocumentVersionScenarioId
                                               from DATAFLOW.DocumentVersionScenario
                                               where DocumentVersionId = @S_DocVersionId)

	end
    declare @xml xml
    select @xml = cast(cast(@stringToConvert AS NTEXT) AS XML)
    --select  cast(cast(@stringToConvert AS NTEXT) AS XML)
    ;
    with dataset
    as (SELECT Tbl.Col.value('Name[1]', 'varchar(50)') tagname,
               t.value('Id[1]', 'int') tagid,
               t.value('TagType[1]', 'varchar(50)') tagtype,
               Tbl.Col.value('Tag[1]', 'varchar(50)') tagIdlists,
               t.value('Name[1]', 'varchar(50)') conceptname
        FROM @xml.nodes('//Concept')Tbl(Col)
            OUTER APPLY Col.nodes('TagData/TagData') AS B(t)
       )
    insert into #issuedata
    (
        docVersionId,
        tagname,
        tagid,
        tagnamelist,
        conceptname,
        versionid,
        DocumentName,
        dvsID
    )
    select @docVersionId,
           tagname,
           tagid,
           tagIdlists,
           conceptname,
           @VersionId,
           @DocumentName,
           @dvcID
    from dataset		  		   		   		  			 	 	   

    set @stringToConvert = ''
END;
CLOSE @cursor;
DEALLOCATE @cursor;	   	  
									  					

-- reporting
with dataset as
(
select v.VersionId,
       v.VersionName,
       n.TypeName as NodeType,
       d.DocumentName,
	   dv.DocumentId,
       d.tagname as ScenarioName,
       conceptname as TagName,
       TagId,
       docVersionId,
       dvsID,
       case
           when tagnamelist like '%,%' then
               'Multi Tag'
           else
               'Single Tag'
       End as MultiTagFlag
	from #issuedata d
    
    inner join DATAFLOW.DocumentVersion dv
        on d.docVersionId = dv.DocumentVersionId
    inner join DATAFLOW.NodeType n
        on dv.EntityTypeId = n.NodeTypeId
    inner join DATAFLOW.[Version] v
        on d.versionid = v.VersionId   	  
)

select  distinct dataset.*,
case when (dd.tagname is not null) then  'Scenario Duplicated' 
when Dataset.ScenarioName COLLATE DATABASE_DEFAULT not in (select TagName from DATAFLOW.Tag ) then 'Scenario Not Existed'
else 'Scenario Exists'
end as 'Scenario Exists', 
DATAFLOW.FN_FullHierarchyPath(dataset.docVersionId) DocumentPath

from dataset 
left join #issuedata dd on dd.dvsID = dataset.dvsID and dd.tagname = dataset.tagname --and dd.tagnamelist not like '%,%'
    where dataset.tagname <> dataset.ScenarioName
          or (
                 Dataset.TagName is null and (dd.tagname is not null and dataset.MultiTagFlag COLLATE DATABASE_DEFAULT = 'Single Tag')                 
             )
		or Dataset.ScenarioName  COLLATE DATABASE_DEFAULT  not in (select TagName from DATAFLOW.Tag )
          or dataset.MultiTagFlag COLLATE DATABASE_DEFAULT = 'Multi Tag'

