#-----------------------------------------
# sync STEP1
#
#  name:   P2V_sync_userbase.ps1 
#  ver:    0.1
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $long =  false (default)   - short summary 
# $long =  true              - all AD entries
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#
# ##
# get the AD-groups for system access and create "users lists"
# config file  "tenant.config" (SNOWgroup, ADgroup)
#-----------------------------------------
param(
  [string]$tenant="",
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  [bool]$checkOnly = $False
)
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#----- variable from P2V_include
# > $spec_accounts 
# > $output_path_base
# > $dashboard_path
# > $log_path
# > $logfile
# > $config_path
# > $adgroupfile
# > $tenantfile
# > $profile_file
# > $debug

#----- Set config variables
$output_path = $output_path_base + "\$My_name"
createdir_ifnotexists($output_path)

$AD_userlist = @{}
#----- start main part
P2V_header -app $My_name -path $My_path 

$all_adgroups = @{}
$adgroups = @{}
$all_adgroups =import-csv $adgroupfile  

foreach ($adg in $all_adgroups)
{
   $adgroups["$($adg.ADgroup)"]=$adg
   if (!$AD_userlist.ContainsKey("$($adg.ADgroup)"))
   {
      write-host -nonewline $($form1_nnl -f "loading users from $($adg.ADgroup)")
      $entries = get_AD_userlist -ad_group $adg.ADgroup -all $true
       
	  if ($entries) 
	  {         
		 $AD_userlist["$($adg.ADgroup)"] = @()
         $AD_userlist["$($adg.ADgroup)"] = $entries
		 
         $counter=$entries.count
  	     $form_status -f "$counter users loaded from $($adg.ADgroup)","[ DONE]"      
	  }
   } else
   { # AD group already loaded
       $counter=$ad_userlist["$($adg.ADgroup)"].count
	   $form_status -f "$counter users already loaded","[ SKIP]"
   }
} 

$linesep         
# variable definitions

$ad_file     = $output_path + "\All_AD_users.csv"
Delete-ExistingFile -file $ad_file

# all user-ad file
Add-Content -Path $ad_file -Value 'ADgroup,category,PSgroup,xkey,LogonId,DisplayName,Description,EmailAddress,UPN'

foreach ($adg in $AD_userlist.keys)
{
    $aduser_file="$output_path\$adg.csv"
    Delete-ExistingFile -file $aduser_file	  
      
    #headerline  
	Add-Content -Path $aduser_file -Value 'ADgroup,category,PSgroup,xkey,LogonId,DisplayName,Description,EmailAddress,UPN'
	write-host -nonewline $($form1_nnl -f "writing [$adg]")
	foreach ($u in $AD_userlist["$adg"])
    {
	   "$adg,$($adgroups[$adg].category),$($adgroups[$adg].PSgroup),$($u.SamAccountName),$($u.logOnId),$($u.displayName),$($u.Department),$($u.EmailAddress),$($u.UserPrincipalName)" | Out-File $ad_file  -Encoding "UTF8" -Append
	   "$adg,$($adgroups[$adg].category),$($adgroups[$adg].PSgroup),$($u.SamAccountName),$($u.logOnId),$($u.displayName),$($u.Department),$($u.EmailAddress),$($u.UserPrincipalName)" | Out-File $aduser_file  -Encoding "UTF8" -Append
	   #write-host -nonewline "$($form_status -f $({writing [$adg]},$($ch='[{0,5}]' -f $($ps_users.count)))`r"
	}
	$form_status -f "writing [$adg]","[DONE]"
}
$form1 -f "output written to: $output_path"
 
P2V_footer -app $My_name
pause

