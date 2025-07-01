$date=Get-Date
$svc_search= "IPS204"
$host_name=$env:computername
cls
$svc=Get-service $svc_search

Write-Host "+---------------------------------------------------------------+"
Write-Host "  STOPPING service:   $($svc.DisplayName)"  
Write-Host "  on                  $host_name"
Write-Host 
Write-Host "  started at $date"
Write-Host "+---------------------------------------------------------------+"

Get-service $svc.Name

Write-Host "`nstopping $($svc.Name) - $($svc.DisplayName)"

Stop-Service $svc.Name

$date=Get-Date
Write-Host "+---------------------------------------------------------------+"
Write-Host "   finished at $date"
Write-Host "+---------------------------------------------------------------+"
Get-service $svc.Name

Pause