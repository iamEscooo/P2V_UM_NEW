@echo off


REM   copy prepared config files from  location %SOURCE%
setlocal
set SOURCE=\\somvat202005\PPS_share\AUCERNA_INSTALL\Planningspace\16.5 - Update 6\ClientConfig
set DEST=C:\Program Files\Palantir\PlanningSpace 16.5

ren %DEST%\PlanningSpace\Palantir.PlanningSpace.Modules.config Palantir.PlanningSpace.Modules.config.orig
ren "%DEST%\PlanningSpace Dataflow\PlanningSpaceDataflow.exe.config" PlanningSpaceDataflow.exe.config.orig
xcopy "%SOURCE%\Palantir.PlanningSpace.Modules.config" "%DEST%\PlanningSpace" /S /F /Y 
xcopy "%SOURCE%\PlanningSpaceDataflow.exe.config" "%DEST%\PlanningSpace Dataflow" /S /F /Y 

endlocal

pause
