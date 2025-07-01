#-----------------------------------------
# P2V_lock_allusers 
#
#  name:   check_locked_user.ps1 
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
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#----- Set config variables
$output_path = $output_path_base + "\$My_name"
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
P2V_header -app $My_name -path $My_path 

if(!$tenant) {$t_result= P2V_get_tenant($tenantfile)}
$tenant=$t_result.tenant

$form1 -f "set all users in  [$tenant] to lock:[$lock] and deactivate:[$deactivate]"

#----- check whether xkey is member of workgroups in P2V

	
foreach ($i in $t_result)
{
    $form1 -f "--> $($i.tenant) <--"
    $linesep
    	   
	$authURL    ="$($i.ServerURL)/identity/connect/token"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
    $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
       
    $updateOperations = @{}
	$updateUserOperations =@()
    # retrieve all users incl. workgroups
    $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
    if (!$resp) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
    # $resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
	$resp=$resp |Where { ($_.authenticationMethod -ne "LOCAL") } # get non-local users
      
	$resp = $resp |where-object {($_.isAccountLocked -ne $lock) -or ($_.isDeactivated -ne $deactivate)}
	$resp | select id, displayName,logOnId,isAccountLocked,isDeactivated |format-table
	 
    foreach ($r in $resp)
    {
	 $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isDeactivated"
                    value = $deactivate
               }
	 
	 $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isAccountLocked"
                    value = $lock
               }
	     
		
		  if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$r.id.ToString()] = $updateUserOperations                
            }  
	     # $updateOperations |convertto-Json
		}
		 
	     if (!$checkOnly)
		 {
	        $linesep
			write-host -nonewline  "changing userprofile(s) "
				 
		    $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
			
			$result |out-host
		   
		#   $check=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/$($r.id)" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"} 
		    
		#	P2V_print_user($check)
		
         }		 
       
      
     }


P2V_footer -app $My_name


