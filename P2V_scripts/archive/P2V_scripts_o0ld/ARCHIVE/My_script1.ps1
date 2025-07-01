#-- My script

param(
	[string]$ips_server="https://ips-test.ww.omv.com",
	[string]$tenant="P2V_TRAINING"
    [string]$tenantUrl = "https://ips-test.ww.omv.com/P2V_TRAINING",
    [string]$workingDir = "\\somvat202005\PPS_Share\P2V_scripts\Userlists\PS-users\mgmt",
    [string]$adgroupfile="\\somvat202005\PPS_Share\P2V_scripts\Userlists\all_adgroups.csv",
    [string]$u_w_file="\\somvat202005\PPS_Share\P2V_scripts\Userlists\PS-users\mgmt\Myuserworkgroup.csv",    
    [bool]$analyzeOnly = $True
)

$workingDir="\\somvat202005\PPS_Share\P2V_scripts\Userlists\PS-users\mgmt"
