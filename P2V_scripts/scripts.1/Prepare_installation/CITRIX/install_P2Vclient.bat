@echo off
REM   installation script for Planningspace

setlocal

REM -- setting for directories,..
set SOURCE=.
set DEST=C:\Program Files\Palantir\PlanningSpace 16.5
set INSTALLEXE=planningspace-cx-suite-165-update-10-client-setup.exe 
REM set INSTALLEXE=planningspace-165-update-10-client-setup.exe

REM --- arguments for silent installation
REM set DIR_IPS_APPDATA="%DEST%"
set ISFeatureInstall="PlanningSpace,CASH"
set SERVER_TYPE="NA"
set MAIL_HOST= "smtprelay.omv.com"
set MAIL_PORT= "25"
set MAIL_SUPPORT_ADDRESS= "plan2value@omv.com"


echo start silent installation 

echo executing : cmd /c "%SOURCE%\%INSTALLEXE% /silent SERVER_TYPE=%SERVER_TYPE% ISFeatureInstall=%ISFeatureInstall%"

echo installing planningspace ....   
cmd /c "%SOURCE%\%INSTALLEXE% /silent SERVER_TYPE=%SERVER_TYPE% ISFeatureInstall=%ISFeatureInstall%"


echo %ERRORLEVEL%
IF %ERRORLEVEL% NEQ 0 GOTO :ERROR

:OK

echo installation finished

echo copying configuration-files to %DEST%
rename  "%DEST%\PlanningSpace\Palantir.PlanningSpace.Modules.config" Palantir.PlanningSpace.Modules.config.orig
rename  "%DEST%\PlanningSpace Dataflow\PlanningSpaceDataflow.exe.config" PlanningSpaceDataflow.exe.config.orig
xcopy "%SOURCE%\Palantir.PlanningSpace.Modules.config" "%DEST%\PlanningSpace" /S /F /Y 
xcopy "%SOURCE%\PlanningSpaceDataflow.exe.config" "%DEST%\PlanningSpace Dataflow" /S /F /Y 

echo "copying finished"
goto :END

:ERROR

echo installation failed! - Errorlevel: [%ERRORLEVEL%]
endlocal


:END
endlocal
pause
