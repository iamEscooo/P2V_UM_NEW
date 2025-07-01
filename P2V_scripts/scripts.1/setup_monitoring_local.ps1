# hostname

# net LOCALGROUP "Administrators" WW\s.at.p2vmonitoring /add
# "Performance Monitor Users"
# Performance Log Users
# Remote Desktop Users
# Remote Management Users
# Administrators

# net LOCALGROUP "Administrators"

write-host -foregroundcolor yellow "+---------------------------------------+"
hostname
write-host -foregroundcolor yellow "+---------------------------------------+"

# write-host " -- Get-WinSystemLocale:  --"
# Get-WinSystemLocale

# write-host " -- Get-WinUILanguageOverride: -- "
# Get-WinUILanguageOverride

# write-host " -- Get-WinUserLanguageList: --"
# Get-WinUserLanguageList

# Write-host " -- get-culture | format-list  --"
# get-culture | select -property IetfLanguageTag |format-list 
# (get-culture).DateTimeFormat
#net LOCALGROUP "Remote Management Users" WW\s.at.p2vmonitoring /add

$users = @( 
           "WW\s.at.p2vmonitoring" 
		  )
$l_groups = @(
              "Remote Management Users",
              "Remote Desktop Users",
			  "Performance Log Users",
			  "Performance Monitor Users"
			  #"Administrators"
			 )

Foreach ($g in $l_groups) 
{
    write-host "$g  "
	Foreach ($u in $users)
	{
	   write-host -nonewline "   adding $u ...                       "
	   if (Add-LocalGroupMember -Group "$g" -Member "$u" -ErrorAction SilentlyContinue) { "[DONE]"} else {"[SKIP]"}
	}
	if ($gm= Get-LocalGroupMember -Group  "$g" -ErrorAction SilentlyContinue){ $gm|format-table}
}
#exit
#if (Add-LocalGroupMember -Group "Remote Management Users" -Member "WW\s.at.p2vmonitoring" –ErrorAction SilentlyContinue)
#{}
#Add-LocalGroupMember -Group "Remote Desktop Users" -Member "WW\s.at.p2vmonitoring"
#Add-LocalGroupMember -Group "Administrators" -Member "WW\s.at.p2vmonitoring"
# net LOCALGROUP "Remote Desktop Users" WW\s.at.p2vmonitoring /add
# net LOCALGROUP "Administrators" WW\s.at.p2vmonitoring /add
# get user localgroups:
#net user s.at.p2vmonitoring /domain 
#net user s.at.p2v.res /domain
#net user s.at.aucerna_res /domain
write-host "+---------------------------------------+"
#Get-LocalGroupMember -Group  "Remote Management Users"|format-table
#Get-LocalGroupMember -Group "Remote Desktop Users"|format-table
#Get-LocalGroupMember -Group "Administrators"|format-table
#pause