param(
  [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
  [string]$xkey="x449222",
  [string]$UPN="martin.kufner@omv.com",
  [bool]$analyzeOnly = $True
)
#-------------------------------------------------
$scriptname=$($MyInvocation.MyCommand.Name)

#----- Set config variables

 [string]$tenantUrl = "https://ips-test.ww.omv.com/P2V_TRAINING",
 [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
 [string]$search_user="*admin*",
 [bool]$analyzeOnly = $True
    
#$workdir     = "\\somvat202005\PPS_Share\P2V_scripts"

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir + "\output\AD-groups"
$u_w_file= $output_path + "\Myuserworkgroup.csv"
$OMV_domain="ww"
param(
    [string]$tenantUrl = "https://ips-test.ww.omv.com/P2V_TRAINING",
    [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
    [string]$search_user="*admin*",
    [bool]$analyzeOnly = $True
    
)
#  Set path for temp userlists

$output_path = $workdir     + "\output\AD-groups"
$u_w_file=     $output_path + "\Myuserworkgroup.csv"
$u_file=       $output_path + "\Myusers.csv"
$ad_file=      $output_path + "\All_AD_users.csv"

$OMV_domain="ww"

$date= Get-Date
Write-Host "
+---------------------------------------------------------+
|  exporting userlists  from Active Directory             |
|                                                         |
|   started at $date                        |
+---------------------------------------------------------+

 Contacting  Active Directory ...
"

$all_adgroups = @{}

$all_adgroups =import-csv $adgroupfile  #| where-object {$_.tenant -eq "PPS_TEST" }
# format:  ADgroup,lic_type,PSgroup,RESgroup,Description,Comments

# load all needed AD-groups

# license collector
$all_lic = @{}

# user collector
$all_users = @{}

write-host " Retrieving data from
"
# user/workgroup file
if (Test-Path $u_w_file) {Remove-Item $u_w_file}
Add-Content -Path $u_w_file -Value 'LogonId,SAMLLogonId,Domain,Workgroup'

# user file
if (Test-Path $u_file) {Remove-Item $u_file}
Add-Content -Path $u_file -Value 'LogonId,SAMLLogonId,Domain,DisplayName,Descr
iption,IsDeactivated,IsAccountLocked,EmailAddress'

if (Test-Path $ad_file) {Remove-Item $ad_file}
Add-Content -Path $ad_file -Value 'ADgroup,LogonId,SAMLLogonId,DisplayName,Domain,Description,IsDeactivated,IsAccountLocked,EmailAddress'

foreach ($i in $all_adgroups){
  
  $aduser_file="$output_path\$($i.ADgroup).csv"
  
  if (Test-Path $aduser_file) {Remove-Item $aduser_file }
 
 #                                       LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress
  Add-Content -Path $aduser_file -Value 'Name,Login ID,Authentication method,Domain,Email,Description,Expiry date,Locked'
  
  $entries=Get-ADGroupMember -Identity $($i.ADgroup)|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress|Sort-Object -Property Name
  $count=0
  foreach ($e in $entries  ) 
  {
     $dep=$($e.Department) -replace '[\W]', ' '
     Add-Content -PAth $aduser_file -Value ("$($e.Surname) $($e.GivenName),$($e.Name),WINDOWS_AD,$OMV_domain,$($e.EmailAddress),$dep,,FALSE,")
     Add-Content -Path $u_w_file -Value ($($e.Name) + ",$OMV_domain," + $($i.PSgroup))
     Add-Content -Path $u_file -Value ("$($e.Name),$OMV_domain,$($e.Surname) $($e.GivenName),$dep,FALSE,FALSE,")
     Add-Content -Path $ad_file -Value ("$($i.ADgroup),$($e.Name),$($e.Surname) $($e.GivenName),$OMV_domain,$dep,FALSE,FALSE,")
     write-output "       ($($e.Name),$OMV_domain,$($i.PSgroup))"
     $count++

     if (!($all_lic.ContainsKey($($e.Name)))) {$all_lic.Add($($e.Name),0)}
	 if (!($all_users.ContainsKey($($e.Name)))) {$all_users.Add($($e.Name),0)}
     $all_lic[$($e.Name)] =($all_lic[$($e.Name)],$e.lic_type | Measure -Max).Maximum

   }
   "  {0,-40}...[{1,4}]>[done]" -f $($i.ADgroup),$count
  
  
 } 


#license -print
write-host "
+---------------------------------------------------------+
     collected licenses
+---------------------------------------------------------+"

$lic_count=@()

foreach ($l in $($all_lic.Keys)) {

if ($lic_count[$all_lic[$l]] ++)

#if ($all_lic[$l] -eq 0){$lictype="LIGHT";$lic_light ++ } else { $lictype="HEAVY";$lic_heavy ++}
 # "  {0,-25}...[{1,2}]...>[{2,5}]" -f $l,$all_lic[$l],$lictype
 # }
write-host "`n+---------------------------------------------------------+
     collected licenses - summary
+---------------------------------------------------------+"

Foreach($i in 0 .. 5) {
"  license type [{0,2}] ... [{1,5}] "  -f  $i,  $lic_count[$i]
}
#"  light user licenses   ... [{0,5}]" -f $lic_light  
#"  heavy user licenses   ... [{0,5}]" -f $lic_heavy



 
$date= Get-Date

write-host "

 data storing in 
 $output_path

+---------------------------------------------------------+
|   finshed at $date                        |
+---------------------------------------------------------+
"
