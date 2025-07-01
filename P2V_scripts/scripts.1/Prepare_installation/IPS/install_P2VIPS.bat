@echo off
REM   installation script for Planningspace

setlocal


REM     C:\Program Files\Palantir\PalantirIPS 16.5\Modules\PlanningSpace\Deployment\PlanningSpace
REM     C:\Program Files\Palantir\PalantirIPS 16.5\Modules\PlanningSpaceDataflow\Deployment\PlanningSpaceDataflow
REM -- setting for directories,..
REM set INSTALL_EXE=planningspace-165-update-10-server-setup.exe
set INSTALL_EXE=planningspace-cx-suite-165-update-10-server-setup.exe
set SOURCE=.
set DEST=C:\Program Files\Palantir\PlanningSpace 16.5
set service_user="ww\s.at.aucerna_ips"
set service_pass="3+t5Ky9gkt6rV%"
echo start silent installation 

echo executing : cmd /c "%SOURCE%\%INSTALLEXE% /silent ...."

echo installing planningspace ....   
cmd /c "%SOURCE%\%INSTALL_EXE% /silent IPS_SERVICE_ACCOUNT=%service_user% IPS_SERVICE_PASSWORD=%service_pass%"

echo %ERRORLEVEL%
IF %ERRORLEVEL% NEQ 0 GOTO :ERROR

:OK
pause



goto :END

:ERROR

echo installation failed! - Errorlevel: [%ERRORLEVEL%]
endlocal


:END
endlocal
pause
