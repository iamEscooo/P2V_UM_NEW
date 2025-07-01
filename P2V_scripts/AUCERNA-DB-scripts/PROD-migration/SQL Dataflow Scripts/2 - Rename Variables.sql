-- This scripts renames variables incorrectly created.
-- Gael Carlier 20-04-2021

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Liquids.Oil'
,Prompt = 'KRI Oil (Gross)'
,Comments = 'KRI Oil (Gross)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Liquids.Oil' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Liquids.Condensate'
,Prompt = 'KRI Condensate (Gross)'
,Comments = 'KRI Condensate (Gross)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Liquids.Condensate' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Liquids.LPG'
,Prompt = 'KRI LPG (Gross)'
,Comments = 'KRI LPG (Gross)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Liquids.LPG' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Gas.AssocGas'
,Prompt = 'KRI Associated Gas (Gross)'
,Comments = 'KRI Associated Gas (Gross)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Gas.AssocGas' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Gas.AssocGas.Fuel'
,Prompt = 'KRI Associated Gas Fuel (Gross)'
,Comments = 'KRI Associated Gas Fuel (Gross)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Gas.AssocGas.Fuel' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Gas.NonAssocGas'
,Prompt = 'KRI Non-Associated Gas (Gross)'
,Comments = 'KRI Non-Associated Gas (Gross)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Gas.NonAssocGas' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Gas.NonAssocGas.Fuel'
,Prompt = 'KRI Non-Associated Gas Fuel (Gross)'
,Comments = 'KRI Non-Associated Gas Fuel (Gross)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Gas.NonAssocGas.Fuel' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Liquids.Oil.Net'
,Prompt = 'KRI Oil (Net)'
,Comments = 'KRI Oil (Net)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Liquids.Oil.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Liquids.Condensate.Net'
,Prompt = 'KRI Condensate (Net)'
,Comments = 'KRI Condensate (Net)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Liquids.Condensate.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Liquids.LPG.Net'
,Prompt = 'KRI LPG (Net)'
,Comments = 'KRI LPG (Net)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Liquids.LPG.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Gas.AssocGas.Fuel.Net'
,Prompt = 'KRI Associated Gas Fuel (Net)'
,Comments = 'KRI Associated Gas Fuel (Net)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Gas.AssocGas.Fuel.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Gas.NonAssocGas.Net'
,Prompt = 'KRI Non-Associated Gas (Net)'
,Comments = 'KRI Non-Associated Gas (Net)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Gas.NonAssocGas.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Gas.NonAssocGas.Fuel.Net'
,Prompt = 'KRI Non-Associated Gas Fuel (Net)'
,Comments = 'KRI Non-Associated Gas Fuel (Net)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Gas.NonAssocGas.Fuel.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Kurdistan.Resources.Input.Gas.AssocGas.Net'
,Prompt = 'KRI Associated Gas (Net)'
,Comments = 'KRI Associated Gas (Net)'
WHERE VariableName = 'CTY.Iraq.Resources.Input.Gas.AssocGas.Net' 

-- FINANCIALS DEPRECIATION CHANGES
PRINT 'Variable 798 - Financials Depreciation Adjustments'
UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Financials.Depreciation.Adjustment.Wells'
,Prompt = 'Depreciation Adj. Wells (Manual Entry)'
WHERE VariableID = 798


