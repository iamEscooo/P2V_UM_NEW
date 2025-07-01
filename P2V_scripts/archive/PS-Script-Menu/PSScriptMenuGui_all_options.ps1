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
    csvPath = '.\P2Vtest.csv'
    windowTitle = 'select a tenant'
    buttonForegroundColor = 'White'
    buttonBackgroundColor = 'Green'
    iconPath = '.\pwsh7.ico'
    hideConsole = $false
    noExit = $true
    Verbose = $false
}
Show-ScriptMenuGui @params