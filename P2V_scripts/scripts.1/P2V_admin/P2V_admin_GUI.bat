@echo off
REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -file P2V_wrapper.ps1 -tenant %1
setlocal
REM set csvpath=\\somvat202005\PPS_share\P2V_UM_data\conf\P2Vmenu_training.csv
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -file P2V_admin.ps1 


REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Unrestricted  -file P2V_usermgmt.ps1
endlocal
