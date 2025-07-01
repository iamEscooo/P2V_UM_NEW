@echo off
setlocal
set SOURCE=\\somvat202005\PPS_share\AUCERNA_INSTALL\Planningspace\16.5 - Update 6
set DEST=c:\TMP_INSTALL
if not exist %DEST%  mkdir  %DEST%
xcopy "%SOURCE%\planningspace-cx-suite-165-update-6-server-setup.exe" %DEST% /S /F /Y

dir %DEST%
endlocal

pause