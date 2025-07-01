
REM PRODUCTION
set SOURCE="\\somvat202005\pps_share\AUCERNA_INSTALL\10 Planningspace\20 series\tenant-configuration\prod\*.xml"
set DEST="D:\Planningspace\data\PalantirIPS 20.4"

REM TEST installation
REM set SOURCE="\\somvat202005\pps_share\AUCERNA_INSTALL\10 Planningspace\20 series\tenant-configuration\test\*.xml"
REM set DEST="D:\Plan2Value\tmp_backup"

REM UPDATE installation
REM set SOURCE="\\somvat202005\pps_share\AUCERNA_INSTALL\10 Planningspace\20 series\tenant-configuration\update\*.xml"
REM set DEST="D:\Planningspace\tmp_backup"



xcopy  %SOURCE% %DEST%   /w /y /x

pause