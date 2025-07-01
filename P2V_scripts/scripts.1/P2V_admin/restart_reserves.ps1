$date=Get-Date
$svc_name= "Aucerna*"
$host_name=$env:computername
cls

Write-Host "+---------------------------------------------------------------+"
Write-Host "|  restarting service:   $svc_name"  
Write-Host "|  on                    $host_name"
Write-Host "|                                  "
Write-Host "|  started at $date                "
Write-Host "+---------------------------------------------------------------+"

$services=Get-service $svc_name

foreach ($svc in $services)
{
  switch ($svc.Status)
  {
    "Running"  {
	              Stop-service $svc.DisplayName;
	              Get-service $svc.DisplayName;
			   }
    "Stopped"  {
	              Write-Host "$($svc.DisplayName) already stopped"
			   }
  }
  Start-service $svc.DisplayName
}
Get-service $svc_name


$date=Get-Date
Write-Host "+---------------------------------------------------------------+"
Write-Host "|   finished at $date                             |"
Write-Host "+---------------------------------------------------------------+"
Pause