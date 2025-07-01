@echo off
REM colors
REM yellow   #FEC114
REM orange   #FF7A1F
REM green    #66CC00
REM petrol blue #0A8282
REM Purple   #A03264
REM Lilac    #966482

setlocal
set menufile=%~dp0config\P2V_training.menu
set xamldir=%~dp0\xaml
set fcolor=#ffffff
set bcolor=#052759
set system=TRAINING

echo starting Plan2Value %system%
echo checking system messages ..
"%~dp0P2V_message.exe" -system %system%
echo opening menu for %system%
REM "%~dp0P2V_menu.exe" -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 
endlocal

