$user=$env:UserDomain+"/"+$env:UserName
$client=$env:ComputerName

$targetgroup0 = @("ctx.omv.com","somvae501603.ww.omv.com","SOMVNZ001602.ww.omv.com")
$targetgroup1 = @("ctx.omv.com","tsomvat423002.ww.omv.com","tsomvat502101.ww.omv.com","tsomvat502102.ww.omv.com","tsomvat502103.ww.omv.com","SOMVAT702569.ww.omv.com")
$output="xy.dat"
$global:linesep    ="+-------------------------------------------------------------------------------+"
$global:form1      ="|  {0,-75}  |"
$linesep|tee-object -filepath $output
$form1 -f "started by [$user] on [$client]"|tee-object -append -filepath $output
get-date -format "[dd/MM/yyyy HH:mm:ss]"|tee-object -append -filepath $output
$linesep|tee-object -append -filepath $output
$form1 -f "local environment: Get-Item -Path Env:*"|tee-object -append -filepath $output
Get-Item -Path Env:*|tee-object -append -filepath $output
$linesep|tee-object -append -filepath $output

foreach ($destination in $targetgroup0)
{
      $form1 -f "checking connection to $destination"|tee-object -append -filepath $output
	  $linesep|tee-object -append -filepath $output
      ping -a -i 40 -w 500 -4 -n 10 $destination |tee-object -append -filepath $output
      $linesep|tee-object -append -filepath $output
	  tracert -w 500 -4 -h 50	$destination |tee-object -append -filepath $output
	  $linesep|tee-object -append -filepath $output
}

notepad $output
