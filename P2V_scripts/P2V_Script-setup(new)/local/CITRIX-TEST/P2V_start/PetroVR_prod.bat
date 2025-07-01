@echo off

setlocal
set system=PETROVR

echo starting  %system%
echo checking system messages ..
"%~dp0P2V_message.exe" -system %system%

cd "C:\Program Files (x86)\Aucerna\PetroVR"
"C:\Program Files (x86)\Aucerna\PetroVR\PetroVR.exe"

REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

endlocal

