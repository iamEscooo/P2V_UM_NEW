

$serverlist_all = import-csv "\\somvat202005\PPS_share\P2V_Script-setup(new)\central\config\P2V_server.csv"
$serverlist=$serverlist_all|out-gridview -title "select server(s) to contact" -outputmode multiple

foreach ($remote in $serverlist ) 
{
">> contacting   $($remote.servername) <<"
(Invoke-Command -ComputerName $remote.servername -FilePath //somvat202005/PPS_Share/P2V_scripts/check_user_sessions.ps1)
}
