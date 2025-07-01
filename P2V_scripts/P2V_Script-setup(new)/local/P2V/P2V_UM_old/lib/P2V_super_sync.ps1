#-----------------------------------------
# P2V_super_sync
#-----------------------------------------
<#  documentation
.SYNOPSIS
	P2V_super_sync to sync AD <> P2V on a per user base
.DESCRIPTION
	P2V_super_sync read AD group memberships, translate them in P2V-workgroup assignments
	and updates the selected P2V tenant

.PARAMETER ??? menufile <filename>  
	CSV file 
	
.PARAMETER ??? xamldir <directory>
	CSV file 
	
.PARAMETER ??? fcolor  <colorcode>
	foregroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.PARAMETER ??? bcolor  <colorcode>
	backgroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.INPUTS
	none

.OUTPUTS
	true / false

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  name:   P2V_super_sync.ps1 
  ver:    1.0
  author: M.Kufner

  approach:
  1) ADgroups -> systemaccess /user     (< adgroups.csv)
  2) ADgroups -> profiles / user        (< adgroups.csv)
  3) user:profiles -> user:workgroups   (< profiles.csv)
  4) 
  
#>

param(
    [bool]$debug=$false
)

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"
$description="This script synchronizes one or more user accounts to one or more tenants.`n  The following activities are performed:`n- loading all P2V related AD groups and members`n-select user(s) & tenant(s)### OLD below`n- No new users are added`n- Information of existing users will be updated based on their UPN (=x-key)`n- if users are not entitled anymore (missing AD-group memberships)`n  deactivation is suggested.`n"

$step=0
#----- Set config variables

$output_path = $output_path_base + "\$My_name"
createdir_ifnotexists($output_path)

#----- variables definition in P2V_include
# $spec_accounts 
 
#----- start main part
  P2V_header -app $MyInvocation.MyCommand -path $My_path  -description $description

#------ step 1  
# get all $adgroups
# load AD group members in @{}
$step++
write-debug ($form2 -f "[STEP $step]","get all AD-groups and load members")
write-debug $linesep

$ADprofile_users = @{}   # $ADprofile_users[<AD.group>] = list of all users in AD group
$ADuser_groups = @{}     # $ADuser_groups[<x-key>] = list of Ad-group for this user
$ADuser_profiles = @{}
$all_adgroups = @{}      # all ADgroups from config file

#$adgroupfile = $config_path + "\P2V_adgroups_devtest.csv"  # tempfile for testing
$all_adgroups =import-csv $adgroupfile  

# load all P2V related AD groups and import users
ForEach ($i in $all_adgroups)
{
   
  if ($check_group = Get-ADGroup -Identity $($i.ADgroup) )
  {
    write-host -nonewline ($form_status -f "$($i.ADgroup)","loading..")"`r"
      #$loc_userlist=Get-ADGroupMember -searchbase "OU=P2V,OU=ADM-Services,DC=ww,DC=omv,DC=com" -Identity $($i.ADgroup)|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress  -SearchBase "CN=Users,DC=ww,DC=omv,DC=com"
	  
    #V1:  $loc_userlist=Get-ADGroupMember -Identity $($i.ADgroup)|Get-ADUser  -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress
	  
	 #V2  
	 $l_userlist=@()
	$loc_userlist=Get-ADGroupMember -Identity $($i.ADgroup)|select SAMAccountName,Name
	$loc_userlist|% {$l_userlist+=@($_.SAMAccountName)}
	  
    $ADprofile_users["$($i.ADGroup)"] =$l_userlist
	write-host ($form_status -f "$($i.ADgroup)",("[{0,3}]" -f $loc_userlist.count))
	$loc_userlist|%{if ($($i.PSGroup)) {$ADuser_profiles["$($_.Name)"]+= @($($i.PSGroup)) }}
  } else
  {
    write-host ($form_status -f "$($i.ADgroup)","[n/a]")
  }
}

#$ADuser_profiles    # hashtable xkey, group of lists)
#write-host $linesep

