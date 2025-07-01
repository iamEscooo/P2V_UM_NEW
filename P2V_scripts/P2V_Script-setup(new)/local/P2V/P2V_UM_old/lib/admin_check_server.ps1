
# set remote-server

$citrixlist = @(
	"tsomvat423002.ww.omv.com",
	"tsomvat423003.ww.omv.com",
	"tsomvat423005.ww.omv.com",
	"tsomvat423006.ww.omv.com",
	"tsomvat422010.ww.omv.com",
	"somvat422001.ww.omv.com",
	"somvat422002.ww.omv.com",
	"somvat422008.ww.omv.com",
	"somvat422009.ww.omv.com"
)

$serverlist = @(
    "tsomvat502898.ww.omv.com",
	"tsomvat502899.ww.omv.com",
	"tsomvat502101.ww.omv.com",
	"tsomvat502102.ww.omv.com",
	"tsomvat502103.ww.omv.com",
	"tsomvat502104.ww.omv.com",
	"tsomvat502060.ww.omv.com",
	"tsomvat502033.ww.omv.com",
	"somvat502672.ww.omv.com",
	"somvat502673.ww.omv.com",
	"somvat502674.ww.omv.com",
	"somvat502675.ww.omv.com"
)

$User = "ww\s.at.p2vmonitoring"
$PWord = ConvertTo-SecureString -String 'hWna$?tJ7MC7T$' -AsPlainText -Force
#$User = "ww\adminx449222"
#$PWord = ConvertTo-SecureString -String 'C[xz\M:"4v-Fn?@&' -AsPlainText -Force
$cred= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

foreach ($remote in $serverlist ) 
{
# check service on remote server
write-host -foregroundcolor yellow ">> checking  $remote <<"
write-host -nonewline "Last Boot Time: "
(Get-CimInstance Win32_OperatingSystem -ComputerName $remote).LastBootupTime|write-host


write-host "check services"

Get-WmiObject -Credential $cred -Class Win32_Service -ComputerName $remote -Amended|where {$_.Name -like "Aucerna*" -or $_.Name -like "IPS*" -or $_.Name -like "*Service Bus*"}|format-table

write-host


}
pause