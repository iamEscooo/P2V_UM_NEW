#-----------------------------------------
#  P2V_super_sync-SEC2
#-----------------------------------------

#-------------------------------------------------

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
		[bool]$debug=$false,
		[bool]$check_BD=$true
	)
   if ($debug) {$DebugPreference = "Continue"}
#-----------------------------------------------------------------      
#----- central configuration / definition part
#-----------------------------------------------------------------      

	$My_name=$($MyInvocation.MyCommand.Name)
	$My_path=Split-Path $($MyInvocation.MyCommand.Path)

	if (!$workdir) {$workdir=$My_Path;$libdir="$workdir"}

	. "$libdir\P2V_forms.ps1"
	. "$libdir\P2V_include.ps1"
	. "$libdir\check_userprofile.ps1"
	. "$libdir\check_P2V_user.ps1"
	# . "$libdir\P2V_super_sync-SEC2.ps1"
	. "$libdir\P2V_export_AD_users.ps1"
	. "$libdir\P2V_export_users.ps1"
	#. "$libdir\P2V_calculate_groups_dependencies-SEC2.ps1"
	#. "$libdir\P2V_calculate_groups_bd-SEC2.ps1"
	. "$libdir\P2V_set_profiles.ps1"
	. "$libdir\P2V_calculate_groups.ps1"

	$user=$env:UserDomain+"/"+$env:UserName
	$client=$env:ComputerName
	$usr_sel= @{}
	$usr_xkey=""
	$default_profile="00DEFAULT"

  
	$description="This script synchronizes one or more user accounts to one or more tenants.`n  The following activities are performed:`n- loading all P2V related AD groups and members`n-select user(s) & tenant(s)### OLD below`n- No new users are added`n- Information of existing users will be updated based on their UPN (=x-key)`n- if users are not entitled anymore (missing AD-group memberships)`n  deactivation is suggested.`n"

	$step=0
	#----- Set config variables

	$output_path = $output_path_base + "\$My_name"
	createdir_ifnotexists($output_path)

	#----- variables definition in P2V_include
	# $spec_accounts 
	
#-----------------------------------------------------------------      
#----- start main part
#-----------------------------------------------------------------      

	P2V_header -app $MyInvocation.MyCommand -path $My_path -description $description

	#------ step 1  
	# get all $adgroups
	# load AD group members in @{}
  
	$ADprofile_users = @{}   # $ADprofile_users[<AD.group>] = list of all users in AD group
	$ADuser_groups = @{}     # $ADuser_groups[<x-key>] = list of PS-groups for this user
	$ADuser_profiles = @{}
	$User_ADgroups = @{}     # $User_ADgroups[<x-key>] = list of "*P2V*" and "*PetroVR*" AD groups
	$all_adgroups  = @{}      # all ADgroups from config file
    $def_profiles  = @{}      # profile<> workgroup list
	#$adgroupfile = $config_path + "\P2V_adgroups_devtest.csv"  # tempfile for testing
	#$all_adgroups =import-csv $adgroupfile  
	
	$ADgroupLoadList =@("dlg.WW.ADM-Services.P2V.access.production","dlg.WW.ADM-Services.P2V.access.test","dlg.WW.ADM-Services.P2V.access.update","dlg.WW.ADM-Services.P2V.access.training")
	(import-csv $adgroupfile  )| % { if ($ADgroupLoadList -contains $($_.ADGroup)) {$all_adgroups["$($_.ADgroup)"]=$_}}
    
	 # not used !
	
	   # load config file 
	   # expected format:  $UserProfileAssignment_File 
	   # <x-key> <logonID> <Profile>
	   # 
	   # expected format:  ProfileDefinition_File

