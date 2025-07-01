-- Fix OMV DB upgrade issue
--DocumentVersionScenarioId      VariableId           Data                                                       Crc                          (No column name)
--21109                                                   127                         0x08011205E212020A00                1620614451         9

-- please run the reporting @IsReporting  bit = 1 to get initial data set 
-- please run the updating @IsReporting  bit = 0 to get update the variable data
-- please rerun the reporting @IsReporting  bit = 1 to make sure all the data updated including history
Declare @IsReporting  bit = 1
, @VariableName varchar(max) = 'System.Document.PriceCalculationSetting'
If (@IsReporting = 1)
Begin
	-- full reporting for data as well as hisotry
	SELECT vd.DocumentVersionScenarioId, VariableId,  EntityTypeId , DocumentId,  dv.DocumentVersionId,DocumentName, vd.Data,'VariableData' as DataType
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300
	union ALL
	-- history
	SELECT vd.DocumentVersionScenarioId, VariableId,  EntityTypeId , DocumentId,  dv.DocumentVersionId,DocumentName, vd.Data,'VariableDataHistory' as DataType
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableDataHistory vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300
	union ALL
	SELECT vd.DocumentVersionScenarioId, VariableId,  EntityTypeId , DocumentId,  dv.DocumentVersionId,DocumentName, vd.Data,'VariableResultantData' as DataType
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableResultantData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300
	union ALL
	SELECT vd.DocumentVersionScenarioId, VariableId,  EntityTypeId , DocumentId,  dv.DocumentVersionId,DocumentName, vd.Data,'VariableResultantDataHistory' as DataType
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableResultantDataHistory vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300
End
ELSE
BEGIN
	-- update the variable data
	Declare @issueDVSId int, @variableId int, @DocumentType int, @DocumentId int, @DocumentVersionId int, @crc int
	Declare @data varbinary(max) 

	SELECT @issueDVSId = vd.DocumentVersionScenarioId, @variableId = VariableId, @DocumentType = EntityTypeId , @DocumentId = DocumentId, @DocumentVersionId = dv.DocumentVersionId, @crc = Crc
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300
	--- copy same docuemtn
	SELECT top 1 @data = Data
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId = @variableId and DocumentId = @DocumentId
	AND len(Data) > 300
	order by len(Data)

	-- copy same type
	if (len(@data) < 300)
	Begin
	SELECT top 1 @data = Data
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId = @variableId and EntityTypeId = @DocumentType
	AND len(Data) > 300
	order by len(Data)
	END

	-- update the issue variable data
	if (len(@data) > 300)
	Begin
	print 'Update the variable data'
	print @data
	update vd set Data = @data 
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300

	update vd set Data = @data 
		from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300


	update vd set Data = @data 
		from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300

	update vd set Data = @data 
	from DATAFLOW.DocumentVersion dv inner join 
	DATAFLOW.DocumentVersionScenario dvs on dv.DocumentVersionId = dvs.DocumentVersionId
	inner join DATAFLOW.VariableData vd on vd.DocumentVersionScenarioId = dvs.DocumentVersionScenarioId
	where VariableId in
	(select VariableId from dataflow.VariableDefinition where VariableName = @VariableName
	)
	AND len(Data) < 300

	End
	else
	begin
	print @data
	print 'Not be able to update variable data'
	End
END