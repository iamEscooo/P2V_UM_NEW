#-----------------------------------------
# P2V_sync_user
#
#  name:   P2V_sync_user.ps1 
#  ver:    0.1
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key (searchstring) and sync to selected tenants
#-----------------------------------------
param(
  [string]$xkey="",
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  [bool]$checkOnly = $TRUE
)
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"



$debug=$False

$output_path = $output_path_base + "\$My_name"
createdir_ifnotexists($output_path)

#----- start main part
P2V_header -app $My_name -path $My_path 
write-output "$workdir\P2V_include.ps1"
# -- some variables
	
$u1_list_vendor=@{}
$u_list_AD=@{}
	
# -- special group for vendors -> add comment to description field
$vendor_group= "dlg.WW.ADM-Services.P2V.Aucerna"

if ($check_group = Get-ADGroup -LDAPFilter "(SAMAccountName=$vendor_group)")
{ # set "vendor tag"
	$u_list_vendor=Get-ADGroupMember -Identity $vendor_group|Get-ADUser -properties Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress 
    $u_list_vendor |% {$u1_list_vendor[$($_.UserPrincipalName)]=$_}
}
# -- load all AD access groups
  $all_systems =import-csv $tenantfile|select -Unique ADgroup
  foreach ($g in $all_systems)
  {
	   $ga=$g.ADgroup
	   if ($check_group = Get-ADGroup -LDAPFilter "(SAMAccountName=$ga)")
       {
	      $u_list_AD[$ga] =Get-ADGroupMember -Identity "$ga"|Get-ADUser -properties Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress 
	      $form_user1 -f $u_list_AD[$ga].count, "users loaded from AD [$ga]",""|out-host
       } 
  }
