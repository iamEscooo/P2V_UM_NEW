@echo off

REM  OMV colors
REM  primary
REM   Deep Blue  #052759
REM   Pure White #ffffff
REM   Neon Green #1fff5a
REM  secondary
REM   Deep Green #005b29
REM   Forest Green  #007a37
REM   Pale Green  #99ffb4
REM   Vivid Blue #1f55df
REM   Azure #0ae1fe
REM   Pale Blue  #aef5ff
REM   Deep Purple  #4614a3
REM   Violet  #854fe9
REM   Lilac  #deb1fb
REM   Lavender #eed8fd

setlocal
set menufile=%~dp0config\P2V2_prod.menu
set xamldir=%~dp0\xaml
set fcolor=#ffffff
set bcolor=#052759
set system=PROD
set icon=%~dp0P2V-standard.ico

echo starting Plan2Value %system%
echo checking system messages ..
"%~dp0P2V_message.exe" -system %system%
echo opening menu for %system%
REM "%~dp0P2V_menu.exe" -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File %~dp0P2V_menu.ps1 -menufile %menufile% -fcolor %fcolor% -bcolor %bcolor% -system %system% -xamldir %xamldir% 


endlocal

