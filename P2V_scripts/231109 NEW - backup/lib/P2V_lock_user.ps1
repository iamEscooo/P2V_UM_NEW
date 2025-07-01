#-----------------------------------------
# check_locked_user 
#
#  name:   check_locked_user.ps1 
#  ver:    1.0  /2020-04-20
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $xkey =  xkey to search
# $long =  false (default)   - short summary 
# $long =  true              - all AD entries
#-----------------------------------------
param(
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  [bool]$checkOnly = $False
)
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#----- Set config variables

$output_path = $output_path_base + "\$My_name"

#------ start main part
P2V_header -app $My_name -path $My_path 

if(!$tenant) {$t_result= P2V_get_tenant($tenantfile)}
$tenant=$t_result.tenant

if (!($u_result= P2V_get_AD_user_UI($user))) {exit}
$user =  $u_result.Name
$UPN  =  $u_result.UserPrincipalName
if ((!$user) -or (!$tenant)) {
" 
[ERROR]: missing argument(s)  

correct usage:  
$My_name  -user  uuu -tenant ttt  [-lock l] [-deactivate d] [-checkonly c]

     uuu ... existing x-key
     ttt ... existing tenant
  optional
       l ... TRUE to lock  / FALSE to unlock 
       d ... TRUE to deactivate / FALSE to activate
       c ... TRUE : only check status / FALSE change settings (default:FALSE)
"
exit
}

$form1 -f "set [$user] in  [$tenant] to lock:[$lock] and deactivate:[$deactivate]"

     
#----- check whether xkey is member of workgroups in P2V
    $linesep
    $form1 -f "checking P2V Planningspace user account for"
    $form2 -f $user, $UPN
	$linesep
   
    foreach ($i in $t_result)
    {
      $form1 -f "--> $($i.tenant) <--"
     	   
	  $authURL    ="$($i.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
      $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
       
      $updateOperations = @{}
	  $updateUserOperations =@()
    # retrieve all users incl. workgroups
      $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      if (!$resp) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
      $resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
	  $resp=$resp |Where { ($_.authenticationMethod -ne "LOCAL") } # get non-local users
      
      foreach ($r in $resp)
      {
		 #P2V_print_user($r)
		 $r |select id,logonid,displayname,isaccountlocked,isdeactivated|format-table
		 	      
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
		 
	     if (!$checkOnly)
		 {
	        $linesep
			$form1 -f "changing userprofile"
			$linesep
		 
		    $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
			
            $result
		   
		    $check=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/$($r.id)" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"} 
		    
			#P2V_print_user($check)
			$check |select id,logonid,displayname,isaccountlocked,isdeactivated|format-table
		    
         }		 
       }
       $linesep
   }
 
  #write-host  -ForegroundColor yellow $linesep
# end while
exit


