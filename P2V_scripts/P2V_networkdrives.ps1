
Set-ExecutionPolicy  -ExecutionPolicy Unrestricted
$Share=@{}
 

$share["J"]="\\somvat202005\Plan2Value"
$share["S"]="\\somvat202005\PPS_share"
$share["T"]="\\somvat202005\PPS_cluster"


foreach ($drive in $share.keys) 
{ 
 if (Test-Path  $share[$drive]) {
    New-PSDrive -Name $drive -PSProvider FileSystem -Root $share[$drive] -Persist
} else {
    Write-error "$share[$drive] not reachable"
}
}
pause
