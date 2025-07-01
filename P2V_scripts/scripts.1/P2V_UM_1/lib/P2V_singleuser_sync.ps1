#-----------------------------------------
# P2V_singleuser_sync
#
#  name:   P2V_singleuser_sync.ps1 
#  ver:    0.1
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key (searchstring) and sync to selected tenants
#-----------------------------------------
param(
  [string]$xkey="",
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  [bool]$checkOnly = $False
)
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#-----   local functions
Function  P2V_add_user  ($tenant, $user_profile)
{ # function to add 1 user to P2V_tenant
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users"
  
  $form1 -f "add $($user_profile.logonID) to $($tenant.tenant)"
  $body = ($user_profile |ConvertTo-Json)
  
  $body = [System.Text.Encoding]::UTF8.GetBytes($body)
  $result = Invoke-RestMethod -Uri $API_URL -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
  
  if ($result) {$rc="[DONE]"  ;$r=$true}
  else         {$rc="[ERROR]" ;$r=$false} 
  
  $form_status -f $user_profile.displayName,$rc 
  out-host  
  return $r
}

Function  P2V_update_user ($tenant, $user_profile, $change)
{ # function to update existing user in P2V_tenant
  #
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users/$($user_profile.id)"
   
  $body = ($change|ConvertTo-Json)
  #$body = [System.Text.Encoding]::UTF8.GetBytes($body)
    
  #P2V_print_object ($change)
  $result = Invoke-RestMethod -Uri $API_URL -Method PATCH -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
    
  if ($result) {$rc="[DONE]"  ;$r=$true}
  else         {$rc="[ERROR]" ;$r=$false} 
  
  $form_status -f $user_profile.displayName,$rc
  out-host
  return $r
}
#----- Set config variables

$output_path = $output_path_base + "\$My_name"
createdir_ifnotexists($output_path)

$spec_accounts = @("adminx449222@ww.omv.com","adminarun05")
#----- start main part
P2V_header -app $My_name -path $My_path 

# -- some variables
	
	$u1_list_vendor=@{}
	$u_list_AD=@{}
	
# -- special group for vendors
	$vendor_group= "dlg.WW.ADM-Services.P2V.Aucerna"
	
	$u_list_vendor=Get-ADGroupMember -Identity $vendor_group|Get-ADUser -properties Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress 
    $u_list_vendor |% {$u1_list_vendor[$($_.UserPrincipalName)]=$_}
# -- load all AD access groups
    $all_systems =import-csv $tenantfile|select -Unique ADgroup
    foreach ($g in $all_systems)
	{
	   $ga=$g.ADgroup
	   $u_list_AD[$ga] =Get-ADGroupMember -Identity "$ga"|Get-ADUser -properties Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress 
	   $form_user1 -f $u_list_AD[$ga].count, "users loaded from AD [$ga]",""|out-host
	}
$linesep|out-host