-- Economics Results Variables
PRINT 'Economics Results Variables'
UPDATE DATAFLOW.VariableDefinition
SET Comments = 'This is Total undiscounted cashflow'
WHERE VariableName = 'Indicators.Totals.Cash Flow After Tax' 

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'This is Discount Rate 2 in Currency & Discount Parameter'
WHERE VariableName = 'Indicators.NPV.USWACC'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'This is Discount Rate 3 in Currency & Discount Parameter'
WHERE VariableName = 'Indicators.NPV.WACC'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'This is Discount Rate 4 in Currency & Discount Parameter'
WHERE VariableName = 'Indicators.NPV.HR'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'DPI is defined by dividing the NPV by the discounted cumulative CAPEX excluding abandonment (discounting for both at country WACC).'
WHERE VariableName = 'Indicators.DPI.WACC'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'The payback period is based on the discounted accumulated project cash flow using the country WACC expressed in years'
WHERE VariableName = 'Indicators.Payback WACC'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'It is calculated by dividing the gross OPEX by the gross production (excluding inerts) of the field throughout the calculation period.'
WHERE VariableName = 'Indicators.Per BOE.Opex per BOE'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'It is calculated by dividing the gross CAPEX (excluding abandonment) by the gross production (excluding inerts) of the field throughout the calculation period.'
WHERE VariableName = 'Indicators.Per BOE.Capex wo Abex per BOE'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Adjustments for correction between RED/RAAS.  This is a Finance input so not from PSE'
WHERE VariableName = 'Resources.RAAS.Revisions.Oil'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Adjustments for correction between RED/RAAS.  This is a Finance input so not from PSE'
WHERE VariableName = 'Resources.RAAS.Revisions.Gas'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Adjustments for correction between RED/RAAS.  This is a Finance input so not from PSE'
WHERE VariableName = 'Resources.RAAS.Revisions.LPG'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Adjustments for correction between RED/RAAS.  This is a Finance input so not from PSE'
WHERE VariableName = 'Resources.RAAS.Revisions.Condensate'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Gross production volume post Economic Limit Truncation'
WHERE VariableName = 'Production.Liquids.Total.Volume.Truncated'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Entitlement available for sales (net)'
WHERE VariableName = 'Production.Liquids.Total.Volume.Truncated.Net'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Gross production volume incl. fuel post Economic Limit Truncation'
WHERE VariableName = 'Production.Gas.Total.Volume.Truncated'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Entitlement available for sales (net) + fuel gas consumed in ops (net)'
WHERE VariableName = 'Production.Gas.Total.Volume.Truncated.Net'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'R/T = Gross volume excl fuel x WI.  PSCs = entitlement volume derived from economic interest method of $ enitlement/price plus grossed up tax bbls where relevant.'
WHERE VariableName = 'Production.Total.Oil.Entitlement.Net'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'R/T = Gross volume excl fuel x WI.  PSCs = entitlement volume derived from economic interest method of $ enitlement/price plus grossed up tax bbls where relevant.'
WHERE VariableName = 'Production.Total.LPG.Entitlement.Net'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'R/T = Gross volume excl fuel x WI.  PSCs = entitlement volume derived from economic interest method of $ enitlement/price plus grossed up tax bbls where relevant.'
WHERE VariableName = 'Production.Total.Condensate.Entitlement.Net'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'R/T = Gross volume excl fuel x WI.  PSCs = entitlement volume derived from economic interest method of $ enitlement/price plus grossed up tax bbls where relevant.'
WHERE VariableName = 'Production.Total.Gas.NonAssoc.Entitlement.Net'

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'R/T = Gross volume excl fuel x WI.  PSCs = entitlement volume derived from economic interest method of $ enitlement/price plus grossed up tax bbls where relevant.'
WHERE VariableName = 'Production.Total.Gas.Assoc.Entitlement.Net'

