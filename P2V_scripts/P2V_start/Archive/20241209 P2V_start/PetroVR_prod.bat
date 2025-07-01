@echo off

setlocal

set system=PETROVR
set menufile=%~dp0config\PetroVR.menu
set xamldir=%~dp0\xaml
set fcolor=White
set bcolor=#003366


echo starting  %system%
echo checking system messages ..
"%~dp0P2V_message.exe" -system %system%

REM cd "C:\Program Files\Quorum\PetroVR64"
REM "C:\Program Files\Quorum\PetroVR64\PetroVR.exe"

REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

endlocal

