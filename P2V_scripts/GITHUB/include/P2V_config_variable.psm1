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






$user=$env:UserDomain+"/"+$env:UserName


$client=$env:ComputerName

