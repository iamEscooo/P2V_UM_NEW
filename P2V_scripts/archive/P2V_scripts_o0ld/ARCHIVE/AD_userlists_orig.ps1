#  Set path for temp userlists
$workdir="\\somvat202005\PPS_Share\P2V_scripts"
$output_path=$workdir + "\output\AD-groups"
$config_path=$workdir + "\config"

$adgroupfile=$config_path + "\all_adgroups.csv"
$date= Get-Date
Write-Host "
+---------------------------------------------------------+
|  exporting userlists  from Active Directory             |
|                                                         |
|   started at $date                        |
+---------------------------------------------------------+

 Contacting  Active Directory ...
"

$all_adgroups = @()

$all_adgroups =import-csv $adgroupfile  #| where-object {$_.tenant -eq "PPS_TEST" }

# load all needed AD-groups

# license collector
$all_licenses = @()


write-host " Retrieving data from
"

foreach ($i in $all_adgroups){

    
  $collection = @()
  
 'Name','Login ID','Authentication method','Domain','Email','Description','Expiry date','Locked' |out-file "$output_path$i.csv"

  foreach ($entry in Get-ADGroupMember -Identity $($i.workgroup)|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress)
  {
   
    $item =  New-Object -TypeName PSObject    $item | Add-Member -Name 'Name' -MemberType NoteProperty -Value $($($entry.Surname)+" "+$($entry.GivenName))
    $item | Add-Member -Name 'Login ID' -MemberType NoteProperty -Value $($entry.Name)
    $item | Add-Member -Name 'Authentication method' -MemberType NoteProperty -Value 'WINDOWS_AD'
    $item | Add-Member -Name 'Domain' -MemberType NoteProperty -Value 'ww'
    $item | Add-Member -Name 'UPN' -MemberType NoteProperty -Value $($entry.UserPrincipalName)
    $item | Add-Member -Name 'Email' -MemberType NoteProperty -Value $($entry.EmailAddress)
    $item | Add-Member -Name 'Description' -MemberType NoteProperty -Value $($entry.Department)
    $item | Add-Member -Name 'Locked' -MemberType NoteProperty -Value 'FALSE'
   
    $collection += $item   
     
    
    # license count
    $lic = New-Object -TypeName PSObject
    $lic | Add-Member -Name 'Login ID' -MemberType NoteProperty -Value $($entry.Name)
    $lic | Add-Member -Name 'Name' -MemberType NoteProperty -Value $($($entry.Surname)+" "+$($entry.GivenName))
    $lic | Add-Member -Name 'Group' -MemberType NoteProperty -Value $($i.workgroup)
    $lic | Add-Member -Name 'Light' -MemberType NoteProperty -Value $($i.is_light)
    $lic | Add-Member -Name 'Heavy' -MemberType NoteProperty -Value $($i.is_heavy)
    $all_licenses += $lic    
 } 

# $collection.GetEnumerator()|Export-Csv "$output_path$i.csv" 
 #write-host 
 "  {0,-40}...[{1,4}]>[done]" -f $($i.workgroup),$($collection.count)
}

#license -print
write-host "
+---------------------------------------------------------+
     collected licenses
+---------------------------------------------------------+"

foreach ($l in $all_licenses.GetEnumerator()|sort-object  -Property 'Login ID') {
# write-host $l
 }
write-host "
+---------------------------------------------------------+
     collected licenses - sorted
+---------------------------------------------------------+"
 
 $all_licenses.GetEnumerator()| sort-object -Property 'Name' |Format-table

 write-host "
+---------------------------------------------------------+
     collected licenses - sorted - unique
+---------------------------------------------------------+"

 foreach ($u in  $all_licenses| select 'Login ID'| sort-object  -Property 'Name' -Unique  ) {
 $u.'Login ID'
 }

$date= Get-Date

write-host "
 data storing in 
 $output_path

+---------------------------------------------------------+
|   finshed at $date                        |
+---------------------------------------------------------+
"
