@echo off
setlocal
set SOURCE=\\somvat202005\PPS_share\P2V_scripts\Prepare_installation\CITRIX
set DEST=c:\TMP_INSTALL
if not exist %DEST%  mkdir  %DEST%
xcopy %SOURCE%\* %DEST% /S /F /Y

dir %DEST%
endlocal

pause