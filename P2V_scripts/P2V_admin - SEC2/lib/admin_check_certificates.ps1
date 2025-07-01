

$root = Split-Path $PSScriptRoot -Parent -Parent -Parent
$serverlist_all = import-csv (Join-Path $root "P2V_Script-setup(new)\central\config\P2V_server.csv")
$serverlist=$serverlist_all|out-gridview -title "select server(s) to contact" -outputmode multiple
 foreach ($remote in $serverlist ) 
 {
   (Invoke-Command -ComputerName $remote.servername -ScriptBlock {
       Get-ChildItem -Path cert:\LocalMachine\My |format-table SerialNumber, Friendlyname,notbefore, notafter, Issuer, subject
	   	
#netsh http show sslcert ipport=0.0.0.0:443

#
#netsh http delete sslcert ipport=0.0.0.0:443

#netsh http add sslcert ipport=0.0.0.0:443 certhash=   appid="{4dc3e181-e14b-4a21-b022-59fc669b0914}"

}
	   )
	   
   write-output ""
}
write-output "`n--- check finished ---"
