
<# $new_reg_key= @(
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\processes\",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\processes",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths\\somvat202005\PPS_cluster\IPS20_TEST",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths",
	"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths"

	)
 #>
	
	$reg_path="HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths"
	$entry = "\\\\somvat202005\\PPS_cluster\\IPS20_UPDATE"
	$value = "0"
	
	 Get-ItemProperty -path $reg_path
	 
#	 registryPath

	$registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\paths\'
 #   $Name = "\\somvat202005\PPS_cluster\IPS20_PROD"
	$Name = "\\somvat202005\PPS_cluster\IPS20_TEST"    
#	$Name = "\\somvat202005\PPS_cluster\IPS20_UPDATE"

 
#    name
    $registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\exclusions\processes\'
	$Name="Palantir.IPS.ApplicationHost.exe"
#	$Name="Palantir.IPS.ApplicationHost.WCF.exe"
#	$Name="Palantir.IPS.RequestProcessorHost.exe"
#	$Name="Palantir.IPS.Server.exe"

#    $Name = "Version"
     $value = "0"

IF(!(Test-Path $registryPath))
{
    New-Item -Path $registryPath -Force | Out-Null
	
}

if ((Get-Item -Path $registryPath).GetValue($name) -ne $null)
{
	Set-ItemProperty -Path $registryPath -Name $name -Value $value -Force| Out-Null
}
ELSE
{
	New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null
}
	
Get-Item -path $registryPath