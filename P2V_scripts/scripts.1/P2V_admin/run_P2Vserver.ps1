param (
 [string] $cmd =""
 )
Add-Type -AssemblyName System.Windows.Forms

$initialDirectory="//somvat202005/PPS_Share/P2V_scripts/P2V_admin"

if (!$cmd -or !(test-path($cmd)))
{
   $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory =$initialDirectory }
   $OpenFileDialog.ShowDialog() | Out-Null
  
   $cmd = $OpenFileDialog.filename
}

$serverlist_all = import-csv "\\somvat202005\PPS_share\P2V_Script-setup(new)\central\config\P2V_server.csv"

#$sb = ScriptBlock::Create("$cmd")
cls
write-host "running script [$cmd] on"

$serverlist=$serverlist_all|out-gridview -title "select server(s) to contact" -outputmode multiple
foreach ($remote in $serverlist ) 
{
write-host -foregroundcolor yellow "-- contacting $($remote.servername)  / $($remote.description) --"
Invoke-Command -ComputerName $remote.servername -filepath  $cmd

}
write-host -foregroundcolor yellow " -- finished --"
