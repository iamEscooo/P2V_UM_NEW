#=======================
#  P2V_include.ps1
#  V 0.6
#  
#  general P2V functions for usermgmt
#
#  Martin Kufner
#=======================
#  1. global variables
#  2. P2V_header
#  3. P2V_footer  
#  4. P2V_Show-Menu
#
#-------------------------------------------------------
#  central layout settings

#-- check if already called (ne)
if ($called) {exit}
$called=$True
$global:debug = $false

#===================================================
<#====  objects                                 ====
#===================================================

----  user_profile AD                          ----
$AD_user=[PSCustomObject]@{
      Givenname,
      surname,
      SamAccountName, 
      EmailAddress, 
      comment, 
      Department, 
      lastlogon, 
      accountExpires,
      UserPrincipalName,
      displayName,
      logOnId
}
		
----  user_profile PS                          ----
$PS_user=[PSCustomObject]@{
       id					= PS user ID
       logOnId              = PS Login name (~ UPN)
       displayName 		    = "$($user_from_AD.Surname) $($user_from_AD.GivenName) ($($user_from_AD.name))"
       description 		    = Department from AD 
       isDeactivated 	 	= $False
       isAccountLocked 	    = $False
       authenticationMethod = "SAML2"
       useADEmailAddress    = $False
       emailAddress         = $user_from_AD.EmailAddress
}
---------------------------------------------------

----  tenant                                   ----
$tenant=[PSCustomObject]@{
       system         = from Csv $tenantfile
       ServerURL      = from Csv $tenantfile
       tenant         = from Csv $tenantfile
       resource       = from Csv $tenantfile
       name           = from Csv $tenantfile
       API            = from Csv $tenantfile
       ADgroup        = from Csv $tenantfile
       base64AuthInfo : calculated string
}
---------------------------------------------------
#>

<# 
#===================================================
#====  Active Directory functions               ====
#===================================================

#---------------------------------------------------
Function get_AD_user
{ # function to verify and select user  via GUI 
  # return values:
  # $ad_user_selected:  FALSE in case of error
  # $ad_user_selected:  userprofile:
  #       Givenname,
  #       surname,
  #       SamAccountName, 
  #       EmailAddress, 
  #       comment, 
  #       Department, 
  #       lastlogon, 
  #       accountExpires,
  #       UserPrincipalName,
  #       displayName,
  #       logOnId
  #--------------------------------
  param (
       [string]$searchstring= "",
    [string]$xkey=""
    )
   $ad_user_selected=""
   
   if ($xkey) {$searchstring=$xkey}
   
   while (!$ad_user_selected)
	 {
	 	while (-not $searchstring) {$searchstring="";return $False}  ## ??? check
		
		if ($xkey) 
		{
		    
		   $u_res=Get-ADUser -identity $xkey.trim() -properties * |
		select  Name, 
		        Givenname, 
				surname,
				SamAccountName,
				UserPrincipalName, 
				EmailAddress, 
				Department,
				distinguishedName,
				lastlogon,
				lastLogonTimestamp,
				accountExpires,
				comment,
				description 
		} else
		{
		    $ad_user='*'+$searchstring.trim()+'*'
		
		    $u_res=Get-ADUser -SearchBase "DC=ww,DC=omv,DC=com" -Filter { (Givenname -like $ad_user) -or (Surname -like $ad_user) -or (Name -like $ad_user)} -properties * |
		    select  Name, 
		        Givenname, 
				surname,
				SamAccountName,
				UserPrincipalName, 
				EmailAddress, 
				Department,
				distinguishedName,
				lastlogon,
				lastLogonTimestamp,
				accountExpires,
				comment,
				description 
	    }	
	    $u_count=0
		$u_res|%{ $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
				
				$_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss') ;
				
				if ("$($_.distinguishedName)" -match "Deactivates") {$_.comment="DEACTIVATED"} else {$_.comment="ACTIVE"} 
				$u_count++
               }
		$searchstring="" # reset searchstr
			
		$ad_user_selected=$u_res|select Givenname,surname,SamAccountName, EmailAddress, comment, Department, lastlogon, accountExpires,UserPrincipalName
				
		If (!$ad_user_selected) {$form_err -f "ERROR","$ad_user_selected not found or no user selected"|out-host;$ad_user_selected=""}
		else
		{
   		   if ($u_count -gt 1) 
		   {
		     $ad_user_selected=$ad_user_selected|out-gridview -Title "select user from AD" -outputmode single
		   }
		
    	  $ad_user_selected.Department=$ad_user_selected.Department -replace '[,]', ''
		  $ad_user_selected.Department=($ad_user_selected.Department).trim()
				
		  $ad_user_selected| Add-Member -Name 'displayName' -Type NoteProperty -Value "$($ad_user_selected.surname) $($ad_user_selected.Givenname) ($($ad_user_selected.SamAccountName))"
	      $ad_user_selected| Add-Member -Name 'logOnId' -Type NoteProperty -Value "$($ad_user_selected.UserPrincipalName)" 
		      

		}
	}	 
	#write-output "get_AD_user: `n$ad_user_selected"
	
    return $ad_user_selected	
} 

#---------------------------------------------------
Function get_AD_userlist 
{ # Get-userlist from a given AD-Group  
   param(
   [string]$ad_group="dlg.WW.ADM-Services.P2V.access.production",
   [bool]  $all=$False
   )
   
    if ($check_group = Get-ADgroup -Identity $($ad_group))  #  OLD : -LDAPFilter "(SAMAccountName=$ad_group)")
    {
	   # AD group found
       $entries=Get-ADGroupMember -Identity $ad_group | Get-ADUser -properties * |Select Givenname,Surname,SamAccountName, EmailAddress, comment, Department, lastlogon, accountExpires,UserPrincipalName
   
       $entries |%{ $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
		            $_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss');
				    $_.Department=$($_.Department) -replace '[,]', ''
				    Add-Member -inputObject $_ -Name 'displayName' -Type NoteProperty -Value "$($_.surname) $($_.Givenname) ($($_.SamAccountName))"
				    Add-Member -inputObject $_ -Name 'logOnId'     -Type NoteProperty -Value "$($_.UserPrincipalName)" 
			      } 
				  
       if (!$all){ $entries = $entries|out-gridview -title "select (multiple) user(s)" -outputmode multiple}
    } else
	{ #AD group not found
        $form_status -f "AD:  $ad_group","[ERROR]"
	    $entries=$false
	}
    return $entries
}


Function get_AD_groups
{ # get AD-group member (incl. temp.storing)
   $all_adgroups = @{}
   $all_adgroups =import-csv $adgroupfile  
   






}

 #>
#===================================================
#====  Planningspace functions                  ====
#===================================================

