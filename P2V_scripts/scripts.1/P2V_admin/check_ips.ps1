
$status= @()

$ips_list=('tsomvat502898.ww.omv.com','tsomvat502101.ww.omv.com','tsomvat502102.ww.omv.com','tsomvat502104.ww.omv.com','tsomvat502060.ww.omv.com','somvat502672.ww.omv.com','somvat502673.ww.omv.com')

$ips_list |% {$U='http://'+$_+':81/servicemonitor';$sl= Invoke-WebRequest $U ;$sl|Add-Member -Name "URL" -Type NoteProperty -Value "$_";$status+=$sl}

$status|select URL,StatusCode, StatusDescription,Content|format-table


pause
