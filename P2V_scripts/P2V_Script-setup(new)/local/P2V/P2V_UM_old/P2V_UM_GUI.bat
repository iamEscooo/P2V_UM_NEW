@echo off
REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -file P2V_wrapper.ps1 -tenant %1
setlocal
REM set csvpath=\\somvat202005\PPS_share\P2V_UM_data\conf\P2Vmenu_training.csv
REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -file P2V_UM.ps1 


REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Unrestricted  -file P2V_usermgmt.ps1
endlocal

setlocal
set menufile=\\somvat202005\PPS_share\P2V_Script-setup(new)\central\config\P2V_UM.menu
set xamldir=%~dp0\xaml
set fcolor=black
set bcolor=#FF7A1F
set system=UserMgmt

echo starting Plan2Value %system%
echo checking system messages ..
REM "%~dp0P2V_message.exe" -system %system%

echo opening menu for %system%
"%~dp0P2V_menu.exe" -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe  -File "%~dp0P2V_menu.ps1" -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %~dp0

endlocal
