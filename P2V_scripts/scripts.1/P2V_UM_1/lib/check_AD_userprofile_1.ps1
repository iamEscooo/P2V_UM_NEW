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
  [bool]   $P2Vgroups = $True,
  [bool]   $get_lic   = $True
   )
#-------------------------------------------------

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#  Set config variables
$output_path = $output_path_base + "\$My_name"

$license     = @("n/a","light license","PetroVR license","heavy license","array exeeded")

#-------------------------------------------------
#----- start main part

P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)

While ($result= P2V_get_AD_user_UI($xkey))
{
  #----- check whether xkey exists in AD and retrieve core information
     $user =  $result.Name
  # $result=Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  if(! $result) {$form_err -f "[ERROR]", " !! [$user] does not exist in Active Directory !!"   }	
  else
  { 
    $linesep
    $form1 -f  "Active Directory information for $($result.SamAccountName)"
    $linesep
	
	P2V_print_object($result)
		   
    if ($P2vgroups)
    {
      #----- check whether xkey is member of ADgroups of P2V
      $form1 -f  "P2V AD group memberships for $($result.SamAccountName)"
      $linesep
      $user_lic = 0;
      foreach ($i in import-csv $adgroupfile)
      {
         if (Get-ADGroupMember -Identity $($i.ADgroup)|where {$($_.SamAccountName) -eq $($result.SamAccountName)}) 
         { 
           $form1 -f $i.ADgroup 
           if ($get_lic) { $user_lic = ($user_lic, $($i.Lic_type)|Measure -Max).Maximum }
         
         }
      }

      # get all AD-groups for specific useraccount
      #$groups= Get-ADPrincipalGroupMembership $user|select name |where { $($_.name) -like "*P2V*" -or ($($_.name) -like "*PetroVR*")}
      #$groups |format-table| out-host 
      
      if ($get_lic)  
      {
      $linesep
       
         $form2_1 -f "license for $user",$license[$user_lic]

      }
    }
    
   
  }
  $linesep


} # end while
P2V_footer -app $My_name