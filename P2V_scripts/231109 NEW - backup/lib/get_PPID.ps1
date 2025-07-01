$p = $PID
$parent = (gwmi win32_process | ? ProcessId -eq  $p).ParentProcessId
"$parent calls $PID"
