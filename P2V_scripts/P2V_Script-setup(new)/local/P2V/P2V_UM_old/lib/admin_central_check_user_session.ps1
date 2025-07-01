
$serverlist = @(
# "somvat502676.ww.omv.com",  # Admin
# "tsomvat502895.ww.omv.com", # golden image TEST
# "somvat502671.ww.omv.com",  # golden image PROD
"tsomvat423002.ww.omv.com", # CITRIX   DEV/TEST
"tsomvat423003.ww.omv.com", # CITRIX   DEV/TEST
"tsomvat423005.ww.omv.com", # CITRIX   DEV/TEST
"tsomvat423006.ww.omv.com" , # CITRIX   DEV/TEST
# "tsomvat502898.ww.omv.com", # IPS      DEV
# "tsomvat502899.ww.omv.com", # Reserves DEV
#"tsomvat502101.ww.omv.com", # IPS      TEST 
# "tsomvat502102.ww.omv.com", # IPS      TEST 
# "tsomvat502103.ww.omv.com", # Reserves TEST 
# "tsomvat502104.ww.omv.com", # IPS      UPDATE 
"tsomvat422010.ww.omv.com", # CITRIX   UPDATE
# "tsomvat502060.ww.omv.com", # IPS      UPDATE 
# "tsomvat502033.ww.omv.com", # Reserves UPDATE
"somvat422001.ww.omv.com",  # CITRIX   PROD
"somvat422003.ww.omv.com",  # CITRIX   PROD
"somvat422008.ww.omv.com",  # CITRIX   PROD
"somvat422009.ww.omv.com"#,   # CITRIX   PROD
# "somvat502672.ww.omv.com",  # IPS      PROD
# "somvat502673.ww.omv.com",  # IPS      PROD
# "somvat502674.ww.omv.com",  # Reserves PROD
#"somvat502675.ww.omv.com"     # IPS      PROD
)


cls

foreach ($remote in $serverlist ) 
{
write-host -foregroundcolor yellow ">> contacting   $remote <<"
Invoke-Command -ComputerName $remote -FilePath //somvat202005/PPS_Share/P2V_scripts/check_user_sessions.ps1

}

pause