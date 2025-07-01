#=======================
#  main user interface
#
#  name:    P2V_usermgmt.ps1 
#  ver:     1.0
#  author:  M.Kufner
#
#  description:
#

#=======================

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#-- global variable --
$u_list=@()

##  menu definition

$menu0=@()
#$menu0+="search for x-key"	    	  		     	#1
$menu0+="Check individual user(s) in Active Directory"	 		#2   ok
$menu0+="Check individual user(s) in all P2V tenants"			#3   ok
$menu0+="check locked users"						#4
$menu0+="export P2V userlists"		  	         	#5   ok
$menu0+="export P2V auditlogs"	 					#6   ok
$menu0+="export Active Directory lists for P2V"				    #7   ok
$menu0+="check all locked users"				    #8
$menu0+="create new user(s)"	   				    #9
$menu0+="manage user workgroups  (single user)"     #10
$menu0+="manage user workgroups - UI (single user)"  #11
$menu0+="calculate Access groups"                    #12
$menu0+="synchronize single user with AD"            #13
$menu0+="synchronize tenant with AD"                 #14
$menu0+="Profile manager"                           #15
$menu0+="apply user profiles"                       #16

$scripts=@()
#$scripts+=$lib_path + ""  		                        #1
$scripts+=$lib_path + "\check_AD_userprofile_1.ps1"     #2   ok
$scripts+=$lib_path + "\check_P2V_user.ps1"      	    #3   ok
$scripts+=$lib_path + "\P2V_lock_user.ps1"	    	    #4
$scripts+=$lib_path + "\P2V_export_users.ps1"           #5
$scripts+=$lib_path + "\PS-auditlogs.ps1"			    #6
$scripts+=$lib_path + "\AD_userlists.ps1"			    #7
$scripts+=$lib_path + "\P2V_lock_allusers.ps1"  	    #8
$scripts+=$lib_path + "\P2V_new_user.ps1"               #9
$scripts+=$lib_path + "\P2V_new_users_tenant.ps1"       #10
$scripts+=$lib_path + "\P2V_users_WG_assignment_1.ps1"  #11
$scripts+=$lib_path + "\P2V_calculate_groups.ps1"       #12
$scripts+=$lib_path + "\P2V_singleuser_sync.ps1"       #13
$scripts+=$lib_path + "\P2V_sync_userbase.ps1"          #14
$scripts+=$lib_path + "\P2V_profile_manager.ps1"        #15
$scripts+=$lib_path + "\P2V_set_profiles.ps1"           #16
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
			
           'old' {   #"search for x-key"
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
				 "`n"
				 $form1 -f "export format"
				 "LogonId,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress,authenticationMethod"
				 $user_list |% {
				#Add-Content $usersFile -Value 
				$_.logOnId + "," + $_.displayName + "," + $_.description + "," + $_.isDeactivated + "," + $_.isAccountLocked + "," + $_.emailAddress + "," + $_.authenticationMethod 
				}
				 pause
			   }
			   
               #"Check individual user(s) in AD"
			   #"Check individual user(s) in P2V"
			   #"check locked users"
			   #"export P2V userlists"
			   #"export P2V auditlogs"
			   #"check all locked users"
			   #"create new user(s)"
			   #"manage user workgroups"
			   #"manage user workgroups - UI"
			   #"calculate Access groups"
			   #"apply user profiles"
			   
           default {  
                cls
				& $scripts[$input-1] # run predefined script
				pause
               }
            
             
     }
	 out-host
} until ($input -eq '0')
$called=$False