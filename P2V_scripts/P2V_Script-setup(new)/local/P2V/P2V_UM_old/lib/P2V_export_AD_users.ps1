#-----------------------------------------
# AD_userlists.ps1 
#
#  name:   AD_userlists.ps1
#  ver:    1.0  /2020-04-20
#  author: M.Kufner
#
#-----------------------------------------
<#  documentation
.SYNOPSIS
	short  BLABLA
.DESCRIPTION
	long BLABLA

.PARAMETER  arguments <xxx>  
	describe 1 .. n arguments
	
.PARAMETER  arguments <xxx>  
	describe 1 .. n arguments
	

.INPUTS
	none

.OUTPUTS
	true / false

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  
#>
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#-------------------------------------------------
#  Set config variables
$output_path = $output_path_base + "\$My_name"

$u_w_file    = $output_path + "\Myuserworkgroup.csv"
$u_file      = $output_path + "\Myusers.csv"
$ad_file     = $dashboard_path + "\All_AD_users.csv"

#----- start main part
P2V_header -app $My_name -path $My_path 

$form1 -f "cleaning up output ..."

createdir_ifnotexists -check_path $output_path  -verbose $true

Delete-ExistingFile -file $u_w_file # -verbose $true
Delete-ExistingFile -file $u_file   # -verbose $true
Delete-ExistingFile -file $ad_file  # -verbose $true


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
  if ($check_group = Get-ADGroup -LDAPFilter "(SAMAccountName=$($i.ADgroup))")
  {
    $aduser_file="$output_path\$($i.ADgroup).csv"
  
    Delete-ExistingFile($aduser_file)
    # headerline
    #                                       LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress
    Add-Content -Path $aduser_file -Value 'Name,Login ID,Authentication method,Domain,UPN,Email,Description,Expiry date,Locked'
  
    $entries=Get-ADGroupMember -Identity $($i.ADgroup)|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress #|where {($($_.Name) -notlike $search_user)}|Sort-Object -Property Name
    $count=0
	if ($entries) {$all_users["$($i.ADGroup)"]=$entries}
	
	
     foreach ($e in $entries  ) 
    {
      $dep=$($e.Department) -replace '[,]', ''
      Add-Content -Path $aduser_file  -Value ("$($e.Surname) $($e.GivenName),$($e.Name),SAML2,$OMV_domain,$($e.UserPrincipalName),$($e.EmailAddress),$dep,,FALSE,")
      Add-Content -Path $u_w_file     -Value ("$($e.Name),$OMV_domain,$($i.PSgroup),$($e.UserPrincipalName),$($e.EmailAddress)")
      Add-Content -Path $u_file       -Value ("$($e.Name),$OMV_domain,$($e.Surname) $($e.GivenName),$dep,FALSE,FALSE,")
      Add-Content -Path $ad_file      -Value ("$($i.ADgroup),$($e.Name),$($e.Surname) $($e.GivenName),$OMV_domain,$dep,FALSE,FALSE,$($e.EmailAddress),$($e.UserPrincipalName)")
    
      #$count++
    } 
	
	$count=$entries.count
	
	
    $form2 -f  "[$count]","users in $($i.ADgroup)" 
   } else 
   { 
    $form2 -f  "[ n/a ]","users in $($i.ADgroup)" 
   }   
 }

<# $form_statu
write-host -nonewline "writing output ...."
foreach($g in $all_users.keys)
{
   $group=$all_users[$g]
   $aduser_file="$output_path\$($g).csv"
   Delete-ExistingFile($aduser_file)

   # LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress
    
	Add-Content -Path $aduser_file -Value 'Name,Login ID,Authentication method,Domain,UPN,Email,Description,Expiry date,Locked'
	 $($all_users[$g])|% { 
	 | Out-File $ad_file  -Encoding "UTF8"
  $form1 -f ">>$g<<"
  $($all_users[$g]) |format-table 
  
}
 #>
  

 
$linesep
$form1 -f $output_path
$linesep


P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
