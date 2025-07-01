#-----------------------------------------
# change_to_saml
#
#  name:   P2V_get_roles.ps1 
#  ver:    1.0
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $tenant =  Tenant to work on 
# $lock  =  false (default)   - set accounts to $lock status (true= locked)
# $deactivate =  false (default)  - set accounts to $deactive status (true= deactivated)
# $long =  true              - all AD entries
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string]$user="<no user>",
  [string]$tenant="",
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  #[bool]$toggle=$True,
  [bool]$analyzeOnly = $True
)
#-------------------------------------------------


$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#----- Set config variables
$output_path = $workdir + "\output\$My_name"
createdir_ifnotexists ($output_path)
#-------------------------------------------------

P2V_header -app $My_name -path $My_path 

#-- 1  check tenant /select tenant
if(!$tenant) {$t= P2V_get_tenant($tenantfile)}
$tenant=$t.tenant

$authURL    ="$($t.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t.name, $t.API)))
$tenantURL  ="$($t.ServerURL)/$($t.tenant)"

$all_systems = @()
#  for testing purposes - only DEMO

$all_systems =import-csv $tenantfile  #| where-object {$_.tenant -eq $tenant }
if (!$all_systems) {$form_err -f "[ERROR]"," Tenant $tenant does not exist";exit}

foreach ($i in $all_systems)
  {
    $out_file= $output_path+"\$($i.tenant).csv"  
    Delete-ExistingFile -file_to_delete $out_file -verbose $true
    $form1 -f "--> $($i.tenant) <--"
     	   
	$authURL    ="$($i.ServerURL)/identity/connect/token"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
    $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
	
	$ps_roles=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/roles?include=allowedWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
	
	if (!$ps_roles) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
	
	$ps_roles |export-csv -path $out_file
		
	}
	
	
	
	