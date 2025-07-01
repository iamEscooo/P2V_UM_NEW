#=================================================================
#  P2V_base_func.psm1
#=================================================================

<#
.SYNOPSIS
	different dialog forms for P2V Usermgmt
.DESCRIPTION
	

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
  name:   P2V_base_func.psm1
  ver:    1.0
  author: M.Kufner

#>


Function P2V_header()
{ # show header
	param (
	[string]$app="--script name--",
    [string]$path="--working directory--",
	[string]$description=""
	)
	
	$linesep 
    $form1 -f "           \  \  \     ____  _             ______     __    _       V 1.1    /  /  / "
    $form1 -f "            \  \  \   |  _ \| | __ _ _ __ |___ \ \   / /_ _| |_   _  ___    /  /  /  "
    $form1 -f "             \  \  \  | |_) | |/ _' | '_ \  __) \ \ / / _' | | | | |/ _ \  /  /  /   "
    $form1 -f "             /  /  /  |  __/| | (_| | | | |/ __/ \ V / (_| | | |_| |  __/  \  \  \   "
    $form1 -f "            /  /  /   |_|   |_|\__,_|_| |_|_____| \_/ \__,_|_|\__,_|\___|   \  \  \  "
    $form1 -f "           /  /  /                                                           \  \  \ "
    $linesep 
    # $form2_1 -f "[$app]",(get-date -format "dd/MM/yyyy HH:mm:ss")  |out-host
    # $form2_1 -f "[$path]","[$user]"|out-host
	$global:startdate = get-date -format "dd/MM/yyyy HH:mm:ss"
	$form2_1 -f "[$app]","[$path]"
	$form2_1 -f "[$user] on [$client]","[$startdate]" 
	
	write-log "[$user] on [$client] started [$app]"
	$linesep
	if ($description)
	{
	  $description -split "`n"| % {$form1 -f $_}
	  $linesep
	}
	
}

Function P2V_footer()
{ # show footer
    param (
	[string]$app="--end of script--",
    [string]$path=""
	)
   #$linesep
   $global:enddate = get-date -format "dd/MM/yyyy HH:mm:ss"
   $form2_1 -f "[$app]", "$path"  
   $form2_1 -f "[$startdate]", "[$enddate]"
   $form1   -f "logs can found in $log_file"
   $linesep
} # end of P2V_footer
