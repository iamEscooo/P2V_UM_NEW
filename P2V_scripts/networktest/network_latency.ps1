$user=$env:UserDomain+"/"+$env:UserName
$client=$env:ComputerName

#$targetgroup = @("ctx.omv.com")
#$targetgroup = @("SOMVNZ001602.ww.omv.com","somvae501603.ww.omv.com","ctx.omv.com","tsomvat423002.ww.omv.com","tsomvat502101.ww.omv.com","tsomvat502102.ww.omv.com","tsomvat502103.ww.omv.com","SOMVAT702569.ww.omv.com")
$targetgroup = @("ctx.omv.com","somvat422034.ww.omv.com","somvat422035.ww.omv.com","somvat422036.ww.omv.com","somvat422037.ww.omv.com","somvat422038.ww.omv.com","somvat422039.ww.omv.com","tsomvat423002.ww.omv.com","somvat502672.ww.omv.com","tsomvat502101.ww.omv.com","somvat502674.ww.omv.com","somvat502603.ww.omv.com","somvat502614.ww.omv.com")
$date=(get-date -format "yyyy-MM-dd_HHmmss")
$check_path="\\SOMVAT202005\PPS_share\P2V_scripts\networktest\results"
$output_REMOTE = "$check_path\$($client)_$($date).txt"
$temp_log=($env:Temp + "\networktestlog"+"\P2V_Usermgmt_Log" + $filedate + ".log")
$output = "$temp_log\$($client)_$($date).txt"
If(!(test-path $check_path)){ $res=New-Item -ItemType Directory -Force -Path $check_path }
If(!(test-path $temp_log)){ $res=New-Item -ItemType Directory -Force -Path $temp_log }

$global:linesep    ="+-------------------------------------------------------------------------------+"
$global:form1      ="|  {0,-75}  |"

$date=get-date -format "[dd/MM/yyyy HH:mm:ss]"
$linesep                                               |tee-object -filepath $output
$form1 -f "started by [$user] on [$client]    [$date]" |tee-object -append -filepath $output
$linesep                                               |tee-object -append -filepath $output
$form1 -f "storing information in "                    |tee-object -append -filepath $output
$form1 -f "$output"                                    |tee-object -append -filepath $output
$form1 -f "local environment: Get-Item -Path Env:*"    |tee-object -append -filepath $output
Get-Item -Path Env:*                                   |tee-object -append -filepath $output
$linesep                                               |tee-object -append -filepath $output
$form1 -f " Network configuration"                     |tee-object -append -filepath $output
$linesep                                               |tee-object -append -filepath $output
$form1 -f "Get-NetIPConfiguration"                     |tee-object -append -filepath $output
Get-NetIPConfiguration                                 |tee-object -append -filepath $output
$form1 -f "Get-NetIPAddress"                           |tee-object -append -filepath $output
Get-NetIPAddress                                       |tee-object -append -filepath $output
$form1 -f "Get-NetAdapter"                             |tee-object -append -filepath $output
Get-NetAdapter                                         |tee-object -append -filepath $output
$linesep                                               |tee-object -append -filepath $output
$form1 -f " Connectivity "                             |tee-object -append -filepath $output
$linesep                                               |tee-object -append -filepath $output

foreach ($destination in $targetgroup)
{
      $form1 -f "checking connection to $destination"  |tee-object -append -filepath $output
	  $linesep                                         |tee-object -append -filepath $output
      ping -a -i 40 -w 500 -4 -n 10 $destination       |tee-object -append -filepath $output
      $linesep                                         |tee-object -append -filepath $output
	  tracert -w 500 -4 -h 50	$destination           |tee-object -append -filepath $output
	  $linesep                                         |tee-object -append -filepath $output
}
get-date -format "[dd/MM/yyyy HH:mm:ss]"               |tee-object -append -filepath $output

Copy-Item $output -Destination $check_path

notepad $output



