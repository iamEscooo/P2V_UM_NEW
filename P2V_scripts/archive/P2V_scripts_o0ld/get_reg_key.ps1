
$analyse_only="TRUE"

function com_registeredpath()
{  
    param([string]$guid)

    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

    $key = Get-Item "HKCR:\CLSID\$guid"
    $values = Get-ItemProperty $key.PSPath

    [string] $defaultValue = [string] $values."(default)"
    write-host ">>>: $defaultValue" # returns a value like: c:\somefolder\somefile.dll
    
		if (($cont=read-host ($form1 -f "Delete registry key $guid? (y/N)")) -like "y")	
	{
	  "deleting key"
	  "Remove-Item -Path HKCR:\CLSID\$guid -Recurse "
	  out-host

    }

    remove-psdrive -name HKCR
    return $defaultValue
}

$k_12= "{3BE786A0-0366-4F5C-9434-25CF162E475E}"
$k_15= "{3BE786A1-0366-4F5C-9434-25CF162E475E}"
$k_16= "{3BE786A2-0366-4F5C-9434-25CF162E475E}"



foreach ($k in ($k_12,$k_15,$k_16) )
{
write-host "~~~" (com_registeredpath "$k") #   returns a value like: HKCR c:\somefolder\somefile.dll
}