#---------------------------------------------------
Function select_PS_tenants_OLD # not used anymore 
{ # funtion to select tenant via GUI  -> returns list (1..n  tenants)
  # returns array  $selected_tenants[tenantname]=@{
  #        system         = from Csv $tenantfile
  #        ServerURL      = from Csv $tenantfile
  #        tenant         = from Csv $tenantfile
  #        resource       = from Csv $tenantfile
  #        name           = from Csv $tenantfile
  #        API            = from Csv $tenantfile
  #        ADgroup        = from Csv $tenantfile
  #        base64AuthInfo : calculated string  
  #}
  param (
         [bool] $multiple=$true, 
	     [bool] $all=$false
	 )
	 
  $t_sel= @{}
  $t_list= @{}
  $t_resp= @{}
  
  $all_tenants =import-csv $tenantfile 
  $all_tenants |% {$t_list[$($_.tenant)]=$_}
  if (!$all_tenants) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
     
  
  if ($all)      
  {  $t_sel=$all_tenants  }
  else
  {  
    if ($multiple) {$out_mode="multiple"}else {$out_mode="single"}
    $t_sel=$all_tenants|select system,tenant, ServerURL |out-gridview -Title "select tenant(s)" -outputmode $out_mode
  }

#  add baseauthstring to tenant
  $t_sel|%{ $t_resp[$_.tenant]=$t_list[$_.tenant];`
            $b=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_list[$_.tenant].name, $t_list[$_.tenant].API)));`
		    $t_resp[$_.tenant]| Add-Member -Name 'base64AuthInfo'  -Type NoteProperty -Value "$b" }
    
  return $t_resp
}

#---------------------------------------------------
Function get_PS_userlist_OLD ($tenant)  # not used anymore 
{ #get-userlist from Planningspace $tenant
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" # w/o grouplist?
  
  $t_users=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
  if (!$t_users) {write-host -ForegroundColor Red ($form_err -f "[ERROR] cannot contact $($tenant.tenant) !");return $False}
  #else { $t_users|%{$t_resp[$_.logOnId]=$_}}
  
  return $t_users
 }

#---------------------------------------------------
Function get_PS_grouplist($tenant)
{ #get-workgrouplist from Planningspace $tenant
  
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/workgroups?include=Users"
  
  $t_groups = Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
  if (!$t_groups) {write-host -ForegroundColor Red ($form_err -f "[ERROR] cannot contact $($tenant.tenant) !")}
   
  return $t_groups
}

#---------------------------------------------------
Function get_PS_user_groups   ($tenant,$user_id)
{
   
#https://ips-update.ww.omv.com/P2V_UPDATE/PlanningSpace/api/v1/users/commonworkgroups?ids=100

   "tttttttt"
   $tenant|format-list
   "tttttttt"
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users/commonworkgroups?ids=$user_id"
  
  $t_groups = Invoke-RestMethod -Uri "$API_URL" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
  if (!$t_groups) {write-host -ForegroundColor Red ($form_err -f "[ERROR]"," cannot contact $($tenant.tenant) !")}
   
  return $t_groups
}

Function add_PS_user ($tenant, $user_profile)
{# function to add 1 user to P2V_tenant
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users"
  
  write-output ($form1 -f "add $($user_profile.logonID) to $($tenant.tenant)")
  $body = ($user_profile |ConvertTo-Json)
  
  $body = [System.Text.Encoding]::UTF8.GetBytes($body)
  $result = Invoke-RestMethod -Uri $API_URL -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
  
  if ($result) {$rc="[DONE]"  ;$r=$true}
  else         {$rc="[ERROR]" ;$r=$false} 
  
  write-output ($form_status -f $user_profile.displayName,$rc )
    
  return $r
}
#---------------------------------------------------

Function update_PS_user ($tenant, $user_profile_old, $user_profile_new)
{ #  function to update existing user in P2V_tenant
  #  [tenant] $tenant7
  #  [PS_user]  $user_profile_old
  #  [PS_user]  $user_profile_new
  #
  <# param (
    [Parameter(Mandatory=$true, Position=0)][PSCustomObject] $tenant=@{},
    [Parameter(Mandatory=$true, Position=1)][PSCustomObject] $user_profile_old=@{},
	[Parameter(Mandatory=$true, Position=2)][PSCustomObject] $user_profile_new=@{}
  ) #>
  
  $debug=$false
  $quiet=$false
 
  #check if arguments are ok
  if (!$($tenant.tenant)) { write-error "tenant arguement emtpy!";return $False}
  if (!$($user_profile_new)){ write-error "user_profile_old emtpy!";return $False}
  if (!$($user_profile_old)){ write-error "user_profile_new emtpy!";return $False}
  if ( $($user_profile_new.id) -ne $($user_profile_old.id)) {write-error "user_profile id do not match!";return $False}
  
  $u_old=$user_profile_old|select id, logOnId, displayName, description, isDeactivated, isAccountLocked, authenticationMethod, useADEmailAddress, emailAddress  
  $u_new=$user_profile_new|select id, logOnId, displayName, description, isDeactivated, isAccountLocked, authenticationMethod, useADEmailAddress, emailAddress  
  
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users/$($user_profile_new.id)"

  if ($debug)   { #show extra lists
  
    $u_old|Add-Member -Name "Age" -Type NoteProperty -Value "OLD"
    $u_new|Add-Member -Name "Age" -Type NoteProperty -Value "NEW"
    write-host -ForegroundColor yellow '>> tenant <<'
    $tenant|format-list|out-host
    write-host -ForegroundColor yellow '>> compare user profiles<<'
    ($u_old,$u_new)|select Age, id, logOnId, displayName, description, isDeactivated, isAccountLocked, authenticationMethod, useADEmailAddress, emailAddress  |format-table|out-host
  }
  
  $change_ops= @() 
  $change_logs= @() 
  
  foreach ($element in $u_new.PSObject.Properties) 
  {
     $change = [PSCustomObject]@{
	    tenant				= $($tenant.tenant)
        logOnId             = $u_new.logOnId
        attribute		    = $element.Name
        old_value_P2V 		= $u_old.$($element.Name)
        new_value_P2V 		= $u_new.$($element.Name)
		activity		 	= ""
     }
	 if ($($change.old_value_P2V) -ne $($change.new_value_P2V)) 
	 {
		$change.activity = "CHANGE"
		$change_ops += [PSCustomObject]@{  
			op     = "replace"
            path   = "/$($element.Name)"
            value  = "$($element.Value)"
        }
				  
		$form_chlogs -f $($change.activity), $($element.Name), "$($change.old_value_P2V)","-> $($change.new_value_P2V)",""|out-host
     }  else
	 {
 	    $change.activity = "SKIP"
	 }
     $change_logs +=$change
  }
  if ($debug)   { # print extra checks
    $change_logs|format-table|out-host
    $linesep
    $change_ops|format-table|out-host
  }
 
  
  $body= $change_ops|ConvertTo-Json
  if ($($change_ops.count) -gt 0 )
  { # no changes required -> u_old == u_new
    if ($($change_ops.count) -eq 1 ){ $body="[ $body ]" }  
	
   #	if (($cont=read-host ($form1 -f "write changes in [$($tenant.tenant)] for $($u_new.logOnId) (y/n = default)")) -like "y") {$write_changes=$true} else {$write_changes=$false}
 
    # switch ($cont=read-host ($form1 -f "write changes in [$($tenant.tenant)] for $($u_new.logOnId) (y-yes/n-no = default/a-all /x-none)"))
	# {
	  # "y"     {$write_changes=$true} 
	  # "n"     {$write_changes=$false}
	  # "a"     {$write_changes=$true;$all_write=$true}
	  # "x"     {$write_changes=$false;$no_write=$true}
	  # default {$write_changes=$false}
	# }
	 
	if ($write_changes) 
	{ 
	   if ($debug)   {
	     $form1 -f "calling $API_URL with"|out-host
	     $body|out-host
	   }

	   $body = [System.Text.Encoding]::UTF8.GetBytes($body)
  
  	   $result = Invoke-RestMethod -Uri $API_URL -Method PATCH -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
    
       if ($result) {$rc="[DONE]"  ;$r=$true}
       else         {$rc="[ERROR]" ;$r=$false} 
	   
	   $form_status -f "$($u_new.displayName)",$rc|  out-host
	   
	} else
	{ $form1 -f "no changes applied on user request"|out-host }
  } 
  else
  { $form_status -f "no changes required","[SKIP]"|out-host}
 
  
  return $True
}

