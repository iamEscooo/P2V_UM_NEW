#=================================================================
#  P2V_config_variable.psm1
#=================================================================

<#
.SYNOPSIS
	include file to configure main variables for P2V Usermanagement
.DESCRIPTION
	defines all "global variables" to be used in P2V Usermanagement
	e.g. directories, configfiles, outputpath, special users, 
	

.PARAMETER menufile <filename>
	
	
.PARAMETER xamldir <directory>
	
	
.PARAMETER fcolor  <colorcode>
	foregroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.PARAMETER bcolor  <colorcode>
	backgroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  name:   P2V_config_variable.psm1
  ver:    1.0
  author: M.Kufner

#>
#=================================================================
# Variables
#=================================================================

$linesep    ="+---------------------------------------------------------------------------------------------------------------------------------+"

$form1      ="|  {0,-125}  |"
$form1_nnl  ="|  {0,-125}  |`r"
$form_debug ="|D {0,-125}  |D"

$form2      ="|  {0,-20} {1,-104}  |"
$form2_1    ="|  {0,-62} {1,62}  |"
$form2_2    ="|  {0,-62} {1,-62}  |"
$form_status="|  {0,-104} {1,-20}  |"
$form_err   ="**>{0,-20} {1,-104}<**"

$form3      ="|  {0,-20} {1,-84} {2,-20} |"
$form3_2    ="|  {0,-41} {1,-41} {2,-42} |"
$form_user  ="|  {0,-10} {1,-57} {2,-57} |"
$form_user1 ="|  {0, 10} {1,-94} {2,-20} |"

$form4      ="|  {0,-20} {1,-34} {2,-34} {3,-34}  |"
$form_chlogs="|  {0,-8} {1,-27} {2,-30} {3,-30} {4,-30}" 
$form_logs=  "|  {0,-8} {1,-40} {2,-40} {3,-40} {4,-40}|" 
$form_wg_r  ="|  {0,5}/{1,-30} {2,-5} {3,-5} {4,-5} {5,5}/{6,-44} " 

$emptyline  =($form1 -f "")

$user=$env:UserDomain+"/"+$env:UserName
$client=$env:ComputerName

#---
$workdir="DIR_NOT_SET"

$filedate = get-date -format "yyyy-MM-dd"   # used for log-filename
$output_path_base = "\\somvat202005\PPS_share\P2V_UM_data\output"
$dashboard_path   = $output_path_base + "\dashboard"
$log_path         = $output_path_base + "\logs"
$logfile 	      = $log_path +("\P2V_Usermgmt_Log" + $filedate + ".log")

$config_path = "\\somvat202005\PPS_share\P2V_Script-setup(new)\central\config"

$adgroupfile     = $config_path + "\P2V_adgroups.csv"
$tenantfile      = $config_path + "\P2V_tenants.csv"
$profile_file    = $config_path + "\P2V_profiles.csv"
$menu_file       = $config_path + "\P2V_menu.csv"
$data_groups     = $config_path + "\data_groups.csv"		
$tag_conf        = $config_path + "\TAG_config.csv"			  
$bd_assign_file  = $config_path + "\P2V_BD.csv"		
$bd_project_file = $config_path + "\P2V_BD_projects.csv"		

$libdir    = $workdir + "\lib"


$spec_accounts = @("adminx449222@ww.omv.com",
                   "ARUN05@ww.omv.com",
                   "demo01",
                   "demo02",
                   "demo03",
                   "demo04",
                   "demo05",
                   "demo06",
                   "demo07",
                   "demo08",
                   "demo09",
                   "demo10",
                   "demo11",
                   "demo14",
                   "demo17",
                   "demo18",
                   "demo20",
                   "demo21",
                   "demo22",
                   "demo30",
                   "demo31",
                   "demo32",
                   "demo33",
                   "demo34",
                   "demo35",
                   "demo36",
                   "demo40",
                   "demo41",
                   "demo42",
                   "demo43",
                   "demo44",
                   "demo45",
                   "demo46",
                   "demo47",
                   "demo50",
                   "demo51",
                   "demo52",
                   "demo53",
                   "demo55",
                   "demo60",
                   "demo61",
                   "demo62",
                   "demo63",
                   "demo64",
                   "demo66",
                   "demo68",
                   "demo69",
                   "demo72",
                   "PBI.corporate",
                   "PBI.corporate.BD",
                   "Reporting",
                   "Reserves_service",
                   "s.at.p2vpbi1",
                   "s.at.p2vpbi10",
                   "s.at.p2vpbi11",
                   "s.at.p2vpbi12",
                   "s.at.p2vpbi13",
                   "s.at.p2vpbi14",
                   "s.at.p2vpbi15",
                   "s.at.p2vpbi2",
                   "s.at.p2vpbi3",
                   "s.at.p2vpbi4",
                   "s.at.p2vpbi5",
                   "s.at.p2vpbi6",
                   "s.at.p2vpbi7",
                   "s.at.p2vpbi8",
                   "s.at.p2vpbi9",
                   "s.ro.checkmw@petrom.com",
                   "svc.ww.at.p2v_useradmin@ww.omv.com",
                   "svc.ww.ro.testagent1@petrom.com",
                   "svc.ww.ro.testagent2@petrom.com",
                   "svc.ww.ro.testagent3@petrom.com",
                   "svc.ww.ro.testagent4@petrom.com",
                   "svc.ww.ro.testagent5@petrom.com"
                  )


#=================================================================
# Functions
#=================================================================

Function P2V_init
{ 
  param (
    [string]  $root=$PSscriptroot
	)
	
	$script:workdir="$root"
	$script:libdir = $workdir + "\lib"
}

#=================================================================
# Exports
#=================================================================
Export-ModuleMember -Variable @('linesep','user','client')
Export-ModuleMember -Variable @('form1','form1_nnl','form_debug','form2','form2_1','form2_2','form_status','form_err','form3','form3_2','form_user','form_user1','form4','form_chlogs')

Export-ModuleMember -Variable @('date','output_path_base','dashboard_path','log_path','logfile','config_path','adgroupfile','tenantfile','profile_file','menu_file','data_groups','tag_conf','bd_project_file','bd_assign_file','libdir')

Export-ModuleMember -Variable @('workdir','spec_accounts')
Export-ModuleMember -Function * -Alias *

if ($workdir -eq 'DIR_NOT_SET') {
    P2V_init -root $PSScriptRoot
}


