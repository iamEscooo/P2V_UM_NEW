SELECT *, len(Data)
from DATAFLOW.VariableData where VariableId in
(select VariableId from dataflow.VariableDefinition where VariableName = 'System.Document.PriceCalculationSetting'
)
AND len(Data) < 300
order by len(Data)
