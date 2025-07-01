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
    
   # $ad_file= $workingDir+"_"+$filename
   
   # if ($user_list.count -gt 0) {Delete-ExistingFile -file  $ad_file}
   
    if (($cont=read-host ($form1 -f "continue clearing users (remove workgroup assignments  [$($user_list.Count)] users? (y/n)")) -like "y")	
   {
      foreach ($u in $user_list) 
      {
	    write-host -nonewline "|  cleaning $($u.UserPrincipalName) ...`r"
        #if (PS_user_clear_all_workgroups -tenant $t -logonID $u.UserPrincipalName -verbose $true){$rc="[DONE]"}else {$rc="[ERROR]"}
		PS_user_clear_all_workgroups -tenant $t -logonID $u.UserPrincipalName -verbose $true
	    $form_status -f "cleaning $($u.UserPrincipalName)",$rc
      }
	}
}


P2V_footer -app $My_name
pause
#--- end of file ---
