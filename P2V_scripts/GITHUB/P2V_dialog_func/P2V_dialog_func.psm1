#=================================================================
#  P2V_dialog_func.psm1
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
  name:   P2V_dialog_func.psm1
  ver:    1.0
  author: M.Kufner

#>
# central configurations
# layouts           
# test line --       |  load profile definitions \\somvat202005\PPS_share\P2V Script-setup(new)\central\config\P2V_profiles.csv [DONE]        |
#                    12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
#                   0         1         2         3         4         5         6         7         8         9        10        11        12        13        14 
#   130 characters per line

Function  P2V_dialog_func 
{
	<#
      .SYNOPSIS
	
      .DESCRIPTION
	    ask_continue opens a dialog box  yes/no

      .PARAMETER msg <question>
	         shows the question (= content of dialog box)
		   	
	  .PARAMETER title <title>
	         sets the title of the dialog box
	
      .EXAMPLE
	      ask_continue -title "Apply changes?" -msg "Apply changes to file xyz ?"

	  .NOTES
       name:   ask_continue 
       ver:    1.0
       author: M.Kufner
	   
	  .LINK

#>
	
    param (
        $msg= " P2V_dialog_func - <default msg>"
		    )
   write-output $msg
   write-output "-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-"
   
    return $true
	
}
$dialog_date= get-date	

Export-ModuleMember -Variable dialog_date
Export-ModuleMember -Function * -Alias *