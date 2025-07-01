-- Add new script to ensure all the current Alias is following standard requirements
-- please run fix duplicated script to fix the duplicated Alias issue
-- Set @IsReporting bit = 1 to display the alias is not based on the Alias naming coversion and copy update_statement to update the Alias indiviauly
-- Set @IsReporting bit = 0 to update all Alias name based on the new Alias naming
Declare @IsReportOnly bit = 1
If (@IsReportOnly = 1)
Begin
; With DataSet As
(
Select VariableId, VariableName, Alias, CASE WHEN IsODataVisible =1 THEN
REPLACE(REPLACE(REPLACE(REPLACE(Replace(Replace(Replace(Replace(Replace([VariableName], ')', '_'), '(', '_'), '/', '_'), '-', '_'), '.', '_'),'&', 'And') ,'%','Pct'),' ', ''), 
Substring([VariableName], PatIndex('%[^a-zA-Z0-9]%', [VariableName]), 1), '_') ELSE
NULL
END AS New_Alias from [FINANCIALS].[Variable] 
)
Select *, 'UPDATE [FINANCIALS].[Variable] SET Alias = '''+New_Alias+''' WHERE VariableId = ' + cast(VariableId as NVARCHAR(10)) AS UPDATE_Statement from DataSet 
where New_Alias <> Alias
End 
Else
Begin
UPDATE [FINANCIALS].[Variable] 
SET 
[Alias] = CASE WHEN IsODataVisible =1 THEN
REPLACE(REPLACE(REPLACE(REPLACE(Replace(Replace(Replace(Replace(Replace([VariableName], ')', '_'), '(', '_'), '/', '_'), '-', '_'), '.', '_'),'&', 'And') ,'%','Pct'),' ', ''), 
Substring([VariableName], PatIndex('%[^a-zA-Z0-9]%', [VariableName]), 1), '_')
ELSE
NULL
END
End
