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


# get user localgroups:
net user s.at.p2vmonitoring /domain 
net user s.at.p2v.res /domain
net user s.at.aucerna_res /domain
net LOCALGROUP "Remote Management Users"
#pause