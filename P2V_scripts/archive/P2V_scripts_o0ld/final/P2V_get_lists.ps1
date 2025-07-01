#-----------------------------------------
# Export P2V  users, workgroups, roles
#
#  name:   P2V_get_lists.ps1 
#  ver:    1.0
#  author: M.Kufner
#
# arguments:
# $tenant =  Tenant to work on 
# 
#-----------------------------------------
param(
  [string]$tenant=""
  )
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path

If (!$tenant)
{
" 
missing argument:  -tenant 

correct usage:  $My_name  -tenant xxx
     xxx ... existing tenant
"
exit
}

. "$workdir/P2V_include.ps1"

#----- Set config variables 

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir + "\output\AD-groups"
$u_file= $output_path + "\P2V_userlist.csv"
$w_file= $output_path + "\P2V_workgrouplist.csv"
$r_file= $output_path + "\P2V_roleslist.csv"

#-------------------------------------------------
#layout
#P2V_layout 
cls
P2V_header -app $My_name -path $My_path 


$all_systems = @()
#  for testing purposes - only DEMO
$all_systems =import-csv $tenantfile| where-object {$_.tenant -eq $tenant }
if (!$all_systems) {$form_err -f "[ERROR]"," Tenant $tenant does not exist";$linesep;exit}


Delete-ExistingFile($u_file)
Delete-ExistingFile($w_file)
Delete-ExistingFile($r_file)

 foreach ($i in $all_systems)
  {
    $form1 -f "--> $($i.tenant) <--"
     	   
	$authURL    ="$($i.ServerURL)/identity/connect/token"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
    $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
	
	$u_result=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
	
	if (!$u_result) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
	
	#$u_result |format-table 
	$form1 -f "export to $u_file"
	$u_result |export-csv -path $u_file
	$c=$u_result.count
	$form_status -f "exporting $c users", "[DONE]"
	$linesep
	
	$r_result=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/roles?include=allowedWorkgroups&include=deniedWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
	
	if (!$r_result) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
	
	#r_result |format-table 
	$form1 -f "export to $r_file"
	$r_result |export-csv -path $r_file
	$c=$r_result.count
	$form_status -f "exporting $c roles", "[DONE]"
	$linesep
	
	$w_result=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/workgroups?include=users&include=allowedRoles" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
	
	if (!$w_result) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
	#$w_result |format-table
	$form1 -f "export to $u_file"
	$w_result |export-csv -path $w_file
    $c=$w_result.count
	$form_status -f "exporting $c workgroups", "[DONE]"
	$linesep
	

    

	
	}
	
	
exit	
	
#
