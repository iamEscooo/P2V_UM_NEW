net LOCALGROUP "Remote Management Users" "WW\s.at.p2vmonitoring" /del
net LOCALGROUP "Remote Desktop Users" "WW\s.at.p2vmonitoring" /del
net LOCALGROUP "Distributed COM Users" "WW\s.at.p2vmonitoring" /add

rem net LOCALGROUP "Remote Desktop Users" "WW\dlg.WW.ADM-Services.P2V.serveradmin" /add
rem net LOCALGROUP "Remote Desktop Users" "WW\dlg.WW.ADM-Services.P2V.testserveradmin" /add

net LOCALGROUP "Remote Desktop Users"
net LOCALGROUP "Remote Management Users"
net LOCALGROUP "Distributed COM Users"
pause