#-----------------------------------------------------------------      
#----- input config files
#-----------------------------------------------------------------      

	$searchdir="\\somvat202005\PPS_share\P2V_UM_data\sec 2.0"
	do
	{   # ask for filenames
		Write-Output "|> select user <> profiles assignment file:  "
		$UserProfileAssignment_File = Get-FileName -initialDirectory $searchdir
		Write-Output ($form1 -f "[$UserProfileAssignment_File]")
 	
		Write-Output "|> select profile <> workgroups file:                 "
		$ProfileDefinition_File = Get-FileName 
		Write-Output ($form1 -f "[$ProfileDefinition_File]")
						
	}until(($cont=read-host ("|> continue with selected files (y/n)")) -like "y")
	
#-----------------------------------------------------------------      
#------ STEP:  read all relevant AD-groups + members
#-----------------------------------------------------------------      
 		
	$step++
	write-output ($form2 -f "[STEP $step]","get all AD-groups and load members")
  
	$form1 -f "loading all relevant AD groups"
	$linesep

	# load all P2V related AD groups and import users
	ForEach ($g in $all_adgroups.keys)
	{
		$i=$all_adgroups[$g]
		if ($check_group = Get-ADGroup -Identity $($i.ADgroup) )
	 	{
			#write-host ($form_status -f "$($i.ADgroup)","loading..")
    	
			$l_userlist=@()
			$loc_userlist=Get-ADGroupMember -Identity $($i.ADgroup)|Get-ADUser -properties * |
		select  Name, 
		        Givenname, 
				surname,
				SamAccountName,
				UserPrincipalName, 
				EmailAddress, 
				Department,
				description,
			    Enabled
		  #select SAMAccountName,Name
			$loc_userlist|% {$l_userlist+=@($_.SAMAccountName)}
	  
			$ADprofile_users["$($i.ADGroup)"] =$l_userlist
			Write-Output -NoEnumerate ($form_status -f "$($i.ADgroup)",("[{0,3}]" -f $loc_userlist.count))
			#$loc_userlist|%{if ($($i.PSGroup)) {$ADuser_profiles["$($_.SAMAccountName)"]+= @($($i.PSGroup)) }}
		} else
		{
			Write-Output -NoEnumerate ($form_status -f "$($i.ADgroup)","[n/a]")
		}	
		
	}
	$linesep 

#-----------------------------------------------------------------     
#------ STEP:  load local information file / AD profile
#---    skip for the moment
#-----------------------------------------------------------------  



#-----------------------------------------------------------------     
#------ STEP:  read <Profiles> definitions file  ->  $def_profiles[profilename]= list of groups
#-----------------------------------------------------------------     

	$step++
	Write-Output ($form2 -f "[STEP $step]","load profile definition file (profiles -> workgroups)")
	Write-Output $linesep
	Write-Output -NoEnumerate ($form1 -f "translate profiles -> workgroups" )
	#if ($debug) { pause}
	
	#$def_profiles= get_profiles -debug $false -ProfileDef $ProfileDefinition_File

    #$def_profiles|ft|out-host
	#$def_profiles.get_type()
	
	write-debug ($form1 -f "loading profiles from $ProfileDef")
    $csv_profiles=import-csv -path $ProfileDefinition_File |sort profile

    foreach ($l in $csv_profiles) 
    {
      $def_profiles["$($l.profile)"]+= @($($l.groups))
    }
    if ($debug) {
	   $def_profiles|format-table |out-host 
    }
     
    write-output -NoEnumerate ($form_status -f "load profile definitions $ProfileDefinition_File","[DONE]")

