#---------------------------------------------------

#---------------------------------------------------


# Martin Kufner
#---------------------------------------------------


#===================================================
#====  global variables                         ====
#===================================================

# global variables
$global:output_path_base = "\\somvat202005\PPS_share\P2V_UM_data\output"
$global:dashboard_path = $output_path_base + "\dashboard"
$global:log_path    = $output_path_base + "\logs"

$logfile    		 = $log_path +("\P2V_Usermgmt_Log" + $date + ".log")

createdir_ifnotexists ($output_path_base)
createdir_ifnotexists ($dashboard_path)
createdir_ifnotexists ($log_path)

$global:lib_path    = $workdir + "\lib"

$global:config_path = "\\somvat202005\PPS_share\P2V Script-setup(new)\central\config"
$global:adgroupfile = $config_path + "\P2V_adgroups.csv"
$global:tenantfile  = $config_path + "\P2V_tenants.csv"
$global:profile_file= $config_path + "\P2V_profiles.csv"
$global:menu_file   = $config_path + "\P2V_menu.csv"
$global:date = get-date -format "yyyy-MM-dd"

# central configurations
# layouts
$global:linesep    ="+-------------------------------------------------------------------------------+"

$global:form1      ="|  {0,-75}  |"
$global:form2      ="|  {0,-12} {1,-62}  |"
$global:form2_1    ="|  {0,-37} {1,37}  |"
$global:form3      ="|  {0,-12} {1,-50} {2,-12} |"
$global:form4      ="|  {0,-12} {1,-24} {2,-24} {3,-12}  |"
$global:form_status="|  {0,-62} {1,-12}  |"
$global:form_err   ="|>>{0,-12} {1,-62}<<|"
$global:form_user  ="|  {0,-5} {1,-29} {2,-40} |"
$global:form_user1 ="|  {0, 5} {1,-57} {2,-12} |"
#                   0         1         2         3         4         5         6         7         8
#                    12345678901234567890123456789012345678901234567890123456789012345678901234567890


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
       id					  = PS user ID
       logOnId              = PS Login name (~ UPN)
       displayName 		  = "$($user_from_AD.Surname) $($user_from_AD.GivenName) ($($user_from_AD.name))"
       description 		  = Department from AD 
       isDeactivated 	 	  = $False
       isAccountLocked 	  = $False
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
        $searchstring= ""
    )

   
   # while (!$ad_user)
#	 {
	 	while (!$searchstring) {$searchstring= Read-Host "|> Please enter user-searchstring (0=exit)"}
	    
		if ($searchstring -eq "0") {$searchstring="";return $False}
		
		#$u_res=Get-ADUser -Filter { (Name -like $ad_user)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department |out-gridview -Title "select user" -passthru
		#select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 	
	    #$u_res=Get-ADUser -Filter { (Name -like $ad_user)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department
		$ad_user='*'+$searchstring+'*'
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
				comment,
				description 
				
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
#	}	 
    return $ad_user_selected	
} 

#---------------------------------------------------
Function get_AD_userlist($ad_group, ) # NOT YET TESTED
{ # Get-userlist from a given AD-Group  
   param(
   [string]$ad_group="dlg.WW.ADM-Services.P2V.access.production",
   [bool]  $all=$False
   )

   $entries=Get-ADGroupMember -Identity $ad_group | Get-ADUser -properties * |Select Givenname,Surname,SamAccountName, EmailAddress, comment, Department, lastlogon, accountExpires,UserPrincipalName
   
   $entries |%{ $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
				$_.lastLogonTimestamp=[datetime]::FromFileTime($_.lastlogonTimestamp).tostring('yyyy-MM-dd HH:mm:ss');
				$_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss');
				if ("$($_.distinguishedName)" -match "Deactivates") {$_.comment="DEACTIVATED"} else {$_.comment="ACTIVE"};
				$_.Department=$($_.Department) -replace '[,]', ''
				Add-Member -Name 'displayName' -Type NoteProperty -Value "$($ad_user_selected.surname) $($ad_user_selected.Givenname) ($($ad_user_selected.SamAccountName))";
				Add-Member -Name 'logOnId' -Type NoteProperty -Value "$($ad_user_selected.UserPrincipalName)" 
			} 
    if (!$all){ $entries = $entries|out-gridview -title "select (multiple) user(s)" -outputmode multiple}
    $entries |format-table|out-host			
   return $entries
}


#===================================================
#====  Planningspace functions                  ====
#===================================================

#---------------------------------------------------
Function select_PS_tenants() # NOT YET TESTED
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

  $selected_tenants= @{}
  $t_list= @{}
  $all_tenants =import-csv $tenantfile 
  $all_tenants |% {$t_list[$($_.tenant)]=$_}
  if (!$all_tenants) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
     
  $t_list=$all_tenants|select system,tenant, ServerURL |out-gridview -Title "select tenant(s)" -outputmode multiple

#  add baseauthstring to tenant
  $t_list|%{ $selected_tenants[$_.tenant]=$t_list[$_.tenant];`
            $b=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_list[$_.tenant].name, $t_list[$_.tenant].API)));`
            $selected_tenants[$_.tenant]| Add-Member -Name 'base64AuthInfo'  -Type NoteProperty -Value "$b" }
  
  $selected_tenants.name
  $selected_tenants.values|format-list|out-host
  return $selected_tenants
}

#---------------------------------------------------
Function get_PS_userlist($tenant)
{ #get-userlist from Planningspace $tenant
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" # w/o grouplist?

  $resp=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
   if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}


}

#---------------------------------------------------
Function get_PS_grouplist($tenant)
{ #get-workgrouplist from Planningspace $tenant
}

#---------------------------------------------------
Function get_PS_user_groups($tenant,$user_id)
{
}

Function add_PS_user ($tenant, $user_profile)
{# function to add 1 user to P2V_tenant
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
#---------------------------------------------------
Function update_PS_user ($tenant, $user_profile_old, $user_profile_new)
{
}

#---------------------------------------------------
Function deactivate_PS_user {$tenant,$user_id}
{
}


