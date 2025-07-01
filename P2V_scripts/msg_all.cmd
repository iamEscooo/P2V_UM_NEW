@echo off

setlocal
set ps_cmd=powershell "Add-Type -AssemblyName System.windows.forms|Out-Null;$f=New-Object System.Windows.Forms.OpenFileDialog;$f.Filter='Text Files (*.txt)|*.txt|All files (*.*)|*.*';$f.showHelp=$true;$f.initialdirectory='\\somvat202005\PPS_share\P2V_scripts\messages';$f.title='Select messagefile';$f.ShowDialog()|Out-Null;$($f.FileName)"

for /f "delims=" %%I in ('%ps_cmd%') do set "filename=%%I"

if defined filename (
    cls
    echo You chose %filename%
	echo ----- begin of message -----
	type %filename%
	echo ----- end of message   -----
	pause
	date /t
	time /t
    for %%S in (somvat422001, somvat422003, somvat422008, somvat422009, somvat422017, somvat422018) DO  (msg * /server:%%S.ww.omv.com /TIME:300 /v < %filename%)
    for %%S in (somvat502676) DO  (msg * /server:%%S.ww.omv.com /TIME:300 /v < %filename%)

) else (
    echo You didn't choose a file!
)

endlocal

