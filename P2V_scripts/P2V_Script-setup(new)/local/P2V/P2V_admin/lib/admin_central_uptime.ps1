
$serverlist_all = import-csv "\\somvat202005\PPS_share\P2V_scripts\config\P2V_server.csv"
$serverlist=$serverlist_all|out-gridview -title "select server(s) to contact" -outputmode multiple

foreach ($remote in $serverlist ) 
{
 $line=">>{0,-30} Last system boot at : {1,-25}"
# write-host -foregroundcolor yellow -nonewline ">> $remote :"
 $line -f $remote.servername,(Invoke-Command -ComputerName $remote.servername -ScriptBlock {(Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime})

}

