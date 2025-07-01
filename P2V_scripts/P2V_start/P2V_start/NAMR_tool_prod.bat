@echo off

setlocal
set system=ALL

echo starting  %system%
echo "USER: %USERNAME%  on HOST: %COMPUTERNAME%"
set
echo checking system messages ..
"%~dp0P2V_message.exe" -system %system%

set WORKDIR="C:\OMV_NAMR_Report_App\PROD"
cd %WORKDIR%
"%WORKDIR%\Aucerna.PSEconExtractor.Gui.exe"

REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

endlocal

