@echo off
rmdir /s c:\OMV_NAMR_Report_App 
rmdir /s /q c:\P2V_start
rmdir /s /q c:\P2V_UM

xcopy \\somvat202005\PPS_Share\P2V_scripts\P2V_start\OMV_NAMR_Report_App  c:\OMV_NAMR_Report_App /I /E
xcopy \\somvat202005\PPS_Share\P2V_scripts\P2V_start\P2V_start c:\P2V_start /I /E
xcopy \\somvat202005\PPS_Share\P2V_scripts\P2V_start\P2V_UM c:\P2V_UM /I /E