#---------------------------------------------------
Function set_PS_user_status ($tenant,$uid,[bool]$deactivate=$false,[bool]$lock=$false,[bool]$verbose=$false)
{
  
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users/$uid" # w/o grouplist?
  $chg_op= @{}
  $chg_ops= @()
   
  $result=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
  
   if ($deactivate)  {$sc="DEACTIVATED"} else {$sc="ACTIVE" }
   if (($result.isDeactivated -ne $deactivate))  
   {
	 $chg_op = [PSCustomObject]@{
          op = "replace"
          path = "/isDeactivated"
          value = "$deactivate"
     }
	 $chg_ops += @($chg_op)
   } else 
   { $form_status -f "$($result.displayName) is already in  activation status", $sc }
   
   if ($lock)  {$sc="LOCKED"} else {$sc="UNLOCKED" }
   if (($result.isAccountLocked -ne $lock))  
   {
	 $chg_op = [PSCustomObject]@{
          op = "replace"
          path = "/isAccountLocked"
          value = "$lock"
     }
	 $chg_ops += @($chg_op)
   } else 
   { $form_status -f "$($result.displayName) is already in  lock status", $sc  }
     	  
   if ($chg_ops.count -gt 0)
   {
     
     $body=  @($chg_ops) |convertto-json
	 if ($($chg_ops.count) -eq 1 ){ $body="[ $body ]" }
	 
    if ($verbose) 
	{ 
	  $body|out-host
	  pause
	}
	 
	 $result=Invoke-RestMethod -Uri $API_URL -Method PATCH -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body) -ContentType "application/json"
	 
	 if ($result) {$form1 -f "$($result.displayName) set to activation status $status"}
	 else         {$form_err -f "[ERROR]", "$($result.displayName) could not be set to activation status $status"}
	
   }
 }
  
Function activate_PS_user ($tenant,$User_Id)
{
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users/$User_id"
  $chg_op = [PSCustomObject]@{
            op    = "replace"
            path  = "/isDeactivated"
            value = "false"
        }
  $debug=$False
 
  $body =
  $body= $chg_op|ConvertTo-Json
  $body="[ $body ]" 
  
  #check if arguments are ok
  if (!$($tenant.tenant)) { write-error "tenant arguement emtpy!";return $False}
  
  
  $result=Invoke-RestMethod -Uri $API_URL -Method PATCH -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
	 
  if ($result) {$form1 -f "$($result.entity.displayName) set to active "}
 else         {$form_err -f "[ERROR]", "$($result.displayName) could not be set to activation status $status"}
 }     
 
Function deactivate_PS_user ($tenant,$User_Id)
{
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users/$User_id"
  $chg_op = [PSCustomObject]@{
            op    = "replace"
            path  = "/isDeactivated"
            value = "true"
        }
  $debug=$False
 
  $body =
  $body= $chg_op|ConvertTo-Json
  $body="[ $body ]" 
  
  #check if arguments are ok
  if (!$($tenant.tenant)) { write-error "tenant arguement emtpy!";return $False}
  
  
  $result=Invoke-RestMethod -Uri $API_URL -Method PATCH -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
	 
  if ($result) {$form1 -f "$($result.entity.displayName) deactivated "}
 else         {$form_err -f "[ERROR]", "$($result.displayName) could not be set to activation status $status"}
  
  }


Function get_PS_user ($tenant,$logOnId)
{
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" # w/o grouplist?
  
  $t_users=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
  
  if (!$t_users) {write-host -ForegroundColor Red ($form_err -f "[ERROR] cannot contact $($tenant.tenant) !");return $False}
  $uresult=$t_users|where { ($_.logonid -eq $logonid)}
    
  $uresult|format-list
  return $uresult
}

