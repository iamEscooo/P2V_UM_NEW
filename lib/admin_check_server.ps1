
# set remote-server

$serverlist_all = import-csv (Join-Path $PSScriptRoot "..\P2V_scripts\config\P2V_server.csv")
$serverlist=$serverlist_all|out-gridview -title "select server(s) to contact" -outputmode multiple

$User = "ww\s.at.p2vmonitoring"
$PWord = ConvertTo-SecureString -String 'hWna$?tJ7MC7T$' -AsPlainText -Force
#$User = "ww\adminx449222"
#$PWord = ConvertTo-SecureString -String 'C[xz\M:"4v-Fn?@&' -AsPlainText -Force
$cred= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

foreach ($remote in $serverlist ) 
{
# check service on remote server
">> checking  $($remote.servername) <<"
$line=">>{0,-30} Last system boot at : {1,-25}"
# write-host -foregroundcolor yellow -nonewline ">> $remote :"
 $line -f $remote.servername,(Invoke-Command -ComputerName $remote.servername -ScriptBlock {(Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime})

"check services"

Get-WmiObject -Credential $cred -Class Win32_Service -ComputerName $remote.servername -Amended|where {$_.Name -like "Aucerna*" -or $_.Name -like "IPS*" -or $_.Name -like "*Service Bus*"}|format-table



}
