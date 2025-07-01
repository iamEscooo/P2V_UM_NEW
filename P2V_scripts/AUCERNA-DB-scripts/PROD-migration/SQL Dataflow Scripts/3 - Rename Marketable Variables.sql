-- This scripts renames the "Marketable" variables
-- Gael Carlier 20-04-2021

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Production.Total.Volume'
,Prompt = 'Total Production'
,Comments = 'aka Marketable Production in OMV Classic, aka Total Production in Petrom'
WHERE VariableName = 'Production.Total.Marketable.Volume' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Production.Total.Rate'
,Prompt = 'Total Production Rate'
,Comments = 'aka Marketable Production in OMV Classic, aka Total Production in Petrom'
WHERE VariableName = 'Production.Total.Marketable.Rate' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Production.Total.IPSC'
,Prompt = 'Production (IPSC)'
WHERE VariableName = 'Production.Total.MarketableIPSC' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Resources.Input.Total.Volume'
,Prompt = 'Total Production (Gross)'
WHERE VariableName = 'Resources.Input.Total.Marketable' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Resources.Profile.Total.Volume'
,Prompt = 'Total Production (Profile)'
WHERE VariableName = 'Resources.Profile.Total.Marketable' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - Associated Gas (Net)'
WHERE VariableName = 'Production.Total.Gas.Assoc.Net' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - Oil (Net)'
WHERE VariableName = 'Production.Total.Oil.Net' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - LPG (Net)'
WHERE VariableName = 'Production.Total.LPG.Net' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - Condensate (Net)'
WHERE VariableName = 'Production.Total.Condensate.Net' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - Non-Associated Gas (Net)'
WHERE VariableName = 'Production.Total.Gas.NonAssoc.Net' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - Oil P90 (Net)'
WHERE VariableName = 'Production.Total.Oil.Net.P90' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - LPG P90 (Net)'
WHERE VariableName = 'Production.Total.LPG.Net.P90' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - Non Associated Gas P90 (Net)'
WHERE VariableName = 'Production.Total.Gas.NonAssoc.Net.P90' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - Condensate P90 (Net)'
WHERE VariableName = 'Production.Total.Condensate.Net.P90' 

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'Production - Associated Gas P90 (Net)'
WHERE VariableName = 'Production.Total.Gas.Assoc.Net.P90' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Resources.Input.Total.Volume.Net'
,Prompt = 'Total Production (Net)'
WHERE VariableName = 'Resources.Input.Total.Marketable.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Production.Total.Volume.Summary'
,Prompt = 'Production LoF'
WHERE VariableName = 'Production.Total.Marketable.Summary' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Production.Total.CY'
,Prompt = 'Total Production - CY'
WHERE VariableName = 'Production.Total.CY.Marketable' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Production.Total.CY.Net'
,Prompt = 'Total Production - CY (Net)'
WHERE VariableName = 'Production.Total.CY.Marketable.Net' 



















