@ECHO off
:begin
ECHO Would you like to only remove read only attributes
ECHO from this director or from all the sub directores as
ECHO well?
ECHO.
ECHO [A] This directory only
ECHO [B] All directories - cascading
ECHO [C] Cancel
SET /P actionChoice="Option(A,B,C): "
ECHO.
IF "%actionChoice%" == "A" GOTO A
IF "%actionChoice%" == "B" GOTO B
IF "%actionChoice%" == "C" GOTO C
GOTO badChoice

:A
CLS
ECHO Are you sure you want to remove all read-only
ECHO attributes from this directory only?
ECHO.
ECHO Directory:
ECHO.
ECHO %CD%
ECHO.
SET /P continueChoice="Continue? (Y, N): "
IF "%continueChoice%" == "N" GOTO abort
ECHO Removing Read Only Attributes From Local Directory...
SET currectDirectory=%CD%
ECHO Current directory is: %currectDirectory%
FOR %%G IN (%currectDirectory%\*) DO (
ECHO %%G
ATTRIB +R "%%G"
)
GOTO end

:B
CLS
ECHO Are you sure you want to remove all read-only
ECHO attributes from this directory and all sub-directories?
ECHO.
ECHO Directory:
ECHO.
ECHO %CD%
ECHO.
SET /P continueChoice="Continue? (Y, N): "
IF "%continueChoice%" == "N" GOTO abort
ECHO Removing Read Only Attributes Cascading...
FOR /R %%f IN (*) DO (
ECHO %%f
ATTRIB +R "%%f"
)
GOTO end

:C
CLS
ECHO Cancel: no files have been changed
GOTO end

:badChoice
CLS
ECHO Unknown Option
ECHO.
ECHO.
ECHO.
GOTO begin

:abort
CLS
ECHO No files have been changed
ECHO.
ECHO.
ECHO.
GOTO begin

:end
ECHO Read only attributes removed
PAUSE