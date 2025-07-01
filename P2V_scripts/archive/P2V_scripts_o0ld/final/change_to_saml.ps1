#-----------------------------------------
# change_to_saml
#
#  name:   change_to_saml.ps1 
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
$output_path = $workdir + "\output\AD-groups"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

#-------------------------------------------------
#layout
#P2V_layout 
cls
P2V_header -app $My_name -path $My_path 



$all_systems = @()
#  for testing purposes - only DEMO
$all_systems =import-csv $tenantfile| where-object {$_.tenant -eq $tenant }
if (!$all_systems) {$form_err -f "[ERROR]"," Tenant $tenant does not exist"}
else
{
#----- start main part
  foreach ($i in $all_systems)
  {
    $form1 -f "--> $($i.tenant) <--"
     	   
	$authURL    ="$($i.ServerURL)/identity/connect/token"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
    $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
       
    $updateOperations = @{}

    # retrieve all users incl. workgroups
    $ps_users=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
    if (!$ps_users) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
	  
	  
    #$resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
	#
	$ps_users=$ps_users |Where { ($_.authenticationMethod -ne "LOCAL") } # get non-local users
	#$ps_users=$ps_users |Where { ($_.authenticationMethod -eq "WINDOWS_AD") } # get only Windows AD users
      
    foreach ($u in $ps_users)
    {
	  # -or (UserPrincipalName -like $u.logOnId))
	  $updateUserOperations =@()
	  $search1=$u.logOnId
	  $ad_users = Get-ADUser -Filter {(Name -like $search1) -or (UserPrincipalName -like $search1)} -properties *|select Name,UserPrincipalName,Department
		  
		  if(!$ad_users)
	      { 
             $form_err -f "[ERROR]", "[$($u.id)][$($u.logOnId)] does not exist in Active Directory !!" 
          }else
	      {	  
		     $updateUserOperations += [PSCustomObject]@{
                 op = "replace"
                 path = "/useADEmailAddress"
                 value = "True"
			 } 
			 $updateUserOperations += [PSCustomObject]@{
                 op = "replace"
                 path = "/EmailAddress"
                 value = ""
			 } 
		     $updateUserOperations += [PSCustomObject]@{
                 op = "replace"
                 path = "/isDeactivated"
                 value = "False"
             }
	 	     $updateUserOperations += [PSCustomObject]@{  
                 op = "replace"
                 path = "/isAccountLocked"
                 value = "False"
             } 
			 $dep=$($ad_users.Department) -replace '[,]', ''
		     $updateUserOperations += [PSCustomObject]@{  
                 op = "replace"
                 path = "/description"
                 value = $dep
             } 
	         switch ($u.authenticationMethod)
		     {
			      'WINDOWS_AD'  
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
                         path = "/logOnId"
                         value = $ad_users.UserPrincipalName
                     }
			     }
			     'SAML2'       
			     {
			                 
			     }
		         'LOCAL'       
			     { }
		 }
	  
		 #P2V_print_user($r)
		 
	
	   
	     if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$u.id.ToString()] = $updateUserOperations                
            }  
			
			

		 
		 
       }
       
     }
	 
	 $updateOperations #|convertto-Json   		 
	 $form1 -f " $($updateOperations.count) profiles to be updated"
	     if (!$analyzeOnly)
		 {

	        $form1 -f "changing $($updateOperations.count) userprofile(s)"
		 
		    $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"

            $result
         }

   } 

   
   
   
   
  #write-host  -ForegroundColor yellow $linesep
} # end while

P2V_footer


