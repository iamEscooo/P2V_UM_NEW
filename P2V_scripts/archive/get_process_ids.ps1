$p = $PID
$parent = (gwmi win32_process | ? processid -eq  $p.Id).parentprocessid
"$parent calls $PID"