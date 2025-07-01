

 $line=">>{0,-30} Last system boot on: {1,-25}"

$line -f $remote,(Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

