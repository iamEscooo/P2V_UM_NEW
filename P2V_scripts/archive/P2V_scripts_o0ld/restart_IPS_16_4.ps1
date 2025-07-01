$date=Get-Date
Write-Host "+---------------------------------------------------------------+"
Write-Host "|  restarting IPS service on tsomvat502101 (IPS-TEST1)          |"
Write-Host "|                                                               |"
Write-Host "|  started at $date                               |"
Write-Host "+---------------------------------------------------------------+"
Pause
Restart-Service "PalantirIPS Services 16.5"
$date=Get-Date
Write-Host "+---------------------------------------------------------------+"
Write-Host "|   finished at $date                             |"
Write-Host "+---------------------------------------------------------------+"