Function PS_user_clear_all_workgroups ($tenant,$logonID,[bool]$verbose=$false)
{
#
#
#
# [ { "op": "replace", "path": "/users", "value": {} } ]


  $tenantURL      = "$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo = "$($tenant.base64AuthInfo)"
  #$API_1URL      = "$tenantURL/PlanningSpace/api/v1/users/"
  $API_URL        = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
 
 #check if arguments are ok
  if (!$($tenant.tenant)) { $form_status -f "tenant argument emtpy!", "[ERROR]";return $False}
  $u_list=get_PS_userlist $tenant 
  $p2v_u=$ulist|  where-Object {($($_.logOnId) -like $logOnId) }
  
  if (!$p2v_u)
  {
    $form_status -f "user $logOnid not in tenant $($tenant.tenant)", "[ERROR]"
	return $false
  }
  
  set_PS_user_status -tenant $t -uid $p2v_u.id -deactivate $false -lock $p2v_u.isAccountLocked -verbose $verbose
  
  $deleteOperations = @{}
  $uid=$p2v_u.id
  foreach ($gs in $p2v_u.userWorkgroups)
  {
	$gs | Get-Member -MemberType Properties | select -exp "Name" | % { $gid= @($($gs| SELECT -exp $_).id);
	$deleteOperations["$gid"] = [PSCustomObject]@{
            op    = "remove"
            path  = "/users/$uid"
            value = ""							
	    }
    }
  }   
   
  foreach ($k in $($deleteoperations.keys))
  {
     $deleteoperations[$k]=@($deleteoperations[$k])
  }

   if ($deleteoperations.Count -gt 0 )
    {
	    if ($verbose) { $form1 -f "preparing $($deleteoperations.Count) removals"}
   	    $body= ConvertTo-Json $deleteoperations
		
        $i_result = Invoke-RestMethod -Uri $API_URL -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
	 
	    $form_status -f  "changing  user /workgroups assignments", "[DONE]"
        If (!$i_result) { $form_err -f "ERROR", "changes failed"}
        else {
               $form1 -f " Creation result:"
               #$i_result #| format-table|out-host #|Out-gridview -title "result of Workgroup changes" -wait
			   $i_result |format-list|out-host 
			   $form1 -f " Finished updating workgroups" |out-host
			 }
    }

   set_PS_user_status -tenant $t -uid $p2v_u.id -deactivate $p2v_u.isDeactivated -lock $p2v_u.isAccountLocked	-verbose $verbose
   return $true
}

Function get_profiles ([bool] $debug=$false)
{
   write-debug ($form1 -f "loading profiles from $profile_file")
   $csv_profiles=import-csv -path $profile_file |sort profile
   $profiles = @{}
   

   foreach ($l in $csv_profiles) 
   {
     $profiles["$($l.profile)"]+= @($($l.groups))
   }
   if ($debug) {$profiles|format-table |out-host }
     
   write-output ($form_status -f "load profile definitions $profile_file","[DONE]")

  return $profiles
}

Function check_datagroup_dependencies ( [System.Collections.ArrayList] $grouplist,[bool] $debug=$false)
{
   	#write-host $linesep
	write-debug ($form1 -f ">> check_datagroup_dependencies ")
	#write-host $linesep
    # check datagroups 
  
   #$Eco_groups= @("profile.Economics.Headoffice","profile.Economics.local")
   #$Fin_groups= @("profile.Finance.Headoffice","profile.Finance.local")
   #$PP_groups=  @("profile.PP.Headoffice","profile.PP.Headoffice.Power","profile.PP.local")
   #$RES_groups= @("profile.Reserves.Headoffice","profile.Reserves.Headoffice.Approve","profile.Reserves.Headoffice.Power","profile.Reserves.local.Approve","profile.Reserves.local.QRE")
   #$Port_groups= @("profile.Portfolio.Light","profile.Portfolio.Power")
   $Eco_groups= @("A13.profile.Economics.Classic","A15.profile.Economics.Plus")
   $Fin_groups= @("A16.profile.Finance.Classic","A18.profile.Finance.Plus")
   $PP_groups=  @("A10.profile.Planning.Classic","A11.profile.Planning.Plus")
   $RES_groups= @("A20.profile.Reserves.local.QRE","A21.profile.Reserves.Headoffice","A22.profile.Reserves.Headoffice.Power","A23.profile.Reserves.Headoffice.Approve")
   $Port_groups= @("A19.profile.Portfolio.Classic","A26.profile.Portfolio.Plus")
   $port_countries= @("data.Bulgaria","data.Corporate","data.Georgia","data.Romania")
   $CAPDAT_groups= @("A03.profile.CAPDAT")
   $other_groups=@("A06.profile.Light.Fin.Port")
 #  $Exp_groups= @("A24.profile.Exploration.Assurance")
  # $Exp_countries= @("data.Corporate")
  
   Foreach ($g in $eco_groups) {if ($grouplist -contains $g) {$eco=$true} else {$eco=$eco -or $false} }
   Foreach ($g in $fin_groups) {if ($grouplist -contains $g) {$fin=$true} else {$fin=$fin -or $false} }
   Foreach ($g in $PP_groups)  {if ($grouplist -contains $g) {$pp=$true} else {$pp=$pp -or $false} }
   Foreach ($g in $RES_groups) {if ($grouplist -contains $g) {$res=$true} else {$res=$res -or $false} }
   Foreach ($g in $Port_groups) {if ($grouplist -contains $g) {$port=$true} else {$port=$port -or $false} }
   Foreach ($g in $CAPDAT_groups) {if ($grouplist -contains $g) {$capdat=$true} else {$capdat=$capdat -or $false} }
   Foreach ($g in $other_groups) {if ($grouplist -contains $g) {$other=$true} else {$other=$other -or $false} }
	 
   write-verbose ($form1 -f "ECO: $eco  FIN: $fin   PP: $pp    RES: $res  Port: $port")	
   $data_groups=$config_path + "\data_groups-SEC2.csv"		
   $data_countries= import-csv $data_groups -Encoding UTF8
  # if ($debug)  {$data_countries|format-list|out-host}  
   
   Foreach ( $country in $data_countries)
   {
	  if ($grouplist -contains $($country.data))
	  {
         write-debug ( $form_debug -f "checking $($country.data)" )
		 
		 if ($eco -and ($grouplist -notcontains $($country.eco))) 
		 { 
		    $grouplist.Add($($country.eco))|out-null
		    write-debug ($form_status -f $($country.eco),"[ADD]")
		 }
			  
	     if ($fin -and ($grouplist -notcontains $($country.fin))) 
	     {  
		    $grouplist.Add($($country.fin))|out-null
			write-debug ($form_status -f $($country.fin),"[ADD]" )
		 }
				
		 if ($pp -and ($grouplist -notcontains $($country.key))) 
		 { 
		    $grouplist.Add($($country.key))|out-null
		    write-debug ($form_status -f $($country.key),"[ADD]")
		 }
		 
		 if ($res -and ($grouplist -notcontains $($country.res))) 
		 { 
		    $grouplist.Add($($country.res))|out-null
		    write-debug ($form_status -f $($country.res),"[ADD]")
		 }
		 #write-output ($form1 -f "Portfolio: $port  -  $country ")  
		 if  ($port_countries -contains $country.data)
		 {
			# $port_countries|fl|out-host
			 #write-output "--> $($country.port)"|out-host
		    if ($port -and ($grouplist -notcontains $($country.port))) 
		    { 
		       $grouplist.Add($($country.port))|out-null
		       write-debug ($form_status -f $($country.port),"[ADD]")
		    }
		 }
		 
		  if ($capdat -and ($grouplist -notcontains $($country.CAPDAT))) 
		 { 
		    $grouplist.Add($($country.CAPDAT))|out-null
		    write-debug ($form_status -f $($country.CAPDAT),"[ADD]")
		 }
	 	  if ($other -and ($grouplist -notcontains $($country.other))) 
		 { 
		    $grouplist.Add($($country.other))|out-null
		    write-debug ($form_status -f $($country.other),"[ADD]")
		 }
	 
      }	   
   }
   
   #if ($debug)  {$linesep;$grouplist|format-wide -column 3|out-host;$linesep;pause}
   #out-host
   if ($debug) {$grouplist|out-gridview -title "check_datagroup_dependencies" -wait }
   	
   write-debug "grouplist:  $($grouplist.GetType().FullName)"
   return ,$grouplist
}

