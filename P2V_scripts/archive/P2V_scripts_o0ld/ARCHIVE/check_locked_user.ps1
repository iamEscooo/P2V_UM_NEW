#-----------------------------------------
# check_locked_user 
#
#  name:   check_locked_user.ps1 
#  ver:    0.1
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $xkey =  xkey to search
# $long =  false (default)   - short summary 
# $long =  true              - all AD entries
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string]$user="<no user>",
  [string]$tenant="<no tenant>",
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  #[bool]$toggle=$True,
  [bool]$analyzeOnly = $False
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
$output_path = $workdir + "\output\AD-groups"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

#-------------------------------------------------
#layout
#P2V_layout 
cls
P2V_header -app $My_name -path $My_path 

$form1 -f "set [$user] in  [$tenant] to lock:[$lock] and deactivate:[$deactivate]"

$all_systems = @()
#  for testing purposes - only DEMO
$all_systems =import-csv $tenantfile| where-object {$_.tenant -eq $tenant }
if (!$all_systems) {$form_err -f "[ERROR]"," Tenant $tenant does not exist"}
else

#----- start main part

#While (($user= Read-Host -Prompt ' >>> Input the user name (0=exit)') -ne "0") 
{
  $result=@()
  #---- check whether xkey exists in AD and retrieve core information
  $result=Get-ADUser -Filter {Name -like $user} -properties *|select Name,UserPrincipalName,Enabled,PasswordExpired ,LockedOut,lockoutTime
  if(!$result)
  { 
    $form_err -f "[ERROR]", "[$user] does not exist in Active Directory !!" 
  }	
  else
  {
    # $result  # print AD result
    $user =  $result.Name
	$UPN  =  $result.UserPrincipalName
    
#----- check whether xkey is member of workgroups in P2V
    $linesep
    $form1 -f "checking P2V Planningspace user profile for"
    $form2 -f $user, $UPN
	$linesep
   
	
    foreach ($i in $all_systems)
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
		 P2V_userprofile($r)
		 #$linesep
	     #$form4 -f "$($r.id)","$($r.displayName)","$($r.logOnId)",""
		 #if ($r.isDeactivated) {$state="deactivated"} else {$state="active"}
		 #$form2_1 -f "isDeactivated :" ,"[$state]"
		 #if ($r.isAccountLocked) {$state="locked"} else {$state="free"}
		 #$form2_1 -f "isAccountLocked :" ,"[$state]"
		 
		 #$form2_1 -f "isDeactivated :" ,"[$($r.isDeactivated)]"
		 #$form2_1 -f "isAccountLocked :" ,"[$($r.isAccountLocked)]"
		 #$form2_1 -f "lastLogin :" ,"[$($r.lastLogin)]"
		 
		 
         #toggle stat isDeactivated, isAccountLocked
         #if ($toggle){$val1=!$r.isDeactivated;$val2=!$r.isAccountLocked}
		 #else        {
		 $val1=$deactivate 
		 $val2=$lock
 
         $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isDeactivated"
                    value = $val1
               }
	 
	     $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isAccountLocked"
                    value = $val2
               }
	     
		 if ($r.authenticationMethod -eq "WINDOWS_AD")
		 {
		    $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/authenticationMethod"
                    value = "SAML2"
               }
	        $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/domain"
                    value = ""
               }
	        $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/useADEmailAddress"
                    value = "False"
               }
	        $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/logOnId"
                    value = $UPN
               }
	      }
    
		  if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$r.id.ToString()] = $updateUserOperations                
            }  
	     $updateOperations |convertto-Json
		 
	     if (!$analyzeOnly)
		 {
	        $form1 -f "changing userprofile"
		 
		    $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
			
            $result
         }		 
       }
       $linesep
     }
   } 
  #write-host  -ForegroundColor yellow $linesep
} # end while
P2V_footer


