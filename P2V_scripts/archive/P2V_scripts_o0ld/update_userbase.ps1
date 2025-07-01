#---------------------
#  update_userbase.ps1
#
#  synchronize AD -users
#---------------------
#  V 0.1
#  
#
#  
#---------------------
param(
  [string]$user="<no user>",
  [string]$tenant="<no tenant>",
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  #[bool]$toggle=$True,
  [bool]$analyzeOnly = $True
)
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path
. "$workdir/P2V_include.ps1"

#----- Set config variables

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$allowedfile = $config_path + "\allowed_users.csv"
$output_path = $workdir + "\output\AD-groups"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

#-------------------------------------------------
#layout
#P2V_layout 
cls
P2V_header -app $My_name -path $My_path 


$all_systems = @()

#--- start main part

# 1-  select  P2V- system

$all_systems =import-csv $tenantfile
if (!$all_systems) {$form_err -f "[ERROR]"," Tenant $tenant does not exist"; exit }
$t_list=@()
foreach ($a in $all_systems){ $t_list+=$a.tenant }
P2V_Show-Menu -Title "select tenant" -menu $t_list

do {
$input = Read-Host "Please select a tenant"

switch ($input)
{
	'q'	{exit}
	'Q'	{exit}
	default  { 
	     if ($input -in 1..$t_list.count )
	       {$tenant=$t_list[$input-1]}
	     else
		   {"wrong input" }
	}
}
}until ($input -in 1..$t_list.count )


if ($True)
{
  $form_err -f $input, $t_list[$input-1]
}else{break;}

$tenant=$t_list[$input-1]
$form2 -f "[stage1]", "[done]"
# 2-  read all users from selected tenant

$i= $all_systems |where-object {$_.tenant -eq $tenant }
$authURL    ="$($i.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
$tenantURL  ="$($i.ServerURL)/$($i.tenant)"
 # retrieve all users incl. workgroups
$ps_users=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if (!$ps_users) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
$c=$ps_users.count
$form2 -f "[stage2]", "$c P2V users loaded [done]"
# 3-  retrieve all AD users from relevant group

$allowed_groups = import-csv $allowedfile 
$allowed_groups  = $allowed_groups | where-object { $_.tenant -like $tenant }
$allowed_groups
$ad_users = @()
foreach ($t in $allowed_groups) {

$ad_users+=Get-ADGroupMember -Identity $($t.ADgroup)| Get-ADUser -properties * |select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress						
	
}
$c=$ad_users.count

$ad_users = $ad_users | sort -uniq

$ad_users |format-table
#Get-ADUser -Filter {(Name -like $search1) -or (UserPrincipalName -like $search1)} -properties *|select Name,UserPrincipalName,Departmentll users from AD-groups (allowed to see system)
 # retrieve all users incl. workgroups
$form2 -f "[stage3]", "$c AD users loaded [done]"

# 4-  if user from AD allowed group does not exist in P2V tenant -> create
#     if user from AD does exist in P2V -> unlock / activate
#     if user from P2v does not exist in "allowed AD group" -> lock account in tenant
$form2 -f "[stage4]", "[done]"
# 5- statistics  + end
$form2 -f "[stage5]", "[done]"