Function check_BD_dependencies ( $login,[System.Collections.ArrayList] $grouplist,[bool] $debug=$false)
{
   $bd_assignments= @{}
   $all_bd= @{}
   $all_bd_ids= @{}
   $all_bd_user_list = @{}
   $bd_group_members= @{}

   #write-host $linesep
   write-debug ($form1 -f ">> check_BD_dependencies ")
   #write-host $linesep	
   
   # standard group to base access BD-version in Dataflow
   write-debug "grouplist1:  $($grouplist.GetType().FullName)"
   $bd_base_group="BD.base"


   # do not touch these accounts
   $bd_exclude = @( "Administrator" , 
				 "Reserves_service" , 
				 "Reporting" , 
				 "PBI.corporate" , 
				 "PBI.corporate.BD" )
				 
   if ($bd_exclude -contains $login){return $grouplist}				 

   # load all user <> BD assignments (allows)
   # format: <BDID>,<xkey>,<logonID>
				 
   $all_bd= import-csv $bd_assign_file -Encoding UTF8|Sort-Object -Property BDID

   # later on :
   # $bd_exclude= Get-Content -Path $bd_exclude_file
   # NO filter - we need ALL BD-numbers
   # $all_bd = $all_bd | where-Object {$_.logonID -eq $login}

   $all_bd_ids =       $all_bd |Select-Object -Property BDID -Unique   # get all BD projects
   $all_bd_user_list = $all_bd |Where-Object logonID -like $login      # get all BD projects

   foreach ($bdi in $all_bd_ids)   # loop all BD-project ids
   {
 
      $bd=$all_bd|where-object {$_.BDID -eq $($bdi.BDID)} #get BD.id & logon  record
   
      $g_a = "$($bdi.BDID).allow"
      $g_d = "$($bdi.BDID).deny"
   
      if  ($bd.logonID -contains $login)
      { # found - user in BD -> add bd.allow
         if ($grouplist -notcontains $bd_base_group) 
	     {
	        $grouplist.Add("$bd_base_group")| Out-Null;
	        write-debug ($form_status -f $bd_base_group,"[ADD]")
	     }
	     if ($grouplist -notcontains $g_a) 
	     {
	        $grouplist.Add("$g_a")| Out-Null
	        write-debug ($form_status -f $g_a,"[ADD]")
	     }
	     if ($grouplist -contains $g_d) 
	     {
	        $grouplist.Remove("$g_d")| Out-Null
	        write-debug ($form_status -f $g_d,"[DEL]")
	     }
	  } else
	  { # add user to bd.xx.deny
         if ($grouplist -notcontains $g_d) 
	     {
	        $grouplist.Add("$g_d")| Out-Null
	        write-debug ($form_status -f $g_d,"[ADD]")
	     }
	     if ($grouplist -contains $g_a) 
	     {
	        $grouplist.Remove("$g_a")| Out-Null
	        write-debug ($form_status -f $g_a,"[DEL]")
	     }
	  }
   }
 
   if ($debug) {$grouplist|out-gridview -Title "check_BD_dependencies"}
   write-debug "grouplist2:  $($grouplist.GetType().FullName)"
   return $grouplist
}

Function check_license_dependencies ( [System.Collections.ArrayList] $grouplist,[bool] $debug=$false)
{
   # check licenses 
   # heavy && light   -> heavy
   # !heavy && !light  -> light
   # heavy || light   -> keep
   
   #write-host $linesep
   write-debug ($form1 -f ">> check_license_dependencies ")
      
   $heavy="license.heavy"
   $light="license.light"
   $l_h=$false
   $l_l=$false
      
   if ($grouplist -contains $heavy) {$l_h=$true}
   if ($grouplist -contains $light) {$l_l=$true}
   
   $lic_input= $grouplist|where-Object {$_ -eq $heavy -or $_ -eq $light}
   
   write-debug ($form1 -f "$lic_input light: $l_l heavy: $l_h ")
   
   if ($l_h -and $l_l) 
   {
      write-debug ($form_status -f $light,"[DEL]")
      $grouplist.Remove("$light")| Out-Null
   }
   if (!$l_h -and !$l_l) 
   {
      write-debug ($form_status -f $light,"[ADD]")
	  $grouplist.Add("$light")| Out-Null
   }
  
    out-host
    if ($debug) {$grouplist|out-gridview -title "check_license_dependencies"}
    write-debug "grouplist:  $($grouplist.GetType().FullName)"
    return $grouplist
} 