-- Royalties
PRINT 'Royalties Liabilities'
UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Royalty.Oil.Liability.Net'
,Prompt = 'Royalties Oil Liability (Net)'
,Comments = 'Royalties Expense. Booked to P&L'
WHERE VariableName = 'Royalties.Oil.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Royalty.Gas.Liability.Net'
,Prompt = 'Royalties Gas Liability (Net)'
,Comments = 'Royalties Expense. Booked to P&L'
WHERE VariableName = 'Royalties.Gas.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.New Zealand.Resources.Input.Gas.AssocGas'
,Prompt = 'NZL Associated Gas (Gross)'
,Comments = 'NZL Associated Gas (Gross)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|MSCF|MMSCF|BSCF|1000|1|0.001|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05'
WHERE VariableName = 'CTY.Kurdistan.Resources.Input.Gas.AssocGas'

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.New Zealand.Resources.Input.Gas.AssocGas.Fuel'
,Prompt = 'NZL Associated Gas Fuel (Gross)'
,Comments = 'NZL Associated Gas Fuel (Gross)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|MSCF|MMSCF|BSCF|1000|1|0.001|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05'
WHERE VariableName = 'CTY.Kurdistan.Resources.Input.Gas.AssocGas.Fuel'

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.New Zealand.Resources.Input.Gas.NonAssocGas'
,Prompt = 'NZL Non-Associated Gas (Gross)'
,Comments = 'NZL Non-Associated Gas (Gross)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|MSCF|MMSCF|BSCF|1000|1|0.001|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05'
WHERE VariableName = 'CTY.Kurdistan.Resources.Input.Gas.NonAssocGas'

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.New Zealand.Resources.Input.Gas.NonAssocGas.Fuel'
,Prompt = 'NZL Non-Associated Gas Fuel (Gross)'
,Comments = 'NZL Non-Associated Gas Fuel (Gross)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|MSCF|MMSCF|BSCF|1000|1|0.001|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05'
WHERE VariableName = 'CTY.Kurdistan.Resources.Input.Gas.NonAssocGas.Fuel'

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.New Zealand.Resources.Input.Gas.AssocGas.Net'
,Prompt = 'NZL Associated Gas (Net)'
,Comments = 'NZL Associated Gas (Net)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|MSCF|MMSCF|BSCF|1000|1|0.001|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05'
WHERE VariableName = 'CTY.Kurdistan.Resources.Input.Gas.AssocGas.Net'

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.New Zealand.Resources.Input.Gas.AssocGas.Fuel.Net'
,Prompt = 'NZL Associated Gas Fuel (Net)'
,Comments = 'NZL Associated Gas Fuel (Net)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|MSCF|MMSCF|BSCF|1000|1|0.001|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05'
WHERE VariableName = 'CTY.Kurdistan.Resources.Input.Gas.AssocGas.Fuel.Net'

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.New Zealand.Resources.Input.Gas.NonAssocGas.Net'
,Prompt = 'NZL Non-Associated Gas (Net)'
,Comments = 'NZL Non-Associated Gas (Net)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|MSCF|MMSCF|BSCF|1000|1|0.001|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05'
WHERE VariableName = 'CTY.Kurdistan.Resources.Input.Gas.NonAssocGas.Net'

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.New Zealand.Resources.Input.Gas.NonAssocGas.Fuel.Net'
,Prompt = 'NZL Non-Associated Gas Fuel (Net)'
,Comments = 'NZL Non-Associated Gas Fuel (Net)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|MSCF|MMSCF|BSCF|1000|1|0.001|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05|E3Sm3|E6Sm3|E9Sm3|28.3168199078571|0.0283168199078571|2.83168199078571E-05'
WHERE VariableName = 'CTY.Kurdistan.Resources.Input.Gas.NonAssocGas.Fuel.Net'

-- Bulgaria

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Bulgaria.Resources.Input.Liquids.Condensate'
,Prompt = 'BGR Condensate (Gross)'
,Comments = 'BGR Condensate (Gross)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|Bbl|MSTB|MMSTB|1000|1|0.001|T|MT|MMT|98.6485153398441|0.0986485153398441|9.86485153398441E-05|Bbl|MSTB|MMSTB|1000|1|0.001'
WHERE VariableName = 'CTY.Kazakhstan.Resources.Input.Liquids.Condensate' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Bulgaria.Resources.Input.Liquids.LPG'
,Prompt = 'BGR LPG (Gross)'
,Comments = 'BGR LPG (Gross)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|Bbl|MSTB|MMSTB|1000|1|0.001|T|MT|MMT|98.6485153398441|0.0986485153398441|9.86485153398441E-05|Bbl|MSTB|MMSTB|1000|1|0.001'
WHERE VariableName = 'CTY.Kazakhstan.Resources.Input.Liquids.LPG' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Bulgaria.Resources.Input.Liquids.Condensate.Net'
,Prompt = 'BGR Condensate (Net)'
,Comments = 'BGR Condensate (Net)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|Bbl|MSTB|MMSTB|1000|1|0.001|T|MT|MMT|98.6485153398441|0.0986485153398441|9.86485153398441E-05|Bbl|MSTB|MMSTB|1000|1|0.001'
WHERE VariableName = 'CTY.Kazakhstan.Resources.Input.Liquids.Condensate.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'CTY.Bulgaria.Resources.Input.Liquids.LPG.Net'
,Prompt = 'BGR LPG (Net)'
,Comments = 'BGR LPG (Net)'
,Label = 'Custom'
,CustomUnit = 'False|1|0|0|Bbl|MSTB|MMSTB|1000|1|0.001|T|MT|MMT|98.6485153398441|0.0986485153398441|9.86485153398441E-05|Bbl|MSTB|MMSTB|1000|1|0.001'
WHERE VariableName = 'CTY.Kazakhstan.Resources.Input.Liquids.LPG.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Tax.ERT.Net'
,Comments = 'Environmental Taxes, Sales Taxes etc.'
WHERE VariableName = 'CTY.KAZ.Tax.ERT.Net' 

