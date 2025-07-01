#region Setup

$PSScriptRoot= Split-Path $($MyInvocation.MyCommand.Path)
Set-Location $PSScriptRoot
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

$params = @{
    csvPath = '.\P2Vdevtest.csv'
    windowTitle = 'Select a Plan2Value TEST tenant'
    buttonForegroundColor = 'White'
    buttonBackgroundColor = 'Green'
    iconPath = '.\aucerna.ico'
    hideConsole = $false
    noExit = $false
    Verbose = $false
}
Show-ScriptMenuGui @params