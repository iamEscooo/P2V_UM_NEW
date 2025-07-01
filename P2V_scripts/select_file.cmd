@echo off
setlocal
set ps_cmd=powershell "Add-Type -AssemblyName System.windows.forms|Out-Null;$f=New-Object System.Windows.Forms.OpenFileDialog;$f.Filter='Text Files (*.txt)|*.txt|All files (*.*)|*.*';$f.showHelp=$true;$f.initialdirectory='\\somvat202005\PPS_share\P2V_scripts\messages';$f.title='Select messagefile';$f.ShowDialog()|Out-Null;$($f.FileName)"

for /f "delims=" %%I in ('%ps_cmd%') do set "filename=%%I"

if defined filename (
    echo You chose %filename%
) else (
    echo You didn't choose squat!
)

goto :EOF