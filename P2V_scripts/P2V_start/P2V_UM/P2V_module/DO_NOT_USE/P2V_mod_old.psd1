@{
	RootModule 				= 'P2V_Module.psm1' 
	ModuleVersion 			= '0.0.1' 
	CompatiblePSEditions 	= 'Desktop', 'Core' 
	Author 					= 'Martin Kufner' 
	GUID                    = 'b4498883-71f1-49d5-ab3e-5427955ec2bf'
	CompanyName 			= 'OMV'
	PowerShellVersion       = '5.1'
	RequiredModules			=  @()
	Copyright 				= '(c) Martin Kufner. All rights reserved.' 
	Description 			= 'P2V dialog functions'
	FunctionsToExport 		= 'ask_continue','ask_YesNoAll','get_AD_user_GUI','my_init'
	CmdletsToExport 		= @() 
	VariablesToExport 		= 'my_new_variable','My_name'
	AliasesToExport 		= @() 
	PrivateData 			= @{
	PSData 					= @{} 
	} 
}