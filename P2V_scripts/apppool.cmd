@echo off
setlocal

set ACTION=%1
set POOL=%2

IF "%ACTION%"=="" (goto LIST)
IF "%POOL%"==""   (set POOL=OMVUPDATE)

:DO_IT
%systemroot%\System32\inetsrv\appcmd.exe %ACTION% apppool /apppool.name:%POOL%
%systemroot%\System32\inetsrv\appcmd.exe %ACTION% apppool /apppool.name:%POOL%-AnnotationsService
%systemroot%\System32\inetsrv\appcmd.exe %ACTION% apppool /apppool.name:%POOL%-ApprovalService
%systemroot%\System32\inetsrv\appcmd.exe %ACTION% apppool /apppool.name:%POOL%-ResultSetService
%systemroot%\System32\inetsrv\appcmd.exe %ACTION% apppool /apppool.name:%POOL%-SecurityService
%systemroot%\System32\inetsrv\appcmd.exe %ACTION% apppool /apppool.name:%POOL%-WSBMonitor

goto END

:LIST

%systemroot%\system32\inetsrv\AppCmd.exe list apppool


:END