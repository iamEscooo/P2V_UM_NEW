
#===================================================
#==   global variables                            ==
#===================================================

# global variables
$global:output_path_base = "\\somvat202005\PPS_share\P2V_UM_data\output"
$global:dashboard_path   = $output_path_base + "\dashboard"
$global:log_path         = $output_path_base + "\logs"

$global:log_file 	     = $log_path +"\P2V_Usermgmt_Log" + $date + ".log"

createdir_ifnotexists ($output_path_base)
createdir_ifnotexists ($dashboard_path)
createdir_ifnotexists ($log_path)

$global:lib_path    = $workdir + "\lib"

# [OLD]> $global:config_path = "\\somvat202005\PPS_share\P2V_UM_data\conf"
$global:config_path = "\\somvat202005\PPS_share\P2V_Script-setup(new)\central\config"

$global:adgroupfile = $config_path + "\P2V_adgroups.csv"
$global:tenantfile  = $config_path + "\P2V_tenants.csv"
$global:profile_file= $config_path + "\P2V_profiles.csv"
$global:menu_file   = $config_path + "\P2V_menu.csv"
$global:data_groups = $config_path + "\data_groups.csv"		
$global:tag_conf    = $config_path + "\TAG_config.csv"			  
$global:bd_groups   = $config_path + "\P2V_BD.csv"		

$global:date = get-date -format "yyyy-MM-dd"

$global:spec_accounts = @("adminx449222@ww.omv.com",
						  "adminarun05",
						  "adminadrian75@ww.omv.com",
						  "useradmin",
						  "svc.ww.at.p2v_useradmin@ww.omv.com",
						  "Reserves_service"
						  )




#===================================================
#==   User/Workgroup functions                    ==
#===================================================

#----  load from PS

function GetUsersFromPS
function GetWorkgroupsFromPS


#----  Load from AD

function GetUsersFromAD
function GetWorkgroupsFromAD



#----  Load from CSV files

function GetUsersFromCsv
function GetWorkgroupsFromCsv




function SelectTenant
function SelectUser
function 