#--- select user from AD
While ($user_from_AD= P2V_get_AD_user_UI($xkey))
{
   $changelog= @()
     
   if(! $user_from_AD) {$form_err -f "[ERROR]", " !! [$($user_from_AD.Name)] does not exist in Active Directory !!"  ;exit }	
   else
   { #print user AD profile
      $linesep
      $form1 -f  "Active Directory information for $($user_from_AD.SamAccountName)"
      $linesep
      P2V_print_object($user_from_AD)
   }
   $logonID=$user_from_AD.logonID

   # get tenants to sync
   #--- select tenant from AD
   $tenants= P2V_get_tenant_UI($tenantfile)
  
   #$tenants|%{$linesep;$_}
   
   #
   $form1 -f "sync user $logonID  from AD to the tenants"
   $tenants.keys|% {$form1 -f " > $_"}
    
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
    
	 #--
     $t_sel=$tenants[$t_s]
	 $tenant=$t_sel.tenant
	 $change_ops=@()
	 $form1 -f "> $tenant <"
     
	 $AD_group   = $t_sel.ADgroup # identify "externals= membership of group to add a mark to the description
         
     $u1_list_P2V=@{}
     $u1_list_AD =@{}

     #-- get AD -user list (list to allow access to system)
     #-D> $u_list_AD =Get-ADGroupMember -Identity $AD_group|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress 

     #| where-Object { ($($_.UserPrincipalName) -like $logonID)} 
     #$form_user1 -f $u_list_AD.count, "users loaded from AD [$AD_group]",""|out-host
	 $u_list_AD[$AD_group]|% {$u1_list_AD[$($_.UserPrincipalName)]=$_}
     
  	 #-- get P2V user list
	 $u_list_P2V = P2V_get_userlist ($t_sel)| where-Object {($($_.authenticationMethod) -ne 'LOCAL') }
	 $form_user1 -f $u_list_P2V.count, "non-local users loaded from $tenant","" |out-host
	 $u_list_P2V|% {$u1_list_P2V[$($_.logOnId)]=$_}	 	 
	 #$user_from_P2V= $u_list_P2V  
	 #P2V_print_object(($u1_list_P2V|where-Object { ($($_.logonID) -like $logonID)}))#|select id,displayname,description,IsAccountLocked,isDeactivated))
   
     #-- start setting up to-be profile
	 $u_ad_sel=$u1_list_AD[$logOnId]    
	 $descr = $u_ad_sel.Department -replace '[,]', ''
	 if ($u1_list_vendor.ContainsKey($logOnId)) { $descr = "[AUCERNA] "+$descr}
     $to_be = [PSCustomObject]@{
				id					 = $u1_list_P2V[$logOnID].id
                logOnId              = $logonID
                displayName 		 = "$($user_from_AD.Surname) $($user_from_AD.GivenName) ($($user_from_AD.name))"
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
	   { # user in AD  and in P2V ->start comparison
	   	    #P2V_print_object ($to_be)
			foreach ($element in $to_be.PSObject.Properties) 
	        {
                #$form2_1 -f "$($element.Name)","$($element.Value)"
								  
 	            $change = [PSCustomObject]@{
				       tenant				 = $tenant
                       logOnId               = $logonID
                       attribute		     = $element.Name
                       old_value_P2V 		 = $u1_list_P2V[$logonID].$($element.Name)
                       new_value_P2V 		 = $($element.Value)
					   activity				 = ""
                }
				  
	            if ($($change.old_value_P2V) -ne $($change.new_value_P2V)) 
			    {
			      $change.activity = "CHANGE"
				  $change_ops += [PSCustomObject]@{  
                       op     = "replace"
                       path   = "/$($element.Name)"
                       value  = "$($element.Value)"
                  }
				  $form2_1 -f "   OLD: change $($element.Name)","$($change.old_value_P2V)" |out-host
				  $form2_1 -f "   NEW:                        ","$($change.new_value_P2V)"|out-host
			    }  else
			    {
			      $change.activity = "SKIP"
			    }
	            $changelog +=$change
	  		}
			if ($write_changes)
		    { 
			    if ($($change_ops.count) -gt 0){ $resp= P2V_update_user -tenant $t_sel -user_profile $to_be -change $change_ops  }
		    }
		    else {$form1 -f ">> no changes applied to $tenant <<"}	   	
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
		 
            if ($write_changes) { $rc= P2V_add_user -tenant $t_sel -user_profile $to_be }
		    else                { $form1 -f " no changes applied to $tenant"}
	   }
	 } else
	 {# user not in AD -> remove access to P2V
	   $linesep
	   $to_be.isDeactivated =$True
	   if ($u1_list_P2V.ContainsKey($logOnId))
	   { #user already exists but not in AD -list -> deactivate
	          
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
	   { # user not in P2V and not in AD -> do nothing ;-)
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
$changelog |out-gridview 
$linesep

P2V_footer -app $My_name
exit
# =============== do not cross this line ==================================================================#
#--- check differences
do
{
$acount=0
$ccount=0
$dcount=0
$add_ops=@()
$del_ops=@()
$change_ops=@()
$updateOperations = @{}
$deleteOperations = @{}
$linesep
foreach ($u1 in $($u1_list_P2V.keys))
{
   if ($spec_accounts -contains $u1) {$form_status -f "* special account $u1","[SKIP]"} # skip spec. accounts (e.g. adminx449222@ww)
   else{
    $change_ops=@()
	$del_ops=@()
			
    if ($u1_list_AD.ContainsKey($u1))
    {
      #-- user found - update infos
	  $u_ad   = $u1_list_AD[$u1]
	  $u_p2v  = $u1_list_P2V[$u1]
	  #$form1 -f "$($u_ad.UserPrincipalName) found - update details"
	  
	  #-- create update ops
  
      $descr = $u_ad.Department -replace '[,]', ''
	  $dname = "$($u_ad.Surname) $($u_ad.GivenName) ($($u_ad.name))"
      $authenticationMethod = "SAML2"
      $isDeactivated        = "False"
      $isAccountLocked      = "False"
      $useADEmailAddress    = $True
	  
	   # if($dname -ne $u_p2v.displayname)
	   # { $change_ops += [PSCustomObject]@{  
                  # op = "replace"
                  # path = "/displayName"
                  # value = $dname
              # } 
	   # }
	  if ($u1_list_vendor.ContainsKey($u1))
	  { $descr = "[AUCERNA] "+$descr}
	  	  
	  if($descr -ne $u_p2v.description)
	  { 
	   
	   $change_ops += [PSCustomObject]@{  
                 op = "replace"
                 path = "/description"
                 value = $descr
             } 
	  }
             
      If (!($u_p2v.useADEmailAddress))
	  { $change_ops += [PSCustomObject]@{
                 op = "replace"
                 path = "/useADEmailAddress"
                 value = $True
			 }
      }			 
	
      if ($u_p2v.isDeactivated)
	  { $change_ops += [PSCustomObject]@{
                 op = "replace"
                 path = "/isDeactivated"
                 value = $False
             }
	  }
	  if ($u_p2v.isaccountlocked)
	  {	$change_ops += [PSCustomObject]@{  
                 op = "replace"
                 path = "/isAccountLocked"
                 value = "False"
            }
      }			
      if ($change_ops.count -gt 0)
	  {$ccount +=1
	  $form_status -f "$($u_ad.UserPrincipalName) found","[UPDATE]"
	  } 
	} else
    { #-- user not entitled -> deactivate
   
      $u_p2v=$u1_list_P2V[$u1]
	 	  
	  
	  if (!($u_p2v.isDeactivated))
	  { 
	     $form_status -f "$($u_p2v.logonID)  in P2V but not in AD","[DEACTIVATE]"
	     $del_ops += [PSCustomObject]@{
                 op = "replace"
                 path = "/isDeactivated"
                 value = "True"
         }
	     $dcount +=1 
	  }else
	  {
	    $form_status -f "$($u_p2v.logonID)  already deactivated","[SKIP]"
	  }
     }
	 
   if ($($change_ops.count) -gt 0){ $updateOperations[$u_p2v.id.ToString()] = $change_ops  }  
   if ($($del_ops.count) -gt 0)   { $deleteOperations[$u_p2v.id.ToString()] = $del_ops  }    
   }
}
$linesep
foreach ($u2 in  $u1_list_AD.keys)
{
   if ($u1_list_P2V.ContainsKey($u2))
   {
   # /-- no ops - already done 
   }
   else
   {
      #-- user not existing -> create
      $u_ad_sel=$u1_list_AD[$u2]
	  #$u_p2v_sel=$u1_list_P2V[$u2]
      	 
	  $form_status -f "$($u_ad_sel.UserPrincipalName)  in AD but not in P2V","[CREATE]"
	  	  
	  $add_ops += [PSCustomObject]@{
                logOnId = $u_ad_sel.UserPrincipalName
                displayName = "$($u_ad_sel.Surname) $($u_ad_sel.GivenName) ($($u_ad_sel.name))"
                description = $u_ad_sel.Department -replace '[,]', ''
                isDeactivated = $False
                isAccountLocked = $False
                authenticationMethod = "SAML2"
				useADEmailAddress    = $True
            }
     }
}
$linesep
$acount=$add_ops.count

if (($cont=read-host ($form1 -f "add $acount users? (y/n)")) -like "y")	
{
     if ($($add_ops.count) -gt 0)   
	 { 
	   $linesep
	   $form1 -f "..adding users"
	      
       if (!$checkOnly) 
       {
	     
	     foreach ($a in $add_ops)
		 {
	        $body = $a|convertto-json
			$body = [System.Text.Encoding]::UTF8.GetBytes($body)
			$result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
			if ($result) {$rc="[DONE]"}else {$rc="[ERROR]"} 
		    
			$form_status -f $a.displayName,$rc
			
		}
	   }
	 }
 }

if (($cont=read-host ($form1 -f "update $ccount users? (y/n)")) -like "y")	
{
    if ($($updateOperations.count) -gt 0)   
	{  
	   $linesep|out-host
	   $form1 -f "..updating users"|out-host
	   $updateOperations |format-table|out-host
	   if (!$checkOnly) 
       {
    	  $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json" 
  	      $result  |format-list|out-host 
	   }
	}
}

if (($cont=read-host ($form1 -f "deactivate $dcount users? (y/n)")) -like "y")	
{
    if ($($deleteOperations.count) -gt 0)   
	{
       $linesep
	   $form1 -f "..deactivating users"
       #$deleteOperations |convertto-Json  	
       if (!$checkOnly) 
       {
	     $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($deleteOperations|ConvertTo-Json) -ContentType "application/json"
	     $result  |format-list|out-host 	 
	   }
	}
}
}until ($false)


exit