Function check_template_dependencies ( [System.Collections.ArrayList] $grouplist,[bool] $debug=$false)
{  #  check templates
   $DebugPreference ="Continue"
   #write-host $linesep
   

   if ($debug) 
   {
	   write-debug ($form1 -f ">> check_template_dependencies ")
	   write-debug "grouplist 1: $($grouplist.count) elements"
	}
   
	   
   $tag_triple=Import-Csv $tag_conf 
   if ($debug) {$tag_triple|format-table}
   
   foreach( $tag in $tag_triple)
   {
      #  binary setup (state0  asist  ; state 1 tobe)
	  #                             bit    421
	  #                                    x      ALLOW 1/0
	  #                                     x     READONLY   1/0
	  #                                      x    DENY 1/0
      $allow_code=    [convert]::toint32("0100",2)	 
      $readonly_code= [convert]::toint32("0010",2)	 
      $deny_code=     [convert]::toint32("0001",2)	 
	  
	  $state_asis=0   # as-is setup  
	  $state_tobe=1   # to-be setup
	  $state_name=""  # status text
	  $debug_form="{0,-20}: set to status {1,10}  [{2,4}] /[{3,4}]" 
      # calculate to-be status -  order matters !  implicit priority ...
	  if ($state_asis -eq 0)                         
	  {$state_tobe = $deny_code; $state_name= "DENY"
	   #$debug_form -f $tag , $state_name, [convert]::tostring($state_asis,2).PadLeft(4, '0'),[convert]::tostring($state_tobe,2).PadLeft(4, '0')|out-host
	   }  # default = DENY
	  
	  if ($grouplist -contains $($tag.deny))   
	  {$state_asis = $state_asis -bor $deny_code;$state_tobe = $deny_code; $state_name= "DENY"
	  #  $debug_form -f $tag , $state_name, [convert]::tostring($state_asis,2).PadLeft(4, '0'),[convert]::tostring($state_tobe,2).PadLeft(4, '0')|out-host
	  }
	  
	  if ($grouplist -contains $($tag.readonly)) 
	  {$state_asis = $state_asis -bor $readonly_code;$state_tobe = $readonly_code; $state_name= "R/O";
	#    $debug_form -f $tag , $state_name, [convert]::tostring($state_asis,2).PadLeft(4, '0'),[convert]::tostring($state_tobe,2).PadLeft(4, '0')|out-host
	  }	   
	  
	  if ($grouplist -contains $($tag.allow))
	  {$state_asis = $state_asis -bor $allow_code;$state_tobe =  $allow_code; $state_name= "FULL";
	 #   $debug_form -f $tag , $state_name, [convert]::tostring($state_asis,2).PadLeft(4, '0'),[convert]::tostring($state_tobe,2).PadLeft(4, '0')|out-host
	  }	
	   
	  # change needed?
	  if ($state_asis -ne $state_tobe)
	  {
	     $change0=$state_asis -bxor $state_tobe   # which group to change
	     $c0=[convert]::tostring($change0,2).PadLeft(4, '0') 
	     $s0=[convert]::tostring($state_asis,2).PadLeft(4, '0')
	     $s1=[convert]::tostring($state_tobe,2).PadLeft(4, '0')
			  
	     if ($state_asis -band $change0)  
	     { # remove
	       $activity="[DEL]"
	     } else 
	     { # add
	       $activity="[ADD]"
	     }

         # not possible option ...
	     if ($change0 -band $allow_code) 
	      { 
		     if ($state_asis -band $change0) {$grouplist.Remove("$($tag.allow)")} 
		     if ($debug) {write-debug ($form_status -f "$($tag.allow) $s0 $s1 $c0",$activity )}
		  }
		
	  	 # more realistic ...
	     if ($change0 -band $readonly_code)
	      { 
		  if ($state_asis -band $change0) {$grouplist.remove("$($tag.readonly)")} 
		  if ($debug) {write-debug ($form_status -f "$($tag.readonly) $s0 $s1 $c0",$activity )}
		  # write-debug ($form_status -f $tag.readonly,$activity )}
	     }
	     # very often ...
	     if ($change0 -band $deny_code)
	      { 
		  if ($state_asis -band $change0) {$grouplist.remove("$($tag.deny)")} 
		  if ($debug) {write-debug ($form_status -f "$($tag.deny) $s0 $s1 $c0",$activity )}
		  }
	  }
	  
    }
    if ($debug) { write-debug "grouplist 2: $($grouplist.count) elements"}
   
   return $grouplist
}

Function write_result     # ($result_list)
{
 Param(
    [Parameter(Mandatory=$true)]
    [array]$result_list
  )
# $o.PSObject.Properties | % { '{0} = {1}' -f $_.Name, $_.Value }
    
   foreach ($o in $result_list) {
    
    foreach ($i in $o.PSObject.Properties) {
      #Write-Verbose "Name: $($i.Name), Value: $($i.Value)"
	  #if ($i.Name -ne "200"){$i.Value.PSObject.Properties.Value.entity }
    }
  }
 #>  pause
}

#===================================================
#====  "AUCERNA script"  functions              ====
#===================================================

# Function to validate working directory
Function Validate-WorkingDirectory($workingDir_l)
{
    $result = Test-Path $workingDir_l
    if (!$result)
    {
        Write-Error " Working directory $($workingDir_l) does not exist."
    }

    return $result
}

# Function to validate CSV files
Function Validate-CsvFile($checkfile)
{
    $result = Test-Path $checkfile
    if (!$result) 
    {
        Write-Error "CSV file $($checkfile) does not exist."
    }

    return $result
}

# Function to get users from CSV file
Function Get-UsersFromCsv($usersFile)
{
    $hash=@{}
    Import-Csv $usersFile -Encoding:UTF8| %{ $hash["$($_.LogonId)"] = $_ }
    return $hash
}

# Function to get user workgroups from CSV file
Function Get-UserWorkgroupsFromCsv($userWorkgroupsFile)
{
    $hash=@{}
    Import-Csv $userWorkgroupsFile -encoding UTF8| %{ $hash["$($_.LogonId)\$($_.Workgroup)"] = $_ }
    return $hash
	
}

#===================================================
#====  "OLD"  function                          ====
#===================================================



Function P2V_header_OLD  # not used anymore
{ # show header
	param (
	[string]$app="--script name--",
    [string]$path="--working directory--",
	[string]$description=""
	)
	$user=$env:UserDomain+"/"+$env:UserName
	$client=$env:ComputerName
	
	$linesep 
    $form1 -f "           \  \  \     ____  _             ______     __    _       V 1.1    /  /  / "
    $form1 -f "            \  \  \   |  _ \| | __ _ _ __ |___ \ \   / /_ _| |_   _  ___    /  /  /  "
    $form1 -f "             \  \  \  | |_) | |/ _' | '_ \  __) \ \ / / _' | | | | |/ _ \  /  /  /   "
    $form1 -f "             /  /  /  |  __/| | (_| | | | |/ __/ \ V / (_| | | |_| |  __/  \  \  \   "
    $form1 -f "            /  /  /   |_|   |_|\__,_|_| |_|_____| \_/ \__,_|_|\__,_|\___|   \  \  \  "
    $form1 -f "           /  /  /                                                           \  \  \ "
    $linesep 
    # $form2_1 -f "[$app]",(get-date -format "dd/MM/yyyy HH:mm:ss")  |out-host
    # $form2_1 -f "[$path]","[$user]"|out-host
	$form2_1 -f "[$app]","[$path]"
	$form2_1 -f "[$user] on [$client]",(get-date -format "[dd/MM/yyyy HH:mm:ss]")  
	write-log "[$user] on [$client] started [$app]"
	$linesep
	if ($description)
	{
	  $description -split "`n"| % {$form1 -f $_}
	  $linesep
	}
	
}

Function P2V_footer_OLD  # not used anymore
{ # show footer
    param (
	[string]$app="--end of script--",
    [string]$path=(get-date -format "dd/MM/yyyy HH:mm:ss")  
	)
   #$linesep
   $form2_1 -f "[$app]", "$path"  
   $linesep
} # end of P2V_footer

