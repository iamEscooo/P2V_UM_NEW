#=================================================================
#  P2V_AD_func.psm1
#=================================================================

<#
.SYNOPSIS
	different dialog forms for P2V Usermgmt
.DESCRIPTION
	

.PARAMETER menufile <filename>
	
	
.PARAMETER xamldir <directory>
	
	
.PARAMETER fcolor  <colorcode>
	foregroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.PARAMETER bcolor  <colorcode>
	backgroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  name:   P2V_AD_func.psm1
  ver:    1.0
  author: M.Kufner

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
        [string]$searchstring= "",
	    [string]$xkey=""
    )
   $ad_user_selected=""
   #write-output "start user selection"
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
				description,
			    Enabled
		} else
		{
		    $ad_user='*'+$searchstring.trim()+'*'
		     
		    $u_res=Get-ADUser -SearchBase "DC=ww,DC=omv,DC=com" -Filter { (EmailAddress -like $ad_user) -or (UserPrincipalName -like $ad_user) -or (Givenname -like $ad_user) -or (Surname -like $ad_user) -or (Name -like $ad_user)} -properties * |
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
				description,
			    Enabled				
	    }	
	    $u_count=0
		$u_res|%{ $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
				
				$_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss') ;
				
### introduced Enabled				
				if (("$($_.distinguishedName)" -match "Deactivates") -or ($($_.Enabled) -like "TRUE"))		{$_.comment="DEACTIVATED"} else {$_.comment="ACTIVE"} 
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

#---------------------------------------------------
Function P2V_get_AD_user($u_xkey)
{ # function to verify and request user
   
   $u_res="";

   while (!$u_res)
	 {
	 	while (!$u_key) {$u_key= Read-Host "Please enter user-xkey: (0=exit)"}
	    
		if ($u_key -eq "0") {return $False}
			    
		$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, mail, Department, description, accountExpires
		
		$u_res.accountExpires=[datetime]::FromFileTime($u_res.accountExpires).tostring('yyyy-MM-dd HH:mm:ss');
					
		If (!$u_res) {$form_err -f "ERROR","$u_key not found in Active Directory"|out-host;$u_key=""}
		else
		{ 
		   $u_res.Department=$u_res.Department -replace '[,]', ''
		   $u_res| Add-Member -Name 'displayName' -Type NoteProperty -Value "$($u_res.surname) $($u_res.Givenname) ($($u_res.Name))"
	       $u_res| Add-Member -Name 'logOnId' -Type NoteProperty -Value "$($u_res.UserPrincipalName)" 
		}
		#$u_res |format-table   
	 }
     return $u_res					
} 

#---------------------------------------------------
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

#---------------------------------------------------
Function P2V_AD_userprofile($u_xkey) ##  CHECK - needed ?
{
  $u_ad_profile=@{}
  $u_ad_profile= Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  

}

Function get_AD_grouplist
{
	if (! $step1)
		{
			$local_list= @{}
			$local_list= @(Get-ADPrincipalGroupMembership -identity "$u_xkey" |where { $_.name -like "*P2V*" -or $_.name -like "*PetroVR*" }|% { $_.name})
			foreach ($ad_g in $local_list)
			{
				#OLD $User_ADgroups["$u_xkey"] = @(Get-ADPrincipalGroupMembership -identity $u_xkey |where { $_.name -like "*P2V*" -or $_.name -like "*PetroVR*" }|% { $_.name})
	  
				$User_ADgroups["$u_xkey"] += @($ad_g)
	  
				if ($all_adgroups["$ad_g"].PSgroup) 
				{
					$ADuser_profiles["$u_xkey"] +=@($all_adgroups["$ad_g"].PSgroup)
				}
			}
}