#-----------------------------------------------------------------     	
#------ STEP:  read <user> - <Profiles> file     ->    $ADuser_profiles[logonID] = list of profiles for login 
#-----------------------------------------------------------------     

	$step++
	Write-Output ($form2 -f "[STEP $step]","get selected user<> profile assignments")
	Write-Output $linesep 
    
	write-Output ($form1 -f "loading user <> profiles from $UserProfileAssignment_File")
	#if ($debug) { pause}
   
	$csv_profiles=import-csv -path $UserProfileAssignment_File 
	$user_profiles = @{}
	$count_u=0
   foreach ($l in $csv_profiles) 
   {
	 $l.logonID=$l.logonID.trim()
	 $l.profile=$l.profile.trim()
     $user_profiles["$($l.logonID)"]+= @($($l.profile))
	# $ADuser_profiles["$($l.logonID)"]= [PSCustomObject]@{}
	# $ADuser_profiles["$($l.logonID)"]= get_AD_user -searchstring $($l.logonID)
	show_progress ($count_u++) 
   }
   
   foreach ($u in $user_profiles.keys)
   { 
      $ADuser_profiles["$($u)"]= get_AD_user -searchstring $($u)
	  show_progress ($count_u++) 
	  write-progress "loading AD-account for $($u)"
   }
 	write-progress "loading finished" -completed	  
   if ($debug) {

	   $user_profiles|format-table |out-host 
	}
     
   write-output -NoEnumerate ($form_status -f "load user<>profiles  $UserProfileAssignment_File","[DONE]")

#-----------------------------------------------------------------      
#------ STEP:  translate profiles -> workgroups file  
#------	$ADuser_groups[logonID] = list of workgroups 
#-----------------------------------------------------------------     

    $step++
	Write-Output ($form2 -f "[STEP $step]","translate profiles to workgroups")
	Write-Output $linesep 
    #if ($debug) { pause}
	#[System.Collections.ArrayList]
	$ADuser_groups= @{}

    foreach ($LogID in $($user_profiles.keys))
	 { # loop through users
		$user_profiles["$LogID"]+= @($default_profile)
	    write-host -nonewline ($form1 -f "[$LogID]")"`r"
	 	Write-debug ($form_err -f "U:","[$LogID]")
		 
		foreach ($p in $user_profiles["$LogID"])
		{  # loop through profiles of user
			Write-debug  ($form_err -f "  P:","[$p]")
            foreach ($g in $def_profiles[$p])
			{# loop through groups per profile
				#$form1 -f  $def_profiles[$p]|out-host
                Write-debug  ($form_err -f "    G:","[$g]")
#  $form1 -f  "U: $LogID,  P: $p,  G: $g / $($def_profiles[$p]) "
#    pause
			#$def_profiles.GetType()
			#$form1 -f "P: [$p]  [$($def_profiles[$($p.tostring())].Value)]"|out-host
			#pause
				#write-Output ($form1 -f "G[$g]:")
				if ($ADuser_groups.keys -notcontains $LogID) 
				{
					$ADuser_groups["$LogID"]=@($g)
				}else
				{				
				  if ($ADuser_groups["$LogID"] -notcontains $g)
				  {
					$ADuser_groups["$LogID"]+=@($g)
					write-debug ($form3 -f $LogID,"$g","[ADD]")
				  }
				  else
				  {
				    write-debug ($form1 -f "skip double $g")
				  }
				}				  
			}
			
		}
		
		#------ STEP:  apply "To-Be Rules"
		
		Write-debug  ($form2 -f "[STEP $step-1]","$LogID : check and correct user/workgroup assignments")
		Write-debug  ($linesep)
		
		Write-debug  ($form1 -f "  $($ADuser_groups[$LogID].count) --> check_datagroup_dependencies")
		$ADuser_groups[$LogID]= [System.Collections.ArrayList] (check_datagroup_dependencies -grouplist $ADuser_groups["$LogID"] -debug $false)
		#Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 
        #$ADuser_groups[$LogID]|out-gridview -title "after check_datagroup_dependencies"
		# check BD permissions (allow - deny)
		
	  if ($check_BD)
	  {	  Write-debug  ($form1 -f "  $($ADuser_groups[$LogID].count) --> check_BD_dependencies")
  		$ADuser_groups[$LogID] = [System.Collections.ArrayList] ( check_BD_dependencies -login $LogID -grouplist $ADuser_groups["$LogID"] -debug $false)
		#Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 
        #$ADuser_groups[$LogID]|out-gridview -title "after check_BD_dependencies"
		# check licences groups (heavy- light)		
	  }
		Write-debug  ($form1 -f "  $($ADuser_groups[$LogID].count)--> check_license_dependencies")
		$ADuser_groups["$LogID"] = [System.Collections.ArrayList] (check_license_dependencies -grouplist $ADuser_groups["$LogID"] -debug $false )
		#$ADuser_groups[$LogID]|out-gridview -title "after check_license_dependencies"
		#Write-debug  $ADuser_groups["$LogID"].GetType().FullName 
		        
		# check template permissions (fullaccess - readonly - deny)
		Write-debug  ($form1 -f "  $($ADuser_groups[$LogID].count)--> check_template_dependencies")
		$ADuser_groups["$LogID"] = [System.Collections.ArrayList] ( check_template_dependencies -grouplist $ADuser_groups["$LogID"] -debug $false )
		
		#Write-debug  $ADuser_groups["$LogID"].GetType().FullName 
	    #$ADuser_groups[$LogID]|out-gridview -title "afer check_template_dependencies" -wait
	   
		
		#$ADuser_groups["$LogID"]|out-host	
	    Write-debug  ($linesep)
		
		
	 }
	

    
