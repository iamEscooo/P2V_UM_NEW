#reg query "HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon" /v version
 

$serverlist_all = import-csv "\\somvat202005\PPS_share\P2V_Script-setup(new)\central\config\P2V_server.csv"
$serverlist=$serverlist_all|out-gridview -title "select server(s) to contact" -outputmode multiple
 foreach ($remote in $serverlist ) 
 {
#">> checking  $($remote.servername) <<"
   (Invoke-Command -ComputerName $remote.servername -ScriptBlock {
     $chrome=@(
       "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
       "C:\Program Files\Google\Chrome\Application\chrome.exe"  # ,
       "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
       "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
     );
     Foreach ($c in $chrome)
     {
       if (test-path $c)  
	   {
          (Get-Itemproperty $c).VersionInfo 
		  #|select FileDescription,Productversion,Fileversion,PScomputername|ft
       }
	 }
	}
   )
   write-output ""	
}
write-output "`n--- check finished ---"

