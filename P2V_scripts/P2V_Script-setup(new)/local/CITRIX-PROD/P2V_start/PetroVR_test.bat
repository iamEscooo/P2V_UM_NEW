@echo off

setlocal
set menufile=%~dp0config\PetroVR.menu
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

REM set
REM set PETROVR_CONFIG_DIR=%APPDATA%\Aucerna\PetroVR\
REM set PETROVR_CONFIG=PetroVR.ini

REM echo looking for  %PETROVR_CONFIG_DIR%\%PETROVR_CONFIG%
REM rename %PETROVR_CONFIG_DIR%\%PETROVR_CONFIG% %PETROVR_CONFIG%.old
REM dir %PETROVR_CONFIG_DIR%

REM pause
"C:\Program Files (x86)\Aucerna\PetroVR\PetroVR.exe"
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 
endlocal

REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

endlocal


echo opening menu for %system%
REM "%~dp0P2V_menu.exe" -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 
endlocal

