

$serverlist_all = import-csv (Join-Path $PSScriptRoot "..\P2V_scripts\config\P2V_server.csv")
$serverlist=$serverlist_all|out-gridview -title "select server(s) to contact" -outputmode multiple

foreach ($remote in $serverlist ) 
{
">> contacting   $($remote.servername) <<"
(Invoke-Command -ComputerName $remote.servername -FilePath (Join-Path $PSScriptRoot "..\P2V_scripts\check_user_sessions.ps1"))
}