UPDATE DATAFLOW.VariableDefinition
SET VariableName = 'Tax.ECD.Net'
,Comments = 'Export Customs Duty, Export Duty etc.'
WHERE VariableName = 'CTY.KAZ.Tax.ECD.Net' 

-- Abandonment variables tooltips

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Input in first available year.  Salvage/Scrap value estimate on disposal of abandoned infrastructure taken to shore (input in positive numbers)'
WHERE VariableName = 'Capital.Expenditure.Abandonment.Salvage' 

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Input in first available year.  Salvage/Scrap value estimate on disposal of abandoned infrastructure taken to shore (input in positive numbers)'
WHERE VariableName = 'Capital.Expenditure.Abandonment.Salvage.Net' 

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Input in expected year of cash inflow.  Salvage/scrap value estimate on disposal of abandoned infrastructure taken to shore (input in positive numbers)'
WHERE VariableName = 'Capital.Expenditure.Abandonment.Salvage.Fixed' 

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Input in expected year of cash inflow.  Salvage/scrap value estimate on disposal of abandoned infrastructure taken to shore (input in positive numbers)'
WHERE VariableName = 'Capital.Expenditure.Abandonment.Salvage.Fixed.Net' 

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Total ABANDONMENT excluding salvage/scrap values'
WHERE VariableName = 'Capital.Expenditure.Abandonment.Total' 

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Total ABANDONMENT (Net) excluding salvage/scrap values'
WHERE VariableName = 'Capital.Expenditure.Abandonment.Total.Net' 

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Operational Efficiency (input in negative numbers)'
WHERE VariableName = 'Opcosts.ProductionCosts.OperationalEfficiency' 

UPDATE DATAFLOW.VariableDefinition
SET Comments = 'Operational Efficiency (Net) (input in negative numbers)'
WHERE VariableName = 'Opcosts.ProductionCosts.OperationalEfficiency.Net' 


-- ROU Variables
UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Oil (Gross)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Liquids.Oil'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Condensate (Gross)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Liquids.Condensate'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU LPG (Gross)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Liquids.LPG'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Associated Gas (Gross)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Gas.AssocGas'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Associated Gas Fuel (Gross)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Gas.AssocGas.Fuel'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Non-Associated Gas (Gross)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Gas.NonAssocGas'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Non-Associated Gas Fuel (Gross)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Gas.NonAssocGas.Fuel'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Oil (Net)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Liquids.Oil.Net'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Condensate (Net)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Liquids.Condensate.Net'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU LPG (Net)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Liquids.LPG.Net'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Associated Gas (Net)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Gas.AssocGas.Net'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Associated Gas Fuel (Net)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Gas.AssocGas.Fuel.Net'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Non-Associated Gas (Net)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Gas.NonAssocGas.Net'

UPDATE DATAFLOW.VariableDefinition
SET Prompt = 'ROU Non-Associated Gas Fuel (Net)'
WHERE VariableName = 'CTY.Romania.Resources.Input.Gas.NonAssocGas.Fuel.Net'














