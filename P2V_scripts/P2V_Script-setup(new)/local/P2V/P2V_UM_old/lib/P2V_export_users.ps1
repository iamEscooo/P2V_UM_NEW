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
$u_file      = $output_path + "\Myusers.csv"
#u_w_file    = $output_path + "\Myusers-WG-assign.csv"
$ad_file     = $output_path + "\All_AD_users.csv"
$all_u_export= $dashboard_path + "\all_users.csv"
$all_g_export= $dashboard_path + "\all_groups.csv"
$all_u_w_export = $dashboard_path + "\all_user_groups.csv"

#-------------------------------------------------

#layout

P2V_header -app $My_name -path $My_path


$form1 -f "cleaning up output ..."
createdir_ifnotexists -check_path $output_path

Delete-ExistingFile -file $u_file  -verbose $true
Delete-ExistingFile -file $w_file  -verbose $true
Delete-ExistingFile -file $all_u_export  -verbose $true
Delete-ExistingFile -file $all_g_export  -verbose $true
Delete-ExistingFile -file $all_u_w_export  -verbose $true


foreach($f in @($all_u_w_export ,$u_file,$w_file, $all_u_export,$all_g_export)) {Delete-ExistingFile $f $true}
#@($all_u_w_export,$u_file,$w_file, $all_u_export,$all_g_export)|% {Delete-ExistingFile($_ , $true)}

Add-Content -Path $all_u_export   -Value 'tenant,id,displayName,logOnId,authenticationMethod,domain,accountExpirationDate,isDeactivated,isAccountLocked,description,authenticationType,enforcePasswordPolicy,enforcePasswordExpiration,userMustChangePassword,userCanChangePassword,isAdministrator,isInAdministratorGroup,emailAddress,useADEmailAddress,changePassword,password,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups,apiKey'
Add-Content -Path $all_g_export   -Value 'tenant,id,name,description,comments,isEveryoneWorkgroup,isAdministratorWorkgroup,users,allowedRoles,deniedRoles'
Add-Content -Path $all_u_w_export -Value 'tenant,logOnId,isDeactivated,displayName,workgroup'


#-------------
# start

$linesep
$form1 -f "exporting users and groups from AUCERNA Planningspace"
$linesep
$form1 -f "Contacting  tenants:"

$t_sel = @{}
$t_cur = @{}

$t_sel = select_PS_tenants

