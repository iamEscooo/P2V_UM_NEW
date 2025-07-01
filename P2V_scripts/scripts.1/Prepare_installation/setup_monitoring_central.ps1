
$serverlist = @(
	"tsomvat423002.ww.omv.com",
	"tsomvat423003.ww.omv.com",
	"tsomvat423005.ww.omv.com",
	"tsomvat423006.ww.omv.com",
	"tsomvat422010.ww.omv.com",
	"somvat422001.ww.omv.com",
	"somvat422003.ww.omv.com",
	"somvat422008.ww.omv.com",
	"somvat422009.ww.omv.com",
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


foreach ($remote in $serverlist ) 
{
write-host -foregroundcolor yellow ">> contacting   $remote <<"
Invoke-Command -ComputerName $remote -FilePath //somvat202005/PPS_Share/P2V_scripts/setup_monitoring_local.ps1

}

pause