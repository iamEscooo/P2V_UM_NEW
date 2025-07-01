# CITRIX Symantec issue

# Please apply the following fix steps and let me know if this is fixing the issue: 
# 1.	Click Windows Start > Run and type and run the following: smc –stop
# 2.	Browse to the SEP installation path ...\Symantec Endpoint Protection\14.x\bin\ folder.
# 3.	Rename sqsvc.dll, sqscr.dll and symerr.exe files to: sqsvc.dll.old, sqscr.dll.old and symerr.exe.old
# 4.	Click Windows Start > Run and type and run the following: smc -start
# I have tested the above steps and it seems that the issue is not replicating anymore on MyOffice Test 
# BR Cristi A.


$sym_prog= "C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\smc.exe"
$sym_folder ="C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\14.3.558.0000.105\Bin\"
$sym_files=@("sqsvc.dll","sqscr.dll","symerr.exe")
Get-Service "Sep*"
"stopping SEP services"
& $sym_prog -stop
Get-Service "Sep*"

"renaming files"
FOREACH ($file_to_rename in $sym_files)
{
   $t_f = $sym_folder + $file_to_rename
   Write-host "checking   $t_f"

   if (Test-Path $t_f)  
   {
      $ren_name= $file_to_rename+".old"
	  $ext=0
      while (Test-Path "$sym_folder\$ren_name.$ext") { $ext++ }
     Write-host "rename   $file-to_rename -> $ren_name.$ext" 
	 Rename-Item -Path "$t_f" -NewName "$ren_name.$ext" -confirm
   }
   else
   { 
      Write-host "[ERROR]:  $sym_folder\$file_to_rename does not exist - exiting"
      "starting SEP services"
      & $sym_prog  -start
      Get-Service "Sep*"
      exit
   }
}


"starting SEP services"
& $sym_prog  -start
Get-Service "Sep*"
pause