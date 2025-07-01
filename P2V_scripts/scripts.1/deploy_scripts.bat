@echo off
setlocal
set SOURCE=\\somvat202005\PPS_Share\P2V_scripts\P2V_start
set DEST=c:

rd /s %DEST%\P2V_UM
xcopy %SOURCE%\P2V_admin %DEST%\P2V_UM /S /F /Y /C /I

rd /s %DEST%\P2V_start
xcopy %SOURCE%\P2V_start %DEST%\P2V_start /S /F /Y /C /I
endlocal

pause