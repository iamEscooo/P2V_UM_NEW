
quser

$PS_proc = Get-WmiObject Win32_Process |where {$_.Name -eq "PlanningSpace.exe" -or $_.Name -eq "PetroVR.exe"}|select CSName, User, ParentProcessId, ProcessId,Name, CommandLine


foreach ($Proc in $PS_proc )
{
  $Proc.User=( Get-process -id $Proc.ProcessId -Includeusername).Username

  # $proc|format-table
   
}

$PS_proc|Format-Table
