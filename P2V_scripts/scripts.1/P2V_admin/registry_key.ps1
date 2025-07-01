# check registry key

Write-host  "checking MS-Office installations:"
Write-host  "Access Database Engine"
$rkeys= @(
  "Registry::HKEY_CLASSES_ROOT\CLSID\{3BE786A0-0366-4F5C-9434-25CF162E475E}",
  "Registry::HKEY_CLASSES_ROOT\CLSID\{3BE786A1-0366-4F5C-9434-25CF162E475E}",
  "Registry::HKEY_CLASSES_ROOT\CLSID\{3BE786A2-0366-4F5C-9434-25CF162E475E}"
  )
$del_rkeys= @(
  "Registry::HKEY_CLASSES_ROOT\CLSID\{3BE786A0-0366-4F5C-9434-25CF162E475E}",
  "Registry::HKEY_CLASSES_ROOT\CLSID\{3BE786A2-0366-4F5C-9434-25CF162E475E}"
  )


foreach( $rk in $rkeys)
{
  Write-host  "`nchecking:  $rk"|out-host
  if (test-path -path $rk)
  {
#     $result=Get-ItemProperty -Path $rk -name *
#  $result 
#  pause
	 $result=Get-Item -Path $rk 
  $result 
#  pause

	if ($result)
	 
	 { 
	   $result|out-host
	   if ($del_rkeys.contains($rk))
	   {
	      if (($cont=read-host "delete key ?(y/n)") -like "y")	
		  {
		     "deleting $rk"
			 Remove-Item -Path $rk  -Recurse
		   }
	   }
	 }
	 
  }else
  { Write-host  "$rk does not exist"|out-host }

}



pause