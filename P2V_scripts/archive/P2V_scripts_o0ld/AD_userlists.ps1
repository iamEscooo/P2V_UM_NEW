param(
    [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
    [string]$search_user="*admin*",
    [bool]$analyzeOnly = $True
    
)
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path
. "$workdir/P2V_include.ps1"

#-------------------------------------------------
#  Set config variables

$config_path = $workdir     + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir + "\output\AD-groups"
$dashboard_path = $workdir + "\output\dashboard"
$u_w_file    = $output_path + "\Myuserworkgroup.csv"
$u_file      = $output_path + "\Myusers.csv"
$ad_file     = $dashboard_path + "\All_AD_users.csv"

#-------------------------------------------------
#----- start main part

P2V_header -app $My_name -path $My_path 

$form1 -f "cleaning up output ..."
createdir_ifnotexists ($dashboard_path)
createdir_ifnotexists ($output_path)

#foreach($f in @($all_u_w_export ,$u_file,$w_file, $all_u_export,$all_g_export)) {Delete-ExistingFile($f)}
($u_w_file  ,$u_file,$ad_file)|% {Delete-ExistingFile($_,$false)}


$form1   -f "exporting userlists  from Active Directory"
$linesep
$form1 -f "Contacting  Active Directory ..."

$all_adgroups = @{}
$all_adgroups =import-csv $adgroupfile  
# format:  ADgroup,lic_type,PSgroup,RESgroup,Description,Comments

# load all needed AD-groups

# license collector
$all_lic = @{}

# user collector
$all_users = @{}

$form1 -f " Retrieving data from "

# create headerlines
# user/workgroup file
Add-Content -Path $u_w_file -Value 'LogonId,Domain,Workgroup,UPN,email'

# user file
Add-Content -Path $u_file -Value 'LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress'

# all user-ad file
Add-Content -Path $ad_file -Value 'ADgroup,LogonId,DisplayName,Domain,Description,IsDeactivated,IsAccountLocked,EmailAddress,UPN'

foreach ($i in $all_adgroups){
  
  $aduser_file="$output_path\$($i.ADgroup).csv"
  
  Delete-ExistingFile($aduser_file)
  # headerline
  #                                       LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress
  Add-Content -Path $aduser_file -Value 'Name,Login ID,Authentication method,Domain,UPN,Email,Description,Expiry date,Locked'
  
  $entries=Get-ADGroupMember -Identity $($i.ADgroup)|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress #|where {($($_.Name) -notlike $search_user)}|Sort-Object -Property Name
  $count=0
  foreach ($e in $entries  ) 
  {
     $dep=$($e.Department) -replace '[,]', ''
     Add-Content -Path $aduser_file  -Value ("$($e.Surname) $($e.GivenName),$($e.Name),SAML2,$OMV_domain,$($e.UserPrincipalName),$($e.EmailAddress),$dep,,FALSE,")
     Add-Content -Path $u_w_file     -Value ("$($e.Name),$OMV_domain,$($i.PSgroup),$($e.UserPrincipalName),$($e.EmailAddress)")
     Add-Content -Path $u_file       -Value ("$($e.Name),$OMV_domain,$($e.Surname) $($e.GivenName),$dep,FALSE,FALSE,")
     Add-Content -Path $ad_file      -Value ("$($i.ADgroup),$($e.Name),$($e.Surname) $($e.GivenName),$OMV_domain,$dep,FALSE,FALSE,$($e.EmailAddress),$($e.UserPrincipalName)")
    
     $count++
  }
  $form2 -f  "[$count]","users in $($i.ADgroup)" 
   
 } 
$linesep
$form1 -f $output_path
$linesep