Function P2V_Show-Menu              #( -> GUI???)
{ # show_menu
     param (
           [string]$Title = 'Usermanagement',
	       [array]$menu= @()
	     )
             
     $form2 -f "",$Title |out-host
     $linesep|out-host
                
     foreach ($i in 1 ..$menu.count) {$form2 -f $i,$menu[$i-1]|out-host}
	 
     $form2 -f "",""|out-host
     $form2 -f "0","exit"|out-host
     $form2 -f "",""|out-host
     $linesep|out-host
	 out-host
	 
}

Function P2V_Show-Menu_GUI            #( -> GUI???
{
     param (
           [string]$Title = 'Usermanagement',
	       [array]$menu= @()
    )
    
     $form2 -f "",$Title |out-host
	 $linesep|out-host
	 if ($debug) { $menu |% { $form2 -f $($_.id),$($_.title) + $($_.script)|out-host;$valid_sel += $($_.id)}}
	        else { $menu |% { $form2 -f $($_.id),$($_.title)|out-host;$valid_sel += $($_.id) }}
	 $form2 -f "",""|out-host
     $form2 -f "0","exit"|out-host
     $form2 -f "",""|out-host
     $linesep|out-host
	  do { [uint16]$resp1 = Read-Host -prompt ($form1 -f ">>> Please make a selection")
	 }until($resp1 -le $menu.count)
                     
     return $resp1
}

Function Delete-ExistingFile_OLD  # not used anymore 
{ # Function to delete existing files
    param(
	  [string]$file    ,
	  [bool]$verbose = $false
	)
	
    if (Test-Path $file) 
    {
        Remove-Item $file
		$msg="[$file] deleted"
	    if ($verbose) {$form_status -f $msg,"[DONE]"|out-host}
	    Write-Log $msg	
    }
}

Function createdir_ifnotexists_OLD  # not used anymore 
{ # Function to create non-existing directories
  param  (
        [string]$check_path        ,
	    [bool]$verbose     = $false
	 )

      If(!(test-path $check_path))
	  {
	   $c_res=New-Item -ItemType Directory -Force -Path $check_path 
	   $msg="directory $checkpath created"
	   if ($verbose) {$form_status -f $msg,"[DONE]"|out-host}
	   Write-Log $msg
	
	  }
	
}

Function P2V_print_object_OLD($object)   ## (OK) # not used anymore 
{ # function to print P2V objects (e.g. user-profile)
 
	foreach ($element in $object.PSObject.Properties) 
	{
      write-output ($form2_1 -f "$($element.Name)","$($element.Value)")
    }
	
}
Function P2V_get_tenant($tenantfile)
{ # function to select tenant (commandline - ascii)
  
  $all_systems =import-csv $tenantfile 
  if (!$all_systems) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
  
  $t_list=@()
  
  foreach ($a in $all_systems){ $t_list+=$a.tenant }
  $linesep |out-host
  P2V_Show-Menu -Title "select tenant" -menu $t_list
  out-host
  do {
    
    $inp_l=read-host ($form1 -f ">>> Please select a tenant")	
    switch ($inp_l)
    {
	 '0'	  {return ""}
	 default  { 
	           if ($inp_l -in 1..$t_list.count )
	            {$t_sel=$t_list[$inp_l-1]}
	           else
		        {"wrong input" }
	          }
    }
  }until ($inp_l -in 1..$t_list.count )
  
  $t_resp=$all_systems |where {($($_.tenant) -eq $t_sel)}
  $linesep|out-host
  $form1 -f "[$($t_resp.tenant)] selected"|out-host
  $linesep|out-host
  #return [string]$t_sel
  return $t_resp
}

Function P2V_get_tenant_UI($tenantfile)
{ # funtion to select tenant via GUI  -> returns list (1..n  tenants)
  $t_list= @{}
  $t_resp= @{}
  
  $all_systems =import-csv $tenantfile 
  $all_systems |% {$t_list[$($_.tenant)]=$_}
  if (!$all_systems) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
     
  $t_sel=$all_systems|select system,tenant, ServerURL |out-gridview -Title "select tenant(s)" -outputmode multiple

#  add baseauthstring to tenant
  $t_sel|%{ $t_resp[$_.tenant]=$t_list[$_.tenant];`
            $b=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_list[$_.tenant].name, $t_list[$_.tenant].API)));`
            $t_resp[$_.tenant]| Add-Member -Name 'base64AuthInfo'  -Type NoteProperty -Value "$b" }
  
  $t_resp.name
  $t_resp.values|format-list|out-host
  return $t_resp
}

Function P2V_get_userlist_OLD ($tenant)  # not used anymore 
{ # function to retrieve P2V userlist
   $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
   $base64AuthInfo ="$($tenant.base64AuthInfo)"
   $API_URL        ="$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups"
  
   $user_list=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
   if (!$user_list) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}
   return $user_list
}

Function P2V_get_AD_user
{ # function to verify and request user
  # $u_search can be either xkey or email.
   param  (
        [string]$u_search  =""   ,
	    [bool]$verbose     = $false
	 )
     
  $u_res="";

   while (!$u_res)
	 {
	 	while (!$u_search) {$u_search= Read-Host "Please enter user-searchstring (xkey,email): (0=exit)"}
	    
		if ($u_search -eq "0") {return $False}
			    
		$u_res=Get-ADUser -Filter { ((Name -like $u_search) -or (UserPrincipalName -like $u_search))} -properties * |select SamAccountName, Givenname, surname,UserPrincipalName, mail, Department, description, accountExpires
		
		
					
		If (!$u_res) {$form_err -f "ERROR","$u_search not found in Active Directory"|out-host;$u_search=""}
		else
		{ 
	       write-output "AD: [$u_search] found - $($u_res.User)"|out-host
		   $u_res.Department=$u_res.Department -replace '[,]', ''
		
		    $u_res.accountExpires=[datetime]::FromFileTime($u_res.accountExpires).tostring('yyyy-MM-dd HH:mm:ss');
		}
		#$u_res |format-table   
	 }
     return $u_res					
} 

