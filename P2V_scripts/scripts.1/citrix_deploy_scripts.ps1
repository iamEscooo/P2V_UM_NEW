
$serverlist = @(
	"tsomvat423002.ww.omv.com",
	"tsomvat423003.ww.omv.com",
	"tsomvat423005.ww.omv.com",
	"tsomvat423006.ww.omv.com" #,
	# "tsomvat422010.ww.omv.com",
	# "somvat422001.ww.omv.com",
	# "somvat422003.ww.omv.com",
	# "somvat422008.ww.omv.com",
	# "somvat422009.ww.omv.com" #,
    # "tsomvat502898.ww.omv.com",
	# "tsomvat502899.ww.omv.com",
	# "tsomvat502101.ww.omv.com",
	# "tsomvat502102.ww.omv.com",
	# "tsomvat502103.ww.omv.com",
	# "tsomvat502104.ww.omv.com",
	# "tsomvat502060.ww.omv.com",
	# "tsomvat502033.ww.omv.com",
	# "somvat502672.ww.omv.com",
	# "somvat502673.ww.omv.com",
	# "somvat502674.ww.omv.com",
	# "somvat502675.ww.omv.com"
)


foreach ($remote in $serverlist ) 
{
write-host -foregroundcolor yellow ">> contacting   $remote <<"
invoke-Command -ComputerName $remote -FilePath \\somvat202005\PPS_Share\P2V_scripts\deploy_scripts.ps1

#$Session = New-PSSession -ComputerName $remote 
#Copy-Item "\\somvat202005\PPS_share\P2V_scripts\P2V_UM\"    -Destination "C:\P2V_UM\" -ToSession $Session  -exclude ".git" -Recurse -force
#Copy-Item "\\somvat202005\PPS_share\P2V_scripts\P2V_start\" -Destination "C:\P2V_start\" -ToSession $Session  -exclude ".git" -Recurse -force

}

pause