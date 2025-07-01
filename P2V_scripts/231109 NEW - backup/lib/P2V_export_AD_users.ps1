#-----------------------------------------
# AD_userlists.ps1 
#
#  name:   AD_userlists.ps1
#  ver:    1.0  /2020-04-20
#  author: M.Kufner
#
#-----------------------------------------
Function P2V_export_AD_users
{
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

#-------------------------------------------------
#  Set config variables
$output_path_base = "\\somvat202005\PPS_share\P2V_UM_data\output"
$output_path = $output_path_base + "\$My_name"

$u_w_file    = $output_path + "\Myuserworkgroup.csv"
$u_file      = $output_path + "\Myusers.csv"
$ad_file     = $dashboard_path + "\All_AD_users.csv"

#----- start main part

  P2V_header -app $MyInvocation.MyCommand -path $My_path 

  write-output ($form1 -f "cleaning up output ...")

  createdir_ifnotexists -check_path $output_path  -verbose $true

  Delete-ExistingFile -file $u_w_file # -verbose $true
  Delete-ExistingFile -file $u_file   # -verbose $true
  Delete-ExistingFile -file $ad_file  # -verbose $true


  write-output ($form1   -f "exporting userlists  from Active Directory")
  write-output $linesep
  write-output ($form1 -f "Contacting  Active Directory ...")

  $all_adgroups = @{}
  $all_adgroups =import-csv $adgroupfile  
  # format:  ADgroup,lic_type,PSgroup,RESgroup,Description,Comments

  # load all needed AD-groups

  # license collector
  $all_lic = @{}

  # user collector
  $all_users = @{}
  $group_members = @{}

  write-output ($form1 -f " Retrieving data from ")

  # create headerlines
  # user/workgroup file
  #Add-Content -Path $u_w_file -Value 'LogonId,Domain,Workgroup,UPN,email'

  # user file
  Add-Content -Path $u_file -Value 'LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress'

  # all user-ad file
  Add-Content -Path $ad_file -Value 'ADgroup,ADgroup_short,LogonId,DisplayName,Domain,Description,IsDeactivated,IsAccountLocked,EmailAddress,UPN'

  foreach ($i in $all_adgroups)
  {
    # if ($check_group = Get-ADGroup -LDAPFilter "(SAMAccountName=$($i.ADgroup))")
    if ($check_group = Get-ADGroup -identity $i.ADgroup )
    {
   
      # headerline
      #     LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress
    
      Get-ADGroupMember -Identity $i.ADgroup|select Name|% {
	      $group_members["$($i.ADgroup)"]+=@($_.Name);
	      if ($all_users.keys -notcontains $_.Name )
		  { 
		     $all_users["$($_.Name)"] = Get-ADUser -identity $_.Name -properties Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress 
		  }
	  }
	  $count=	$group_members["$($i.ADgroup)"].count
	
      #write-output ($form2 -f  "[$count]","users in $($i.ADgroup)" )
	  write-output ($form_status -f "$($i.ADgroup)",("[{0,3}]" -f $count))
    } else 
    { 
	  write-output ($form_status -f "$($i.ADgroup)",("[{0,3}]" -f "n/a"))
      #write-output ($form2 -f  "[ n/a ]","users in $($i.ADgroup)" )
    }   
  } 

  write-output $linesep
  write-output ($form1 -f "writing output ..")
  write-output $linesep
  foreach ($g in $group_members.keys ) 
  {
  	write-output ($form1 -f "$g" )
    #  $aduser_file="$output_path\$g.csv"
	
    # Delete-ExistingFile($aduser_file)
    #	 Add-Content -Path $aduser_file -Value 'Name,Login ID,Authentication method,Domain,UPN,Email,Description,Expiry date,Locked'
	
    foreach ($u in $group_members["$g"])
    {
       $e= $all_users["$u"]
	   $g_short =$g -replace 'dlg.WW.ADM-Services.',''
   
       $dep=$($e.Department) -replace '[,]', ''
       #     Add-Content -Path $aduser_file  -Value ("$($e.Surname) $($e.GivenName),$($e.Name),SAML2,$OMV_domain,$($e.UserPrincipalName),$($e.EmailAddress),$dep,,FALSE,")
       #      Add-Content -Path $u_w_file     -Value ("$($e.Name),$OMV_domain,$($i.PSgroup),$($e.UserPrincipalName),$($e.EmailAddress)")
       Add-Content -Path $u_file       -Value ("$($e.Name),$OMV_domain,$($e.Surname) $($e.GivenName),$dep,FALSE,FALSE,")
       Add-Content -Path $ad_file      -Value ("$g,$g_short,$($e.Name),$($e.Surname) $($e.GivenName),$OMV_domain,$dep,FALSE,FALSE,$($e.EmailAddress),$($e.UserPrincipalName)")
    
       #$count++
    }
  }	
	 
  write-output $linesep
  write-output ($form1 -f $output_path)
  write-output $linesep

  P2V_footer -app $MyInvocation.MyCommand

}