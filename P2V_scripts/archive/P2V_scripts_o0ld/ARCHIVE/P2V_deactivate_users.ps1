#-----------------------------------------
# check_locked_user 
#
#  name:   P2V_deactivate_users.ps1 
#  ver:    0.1
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $long =  false (default)   - short summary 
# $long =  true              - all AD entries
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string]$tenant="",
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  [bool]$checkOnly = $False
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
$output_path = $workdir + "\output\$My_name"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

#[ERROR]: missing argument(s)  
#
#correct usage:  
#$My_name  -tenant ttt  [-lock l] [-deactivate d] [-checkonly c]#
#
#    ttt ... existing tenant
#  optional
#       l ... TRUE to lock  / FALSE to unlock 
#       d ... TRUE to deactivate / FALSE to activate
#       c ... TRUE : only check status / FALSE change settings (default:TRUE)
#"

#----- start main part
cls
P2V_header -app $My_name -path $My_path 

if(!$tenant) {$t_sel= P2V_get_tenant($tenantfile)}
$tenant=$t_sel.tenant

$authURL    ="$($t_sel.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
$tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"

#-- select users 

$resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}

$u_sel=$resp |select id,displayName,logOnId,description,isDeactivated,isAccountLocked,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups |out-gridview -title "select user to deactivate" -outputmode multiple

$form1 -f "the following users will be deactivated:"

$u_sel|select id,displayname,description |format-table
#----- check whether xkey is member of workgroups in P2V
$updateOperations = @{}

 foreach ($u in $u_sel)
    {
	   $updateUserOperations =@()
	   $form1 -f "$($u.id) / $($u.displayname) marked for deactivation"
	   $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isDeactivated"
                    value = $True
       }
	   if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$u.id.ToString()] = $updateUserOperations                
            }  
	}
 
		
if (($cont=read-host ($form1 -f "deactivate users? (y/n)")) -like "y")	
{

      $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
			
	 $result |format-list |out-host
}		   
 

P2V_footer -app $My_name

exit
