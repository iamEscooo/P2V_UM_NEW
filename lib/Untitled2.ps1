$folder = Join-Path $PSScriptRoot "..\P2V_UM_data\output\P2V_export_AD_users"

$age=10

$now=Get-Date
$limit =($now).addminutes(-$age)

foreach($file in (get-childitem $folder))
{
write-host ">> $file <<"
write-host $now
write-host $limit
write-host ($now - $limit)

write-host $file.LastwriteTime 
write-host ($limit - $file.LastwriteTime)

#if ($limit-$file.LastwriteTime ).minut

pause
}

