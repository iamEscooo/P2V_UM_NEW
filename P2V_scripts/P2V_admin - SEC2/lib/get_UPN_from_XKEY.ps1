#-----------------------------------------
# check_AD_userprofile 
#
#  name:   check_AD_userprofile.ps1 
#  ver:    1.0
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $xkey =  xkey to search

# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string] $xkey      = "<no user>",
  [string] $workdir   = "",
  [bool]   $P2Vgroups = $True,
  [bool]   $get_lic   = $True
   )
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#  Set config variables
$output_path = $output_path_base + "\$My_name"
$exportfile= $output_path + "\export_list.csv"
#-------------------------------------------------
#----- start main part
$userlist= @()
P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)
While ($result= P2V_get_AD_user($xkey))
{
  #----- check whether xkey exists in AD and retrieve core information
     $user =  $result.Name
	 
  # $result=Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  if(! $result) {$form_err -f "[ERROR]", " !! [$user] does not exist in Active Directory !!"   }	
  else
  { 
    $userlist+= $result
  }
    
   
}

$userlist |format-table
write-output "exporting to $exportfile"
$userlist |export-csv -Path $exportfile

$linesep



P2V_footer -app $My_name
Read-Host "Press Enter to close the window"