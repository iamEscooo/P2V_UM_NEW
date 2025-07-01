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
$filename="users_fromAD.csv"
$AD_userlist = @{}
#----- start main part
P2V_header -app $My_name -path $My_path 

$tenants= select_PS_tenants -all $true

#  SNOWgroup  ADgroup

foreach ($ts in $tenants.keys)
{
   $t  = $tenants[$ts]
   $tenant=$t.tenant
   $tenantURL  ="$($t.ServerURL)/$($t.tenant)"
   $workingDir =$output_path +"\$tenant"
   # Initialize CSV file paths
   createdir_ifnotexists -check_path $workingDir 
   $linesep
   $form1 -f "$tenant loading users from $($t.SNOWgroup)"
   
   if (!$AD_userlist.ContainsKey("$($t.SNOWgroup)"))
   {
      $entries = get_AD_userlist -ad_group $t.SNOWgroup -all $true
       
	  if ($entries) 
	  {
         $AD_userlist["$($t.SNOWgroup)"] = @()
         $AD_userlist["$($t.SNOWgroup)"] = $entries
         $counter=$entries.count
  	     $form_status -f "$counter users loaded","[ DONE]"      
	  }
   } else
   { # AD group already loaded
       $counter=$ad_userlist["$($t.SNOWgroup)"].count
	   $form_status -f "$counter users already loaded","[ SKIP]"
   }
   
   # write file
   $ad_file= $workingDir+"\"+$filename
   if ($AD_userlist["$($t.SNOWgroup)"].Count -gt 0)   {  Delete-ExistingFile -file $ad_file }
   
    #headerline  
	Add-Content -Path $ad_file -Value 'LogonId,authenticationMethod,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked'
	
	foreach ($u in $AD_userlist["$($t.SNOWgroup)"])
    {
	   $u.Department= $($u.Department) -replace '[,]', ''
	   $u.Department= ($u.Department).trim()
			
	  "$tenant,$($u.Name),$($u.UserPrincipalName),$($u.Department),$($u.EmailAddress)"| Out-File $ad_file -Append 
	}
	$form1 -f "output written to: $output_path"
    $form_status -f "output file : $tenant\users.csv","[DONE]"	
 }

 
P2V_footer -app $My_name
pause
#--- end of file ---