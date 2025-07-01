# GetSMBOpenFiles.ps1
# 
#  by  Gabriel Vasilica
#  gabriel.vasilica@external.petrom.com
#
#  minor adaption by martin.kufner@omv.com
#
#------------------
$max_sec=1000
$client=$env:ComputerName
$startd=get-date -format "yyyyMMdd-HHmmss_"
$output="\\somvat202005\PPS_share\P2V_scripts\error\$($startd)_$($client)_P2Vsmb.csv"

$SmbOpenFiles = New-Object System.Data.DataTable("DataArray")
$SmbOpenFilescol = "Iteration", "Timestamp", "Path", "ShareRelativePath", "ClientComputerName", "ClientUserName","ContinuouslyAvailable","Locks"
foreach ($col in $SmbOpenFilescol) 
{    
    $SmbOpenFiles.Columns.Add($col) | Out-Null    
}
$i = 1
write-output "data collection started on $client"
write-output "press 'q' to stop "
while ($i -le $max_sec)                 
{    
    $smb = Get-SmbOpenFile -IncludeHidden 
	$ts = get-date    
	foreach ($line in $smb) 
	{        
			$row = $SmbOpenFiles.NewRow()
			$row["Iteration"] = $i
			$row["Timestamp"] = $ts
			$row["Path"] = "$($line.Path)"
			$row["ShareRelativePath"] = "$($line.ShareRelativePath)"
			$row["ShareRelativePath"] = "$($line.ShareRelativePath)"
			$row["ClientComputerName"] = "$($line.ClientComputerName)"
			$row["ClientUserName"] = "$($line.ClientUserName)"
			$row["ContinuouslyAvailable"] = "$($line.ContinuouslyAvailable)"
			$row["Locks"] = "$($line.Locks)"
			
			$SmbOpenFiles.Rows.Add($row) | Out-Null
	}
    $i++    
	start-sleep 1
	if($Host.UI.RawUI.KeyAvailable -and ("q" -eq $Host.UI.RawUI.ReadKey("IncludeKeyup,NoEcho").Character))
	{ 
	  break; 
	}
	
}
$SmbOpenFiles | Export-Csv "$($output)" -NoClobber -NoTypeInformation

write-output "data saved to $output"
write-output "--- end ---"

