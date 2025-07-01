#=======================
#  main user interface
#
#  name:   P2V_menu.ps1 
#  ver:    1.0
#  author: M.Kufner
#=======================

$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path
. "$workdir/P2V_include.ps1"

#-- global variable --
$u_list=@()
$workdir     = $My_path        #"\\somvat202005\PPS_Share\P2V_scripts"

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$allowedfile = $config_path + "\allowed_users.csv"
$output_path = $workdir + "\output"


$menu0=@()
$menu0+="search for x-key"	    	  		     	#1
$menu0+="Check individual user(s) in AD"	 		#2   ok
$menu0+="Check individual user(s) in P2V"			#3   ok
$menu0+="check locked users"						#4
$menu0+="export P2V userlists"		  		#5   ok
$menu0+="export P2V auditlogs"	 					#6   ok
$menu0+="export AD list for P2V"				    #7   ok
$menu0+="check all locked users"				    #8
$menu0+="create new user(s)"	   				    #9
$menu0+="manage user workgroups"                    #10
$menu0+="manage user workgroups - UI"               #11
$menu0+="calculate Access groups"                    #12
$menu0+="synchronize with AD"                       #13
$menu0+="Profile manager"                           #14
$menu0+="apply user profiles"                       #15

$scripts=@()
$scripts+=$workdir + ""  		                    #1
$scripts+=$workdir + "\check_AD_userprofile_1.ps1"    #2   ok
$scripts+=$workdir + "\check_P2V_user.ps1"      	#3   ok
$scripts+=$workdir + "\P2V_lock_user.ps1"	    	#4
$scripts+=$workdir + "\P2V_export_users.ps1"        #5
$scripts+=$workdir + "\PS-auditlogs.ps1"			#6
$scripts+=$workdir + "\AD_userlists.ps1"			#7
$scripts+=$workdir + "\P2V_lock_allusers.ps1"  		#8
$scripts+=$workdir + "\P2V_new_user.ps1"            #9
$scripts+=$workdir + "\P2V_new_users_tenant.ps1"    #10
$scripts+=$workdir + "\P2V_users_WG_assignment_1.ps1"   #11
$scripts+=$workdir + "\P2V_calculate_groups.ps1"    #12
$scripts+=$workdir + "\P2V_sync_userbase.ps1"         #13
$scripts+=$workdir + "\P2V_profile_manager.ps1"         #14
$scripts+=$workdir + "\P2V_set_profiles.ps1"         #15


#-- start main part
do
{
     cls
	 P2V_header -app $My_name -path $My_path 
     P2V_Show-Menu -Title "Main Menu - user management" -menu $menu0
     out-host
     $input = Read-Host "Please make a selection"
      
     switch ($input)
     {
	       '0' {
                return
               }
			
           '1' {   #"search for x-key"
                 $inp=""
				 $user_list =@()
				 $u_res= @()
                 do 
				 {
				    while (!$inp) {$inp= Read-Host "Please enter search term: (0=exit)"}
					if (!($inp -eq "0"))
					{
						$u_res=Get-ADUser -Filter { (Givenname -like $inp) -or (Surname -like $inp) -or (Name -like $inp)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department, EmailAddress
					
					   If ($u_res) 
					   {
					     $u_sel=$u_res
						 #$u_sel=$u_res |out-gridview -title "search-results for $inp"  -PassThru}
						 $u_sel|% {
						 $user_list += [PSCustomObject]@{
                               logOnId = $_.UserPrincipalName
                               #domain = $_.Domain
                               displayName = "$($_.Surname) $($_.GivenName) ($($_.Name))"
                               description = $_.Department -replace '[,]', ''
                               isDeactivated = $False
                               isAccountLocked = $False
                               useADEmailAddress    = $True
                               authenticationMethod = "SAML2"
                              }			  
						 }
						 $user_list |format-table 
						 
					   }
			     		else    {"$u_res not found in Active Directory"}
						$inp=""
					}
					
				 } until ($inp -eq "0")
				 
				 
				 "LogonId,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress,authenticationMethod"
				 $user_list |% {
				#Add-Content $usersFile -Value 
				$_.logOnId + "," + $_.displayName + "," + $_.description + "," + $_.isDeactivated + "," + $_.isAccountLocked + "," + $_.emailAddress + "," + $_.authenticationMethod 
				}
				 pause
			   }
		   '2' {  #"Check individual user(s) in AD"
                cls
				& $scripts[$input-1] -xkey $($resp.Name) -P2Vgroups $true -long $false
  				pause
               } 
           '3' {  #"Check individual user(s) in P2V"
                cls
                & $scripts[$input-1] #-xkey $($resp.Name) -UPN $($resp.UserPrincipalName)
                pause
               } 
			   
			   #"check locked users"
			   #"export P2V userlists"
			   #"export P2V auditlogs"
			   #"check all locked users"
			   #"create new user(s)"
			   #"manage user workgroups"
			   #"manage user workgroups - UI"
			   #"calculate Deny groups"
			   #"calculate Deny groups"
			   #"apply user profiles"
           default {  
               cls
				& $scripts[$input-1]
				pause
               }
            
             
     }
	 out-host
} until ($input -eq '0')
$called=$False