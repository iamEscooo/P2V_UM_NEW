cls

hostname

write-host " -- Get-WinSystemLocale:  --"
Get-WinSystemLocale

write-host " -- Get-WinUILanguageOverride: -- "
Get-WinUILanguageOverride

write-host " -- Get-WinUserLanguageList: --"
Get-WinUserLanguageList

Write-host " -- get-culture | format-list  --"
get-culture | format-list 