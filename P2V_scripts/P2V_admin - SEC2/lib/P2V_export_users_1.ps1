#-----------------------------------------------
#   export  userlists for all TENANTS
#
#  name:   P2V_export_users.ps1
#  ver:    1.0
#  author: M.Kufner
#-----------------------------------------------
param(
  [string]$tenant=""
  )
#-------------------------------------------------

$user=$env:UserDomain+"/"+$env:UserName

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#-------------------------------------------------
#  Set config variables

$output_path = $output_path_base + "\$My_name"

$w_file      = $output_path + "\Myuserworkgroup.csv"
$u_file     = $output_path + "\Myusers.csv"
$u_w_file    = $output_path + "\Myusers-WG-assign.csv"
$ad_file     = $output_path + "\All_AD_users.csv"
$all_u_export= $dashboard_path + "\all_users.csv"
$all_g_export= $dashboard_path + "\all_groups.csv"
$all_u_w_export = $dashboard_path + "\all_user_groups.csv"

#-------------------------------------------------

#layout

P2V_header -app $My_name -path $My_path


$form1 -f "cleaning up output ..."
createdir_ifnotexists ($output_path)

Delete-ExistingFile -file_to_delete $u_file  -verbose $true
Delete-ExistingFile -file_to_delete $w_file  -verbose $true
Delete-ExistingFile -file_to_delete $all_u_export  -verbose $true
Delete-ExistingFile -file_to_delete $all_g_export  -verbose $true
Delete-ExistingFile -file_to_delete $all_u_w_export  -verbose $true


foreach($f in @($all_u_w_export ,$u_file,$w_file, $all_u_export,$all_g_export)) {Delete-ExistingFile($f, $true)}
#@($all_u_w_export,$u_file,$w_file, $all_u_export,$all_g_export)|% {Delete-ExistingFile($_ , $true)}

Add-Content -Path $all_u_export -Value 'tenant,id,displayName,logOnId,authenticationMethod,domain,accountExpirationDate,isDeactivated,isAccountLocked,description,authenticationType,enforcePasswordPolicy,enforcePasswordExpiration,userMustChangePassword,userCanChangePassword,isAdministrator,isInAdministratorGroup,emailAddress,useADEmailAddress,changePassword,password,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups,apiKey'
Add-Content -Path $all_g_export -Value 'tenant,id,name,description,comments,isEveryoneWorkgroup,isAdministratorWorkgroup,users,allowedRoles,deniedRoles'
Add-Content -Path $all_u_w_export -Value 'tenant,logOnId,displayName,workgroup'


#-------------
# start

$linesep
$form1 -f "exporting users and groups from AUCERNA Planningspace"
$linesep
$form1 -f "Contacting  tenants:"

$all_systems = @()
$all_systems =import-csv $tenantfile 

