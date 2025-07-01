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

Export-ModuleMember -Variable @('workdir')
Export-ModuleMember -Function * -Alias *

if ($workdir -eq 'DIR_NOT_SET') {
    P2V_init -root $PSScriptRoot
}