#$ADprofile_users
#write-host $linesep

#------ step 2
# select users
$step++
Write-debug ($form2 -f "[STEP $step]","get selected user(s)")
Write-debug $linesep 


write-host $linesep 
while ( $user_selected = get_AD_user )
{
  write-host $linesep 
  write-host ($form1 -f "user_selected: $($user_selected.displayname)")
  write-host ($form1 -f "assigned profiles")

  $u_xkey=$($user_selected.SAMAccountName)
  $u_logonID=$($user_selected.UserPrincipalName)
  $ADuser_profiles["$u_xkey"]|% {write-host ($form1 -f " *   $_")}

  $ADuser_groups["$u_xkey"] = new-object System.Collections.ArrayList
  Write-Debug $ADuser_groups["$u_xkey"].GetType().FullName 

  #------ step 3
  # select tenant(s)
  $step=3
  Write-debug ($form2 -f "[STEP $step]","get selected tenant(s)")
  Write-debug $linesep 
  Write-host  ($form1 -f "select tenant(s) to sync :")
  $tenants=select_PS_tenants -multiple $true -all $false
  #$tenants.keys|% {P2V_print_object $tenants[$_] }
  $tenants.keys|% { Write-host($form1 -f " > $($tenants[$_].tenant)" )}

  Write-host $linesep  

  #------ step 4
  # load all profile -definitions
  $step++
  Write-debug ($form2 -f "[STEP $step]","translate profiles -> workgroups")
  Write-debug $linesep

  $def_profiles= get_profiles -debug $false

  Write-host $linesep

  foreach ($p in $ADuser_profiles["$u_xkey"])
  {
    Write-host  ($form_err -f "P:","[$p]")
   
    foreach ($g in $def_profiles["$p"])
    {
      #$form1 -f "G[$g]:"|out-host
      if ($ADuser_groups["$u_xkey"] -notcontains $g)
      {
	     $ADuser_groups["$u_xkey"].Add("$g")|out-null
	     write-debug ($form3 -f $u_xkey,"$g","[ADD]")
	  }
	  else
	  {
         write-debug ($form1 -f "skip double $g")
      }	   
    }
  }
  Write-host $linesep

  #------ step 5
  # $ADuser_groups["$u_xkey"]|format-wide -column 3|out-host
  # check group dependencies (data.country.eco,..)

  $step++
  Write-debug ($form2 -f "[STEP $step]","check and correct user/workgroup assignments")
  Write-debug $linesep

  $ADuser_groups["$u_xkey"]= [System.Collections.ArrayList] (check_datagroup_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false)
  Write-Debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  # check BD permissions (allow - deny)
  $ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] ( check_BD_dependencies -login $u_logonID -grouplist $ADuser_groups["$u_xkey"] -debug $false)
  Write-Debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  # check licences groups (heavy - light)
  $ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] (check_license_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false )
  Write-Debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  # check template permissions (fullaccess - readonly - deny)
  $ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] ( check_template_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false )
  Write-Debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  Write-Debug $linesep
  $ADuser_groups["$u_xkey"] |% {Write-Debug ($form1 -f "$_")}

  foreach ($ts in $tenants.keys)
  {
    $t               = $tenants[$ts]
    $tenant          = $t.tenant
    $tenantURL       = "$($t.ServerURL)/$($t.tenant)"
    $base64AuthInfo  = $t.base64AuthInfo   
	$accessgroup     = $t.ADgroup
    # $PS_users= get_PS_userlist -tenant $t
    
	# $ADgroup_users[ADgroup]= userlist @()
    #load all "profiles" to user
    #-- #   read profiles
    write-host $linesep
	write-host ($form1 -f ">> checking tenant [$tenant] <<")
	write-host $linesep
	
    $user_profile_asis = @{}
    $user_profile_tobe = @{}
  
    $change_ops= @{}
    $updateOperations= @{}
    $group_list= @{}
    $g_list= @{}
  
    $user_profile_list=get_PS_userlist $tenants[$ts] |  where-Object {($($_.logOnId) -eq $user_selected.logOnId) }
    $U_G_list= @()
    $group_list=get_PS_grouplist $tenants[$ts]|select id,name,description,comments,externalGroup
    $group_list|% {$g_list[$($_.name)]=$_ }
	
	#------------- check if user is entitled to access the systemaccess
	write-host ($form1 -f "check if user is entitled to access $tenant")		
	# if user in Tenant.AD.accesslist & user does not exist in P2v -> ask & ADD user
    
	# if user in Tenant.AD.accesslist & user deactivated in P2V -> ask & activate user
		
	# if user in P2v but not in Tenant.AD.Accesslist  -> ask & deactivate user
	
	# if user not in P2V and not in Tenant.AD.Accesslist  -> warning msg & skip
	
	# if user deactivated in P2v and not in Tenant.AD.Accesslist  -> ask and delete groups (deactviate)
	
	# if user in Tenant.AD.accesslist

   		
	if ($ADprofile_users["$accessgroup"] -contains $u_xkey)
	  {
	#     if user not in tenant ->  ask & add
	    if (!$user_profile_list)
		  {  # add user
		     write-warning ($form_status -f "$($user_selected.Displayname) does not exist in $tenant","[ADD]") 
			 $to_be = [PSCustomObject]@{
		        logOnId              = $user_selected.logOnId
                displayName 		 = $user_selected.displayName
                description 		 = $user_selected.Department
                isDeactivated 		 = $False
                isAccountLocked 	 = $False
                authenticationMethod = "SAML2"
				useADEmailAddress    = $False
				emailAddress         = $user_selected.EmailAddress
            }
			$to_be|fl 
			if (($cont=read-host ($form1 -f "add user $($user_selected.displayName) to $tenant ? (y/n)")) -like "y")
			{
	            $rc= add_PS_user -tenant $t -user_profile $to_be 
				if (!$rc){write-warning "error in adding user"}
			}
			# reload user-profile
			
			 $user_profile_list=get_PS_userlist $tenants[$ts] |  where-Object {($($_.logOnId) -eq $user_selected.logOnId) }
		  }
	#     if user deactivated   ->  ask & activate
	    if ($user_profile_list.isdeactivated)
		  {
		     write-warning ($form_status -f "$($user_selected.Displayname) is deactivated in $tenant","[ACTIVATE]")  
			 if (($cont=read-host ($form1 -f "activate user $($user_selected.displayName) in $tenant ? (y/n)")) -like "y")
			{
			  activate_PS_user -tenant $t -User_Id $user_profile_list.id
			}
			 
		  }
		else
	      {
		     write-host  ($form_status -f "$($user_selected.Displayname) is activated in $tenant","[CHECK]")  
		  }
	  } 
	else
	  {
	# else (not in Tenant.AD.accesslist)
	#     if user in P2V        
	     if ($user_profile_list)
		  {
		    if ($user_profile_list.isdeactivated)
		      {
			    write-warning ($form_status -f "$($user_selected.Displayname) already is deactivated in $tenant - delete groups","[DEACTIVATE]")  
			  } 
	#         if user is deactivated ->  ask & activate & deactivate (delete groups)
              else 
			  {
			    write-warning ($form_status -f "$($user_selected.Displayname) already is deactivated in $tenant - delete groups","[DEACTIVATE]")  
			    if (($cont=read-host ($form1 -f "deactivate user $($user_selected.displayName) in $tenant ? (y/n)")) -like "y")
			{
			  deactivate_PS_user -tenant $t -User_Id $user_profile_list.id
			}
			  } 
	#         else
	#            ->  ask  & deactivate (delete groups)
	      }
		 else
	      {
		    write-host  ($form_status -f "$($user_selected.Displayname)-no AD, no P2V","[SKIP]")  
		  }

	#     else
    #        ->  relax and skip  (nothing to do)	
	    
	  }

    foreach ($gs in  $($user_profile_list.userWorkgroups))
    {
 	  $hash = @{}            
      $gs | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($gs | SELECT -exp $_) }
	  foreach($wg in ($hash.Values | Sort-Object -Property Name))
      {
	    if ($($wg.name) -notlike "Everyone")
	    {
          $user_profile_asis["$u_xkey"]+=@($($wg.name))
		  $U_G_list+=$($wg.name)
	    }
	  }
    }
    #[System.Collections.ArrayList]$templist=$U_G_list
    Write-debug "ADuser_groups"
    $ADuser_groups["$u_xkey"]|%{Write-debug $_}
    
    $user_profile_list |Add-Member  -MemberType NoteProperty  -Name asis -value $U_G_list
    $user_profile_list.asis = $U_G_list
    $user_profile_list |Add-Member  -MemberType NoteProperty  -Name tobe -Value $ADuser_groups["$u_xkey"] 
    $user_profile_list.tobe = $ADuser_groups["$u_xkey"]
    #$user_profile_list|select LogonID, asis, tobe |format-table
  
    write-host ($form2 -f $ts,$user_profile_list.LogonID)
    write-host ($form3_2 -f "AS-IS","TO-BE","ACTION")
    write-host $linesep
    $user_profile_list.asis|% { 
      if ($user_profile_list.tobe -contains $_)
   	    { 
	      write-host ($form3_2 -f $_,$_,"[ - ]")
	    } 
	  else
	    { 
	      write-host ($form3_2 -f $_,"-","[DEL]")
	  	  $gid=$g_list["$_"].id
		  $change_ops  = [PSCustomObject]@{
           op = "remove"
           path = "/userworkgroups/$gid"
           value = ""
		   }
		  $updateOperations["$($user_profile_list.id)"]+= @($change_ops)	
	    } 
    }
    $user_profile_list.tobe|% { 
      if ($user_profile_list.asis -notcontains $_) 
	    {  
	      write-host ($form3_2 -f "-",$_,"[ADD]")
		  $gid=$g_list["$_"].id
		  $change_ops  = [PSCustomObject]@{
              op = "add"
              path = "/userworkgroups/$gid"
              value = ""
			  }
		  $updateOperations["$($user_profile_list.id)"]+= @($change_ops)
	    } 
	  else
	    {  write-debug ($form3_2 -f $_,$_,"[SKIP]")}
    }
 
    write-debug $linesep
    write-debug ($form1 -f "json to patch")
    write-debug $linesep
 
    if ($updateOperations.count -gt 0)
      {
        write-debug ($updateoperations |convertto-json	)
        if (($cont=read-host ($form1 -f "apply changes? (y/n)")) -like "y")
          {
            foreach ($i in $updateOperations.keys)
              {
                $body=$updateOperations[$i]|convertto-json		
	            if ($($updateOperations[$i].count) -eq 1 )
	              { $body="[ $body ]" }
	      		        
	            $apiUrl = "$($tenantUrl)/PlanningSpace/api/v1/users/$($user_profile_list.id)"	
		        write-debug ($form1 -f "calling [$apiUrl]")
		        write-debug $body 
			    $line= "changing groups for user $($user_profile_list.displayname)"
		        write-host -nonewline ($form_status -f  $line, "")
			    write-host -nonewline "`r"
                $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
              
                if ($i_result) 
                  {
				     write-host ($form_status -f  $line, "[DONE]")
				     $i_result.entity|format-list
			      } 
	            else
                  {
				     write-host ($form_status -f  $line, "[ERROR]")
				  } 
				 
             } 
         }
      }
 
    # next step
   
    # 5.1  foreach asis.group:  if not in tobe.group.list? add "remove group" activity: "keep group"
    # 5.2  foreach tobe.group:  if not in asis.group.list? add "add group" activity: "group already there"
    # 5.3  show change-ops

    # 5.4  if (apply_changes): apply
    #       write logfile
  } # end foreach tenant 
}
write-warning "-- END of script so far --"
P2V_footer -app $My_name
pause