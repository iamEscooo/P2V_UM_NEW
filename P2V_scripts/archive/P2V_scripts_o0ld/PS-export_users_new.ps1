#-----------------------------------------------
#   export  userlists for all TENANTS
#
#
#-----------------------------------------------
param(
    [string]$tenantfile="\\somvat202005\PPS_Share\P2V_scripts\config\all_tenants.csv",
    [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
    [bool]$analyzeOnly = $True
)
#  Set path for temp userlists
$output_path = $workdir + "\output\PS-users1"
$all_u_export= $output_path + "\all_users.csv"
$all_g_export= $output_path + "\all_groups.csv"

if (Test-Path $all_u_export) {Remove-Item $all_u_export}
Add-Content -Path $all_u_export -Value 'tenant,id,displayName,logOnId,authenticationMethod,domain,accountExpirationDate,isDeactivated,isAccountLocked,description,authenticationType,enforcePasswordPolicy,enforcePasswordExpiration,userMustChangePassword,userCanChangePassword,isAdministrator,isInAdministratorGroup,emailAddress,useADEmailAddress,changePassword,password,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups,apiKey'
if (Test-Path $all_g_export) {Remove-Item $all_g_export}
Add-Content -Path $all_g_export -Value 'tenant,id,name,description,comments,isEveryoneWorkgroup,isAdministratorWorkgroup,users,allowedRoles,deniedRoles'

#-------------
# Web-API
# set Web-API connectivity



#-------------
# start
cls                                                                                                    
$date= Get-Date

Write-Host "
+---------------------------------------------------------+
|  exporting users and groups from AUCERNA Planningspace  |
|                                                         |
|  started at $date                         |
+---------------------------------------------------------+

 Contacting  tenants:
"
$all_systems = @()
$all_systems =import-csv $tenantfile 

foreach ($i in $all_systems)
{

      $out        =" --- {0,-15} ---" -f $($i.tenant)
	  $authURL    ="$($i.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
      $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
          
      write-host -ForegroundColor yellow "$out"
   
      # retrieve users 
      $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      if (!$resp) {write-host -ForegroundColor Red "    cannot contact $i !" ;break}   
    
      $resp | Export-Csv "$output_path\$($i.tenant)-users.csv" 
   
      $out="[{0,3}] users, " -f $resp.count
      write-host -NoNewline $out
      
      $resp | Foreach-object { Add-Content -Path $all_u_export -Value ("$($i.tenant),$($_.id),$($_.displayName),$($_.logOnId),$($_.authenticationMethod),$($_.domain),$($_.accountExpirationDate),$($_.isDeactivated),$($_.isAccountLocked),$($_.description),$($_.authenticationType),$($_.enforcePasswordPolicy),$($_.enforcePasswordExpiration),$($_.userMustChangePassword),$($_.userCanChangePassword),$($_.isAdministrator),$($_.isInAdministratorGroup),$($_.emailAddress),$($_.useADEmailAddress),$($_.changePassword),$($_.password),$($_.lastLogin),$($_.accountLockedDate),$($_.deactivatedDate),$($_.userWorkgroups),$($_.apiKey)")   }
   
      # get workgroups
    
      $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/workgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
    
      $resp | Export-Csv "$output_path\$($i.tenant)-groups.csv" 
      $out="[{0,3}] groups, " -f $resp.count
      write-host -NoNewline "$out "
    
      $resp | Foreach-object { Add-Content -Path $all_g_export -Value ("$($i.tenant),$($_.id),$($_.name),$($_.description),$($_.comments),$($_.isEveryoneWorkgroup),$($_.isAdministratorWorkgroup),$($_.users),$($_.allowedRoles),$($_.deniedRoles)")   }
    write-host -ForegroundColor Green "[done]"
    }

$date= Get-Date

write-host " 
 data storing in 
 $output_path
+---------------------------------------------------------+
|   finished at $date                       |
+---------------------------------------------------------+"

# ----- end of file -----