foreach ($t in $t_sel.keys)
{
      $count_ug=0            # counter for user <-> workgroup assignments
	  $t_cur=$t_sel[$t]
	  
	  $ps_groups =@()
	  $ps_groups_array= @{}
	  $ps_users =@()
	  $ps_users_array= @{}
	  		
      $form1 -f "--> $($t_cur.tenant)"
      
	  # retrieve workgroups    
	  if (!($ps_groups = get_PS_grouplist($t_cur)))  { break }
	
      $t_group_out = "$output_path\$($t_cur.tenant)-groups.csv"
	  Delete-ExistingFile -file  $t_group_out
            
	  $ch="[{0,5}]" -f $($ps_groups.count)
	  $form1 -f "$ch groups loaded"
	  	  
	  Add-Content -Path $t_group_out -Value 'id,name,description,comments,isEveryoneWorkgroup,isAdministratorWorkgroup,users,allowedRoles,deniedRoles'
      $ps_groups| %{ 
	     $ps_groups_array[$($_.id)]=$_;
		 #Add-Content -Path $t_group_out -Value                   
		 "$($_.id),$($_.name),$($_.description),$($_.comments),$($_.isEveryoneWorkgroup),$($_.isAdministratorWorkgroup),$($_.users),$($_.allowedRoles),$($_.deniedRoles)"| Out-File $t_group_out -Encoding "UTF8" -Append 
	  }
     $ps_groups| %{ 	  
		#Add-Content -Path $all_g_export -Value 
		 "$($t_cur.tenant),$($_.id),$($_.name),$($_.description),$($_.comments),$($_.isEveryoneWorkgroup),$($_.isAdministratorWorkgroup),$($_.users),$($_.allowedRoles),$($_.deniedRoles)" | Out-File $all_g_export -Encoding "UTF8" -Append 
		}

      # retrieve users 
	  $ps_users = get_PS_userlist($t_cur)
	  #if (!($ps_users = get_PS_userlist($t_cur)))  { break }
	   
	  $t_users_out = "$output_path\$($t_cur.tenant)-users.csv"
	  Delete-ExistingFile($t_users_out)
	  
	  $ch="[{0,5}]" -f $($ps_users.count)
      $form1 -f "$ch users loaded"
	  
	  Add-Content -Path $t_users_out -Value 'id,displayName,logOnId,authenticationMethod,domain,accountExpirationDate,isDeactivated,isAccountLocked,description,authenticationType,enforcePasswordPolicy,enforcePasswordExpiration,userMustChangePassword,userCanChangePassword,isAdministrator,isInAdministratorGroup,emailAddress,useADEmailAddress,changePassword,password,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups,apiKey'
      
      #$ps_users | Foreach-object { Add-Content -Path $all_u_export -Value ("$($i.tenant),$($_.id),$($_.displayName),$($_.logOnId),$($_.authenticationMethod),$($_.domain),$($_.accountExpirationDate),$($_.isDeactivated),$($_.isAccountLocked),$($_.description),$($_.authenticationType),$($_.enforcePasswordPolicy),$($_.enforcePasswordExpiration),$($_.userMustChangePassword),$($_.userCanChangePassword),$($_.isAdministrator),$($_.isInAdministratorGroup),$($_.emailAddress),$($_.useADEmailAddress),$($_.changePassword),$($_.password),$($_.lastLogin),$($_.accountLockedDate),$($_.deactivatedDate),$($_.userWorkgroups),$($_.apiKey)")   }     
    
      Foreach ($u_cur in $ps_users)
      { 
	  	    
	    $ps_users_array[$($u_cur.logOnId)]=$u_cur
        #Add-Content -Path $t_users_out  -Value 
		                 "$($u_cur.id),$($u_cur.displayName),$($u_cur.logOnId),$($u_cur.authenticationMethod),$($u_cur.domain),$($u_cur.accountExpirationDate),$($u_cur.isDeactivated),$($u_cur.isAccountLocked),$($u_cur.description),$($u_cur.authenticationType),$($u_cur.enforcePasswordPolicy),$($u_cur.enforcePasswordExpiration),$($u_cur.userMustChangePassword),$($u_cur.userCanChangePassword),$($u_cur.isAdministrator),$($u_cur.isInAdministratorGroup),$($u_cur.emailAddress),$($u_cur.useADEmailAddress),$($u_cur.changePassword),$($u_cur.password),$($u_cur.lastLogin),$($u_cur.accountLockedDate),$($u_cur.deactivatedDate),$($u_cur.userWorkgroups),$($u_cur.apiKey)"| Out-File $t_users_out -Encoding "UTF8" -Append 
		#Add-Content -Path $all_u_export -Value 
		"$($t_cur.tenant),$($u_cur.id),$($u_cur.displayName),$($u_cur.logOnId),$($u_cur.authenticationMethod),$($u_cur.domain),$($u_cur.accountExpirationDate),$($u_cur.isDeactivated),$($u_cur.isAccountLocked),$($u_cur.description),$($u_cur.authenticationType),$($u_cur.enforcePasswordPolicy),$($u_cur.enforcePasswordExpiration),$($u_cur.userMustChangePassword),$($u_cur.userCanChangePassword),$($u_cur.isAdministrator),$($u_cur.isInAdministratorGroup),$($u_cur.emailAddress),$($u_cur.useADEmailAddress),$($u_cur.changePassword),$($u_cur.password),$($u_cur.lastLogin),$($u_cur.accountLockedDate),$($u_cur.deactivatedDate),$($u_cur.userWorkgroups),$($u_cur.apiKey)"| Out-File $all_u_export -Encoding "UTF8" -Append 
		#Add-Content -Path $all_u_export -Value 
		#"$($t_cur.tenant),$($u_cur.id),$($u_cur.displayName),$($u_cur.logOnId),$($u_cur.authenticationMethod),$($u_cur.domain),$($u_cur.accountExpirationDate),$($u_cur.isDeactivated),$($u_cur.isAccountLocked),$($u_cur.description),$($u_cur.authenticationType),$($u_cur.enforcePasswordPolicy),$($u_cur.enforcePasswordExpiration),$($u_cur.userMustChangePassword),$($u_cur.userCanChangePassword),$($u_cur.isAdministrator),$($u_cur.isInAdministratorGroup),$($u_cur.emailAddress),$($u_cur.useADEmailAddress),$($u_cur.changePassword),$($u_cur.password),$($u_cur.lastLogin),$($u_cur.accountLockedDate),$($u_cur.deactivatedDate),$($u_cur.userWorkgroups),$($u_cur.apiKey)"| Out-File $all_g_export -Append 
    		
       #"calling get_PS_user_groups"+ [int]$($u_cur.id)

	   <#  VARIANT 1
		$user_groups= get_PS_user_groups $t_cur $($u_cur.id)	
		
		$user_groups|% { 
		        Add-Content -Path $all_u_w_export -Value ($t_cur.tenant + "," + $($u_cur.logOnId) + "," + $($u_cur.displayname) + "," + $($_.name))
                $count_ug++
				if ($count_ug %10 -eq 0){write-host -nonewline ($form1 -f ("[{0,5}] loading ..." -f $count_ug))"`r"}
				}
		#>
		
		# # ???   $id=$($u_cur.id)
        #show_progress ($count_u++) 
		$hash = @{}
		
		#$hash|format-list
		foreach ($gs in $u_cur.userWorkgroups)
        {
		   	$hash = @{}            
            $gs | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($gs | SELECT -exp $_) }
            foreach($wg in ($hash.Values | Sort-Object -Property Name))
            {
                #Add-Content -Path $all_u_w_export -Value 
				($t_cur.tenant + "," + $($u_cur.logOnId) + "," + $($u_cur.isDeactivated) + "," + $($u_cur.displayname)+ "," + $($wg.name))| Out-File $all_u_w_export -Encoding "UTF8" -Append 
                $count_ug++
				if ($count_ug %10 -eq 0){write-host -nonewline ($form1 -f ("[{0,5}] loading ..." -f $count_ug))"`r"}
            }
			
        }     #>
      }
	  $ch="[{0,5}]" -f $count_ug
      $form1 -f "$ch user-workgroup assignments loaded"
    }
$linesep
$form1 -f "storing data in"
$form1 -f $output_path

P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----