Function P2V_get_AD_user_UI()
{ # function to verify and select user  via GUI 
  # return values:
  # $ad_user_selected:  FALSE in case of error
  # $ad_user_selected:  userprofile:
  #            .Name, 
  #            .Givenname, 
  #            .surname,
  #            .SamAccountName,
  #            .UserPrincipalName, 
  #            .EmailAddress, 
  #            .Department,            
  #            .displayName,
  #            .logonID
  #--------------------------------
   $ad_user="";
   while (!$ad_user)
	 {
	 	while (!$ad_user) {$ad_user= Read-Host "|> Please enter user-searchstring (0=exit)"}
	    
		if ($ad_user -eq "0") {$ad_user="";return $False}
		
		#$u_res=Get-ADUser -Filter { (Name -like $ad_user)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department |out-gridview -Title "select user" -passthru
		#select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 	
	    #$u_res=Get-ADUser -Filter { (Name -like $ad_user)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department
		$ad_user='*'+$ad_user+'*'
		$u_res=Get-ADUser -Filter { (Givenname -like $ad_user) -or (Surname -like $ad_user) -or (Name -like $ad_user)} -properties * |
		select  Name, 
		        Givenname, 
				surname,
				SamAccountName,
				UserPrincipalName, 
				EmailAddress, 
				Department,
				distinguishedName,
				lastlogon,
				lastLogonTimestamp,
				accountExpires,
				comment   # ,
#				description 
				
		$u_res|%{ $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
				$_.lastLogonTimestamp=[datetime]::FromFileTime($_.lastlogonTimestamp).tostring('yyyy-MM-dd HH:mm:ss');
				$_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss');
				if ("$($_.distinguishedName)" -match "Deactivates") {$_.comment="DEACTIVATED"} else {$_.comment="ACTIVE"} 
        }
		
		$ad_user_selected=$u_res|select Givenname,surname,SamAccountName, EmailAddress, comment, Department, lastlogon, accountExpires,UserPrincipalName|out-gridview -Title "select user from AD" -outputmode single
		
		If (!$ad_user_selected) {$form_err -f "ERROR","$ad_user_selected not found or no user selected"|out-host;$ad_user_selected=""}
		else
		{ 
		   $ad_user_selected.Department=$ad_user_selected.Department -replace '[,]', ''
				
		  $ad_user_selected| Add-Member -Name 'displayName' -Type NoteProperty -Value "$($ad_user_selected.surname) $($ad_user_selected.Givenname) ($($ad_user_selected.SamAccountName))"
	      $ad_user_selected| Add-Member -Name 'logOnId' -Type NoteProperty -Value "$($ad_user_selected.UserPrincipalName)" 
		}
	}	 
    return $ad_user_selected	
} 

Function P2V_AD_userprofile($u_xkey) ##  CHECK - needed ?
{
  $u_ad_profile=@{}
  $u_ad_profile= Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  

}

Function P2V_get_P2V_user_UI($t_sel)
{
   $u_res="";
   $authURL    ="$($t_sel.ServerURL)/identity/connect/token"
   $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
   $tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
   
   while (!$u_res)
	 {
	 	while (!$u_key) {$u_key= Read-Host "Please enter searchstring (0=exit)"}
	    
		if ($u_key -eq "0") {return $False}
		
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department |out-gridview -Title "select user" -passthru
		$u_res=Get-ADUser -Filter { (Givenname -like $u_key) -or (Surname -like $u_key) -or (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department|out-gridview -Title "select user" -outputmode single
		
	    
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department
					
		If (!$u_res) {$form_err -f "ERROR","$u_key not found in Active Directory"|out-host;$u_key=""}
		else
		{ 
		   $u_res.Department=$u_res.Department -replace '[,]', ''
		}
		$u_res |format-table   
	 }
     return $u_res					
} 

Function P2V_get_WG_UI($t_sel)
{
  # ---- not ready ----
   $wg_sel= @()
   
     while (!$u_res)
	 {
	 	while (!$u_key) {$u_key= Read-Host "Please enter searchstring (0=exit)"}
	    
		if ($u_key -eq "0") {return $False}
		
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department |out-gridview -Title "select user" -passthru
		$u_res=Get-ADUser -Filter { (Givenname -like $u_key) -or (Surname -like $u_key) -or (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department|out-gridview -Title "select user" -passthru
		
	    
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department
					
		If (!$u_res) {$form_err -f "ERROR","$u_key not found in Active Directory"|out-host;$u_key=""}
		else
		{ 
		   $u_res.Department=$u_res.Department -replace '[,]', ''
		}
		$u_res |format-table   
	 }
     return $u_res					
} 

# Function to invoke interactive login via browser
Function Get-PlanningSpaceAuthToken ($tenantUrl)
{
    Add-Type -AssemblyName System.Windows.Forms

    $tenantUrl = $tenantUrl.Trim("/") + "/"
    $url = [System.Uri]$tenantUrl
    $script:returnUrl = ""

    $authUrl = "{0}/identity/connect/authorize?response_type=token&state=foo&client_id={1}%20web&scope=planningspace&redirect_uri={2}loginCallback.html" `
        -f $url.GetLeftPart([System.UriPartial]::Authority), $url.Segments[1].Trim("/"), [System.Uri]::EscapeUriString($tenantUrl)

    $popupForm = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=500;Height=700}
    $browser  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Url=$authUrl}
    $completedHandler  = {
            $script:returnUrl = $browser.Url.AbsoluteUri
            if ($script:returnUrl -match "error=[^&]*|access_token=[^&]*")
            {
                $popupForm.Close() 
            }
    }
    
    $browser.Add_DocumentCompleted($completedHandler)
    $popupForm.Controls.Add($browser)
    $browser.Dock = [System.Windows.Forms.DockStyle]::Fill

    $popupForm.Add_Shown({$popupForm.Activate()})
    $popupForm.ShowDialog() | Out-Null

    [RegEx]::Match(([System.Uri]$script:returnUrl).Fragment, "(access_token=)(.*?)(&)").Groups[2].Value
}

#---   get filename from

Function Get-FileName($initialDirectory)
{ #Function to get filename
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}


Function show_progress ([int]$i=0 )
{
 $progress=@("[/]`b`b`b","[-]`b`b`b","[\]`b`b`b","[|]`b`b`b")
 #$i=$i%4
 write-host -nonewline -ForegroundColor green $progress[$i%4]
}

#===================================================
#==   global variables                            ==
#===================================================


createdir_ifnotexists ($output_path_base)
createdir_ifnotexists ($dashboard_path)
createdir_ifnotexists ($log_path)



# [OLD]> $global:config_path = "\\somvat202005\PPS_share\P2V_UM_data\conf"
<# $global:config_path = "\\somvat202005\PPS_share\P2V_Script-setup(new)\central\config"

$global:adgroupfile = $config_path + "\P2V_adgroups.csv"
$global:tenantfile  = $config_path + "\P2V_tenants.csv"
$global:profile_file= $config_path + "\P2V_profiles.csv"
$global:menu_file   = $config_path + "\P2V_menu.csv"
$global:data_groups = $config_path + "\data_groups.csv"		
$global:tag_conf    = $config_path + "\TAG_config.csv"			  
$global:bd_groups   = $config_path + "\P2V_BD.csv"		
 #>


$global:spec_accounts = @("adminx449222@ww.omv.com",
						  "adminarun05",
						  "adminadrian75@ww.omv.com",
						  "useradmin",
						  "svc.ww.at.p2v_useradmin@ww.omv.com",
						  "Reserves_service"
						  )

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
							