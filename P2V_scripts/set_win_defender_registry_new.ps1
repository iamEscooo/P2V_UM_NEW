
<# $new_reg_key= @(
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\processes\",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\processes",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths\\somvat202005\PPS_cluster\IPS20_TEST",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths"

	)
 #>
	

	$value = "0"
	
#	 registryPath

	$registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths\'
	

    $Name = "\\somvat202005\PPS_cluster\IPS20_PROD"
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null
    $Name = "\\somvat202005\PPS_cluster\IPS20_TEST"    
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null
 	$Name = "\\somvat202005\PPS_cluster\IPS20_UPDATE"
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

Get-Item -path $registryPath
#   processes
    $registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\processes\'


	$Name="Palantir.IPS.ApplicationHost.exe"
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

	$Name="Palantir.IPS.ApplicationHost.WCF.exe"
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

	$Name="Palantir.IPS.RequestProcessorHost.exe"
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

	$Name="Palantir.IPS.Server.exe"
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

Get-Item -path $registryPath
