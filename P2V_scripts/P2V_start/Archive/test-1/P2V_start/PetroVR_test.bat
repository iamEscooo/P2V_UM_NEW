@echo off

setlocal
set menufile=%~dp0config\PetroVR_test.menu
set xamldir=%~dp0\xaml
set fcolor=white
set bcolor=#3A958B
set system=PetroVR


echo starting  %system%
echo checking system messages ..
"%~dp0P2V_message.exe" -system %system%


echo opening menu for %system%
REM "%~dp0P2V_menu.exe" -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 
endlocal

