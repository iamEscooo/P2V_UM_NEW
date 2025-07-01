$date=Get-Date
$svc_name= "PalantirIPS Services 16.5"
$host_name=$env:computername
cls

Write-Host "+---------------------------------------------------------------+"
Write-Host "|  restarting service:   PalantirIPS Services 16.5              |"  
Write-Host "|  on                    $host_name                           |"
Write-Host "|                                                               |"
Write-Host "|  started at $date                               |"
Write-Host "+---------------------------------------------------------------+"

Get-service $svc_name

Write-Host "`nrestarting $svc_name"
Restart-Service $svc_name

$date=Get-Date
Write-Host "+---------------------------------------------------------------+"
Write-Host "|   finished at $date                             |"
Write-Host "+---------------------------------------------------------------+"
Get-service $svc_name
Pause