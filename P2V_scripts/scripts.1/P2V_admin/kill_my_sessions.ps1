#requires -RunAsAdministrator
$date = Get-Date -Format d.MMMM.yyyy
$time = get-date -Format HH:mm:ss
$servers =import-csv "conf\serverlist.csv"
$logfile=".\disconnect_admin.log"
$username="adminx449222" #to exclude Gridview
#log out user

 

$serverlist_all = import-csv "\\somvat202005\PPS_share\P2V_Scripts\config\P2V_server.csv"




$serverlist=$serverlist_all|out-gridview -title "select server(s) to contact" -outputmode multiple
foreach ($s in $serverlist ) 
{

$server=$s.servername

if ($server -ne $env:computername)
{
Write-Host "Currently logging off $username from server: $server"
#Write-Host "Currently logging off from server: $server "#to exclude Gridview

quser $username /server:$server  | Select-Object -Skip 1 |
     #Out-GridView -Title "Select User Profile" -OutputMode Single |#to exclude Gridview
    ForEach-Object { 
$Session = ($_ -split ‘ +’)[2]
$user = ($_ -split ‘ +’)[1]
$idletime= ($_ -split ‘ +’)[4]
logoff $Session /server:$server
Write-output “You are about to log off $user with session id $Session who is idle for $idletime at $date $time from $server” | Add-Content $logfile
#to exclude Gridview Write-output “You are about to log off $user with session id $Session who is idle for $idletime at $date $time from $server” | Add-Content $logfile
}
}

 

  } 
write-host "done"  
pause