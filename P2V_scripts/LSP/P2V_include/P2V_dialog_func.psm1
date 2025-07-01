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


#---------------------------------------------------
Function  ask_continue 
{
	<#
      .SYNOPSIS
	
      .DESCRIPTION
	    ask_continue opens a dialog box 

      .PARAMETER msg <question>
	         shows the question (= content of dialog box)
		 		   	
	  .PARAMETER title <title>
	         sets the title of the dialog box
	
	  .PARAMETER button <num>
	       defines buttons whereas
		   	0  OK
			1  OK, Cancel
			2  Abort, Retry, Ignore
			3  Yes, No, Cancel
			4  Yes, No
			5  Retry, Cancel
	  
      .EXAMPLE
	      ask_continue -title "Apply changes?" -msg "Apply changes to file xyz ?" -button 4

	  .NOTES
       name:   ask_continue 
       ver:    1.0
       author: M.Kufner
	   
	  .LINK

#>
	
    param (
        $msg= "-- Question? --",
		$title= "Question",
		$button=4
    )

	$Result = [System.Windows.Forms.MessageBox]::Show($msg,$title,$button)

    #write-host -ForegroundColor Green $result
    return $result
}

#---------------------------------------------------
Function  ask_YesNoAll
{
	<#
      .SYNOPSIS
	
      .DESCRIPTION
	    ask_YesNoAll opens a dialog box  yes/no/all

      .PARAMETER msg <question>
	         shows the question (= content of dialog box)
		   	
	  .PARAMETER title <title>
	         sets the title of the dialog box
	

      .EXAMPLE
	      ask_YesNoAll -title "Apply changes?" -msg "Apply changes to file xyz ?"
		  

	  .NOTES
       name:   ask_YesNoAll 
       ver:    1.0
       author: M.Kufner
	   
	  .LINK

#>
    param (
        $msg= "-- Question? --",
		$title= "Question"
    )
	$workdir|out-host
    $Allbox = New-Object system.Windows.Forms.Form
	$Allbox.ClientSize = '400,200'
$Allbox.text = $title
$Allbox.Font = 'Microsoft Sans Serif,8.25pt'
$Allbox.Icon="$workdir\P2V.ico"
$Allbox.Formborderstyle = "FixedDialog"
$Allbox.Acceptbutton = $u_search_button
$Allbox.Cancelbutton = $cancelbutton
	
$background= New-Object system.Windows.Forms.PictureBox
$background.width = 400	
$background.height = 145
$background.location = New-Object System.Drawing.Point(0,0)
$background.backcolor = "white"
$background.Anchor= "Top, Bottom, Left, Right"

$msg_field = New-Object system.Windows.Forms.TextBox
$msg_field.multiline = $true
$msg_field.ReadOnly = $True
$msg_field.width = 370
$msg_field.height = 115
$msg_field.location = New-Object System.Drawing.Point(15,15)
$msg_field.Font = 'Microsoft Sans Serif,8.25pt'
$msg_field.Backcolor = "white"
$msg_field.BorderStyle = "None" 
$msg_field.TextAlign="center"
$msg_field.Scrollbars = "none" 
$msg_field.Anchor= "Top, Bottom, Left, Right"
$msg_field.margin= "20,20,20,20"
$msg_field.text= $msg
$msg_field.bringtofront()

$yes_button = New-Object system.Windows.Forms.Button
$yes_button.text = "Yes"
$yes_button.width = 80
$yes_button.height = 25
$yes_button.location = New-Object System.Drawing.Point(15,160)
$yes_button.Font = 'Microsoft Sans Serif,8.25pt'
$yes_button.DialogResult = [System.Windows.Forms.DialogResult]::YES
$yes_button.Add_Click({
    $result= $yes_button.text    
   $allbox.Close()
})


$no_button = New-Object system.Windows.Forms.Button
$no_button.text = "No"
$no_button.width = 80
$no_button.height = 25
$no_button.location = New-Object System.Drawing.Point(110,160)
$no_button.Font = 'Microsoft Sans Serif,8.25pt'
$no_button.DialogResult = [System.Windows.Forms.DialogResult]::NO
$no_button.Add_Click({
    $result= $no_button.text    
   $allbox.Close()
})

$yesall_button = New-Object system.Windows.Forms.Button
$yesall_button.text = "Yes to All"
$yesall_button.width = 80
$yesall_button.height = 25
$yesall_button.location = New-Object System.Drawing.Point(205,160)
$yesall_button.Font = 'Microsoft Sans Serif,8.25pt'
$yesall_button.DialogResult =  [System.Windows.Forms.DialogResult]::OK
$yesall_button.Add_Click({
   #$result= $yesall_button.text   
   $result= "YesAll"
   $allbox.Close()
})

$noall_button = New-Object system.Windows.Forms.Button
$noall_button.text = "No to All"
$noall_button.width = 80
$noall_button.height = 25
$noall_button.location = New-Object System.Drawing.Point(300,160)
$noall_button.Font = 'Microsoft Sans Serif,8.25pt'
$noall_button.DialogResult =  [System.Windows.Forms.DialogResult]::ABORT
$noall_button.Add_Click({
   #$result= $noall_button.text  
   $result= "NoAll"
   $allbox.Close()
})
	
$allbox.controls.AddRange(@($background,$yes_button,$no_button,$yesall_button,$noall_button,$msg_field))
$msg_field.bringtofront()
$allbox.showdialog()
	

    #write-verbose -ForegroundColor Green $result
    return $result
}

#---------------------------------------------------
$dialog_date= get-date	

Export-ModuleMember -Variable dialog_date
Export-ModuleMember -Function * -Alias *