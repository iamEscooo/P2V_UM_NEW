#-----------------------------------------
# check_userprofile 
#
#  name:   check_userprofile.ps1 
#  ver:    1.0
#  author: M.Kufner
#
# retrieve account settings for specific user 
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#------------------------------------------------------------------------------------
Function check_userprofile 
{
param(
  [string] $xkey ,
  [bool]   $P2Vgroups = $True,
  [bool]   $P2Vtenants = $True
   )
<#
.SYNOPSIS
	P2V_menu displays a menu based on an CSV configuration file
.DESCRIPTION
	P2V_menu displays a menu based on an CSV configuration file.
	Based on the great menu script from 
	Based on: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
	just added an "EXIT" option

.PARAMETER menufile <filename>
	CSV file 
	
.PARAMETER xamldir <directory>
	CSV file 
	
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
  name:   check_userprofile.ps1 
  ver:    1.0
  author: M.Kufner

#>

#-------------------------------------------------

#  Set config variables
#$output_path = $output_path_base + "\$My_name"
P2V_header -app $MyInvocation.MyCommand -path $My_path
#$license     = @("n/a","light license","PetroVR license","heavy license","array exeeded")

#-------------------------------------------------

#----- start main part

$age=5   # refresh after $age minutes
$now=get-date
$AD_loaded=$now.addDays(-2)  # intial value very old to trigger initial load

$ad_groups=@{}
$count=0

While ($result= get_AD_user -xkey $xkey)
{
  if ($xkey){$xkey=""}
  #----- check whether xkey exists in AD and retrieve core information
  $user =  $result.SamAccountName
	  
  # $result=Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  if(! $result) {$form_err -f "[ERROR]", " !! [$user] does not exist in Active Directory !!"   }	
  else
  { 
    
    write-output ($form1 -f  "Active Directory information for $($result.displayName)")
    write-output $linesep
	
	P2V_print_object($result)
		   
    if ($P2vgroups)
    {
      #----- check whether xkey is member of ADgroups of P2V
      $linesep
	  $form1 -f  "P2V AD group memberships for $($result.displayName)"
	  $form1 -f ""
      
      # get all AD-groups for specific useraccount
	
      #	Get-ADPrincipalGroupMembership -identity "$($result.SamAccountName)" |where name -like "*P2V*" |select name | % { $form1 -f $_.name}
      Get-ADPrincipalGroupMembership -identity "$($result.SamAccountName)"|where { $_.name -like "*P2V*" -or $_.name -like "*PetroVR*" }| % { $form1 -f $_.name }
      #$groups |format-table| out-host 
      
      if ($get_lic)  
      {
      $linesep   
         $form1 -f "license for $($result.displayName): $($license[$user_lic])"
      }
    }
	$linesep
	$form1 -f "checking PS tenant for user $($result.displayName)"
	$form1 -f ""
	$form4 -f "tenant" ,"Deactivated","AccountLocked","(ID)/Lastlogin"              		  
	#$form2_1 -f "tenant","login","islocked","isdeactivated",
	if ($P2Vtenants)
	{
        $t_list= @{}
		$tenants=select_PS_tenants -all $true
        $all_tenants =import-csv $tenantfile 
        $all_tenants |% {$t_list[$($_.tenant)]=$_}
        if (!$all_tenants) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
        # $all_tenants|ft
        foreach ($ts in $tenants.keys)
		{
		  $t               = $tenants[$ts]
		  $tenant          = $t.tenant
		  $tenantURL       = "$($t.ServerURL)/$($t.tenant)"
		  $base64AuthInfo  = $t.base64AuthInfo   
	      $accessgroup     = $t.ADgroup
		  
          $API_URL         ="$tenantURL/PlanningSpace/api/v1/users" 
          $UPN             =$($result.UserPrincipalName)
		 		  
          $resp=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
          if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}
		  $resp_user=$resp|where-Object {($($_.authenticationMethod) -ne 'LOCAL' -and $_.logOnId -eq $UPN) } 
		  
		  if ($resp_user)
		  {
		    $resp_user|%{ $form4 -f "$($tenant)" ,"[$($_.isDeactivated)]","[$($_.isAccountLocked)]", "$($_.id)/$($_.lastLogin)"}
		  } else 
		  {
		    $form4 -f "$($tenant)","","", "[no account]"
		  }	  
		}
	}
  }
} # end while
write-output $linesep
#P2V_footer -app $MyInvocation.MyCommand
}

Function createdir_ifnotexists  # not used anymore 
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
#------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------

Function select_PS_tenants # not used anymore 
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
#------------------------------------------------------------------------------------
Function P2V_footer  # not used anymore
{ # show footer
    param (
	[string]$app="--end of script--",
    [string]$path=(get-date -format "dd/MM/yyyy HH:mm:ss")  
	)
   #$linesep
 #  $form2_1 -f "[$app]", "$path"  
   $linesep
} # end of P2V_footer
Function P2V_header  # not used anymore
{ # show footer
    param (
	[string]$app="--end of script--",
    [string]$path=(get-date -format "dd/MM/yyyy HH:mm:ss")  
	)
   #$linesep
   #$form2_1 -f "[$app]", "$path"  
   $linesep
} # end of P2V_footer
Function P2V_print_object($object)   ## (OK) # not used anymore 
{ # function to print P2V objects (e.g. user-profile)
 
	foreach ($element in $object.PSObject.Properties) 
	{
      write-output ($form2_1 -f "$($element.Name)","$($element.Value)")
    }
	
}

#--
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

$u_search =""

while ($true)
{
	$u_search=""
	while (!$u_search) { $u_search= Read-Host "Please enter user-searchstring (xkey): (0=exit)"}
	  
	if ($u_search -eq "0") {return "finished"}
	
#	write-output "checking  $u_search"|out-host
	check_userprofile -xkey $u_search	
	
	
	#$linesep
	
}
Read-Host "--END-- Press Enter to close the window"