#-----------------------------------------------------------------     
#------ STEP:  select tenant
#-----------------------------------------------------------------     

	$step++
	Write-debug ($form2 -f "[STEP $step]","get selected tenant(s)")
	Write-debug $linesep 
	Write-Output -NoEnumerate ($form1 -f "select tenant(s) to sync :")
	Write-Output -NoEnumerate $linesep
	$tenants=select_PS_tenants -multiple $true -all $false
	#$tenants.keys|% {P2V_print_object $tenants[$_] }
	Write-Output -NoEnumerate ($form1 -f "tenants selected:")
	$tenants.keys|% { Write-Output -NoEnumerate ($form1 -f " > $($tenants[$_].tenant)" )}

	Write-Output -NoEnumerate ($linesep  )
			
#-----------------------------------------------------------------     
#------ select users to update
#-----------------------------------------------------------------     
	
	# $userlist=get_PS_userlist ($tenant)

    $userlist=$ADuser_groups.keys|out-gridview  -Title "select users to update" -OutputMode multiple
	
    #$UsersToUpdate=$ADuser_groups.keys|out-gridview  -OutputMode multiple

    <#
        
		$ADuser_profiles["$u_xkey"]|% {Write-Output -NoEnumerate ($form1 -f " *   $_")}

		$ADuser_groups["$u_xkey"] = new-object System.Collections.ArrayList
  
		Write-Output -NoEnumerate ($linesep)
		    if ($debug) { pause }
		
  
		

		Write-Output -NoEnumerate ($linesep)

		foreach ($p in $ADuser_profiles["$u_xkey"])
		{
			Write-Output -NoEnumerate ($form_err -f "P:","[$p]")
   
			foreach ($g in $def_profiles["$p"])
			{
				write-debug ($form1 -f "G[$g]:")
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
		$linesep
		#if ($debug) {pause}
		#------ step 5
		write-debug "step 5:"
  
		# write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 
		# check group dependencies (data.country.eco,..)F
		#$ADuser_groups["$u_xkey"]|convertto-json |out-host
		
		$step++
		Write-Output -NoEnumerate ($form2 -f "[STEP $step]","check and correct user/workgroup assignments")
		Write-Output -NoEnumerate ($linesep)
		Write-Output -NoEnumerate ($form1 -f "--> check_datagroup_dependencies")
		$ADuser_groups["$u_xkey"]= [System.Collections.ArrayList] (check_datagroup_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false)
		#Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 

		# check BD permissions (allow - deny)
		Write-Output -NoEnumerate ($form1 -f "--> check_BD_dependencies")
		$ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] ( check_BD_dependencies -login $u_logonID -grouplist $ADuser_groups["$u_xkey"] -debug $false)
		#Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  # check licences groups (heavy - light)		
  Write-Output -NoEnumerate ($form1 -f "--> check_license_dependencies")
  $ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] (check_license_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false )
  #Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  # check template permissions (fullaccess - readonly - deny)
  Write-Output -NoEnumerate ($form1 -f "--> check_template_dependencies")
  $ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] ( check_template_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false )
  #Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  #Write-Debug $linesep
  #$ADuser_groups["$u_xkey"] |% {Write-host ($form1 -f "$_")}
  #if ($debug) {pause}
  #>
  
  