foreach ($i in $all_systems)
{
      $count_ug=0            # counter for user <-> workgroup assignments
      $form1 -f "--> $($i.tenant)"
      
	  $authURL    ="$($i.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
      $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
      $t_group = "$output_path\$($i.tenant)-groups.csv"
	  Delete-ExistingFile($t_group)
      # retrieve workgroups    
      $ps_groups=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/workgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      if (!$ps_groups) {write-host -ForegroundColor Red "    cannot contact $i !" ;break}   
      $form1 -f "  [$($ps_groups.count)] groups loaded"
	  	  
	  Add-Content -Path $t_group -Value 'id,name,description,comments,isEveryoneWorkgroup,isAdministratorWorkgroup,users,allowedRoles,deniedRoles'
      $ps_groups| Foreach-object { 
		Add-Content -Path $t_group -Value ("$($_.id),$($_.name),$($_.description),$($_.comments),$($_.isEveryoneWorkgroup),$($_.isAdministratorWorkgroup),$($_.users),$($_.allowedRoles),$($_.deniedRoles)")   
		Add-Content -Path $all_g_export -Value ("$($i.tenant),$($_.id),$($_.name),$($_.description),$($_.comments),$($_.isEveryoneWorkgroup),$($_.isAdministratorWorkgroup),$($_.users),$($_.allowedRoles),$($_.deniedRoles)")   
		}

      # retrieve users 
	  $t_users = "$output_path\$($i.tenant)-users.csv"
	  Delete-ExistingFile($t_users)
	  Add-Content -Path $t_users -Value 'id,displayName,logOnId,authenticationMethod,domain,accountExpirationDate,isDeactivated,isAccountLocked,description,authenticationType,enforcePasswordPolicy,enforcePasswordExpiration,userMustChangePassword,userCanChangePassword,isAdministrator,isInAdministratorGroup,emailAddress,useADEmailAddress,changePassword,password,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups,apiKey'
      $ps_users=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      if (!$ps_users) { $form1 -f "[ERROR]: cannot get users from $i !" ;break}   
      
      $form1 -f "  [$($ps_users.count)] users loaded"
      
      #$ps_users | Foreach-object { Add-Content -Path $all_u_export -Value ("$($i.tenant),$($_.id),$($_.displayName),$($_.logOnId),$($_.authenticationMethod),$($_.domain),$($_.accountExpirationDate),$($_.isDeactivated),$($_.isAccountLocked),$($_.description),$($_.authenticationType),$($_.enforcePasswordPolicy),$($_.enforcePasswordExpiration),$($_.userMustChangePassword),$($_.userCanChangePassword),$($_.isAdministrator),$($_.isInAdministratorGroup),$($_.emailAddress),$($_.useADEmailAddress),$($_.changePassword),$($_.password),$($_.lastLogin),$($_.accountLockedDate),$($_.deactivatedDate),$($_.userWorkgroups),$($_.apiKey)")   }
      
      $count_u=0;
      Foreach ($u in $ps_users)
      { 
        Add-Content -Path $t_users -Value ("$($u.id),$($u.displayName),$($u.logOnId),$($u.authenticationMethod),$($u.domain),$($u.accountExpirationDate),$($u.isDeactivated),$($u.isAccountLocked),$($u.description),$($u.authenticationType),$($u.enforcePasswordPolicy),$($u.enforcePasswordExpiration),$($u.userMustChangePassword),$($u.userCanChangePassword),$($u.isAdministrator),$($u.isInAdministratorGroup),$($u.emailAddress),$($u.useADEmailAddress),$($u.changePassword),$($u.password),$($u.lastLogin),$($u.accountLockedDate),$($u.deactivatedDate),$($u.userWorkgroups),$($u.apiKey)")       
		
		Add-Content -Path $all_u_export -Value ("$($i.tenant),$($u.id),$($u.displayName),$($u.logOnId),$($u.authenticationMethod),$($u.domain),$($u.accountExpirationDate),$($u.isDeactivated),$($u.isAccountLocked),$($u.description),$($u.authenticationType),$($u.enforcePasswordPolicy),$($u.enforcePasswordExpiration),$($u.userMustChangePassword),$($u.userCanChangePassword),$($u.isAdministrator),$($u.isInAdministratorGroup),$($u.emailAddress),$($u.useADEmailAddress),$($u.changePassword),$($u.password),$($u.lastLogin),$($u.accountLockedDate),$($u.deactivatedDate),$($u.userWorkgroups),$($u.apiKey)")  
		
        $id=$($u.id)
        show_progress ($count_u++) 
        # foreach ($gs in $($u.userWorkgroups))
        # {
            # $hash = @{}
            # $gs | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($gs | SELECT -exp $_) }
            # foreach($wg in ($hash.Values | Sort-Object -Property Name))
            # {
                # Add-Content -Path $all_u_w_export -Value ($i.tenant + "," + $u.logOnId + "," + $u.displayname + "," + $($wg.name))
                # $count_ug++
            # }
			
        # }    
		$usr_groups=Invoke-RestMethod -Uri "$tenantURL//PlanningSpace/api/v1/users/commonworkgroups?ids=$id" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
		
		
      }
      $form1 -f "  [$count_ug] user-workgroup assignments loaded"
    }
$linesep
$form1 -f "storing data in"
$form1 -f $output_path

P2V_footer -app $My_name

# ----- end of file -----

