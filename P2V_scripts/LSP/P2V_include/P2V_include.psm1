#=================================================================
#  P2V_include.psm1
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
  name:   P2V_dialog_func.psm1
  ver:    1.0
  author: M.Kufner

#>
import-module -name ".\P2V_config.psd1" -verbose

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
Add-Type -AssemblyName System.Windows.Forms

#=================================================================
# Variables
#=================================================================

$my_new_variable = @("dlg.WW.ADM-Services.P2V.access.production","dlg.WW.ADM-Services.P2V.access.test","dlg.WW.ADM-Services.P2V.access.update","dlg.WW.ADM-Services.P2V.access.training")



#=================================================================
# Functions
#=================================================================

Function P2V_header
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

#-----------------------------------------------------------------
Function P2V_footer
{ # show footer
    param (
	[string]$app="--end of script--",
    [string]$path=(get-date -format "dd/MM/yyyy HH:mm:ss")  
	)
   #$linesep
   $form2_1 -f "[$app]", "$path"  
   $linesep
} # end of P2V_footer

#-----------------------------------------------------------------

Function Write-Log
{
	param (
	[string]$logtext          ,
	[int]$level			= 0
	)
	
	$logdate = get-date -format "[yyyy-MM-dd HH:mm:ss]"
	if($level -eq 0) {$severity="[INFO]"}
	if($level -eq 1) {$severity="[WARNING]"}
	if($level -eq 2) {$severity="[ERROR]"}
	
	$text= "$logdate - "+ "$severity "+ $logtext
	$text >> $logfile
}

#-----------------------------------------------------------------
Function createdir_ifnotexists 
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

#-----------------------------------------------------------------
Function Delete-ExistingFile
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

#-----------------------------------------------------------------
Function P2V_print_object($object)   ## (OK)
{ # function to print P2V objects (e.g. user-profile)
 
	foreach ($element in $object.PSObject.Properties) 
	{
      write-output ($form2_1 -f "$($element.Name)","$($element.Value)")
    }
	
}

#-----------------------------------------------------------------
#-----------------------------------------------------------------
Function check_userprofile 
{ # Function to check AD userprofile and basic setup in P2V tenants
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
      Get-ADPrincipalGroupMembership -identity "$($result.SamAccountName)"|where { $_.name -match "P2V" -or $_.name -match "PetroVR" }| % { $form1 -f $_.name }
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
P2V_footer -app $MyInvocation.MyCommand
}

#-----------------------------------------------------------------
Function check_P2V_user 
{ # function to check P2V user profile settings in PLanningspace
  param(
    [string]$xkey="<no user>"
  )
  #-------------------------------------------------

  #----- Set config variables
  $output_path = $output_path_base + "\$My_name"

  #-------------------------------------------------
  P2V_header -app $MyInvocation.MyCommand -path $My_path 
  createdir_ifnotexists($output_path)
  #----- start main part

  While ($result= get_AD_user -xkey $xkey)
  {
    if ($xkey){$xkey=""}
    #----- check whether xkey is member of workgroups in P2V
	$user =  $result.Name
	$UPN  =  $result.UserPrincipalName
    #[DEL] -- $dname=  "$($result.Surname) $($result.GivenName)"
	#$linesep
    $form1 -f "checking P2V Planningspace user profile for"
    $form1 -f $result.displayName
	$linesep

	$u_list_P2V=@{}
    # $all_systems = @()
   
    $tenants= select_PS_tenants
		
    foreach ($i in $tenants.keys)
    {
	  $t_sel=$tenants[$i]
      $form1 -f "--> $($t_sel.tenant) <--"
      	   
	  $authURL    ="$($t_sel.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
      $tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
  
    # retrieve all users incl. workgroups
      # $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      # if (!$resp) {$form2_1 -f "[ERROR]", "cannot contact $t_sel !" ;break}
      
	  #$resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
	  $u_list_P2V = P2V_get_userlist ($t_sel)| where-Object {($($_.authenticationMethod) -ne 'LOCAL' -and $_.logOnId -eq $UPN) }
      #$u_list_P2V|% {$u1_list_P2V[$($_.logOnId)]=$_}
	  
      if ($u_list_P2V) 
      {
	     #P2V_print_object(($u_list_P2V|where-Object { ($($_.logonID) -like $logonID)}))#|select id,displayname,description,IsAccountLocked,isDeactivated))
          
         P2V_print_object ($u_list_P2V|
		 select id,
				displayName,
				logOnId,
				authenticationMethod,
				domain,
				accountExpirationDate,
				isDeactivated,
				isAccountLocked,
				description,
				authenticationType,
				enforcePasswordPolicy,
				enforcePasswordExpiration,
				userMustChangePassword,
				userCanChangePassword,	
				isAdministrator,
				isInAdministratorGroup,
				emailAddress,
				useADEmailAddress,
				changePassword,
				password,
				lastLogin,
				accountLockedDate,
				deactivatedDate	)
				
         $form1 -f "  workgroups: "
         foreach( $g in $u_list_P2V.userworkgroups)
         {
            $hash = @{}  
            $g | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($g | SELECT -exp $_) }
            foreach($wg in ($hash.Values | Sort-Object -Property Name)) {$form2 -f $($wg.id), $($wg.name) }   
         }
         out-host
       } else 
       {
          $form2_1 -f "[ERROR]", "$user does not exist"
       }
       $linesep
     }
  } 
P2V_footer -app $MyInvocation.MyCommand
}



#

#=================================================================
# Exports
#=================================================================

Export-ModuleMember -Variable workdir
Export-ModuleMember -Function * -Alias *

