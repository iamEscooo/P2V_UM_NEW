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
# $long =  false (default)   - short summary 
# $long =  true              - all AD entries
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string] $xkey      = "<no user>",
  [bool]   $long      = $False, 
  [bool]   $P2Vgroups = $False,
  [bool]   $get_lic   = $True
   )
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path
. "$workdir/P2V_include.ps1"

#  Set config variables

$config_path = $workdir     + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir     + "\output\AD-groups"
$u_w_file    = $output_path + "\Myuserworkgroup.csv"

$license     = @("n/a","light license","PetroVR license","heavy license","array exeeded")

#-------------------------------------------------
#layout
P2V_layout 
cls
P2V_header -app $My_name -path $My_path 

#----- start main part

$user= $xkey

While (($user= Read-Host ' >>> Input the user name (0=exit)') -ne "0") 
{
  $result=@()
  cls
#----- check whether xkey exists in AD and retrieve core information
  $linesep
  $form1 -f "checking Active Directory  for ($user) "
  $linesep
  
  # long output requested`?
  If ($long) 
  { $result=Get-ADUser -Filter {Name -like $user} -properties * } 
  else
  { $result=Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory }
  
  # select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Country,Company,Department,EmployeeNumber, Enabled, HomeDirectory ,PasswordExpired ,LockedOut,lockoutTime
  if(!$result) 
  { 
    $form_err -f "[ERROR]", " !! [$user] does not exist in Active Directory !!" 
  }	
  else
  { 
    $result 
	   
    $dep=$($result.Department) -replace '[,]', ''
    
	$linesep
	$form1 -f "export-formats"
	#format: LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress,
	
    $form1 -f "$($result.Name),ww,$($result.Surname) $($result.GivenName),$dep,FALSE,FALSE,,"
    $form1 -f "$($result.Surname) $($result.GivenName),$($result.Name),$($result.UserPrincipalName),$dep"
	$linesep
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

#----- check whether xkey is member of workgroups in P2V
} # end while
P2V_footer -app $My_name