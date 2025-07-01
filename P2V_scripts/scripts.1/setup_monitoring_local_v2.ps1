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

# copy installer 
Copy-Item -Path "\\\somvat202005\PPS_share\AUCERNA_INSTALL\Planningspace\16.5 - Update 10\planningspace-cx-suite-165-update-10-client-setup.exe" -Destination "C:\TMP_INSTALL\planningspace-cx-suite-165-update-10-client-setup.exe" -Recurse -Force
# Run sillent intaller
#$command = @'
#cmd / "\\somvat202005\PPS_share\AUCERNA_INSTALL\Planningspace\16.5 - Update 10\planningspace-165-update-10-client-setup.exe" /silent DIR_IPS_APPDATA="<ProgramFilesLocation>" ISFeatureInstall="<ListOfFeaturesToInstall>" SERVER_TYPE=NA MAIL_HOST=SomeMaileHost  MAIL_SUPPORT_ADDRESS=support@email.com MAIL_PORT=25"
#'@

#Invoke-Expression -Command:$command



# Copy Modules config
#Copy-Item -Path "\\somvat202005\PPS_share\AUCERNA_INSTALL\Planningspace\Clientconfig\Palantir.PlanningSpace.Modules.config" -Destination "C:\Program Files\Palantir\PlanningSpace 16.5\PlanningSpace\Palantir.PlanningSpace.Modules.config" -Recurse -Force


# copy Dataflow config
#copy-item -path "\\somvat202005\PPS_share\AUCERNA_INSTALL\Planningspace\Clientconfig\PlanningSpaceDataflow.exe.config" -Destination "C:\Program Files\Palantir\PlanningSpace 16.5\PlanningSpace Dataflow"  -Recurse -Force