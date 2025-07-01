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
$filename="users_fromxkey.csv"

$AD_userlist = @{}
#----- start main part
P2V_header -app $My_name -path $My_path 

$tenants= select_PS_tenants -multiple $false

#  SNOWgroup  ADgroup

$u_c=@()

foreach ($ts in $tenants.keys)
{
   $t  = $tenants[$ts]
   $tenant=$t.tenant
   $tenantURL  ="$($t.ServerURL)/$($t.tenant)"
   $workingDir =$output_path +"\$tenant"
   # Initialize CSV file paths
   createdir_ifnotexists -check_path $workingDir 
   $linesep
   #
   $user_list= @()  
    # 
   $u_res=@{}
   
   while ( ($x_key= Read-Host "Please enter user-xkey: (0=exit)") -ne "" )
   {
       if ($x_key -eq "0") {$x_key="";break}
       # $u_res = [PSCustomObject]@{
	   $u_res=Get-ADUser -Filter {  (SamAccountName -like $x_key)} -properties * |
	       select  Name, 
	          Givenname, 
			  surname,
			  SamAccountName,
			  UserPrincipalName, 
			  EmailAddress, 
			  Department
				
	   if(!$u_res ) { $form_err -f  "[ERROR]","$x_key not found" }			
	   else      	{ $user_list += $u_res      } 
   }
    
   $ad_file= $workingDir+"_"+$filename
   
   if ($user_list.count -gt 0) {Delete-ExistingFile -file  $ad_file}
   Add-Content -Path $ad_file -Value 'xkey,LogonId,authenticationMethod,Domain,DisplayName,EmailAddress,Description,IsDeactivated,IsAccountLocked'
  
   foreach ($u in $user_list) 
   {
      $u.Department= $($u.Department) -replace '[,]', ''
	  $u.Department= ($u.Department).trim()
		
      "$($u.SamAccountName),$($u.UserPrincipalName),SAML2,,$($u.surname) $($u.Givenname) ($($u.SamAccountName)),$($u.EmailAddress),$($u.Department),FALSE,FALSE"| Out-File $ad_file  -Encoding "UTF8" -Append
    }
	$form1 -f "output: $ad_file "
}


P2V_footer -app $My_name
pause
#--- end of file ---
