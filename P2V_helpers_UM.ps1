#region Setup
param(
  [string]$csvpath=Join-Path $PSScriptRoot "P2V_scripts\NEW\P2V_helpers_UM.csv"
)
  
import-module -name "$PSScriptRoot\P2V_config.psd1" -verbose
import-module -name "$PSScriptRoot\P2V_include.psd1"  -verbose
import-module -name "$PSScriptRoot\P2V_dialog_func.psd1"  -verbose 
import-module -name "$PSScriptRoot\P2V_AD_func.psd1" -verbose
import-module -name "$PSScriptRoot\P2V_PS_func.psd1" -verbose

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
  $My_Path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
  } else {
    $My_Path = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    if (!$My_Path){ $My_Path = "." }
  }
if (!$workdir) {$workdir=$My_Path}
# $My_path=Split-Path $($MyInvocation.MyCommand.Path)
# if (!$workdir) {$workdir=$My_Path}
#. "$workdir/lib/P2V_include.ps1"
#-- global variable --
#Set-Location $workdir
Remove-Module PSScriptMenuGui -ErrorAction SilentlyContinue
try {
    Import-Module PSScriptMenuGui -ErrorAction Stop
}
catch {
    Write-Warning $_
    Write-Verbose 'Attempting to import from parent directory...' -Verbose
    Import-Module '..\'
}
#endregion

if (!$csvpath) {$csvpath=$config_path + "\P2V_helpers_UM.csv"}

$params = @{
    csvPath = $csvpath
    windowTitle = 'Plan2Value User Management'
    buttonForegroundColor = 'Black'
    buttonBackgroundColor = '#FF7A1F'   	#'#003366'
    iconPath = '.\P2V.ico'
    hideConsole = $false
    noExit = $false
    Verbose = $true
}
Show-ScriptMenuGui @params 