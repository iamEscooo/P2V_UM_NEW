#-------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
import-module -name "$PSScriptRoot\P2V_config.psd1"    # -verbose
import-module -name "$PSScriptRoot\P2V_include.psd1"    #-verbose
import-module -name "$PSScriptRoot\P2V_dialog_func.psd1" # -verbose 
import-module -name "$PSScriptRoot\P2V_AD_func.psd1" #-verbose
import-module -name "$PSScriptRoot\P2V_PS_func.psd1" #-verbose


#-------------------------------------------------
[System.Windows.Forms.Application]::EnableVisualStyles()


$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$description= "created country node in LIVE version to document cloning date"

# "This script synchronizes one or more user accounts to one or more tenants.`n  The following activities are performed:`n- loading all P2V related AD groups and members`n-select user(s) & tenant(s)### OLD below`n- No new users are added`n- Information of existing users will be updated based on their UPN (=x-key)`n- if users are not entitled anymore (missing AD-group memberships)`n  deactivation is suggested.`n"

P2V_header -app $MyInvocation.MyCommand -path $My_path -description $description



$comment="2023-09-06 0600 cloning from PROD"

$body= [PSCustomObject]@{
  parentId    = 1 
  versionId   = 1 
  nodeTypeId  = 2 
  name        =   "$comment"
}

ask_continue -title "select tenants" -msg "select tenants to set the <cloned on ...> comment " -button 0 -icon 64

$tenants=select_PS_tenants -multiple $true -all $false


foreach ($ts in $tenants.keys)
	{
		$t               = $tenants[$ts]
		$tenant          = $t.tenant
		$tenantURL       = "$($t.ServerURL)/$($t.tenant)"
		$base64AuthInfo  = $t.base64AuthInfo   
		$apiUrl = "$($tenantUrl)/PlanningSpaceDataflow/api/v1/hierarchy/HierarchyNode"	
		
		write-output "adding:"
		write-output (convertto-json ($body))
		write-output $linesep
		#write-output $body
		pause
		write-output "writing ..."
		$check = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body (convertto-json ($body)) -ContentType "application/json"
		write-output "result:"
		if ($check) { write-output ($check|ConvertTo-Json) }$i_result
		
		pause
	}
	

	
		