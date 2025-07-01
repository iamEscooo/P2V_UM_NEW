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

$group = "Remote Desktop Users"

write-host -nonewline "   adding $group ...                       "
   if (Add-LocalGroupMember -Group "$group" -Member "WW\s.at.p2vmonitoring","WW\dlg.WW.ADM-Services.P2V.serveradmin","WW\dlg.WW.ADM-Services.P2V.testserveradmin"  ) { "[DONE]"} else {"[SKIP]"}


net LOCALGROUP $group
