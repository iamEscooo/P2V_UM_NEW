param(
  [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
  [string]$search_user="*admin*",
  [bool]$analyzeOnly = $True
)
#-------------------------------------------------
#  Set config variables

#$workdir     = "\\somvat202005\PPS_Share\P2V_scripts"

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir + "\output\AD-groups"
$u_w_file= $output_path + "\Homedir.csv"
$OMV_domain="ww"
$all_users=@()
#-------------------------------------------------

foreach ($i in import-csv $adgroupfile)
{
  "$($i.ADgroup)"
  $entries=Get-ADGroupMember -Identity $($i.ADgroup) |Get-ADUser -properties * |select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Country,Company,Department,EmployeeNumber, Enabled, HomeDirectory ,PasswordExpired ,LockedOut,lockoutTime |where {($($_.Name) -notlike $search_user)}|Sort-Object -Property Name

  foreach ($e in $entries  ) {if ($e.HomeDirectory){$all_users += $e} }
 }  
"loaded"
$cleanlist=$all_users|select Name, Surname, GivenName,SamAccountName,Country,Company,Department,EmployeeNumber, HomeDirectory |Sort-Object -Property Name -Unique
"cleaned"
if (Test-Path $u_w_file) {Remove-Item $u_w_file}
Add-Content -Path $u_w_file -Value 'Name, Surname, GivenName,SamAccountName,EmployeeNumber,HomeDirectory,Country,Company,Department'
"exporting"
foreach ($e in $cleanlist  ) 
{
   write-host "$($e.Name) in in $($e.Country) accesses $($e.HomeDirectory)"
   Add-Content -Path $u_w_file -Value "$($e.Name),$($e.Surname), $($e.GivenName),$($e.SamAccountName),$($e.EmployeeNumber),$($e.HomeDirectory),$($e.Country),$($e.Company),$($e.Department)"
} 

"finish"

