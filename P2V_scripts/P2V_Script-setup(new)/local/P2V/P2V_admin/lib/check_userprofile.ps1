#-----------------------------------------
# check_userprofile 
#
#  name:   check_userprofile.ps1 
#  ver:    1.0
#  author: M.Kufner
#
# retrieve account settings for specific user 
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------

Function check_userprofile 
{
param(
  [string] $xkey ,
  [bool]   $P2Vgroups = $True,
  [bool]   $P2Vtenants = $True,
  [bool]   $get_lic   = $False
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
$output_path = $output_path_base + "\$My_name"
P2V_header -app $MyInvocation.MyCommand -path $My_path
$license     = @("n/a","light license","PetroVR license","heavy license","array exeeded")

#-------------------------------------------------
#$global:form4      ="|  {0,-18} {1,-16}{2,-16} {3,-24} |"
#----- start main part

$AD_loaded
$age=5   # refresh after $age minutes
$now=get-date
$AD_loaded=$now.addDays(-2)  # intial value very old to trigger initial load

$ad_groups=@{}
$count=0

# was while {}
if ($result= get_AD_user -xkey $xkey)
{
  if ($xkey){$xkey=""}
  #----- check whether xkey exists in AD and retrieve core information
  $user =  $result.SamAccountName
	  
  # $result=Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  if(! $result) {$form_err -f "[ERROR]", " !! [$user] does not exist in Active Directory !!"   }	
  else
  { 
    write-output $linesep
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
        $all_tenants =import-csv $tenantfile 
        $all_tenants |% {$t_list[$($_.tenant)]=$_}
        if (!$all_tenants) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
        # $all_tenants|ft
        foreach ($i in $t_list.keys)
		{
		  $t_sel=$t_list[$i]
		  # $form1 -f "--> $($t_sel.tenant) <--"
      	  $tenantURL      ="$($t_sel.ServerURL)/$($t_sel.tenant)"
          $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
          $API_URL        ="$tenantURL/PlanningSpace/api/v1/users" # w/o grouplist?
          $UPN            =$($result.UserPrincipalName)
		 		  
          $resp=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
          if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}
		  $resp_user=$resp|where-Object {($($_.authenticationMethod) -ne 'LOCAL' -and $_.logOnId -eq $UPN) } 
		  
		  if ($resp_user)
		  {
		    $resp_user|%{ $form4 -f "$($t_sel.tenant)" ,"[$($_.isDeactivated)]","[$($_.isAccountLocked)]", "$($_.id)/$($_.lastLogin)"}
		  } else 
		  {
		    $form4 -f "$($t_sel.tenant)","","", "[no account]"
		  }	  
		}
	}
  }
} # end while
write-output $linesep
P2V_footer -app $MyInvocation.MyCommand
}