$linesep|out-host
pause
#--- select user from AD  - main loop
While ($user_from_AD=  get_AD_user)
{
   $changelog= @()
        
   if(! $user_from_AD) 
   { # user not in AD (this branch should never been reached)
      $form_err -f "[ERROR]", " !! [$($user_from_AD.Name)] not in AD !!(uups - this should not have happened)"  ;exit 
   }	
   else
   { #valid AD profile -print it
      $linesep
      $form1 -f  "Active Directory information for $($user_from_AD.SamAccountName)"
      $linesep
      P2V_print_object($user_from_AD)
   }
   $logonID=$user_from_AD.logonID

   # get tenants to sync
   $tenants= select_PS_tenants
  
  #  $tenants|%{$linesep;$($_.name)} ### ??????
   
   #
   $form1 -f "sync user $logonID  from AD to the tenants"
   $tenants.keys|% {$form1 -f " > $_"  }
    
   $write_changes=$false
   $all_write=$false
   $no_write=$false
   if (($cont=read-host ($form1 -f "write changes to tenants? (y/n = default)")) -like "y") {$write_changes=$true} else {$write_changes=$false}
  
   if ($write_changes)  {$form1 -f ">> changes will be applied in P2V <<"}
   else                 {$form1 -f ">> necessary changes are only analyzed - no changes will be applied ! <<"}
     
   $linesep
    
   foreach ($t_s in $tenants.keys) 
   { #--- loop selected tenants
  
     #-- local variables
 	 $add_ops=@()
     $del_ops=@()
     $change_ops=@()
     $updateOperations = @{}
     $deleteOperations = @{}
      
	 $u1_list_P2V=@{}   
     $u1_list_AD =@{}
	 
	 #--
     $t_sel=$tenants[$t_s]
	 $tenant=$t_sel.tenant
	 
	 $form1 -f "> $tenant <"
     
	 $AD_group   = $t_sel.ADgroup # "access AD-group for specific tenant
         
	 $u_list_AD[$AD_group]|% {$u1_list_AD["$($_.UserPrincipalName)"]=$_}
     
  	 #-- get P2V user list
	 $u_list_P2V = P2V_get_userlist ($t_sel)| where-Object {($($_.authenticationMethod) -ne 'LOCAL') }
	 $form_user1 -f $u_list_P2V.count, "non-local users loaded from $tenant","" |out-host
	 $u_list_P2V|% {$u1_list_P2V[$($_.logOnId)]=$_}	 	 
	 
     #-- get current user_profile "as-is" from tenant
     $as_is=$u1_list_P2V[$($logonID)]|select id, logOnId, displayName, description, isDeactivated, isAccountLocked, authenticationMethod, useADEmailAddress, emailAddress  
     
	 #-- start preparing "to-be" profile
	 $u_ad_sel=$u1_list_AD[$logOnId]    
	 $descr = $u_ad_sel.Department -replace '[,]', ''
	 
	 # mark external "vendor" accounts
	 if ($u1_list_vendor.ContainsKey($logOnId)) { $descr = "[AUCERNA] "+$descr} 
	 
     $to_be = [PSCustomObject]@{
				id					 = $u1_list_P2V[$logOnID].id
                logOnId              = $logonID
                displayName 		 = $user_from_AD.displayName
                description 		 = $descr
                isDeactivated 		 = $False
                isAccountLocked 	 = $False
                authenticationMethod = "SAML2"
				useADEmailAddress    = $False
				emailAddress         = $user_from_AD.EmailAddress
            }

	 if ($u1_list_AD.ContainsKey($logOnId))  
	 {# user is granted access in AD ?
	   if ($u1_list_P2V.ContainsKey($logOnId))
	   { # user in AD  and in P2V      ->start comparison
	   	   
		   $resp = update_PS_user -tenant $t_sel -user_profile_old $as_is -user_profile_new $to_be
           
		  
	    } else
	   { # user in AD  but NOT in P2V  -> create user
    	  $form_status -f "$($u_ad_sel.UserPrincipalName)  in AD but not in P2V","[ADD]"
	  	  			
		  foreach ($element in $to_be.PSObject.Properties) 
	      { # create changelog
            $form2_1 -f "$($element.Name)","$($element.Value)"
			#if ($($u1_list_P2V[$logonID].$($element.Name))
			       			
 	        $change = [PSCustomObject]@{
			       tenant				 = $tenant
                   logOnId               = $u_ad_sel.UserPrincipalName
                   attribute		     = $element.Name
                   old_value_P2V 		 = $u1_list_P2V[$logonID].$($element.Name)
                   new_value_P2V 		 = $($element.Value)
			       activity				 = "ADD"
                }
	        if   ($($change.old_value_P2V) -ne $($change.new_value_P2V)) { $change.activity = "ADD" }  
			else                                                         { $change.activity = "SKIP" }
	        $changelog +=$change
	  		}

  	        $add_ops+=$to_be  # ?
            $acount++         # ?
		 
            if ($write_changes) { $rc= add_PS_user -tenant $t_sel -user_profile $to_be }
		    else                { $form1 -f " no changes applied to $tenant"}
	   }
	 } else
	 {# user not in AD -> remove access to P2V
	   $linesep
	   $to_be.isDeactivated =$True
	   if ($u1_list_P2V.ContainsKey($logOnId))
	   { #user already exists but not in AD -list       -> deactivate
	          
		  $u_p2v=$u1_list_P2V[$logonId]
	      if (!($u_p2v.isDeactivated))
	      { 
	            $form_status -f "$($u_p2v.logonID) in P2V but not in AD","[DEACTIVATE]"
				$change = [PSCustomObject]@{
				      tenant				 = $tenant
                      logOnId                = $logonID
                      attribute		         = "isDeactivated"
                      old_value_P2V 		 = $u_p2v.isDeactivated
                      new_value_P2V 		 = $true
					  activity				 = ""
                   }
							   
				 if ($($change.old_value_P2V) -ne $($change.new_value_P2V)) 
				 { 
				    $change.activity = "DEACTIVATE"
					$change_ops += [PSCustomObject]@{  
                       op     = "replace"
                       path   = "/isDeactivated"
                       value  = "True"			
				    }  
					$change_ops += [PSCustomObject]@{  
                       op     = "replace"
                       path   = "/description"
                       value  = "[DEACTIVATED] $($u_p2v.description)"			
				    }  
									
				 } else 
				 { $form_status -f "$($u_p2v.logonID)  already deactivated","[SKIP]";
				   $change.activity = "SKIP"}
				 
				 $changelog +=$change	         		     
				 
				 if ($write_changes)
		         { 
				   #start deactivation
			       # step 1 - remove all workgroup assignments
				   PS_user_clear_all_workgroups -tenant $t -logonID $u_p2v.logonid
				   
				   
				   if ($($change_ops.count) -gt 0)
				   {
				     $resp=P2V_update_user -tenant $t_sel -user_profile $to_be -change $change_ops
				   }
				   
				   
				   
				 }
		         else 
				 { $form1 -f " no changes applied to $tenant" }
	       } else
	       {
	          $form_status -f "$logonID already deactivated","[SKIP]"
	       }
	      
	   } else
	   { # user not in P2V and not in AD                -> do nothing ;-)
	     $form_status -f "$($u_p2v.logonID)  - no AD and no P2V access","[SKIP]"
	   }
	 }

  	 foreach ($element in $uprofile.PSObject.Properties) 
	 {
       $form2_1 -f "$($element.Name)","$($element.Value)"
     }
     $linesep
  }

 }
#$changelog |out-gridview 
$linesep

P2V_footer -app $My_name
exit
# =============== do not cross this line ==================================================================#
