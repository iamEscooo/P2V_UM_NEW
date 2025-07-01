#-----------------------------------------
# AD_userlists.ps1 
#
#  name:   AD_userlists.ps1
#  ver:    1.0  /2020-04-20
#  author: M.Kufner
#
#-----------------------------------------

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

$form1   -f "checking existing AD groups"
$linesep
$form1 -f "Contacting  Active Directory ..."
$form1 -f "$workdir\P2V_include.ps1"
$form1 -f "loading [$adgroupfile] ..."

$all_adgroups = @{}
$all_adgroups =import-csv $adgroupfile  
# format:  ADgroup,lic_type,PSgroup,RESgroup,Description,Comments

# load all needed AD-groups
$form1 -f "loading [$adgroupfile] ...[$($all_adgroups.count)] groups"


# license collector
$all_lic = @{}

# user collector
$all_users = @{}
$count=0

foreach ($i in $all_adgroups)
{
  #write-host -nonewline "$($i.ADgroup)                     "
   #$i|Add-Member -Name 'members' -Type NoteProperty -Value "n/a"
  if ($check_group = Get-ADGroup -LDAPFilter "(SAMAccountName=$($i.ADgroup))")
  #if ($entries=Get-ADGroupMember -Identity $($i.ADgroup) -ErrorAction SilentlyContinue) 
  {
    #$entries=Get-ADGroupMember -Identity $($i.ADgroup)|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress #|where {($($_.Name) -notlike $search_user)}|Sort-Object -Property Name
    $entries=Get-ADGroupMember -Identity $($i.ADgroup)
	$i|Add-Member -Name 'members' -Type NoteProperty -Value "$($entries.count)"
  } else
  {$i|Add-Member -Name 'members' -Type NoteProperty -Value "n/a"}
  $count++
  write-host -nonewline "$count`r"
}

$all_adgroups|select ADgroup,PSgroup,Description,Activity,members|format-table
$all_adgroups|out-gridview

$linesep

P2V_footer -app $My_name

