
param(
  [string] $xkey      = "x449222"
  )

Function Show-ProcessTree
{
    Function Get-ProcessChildren($P,$Depth=1)
    {
        $procs | Where-Object {$_.ParentProcessId -eq $p.ProcessID -and $_.ParentProcessId -ne 0} | ForEach-Object {
            
            $user=( Get-process -id $_.ProcessId -Includeusername).Username
            if ($user -like "*$xkey*"){"pid={0,5} ppid={1,5} sessionID={2,4} user={3,-30} {4}|--{5} :{6}" -f $_.ProcessID,$_.ParentProcessId,$_.SessionID,$user,(" "*3*$Depth),$_.Name,$_.CommandLine}
            Get-ProcessChildren $_ (++$Depth)
            $Depth--
        }
    }

    $filter = {-not (Get-Process -Id $_.ParentProcessId -ErrorAction SilentlyContinue) -or $_.ParentProcessId -eq 0}
    $procs = Get-WmiObject Win32_Process
    $top = $procs | Where-Object $filter | Sort-Object ProcessID
    foreach ($p in $top)
    {
        #"{0} pid={1}" -f $p.Name, $p.ProcessID
        $m_user=( Get-process -id $p.ProcessId -Includeusername).Username
        if ($m_user -like "*$xkey*"){"pid={0,5} ppid={1,5} sessionID={2,4} user={3,-30} {4} :{5}" -f  $p.ProcessID,$p.ParentProcessId,$p.SessionID,$m_user,$p.Name,,$p.CommandLine}
        Get-ProcessChildren $p
    }
}

Show-ProcessTree