#-----------------------------------------------------------------     
#------ loop trough selected tenants
#----------------------------------------------------------------- 
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
		#Write-Output -NoEnumerate ($linesep)
		Write-Output -NoEnumerate ($form1 -f ">> checking tenant [$tenant] <<")
		Write-Output -NoEnumerate ($linesep)
	  
	    $do_all   = $false
	    $skip_all = $false
	    
		$UsersFromTenantList      = @{}
		$UsersFromTenant          = @{}
		$WorkgroupsFromTenantList = @{}
		$WorkgroupsFromTenant     = @{}
		
		$UsersFromTenantList= get_PS_userlist $tenants[$ts]
		$UsersFromTenantList|%{$UsersFromTenant[$($_.LogonID)]=$_}
		
		$WorkgroupsFromTenantList=get_PS_grouplist $tenants[$ts]|select id,name,description,comments,externalGroup
		$WorkgroupsFromTenantList|% {$WorkgroupsFromTenant[$($_.name)]=$_ }

#-----------------------------------------------------------------     
#------ loop trough selected users / tenant
#----------------------------------------------------------------- 
		
		foreach ($user_selected in $userlist)
		{
			$skip_user= $false
			$do_it    = $false
			
			
			
		    if ($debug)
			{
				Write-Debug  ($form_debug -f "user selected: $($user_selected)")
				$form_debug -f " U: $user_selected"|out-host
				Write-Debug  ($form_debug -f "assigned profiles")
		
				$user_profiles[$user_selected]|% {$form_debug -f "   P: $_"}|out-host
		
				Write-Debug  ($form_debug -f "assigned groups")
			
				$ADuser_groups[$user_selected]|% {$form_debug -f "     G: $_"}|out-host
				
				pause
			}
			
			$user_profile_asis = @{}
			$user_profile_tobe = @{}
  
			$change_ops= @{}
			$updateOperations= @{}
			
  
			#  $user_profile_list=get_PS_userlist $tenants[$ts] |  where-Object {($($_.logOnId) -eq $user_selected) }
			$user_profile_list=$UsersFromTenant[$user_selected]
			$U_G_list= @()
	
	        # $group_list=get_PS_grouplist $tenants[$ts]|select id,name,description,comments,externalGroup
			# $group_list|% {$g_list[$($_.name)]=$_ }
			
	    	# $user_profile_list|out-gridview -wait
		
			
			# if user not in tenant ->  ask & add
			if (!$user_profile_list)
			{  # add user
		        write-output -NoEnumerate ($form_1 -f "$($user_selected) does not exist in $tenant - create the account first")
				# 
				$to_be= @{}
				$user_sel=@{}
				$user_sel=$ADuser_profiles[$user_selected]
				#<#P2v_
			    $to_be = [PSCustomObject]@{
		           logOnId              = $user_sel.logOnId
                   displayName 		    = $user_sel.displayName
                   description 		    = $user_sel.Department
                   isDeactivated 	 	= $False
                   isAccountLocked 	 	= $False
                   authenticationMethod = "SAML2"
				   useADEmailAddress    = $False
				   emailAddress         = $user_sel.EmailAddress
                }
			  
			   if ($debug){$to_be|format-list
			     #if (($cont=read-host ($form1 -f "add user $($user_sel.displayName) to $tenant ? (y/n)")) -like "y")
				 $user_sel|format-list
				 $linesep 
				 $to_be|format-list
				 $linesep
				 $user_selected|format-list
			   }
			    if (($cont=ask_continue -title "Add user to tenant [$tenant]?" -msg "add user [$($to_be.displayName)] / [$($to_be.logOnId)] ?") -like "Yes")
			   {
	                $rc= add_PS_user -tenant $t -user_profile $to_be 
				    if ($rc) {Write-Output -NoEnumerate ($form_status -f "adding [$($to_be.logOnId)]  in $tenant","[DONE]") }
					else     {Write-Output -NoEnumerate ($form_status -f "adding [$($to_be.logOnId)]  in $tenant","[ERROR]")}
			   }
			   else
			   {
				  continue 
			   }
			#
			# reload user-profile
			
			 $user_profile_list=get_PS_userlist $tenants[$ts] |  where-Object {($($_.logOnId) -eq $user_sel.logOnId) }
			 			 
			}
			Write-Output -NoEnumerate (($form_status -f "$ts : $($user_profile_list.LogonID)","[CHECK]")+"`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b")
			
	#     if user deactivated   ->  ask & activate
			if ($user_profile_list.isdeactivated)
			{
				Write-Output -NoEnumerate ($emptyline)
				Write-Output -NoEnumerate ($form_status -f "$($user_profile_list.Displayname) is deactivated in $tenant","[ACTIVATE]")  
				#if (($cont=read-host ($form1 -f "activate user $($user_selected.displayName) in $tenant ? (y/n)")) -like "y")
				if (($cont=ask_continue -title "Activate user?" -msg "activate user $($user_profile_list.displayName) in $tenant ?") -like "Yes")
				{
					activate_PS_user -tenant $t -User_Id $user_profile_list.id
				}
				else
				{$skip_user=$true}
			 
			}
			else
			{
			   Write-debug  "$emptyline"
		       Write-debug  ($form_status -f "$($user_profile_list.LogonID) is activated in $tenant","[CHECK]") 
			}
	
			if($skip_user) {continue}
        #   $form1 -f " $user_selected"|out-host
		#	$user_profile_list.userWorkgroups|fl|out-host

			foreach ($gs in  $($user_profile_list.userWorkgroups))
			{
				$hash = @{}            
				$gs | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($gs | SELECT -exp $_) }
				foreach($wg in ($hash.Values | Sort-Object -Property Name))
				{
					#if ($($wg.name) -notlike "Everyone")
					#{
						$user_profile_asis["$user_selected"]+=@($($wg.name))
						$U_G_list+=$($wg.name)
					#}
				}
			}
			#[System.Collections.ArrayList]$templist=$U_G_list
			Write-debug "ADuser_groups"
			$ADuser_groups["$user_selected"]|% { if ($_) { write-debug $_.tostring()}}
    
			$user_profile_list |Add-Member  -MemberType NoteProperty  -Name asis -value $U_G_list
			$user_profile_list.asis = $U_G_list
			$user_profile_list |Add-Member  -MemberType NoteProperty  -Name tobe -Value $ADuser_groups["$user_selected"] 
			$user_profile_list.tobe = $ADuser_groups["$user_selected"]
			
			#$user_profile_list|select LogonID, asis, tobe |format-table
  

			#Write-Output -NoEnumerate ($form3_2 -f "AS-IS","TO-BE","ACTION")
			#Write-Output -NoEnumerate ($linesep)
	        $compare_log =@(($form3_2 -f "AS-IS","TO-BE","ACTION"))
			$compare_log += @(($linesep))
	
			$user_profile_list.asis|% { 
				if ($_ -and ($user_profile_list.tobe -contains $_))
				{ 
					#Write-Output -NoEnumerate ($form3_2 -f "[$_]","[$_]","[ - ]")
				 $compare_log += @(($form3_2 -f "[$_]","[$_]","[ - ] - GID: $($WorkgroupsFromTenant["$_"].id)"))
			
				} 
				else
				{ 
					#Write-Output -NoEnumerate ($form3_2 -f "[$_]","-","[DEL]")
					$compare_log += @(($form3_2 -f "[$_]","-","[DEL] - GID: $($WorkgroupsFromTenant["$_"].id)"))
					
					$gid=$WorkgroupsFromTenant["$_"].id
					$change_ops  = [PSCustomObject]@{
						op = "remove"
						path = "/userWorkgroups/$gid"
						value = ""
					}
					$updateOperations["$($user_profile_list.id)"]+= @($change_ops)	
				} 
			}

			$user_profile_list.tobe|% { 
				if ($_ -and ($user_profile_list.asis -notcontains $_)) 
				{  
					#Write-Output -NoEnumerate ($form3_2 -f "-","[$_]","[ADD]")
					$compare_log += @(($form3_2 -f "-","[$_]","[ADD] - GID: $($WorkgroupsFromTenant["$_"].id)"))
					$gid=$WorkgroupsFromTenant["$_"].id
					$change_ops  = [PSCustomObject]@{
						op = "add"
						path = "/userWorkgroups/$gid"
						value = ""
					}
					$updateOperations["$($user_profile_list.id)"]+= @($change_ops)
				} 
				else
				{  write-debug ($form3_2 -f "[$_]","[$_]","[SKIP] - GID: $($WorkgroupsFromTenant["$_"].id)")}
			}
 
			write-debug $linesep
			write-debug ($form1 -f "json to patch")
			write-debug $linesep
 
			if ($updateOperations.count -gt 0)
			{
				write-Output $compare_log
				write-output $linesep
				write-Output  ($form1 -f "apply changes ?")
				write-output $linesep
                
				if ((! $do_all) -and (! $skip_all))
				{
                    $cont=ask_YesNoAll -title "Apply changes in tenant [$tenant]?" -msg " apply listed changes for $($user_selected)?"
					write-output ($form1 -f "[$cont] selected")
					switch ($cont)
					{
						Yes    {$do_it =$true; Break}
						OK     {$do_it =$true;  $do_all=$true; Break}
						No     {$do_it =$false; Break}
						Abort  {$do_it =$false; $skip_all=$true; Break}
					}
				}   			  
			  
				
				
		
				write-debug ($updateoperations |convertto-json	)
				#if (($cont=read-host ($form1 -f "apply changes? (y/n)")) -like "y")
				# if (($cont=ask_continue -title "Apply changes?" -msg "apply listed changes for $($user_selected) in $tenant ?") -like "Yes")
				if ($do_it -or $do_all)
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
						#($form_status -f  $line, "")+"`r"
						($form_status -f  $line, "`r")
						$i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
              
						if ($i_result) 
						{
							Write-Output -NoEnumerate ($form_status -f  $line, "[DONE]")
							Write-Log -logtext "user=$user,script=$My_name,tenant=$tenant,uid=$($user_profile_list.id)/$($user_profile_list.logOnId),gid=$($updateOperations[$i].path),$($updateOperations[$i].op),[DONE]" -level 0
							#if ($debug){$i_result.entity|format-list}
						} 
						else
						{
							Write-Output -NoEnumerate ($form_status -f  $line, "[ERROR]")
							Write-Log -logtext "user=$user,script=$My_name,tenant=$tenant,uid=$($user_profile_list.id)/$($user_profile_list.logOnId),gid=$($updateOperations[$i].path),$($updateOperations[$i].op),[FAIL]" -level 2
						} 
				 
					}
					write-output $linesep
				}
		   			 
			} else
			{
				write-Output  ("{0,-20}  |" -f "[no changes to apply]")
				write-output $linesep
			}
 
    #if ($debug) {pause}
    #       write logfile
  } # end foreach user 
  
  
  
  
 }  # end foreach tenant
 
P2V_footer -app $MyInvocation.MyCommand
