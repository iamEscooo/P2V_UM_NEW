#=======================
#  P2V_forms.ps1
#=======================
<#
.SYNOPSIS
	P2V_menu displays a menu based on an CSV configuration file
.DESCRIPTION
	P2V_menu displays a menu based on an CSV configuration file.
	Based on the great menu script from 
	Based on: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
	just added an "EXIT" option

.PARAMETER menufile <filename>
	CSV file 
	
.PARAMETER xamldir <directory>
	CSV file 
	
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
  name:   check_userprofile.ps1 
  ver:    1.0
  author: M.Kufner

#>

Function  ask_continue 
{
    param (
        $msg= "-- Question? --",
		$title= "Question"
    )
	$Result = [System.Windows.Forms.MessageBox]::Show($msg,$title,4)

    #write-host -ForegroundColor Green $result
    return $result
}

Function  ask_YesNoAll_alternative
{
    param (
        $msg= "-- Question? --",
		$title= "Question"
    )
    $rc=""
    $yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Yes";
    $no = new-Object System.Management.Automation.Host.ChoiceDescription "&No","No";
	$yesall = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes to All","Yes to All";
	$noall = new-Object System.Management.Automation.Host.ChoiceDescription "&No to All","No to All";
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no,$yesall,$noall);
    $answer = $host.ui.PromptForChoice($title,$msg,$choices,0)
     switch ($answer){
        0 {"You selected YES"; $rc="Yes";break}
        1 {"You entered NO"; $rc="No"; break}
		2 {"You selected YES TO ALL"; $rc="YesAll";break}
        3 {"You entered NO TO ALL"; $rc="NoAll"; break}
      }
     return $rc
}

Function  ask_YesNoAll
{
    param (
        $msg= "-- Question? --",
		$title= "Question"
    )
    $Allbox = New-Object system.Windows.Forms.Form
	$Allbox.ClientSize = '400,200'
$Allbox.text = $title
$Allbox.Font = 'Microsoft Sans Serif,8.25pt'
$Allbox.Icon="$workdir/P2V.ico"
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
 
Function get_AD_user_GUI 
{
   param (
        $msg= "enter user-searchstring: ",
		$title= "user selection"
    )
 
  $script:rc=$FALSE
#  $usr_sel = @{}
  $Readuser = New-Object system.Windows.Forms.Form
  $Readuser.ClientSize = '400,230'
  $Readuser.text = $title
  $Readuser.Font = 'Microsoft Sans Serif,10'
  $Readuser.Icon="$workdir/P2V.ico"
  $Readuser.Formborderstyle = "FixedDialog"
  # $Readuser.StartPosition    = "CenterScreen"
  $Readuser.Acceptbutton = $u_search_button
  $Readuser.Cancelbutton = $cancelbutton

  $u_label = New-Object system.Windows.Forms.Label
  $u_label.width = 180	
  $u_label.height = 20
  $u_label.location = New-Object System.Drawing.Point(15,15)
  $u_label.Font = 'Microsoft Sans Serif, 8.25pt'
  $u_label.Anchor= "Top,Bottom, Left, Right"
  $u_label.TextAlign = "MiddleRight"
  $u_label.Text = $msg

  $u_input = New-Object system.Windows.Forms.textbox
  $u_input.width = 175
  $u_input.height = 20
  $u_input.location = New-Object System.Drawing.Point(210,15)
  $u_input.Font = 'Microsoft Sans Serif, 8.25pt'
  $u_input.Anchor= "Top,Bottom, Left, Right"
  $u_input.TextAlign = "Left"
  $u_input.Text = "<user - xkey>"

  $u_search_button = New-Object system.Windows.Forms.Button
  $u_search_button.width = 140	
  $u_search_button.height = 25
  $u_search_button.location = New-Object System.Drawing.Point(130,45)
  $u_search_button.Font = 'Microsoft Sans Serif, 8.25pt'
  $u_search_button.Anchor= "Top,Bottom, Left, Right"
  $u_search_button.Text = "search user"
  $u_search_button.Add_Click({
     $adserver=Get-ADDomainController |select Hostname,Name,IPv4Address
	 $Userinfo.Lines =  "searching <$($u_input.Text)> in Active Directory"
	 $Userinfo.Lines += " contacting $($adserver.HostName) ($($adserver.IPv4Address))"
	 $Readuser.Refresh()
	 
	 
  	 $global:usr_sel = get_AD_user -searchstring $u_input.Text
	 if ($global:usr_sel)
	 {
	    $Userinfo.Lines =  " "
	    $Userinfo.Lines += "user:           $($global:usr_sel.displayName)"
	    $Userinfo.Lines += "xkey:           $($global:usr_sel.SamAccountName)"
	    $Userinfo.Lines += "LogonID:        $($global:usr_sel.logOnId)"
	    $Userinfo.Lines += "Email:          $($global:usr_sel.EmailAddress)"
	    $Userinfo.Lines += "Department:     $($global:usr_sel.Department)"
	    $Userinfo.Lines += "Comment:        $($global:usr_sel.comment)"
		$Readuser.Acceptbutton = $okbutton
	 }else
	 {
		$Userinfo.Lines =  " error in search - please retry " 
	 }
	
	 $Readuser.Refresh()
  })

  $okbutton = New-Object system.Windows.Forms.Button 
  $okbutton.width = 140	
  $okbutton.height = 25
  $okbutton.location = New-Object System.Drawing.Point(15,195)
  $okbutton.Font = 'Microsoft Sans Serif, 8.25pt'
  $okbutton.Anchor= "Top,Bottom, Left, Right"
  $okbutton.Text = "continue"
  $okbutton.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $okbutton.Add_Click({
    $script:rc=$True
    $Readuser.Close()
  })

  $cancelbutton = New-Object system.Windows.Forms.Button
  $cancelbutton.width = 140	
  $cancelbutton.height = 25
  $cancelbutton.location = New-Object System.Drawing.Point(245,195)
  $cancelbutton.Font = 'Microsoft Sans Serif, 8.25pt'
  $cancelbutton.Anchor= "Top,Bottom, Left, Right"
  $cancelbutton.Text = "Exit"
  $cancelbutton.DialogResult = [System.Windows.Forms.DialogResult]::ABORT
  $cancelbutton.Add_Click({
     $Readuser.Close()
  })


  $Userinfo = New-Object system.Windows.Forms.textbox
  $Userinfo.width = 370	
  $Userinfo.height = 100
  $Userinfo.location = New-Object System.Drawing.Point(15,80)
  $Userinfo.Font = 'Lucida Console,9'
  $Userinfo.multiline = $TRUE
  $Userinfo.ReadOnly = $TRUE
  $Userinfo.Anchor= "Top,Bottom, Left, Right"
  $Userinfo.TextAlign = "left"
  $Userinfo.Lines  = ""
  $Userinfo.BorderStyle="fixedsingle"
  
  $Readuser.Acceptbutton = $u_search_button
  $Readuser.Cancelbutton = $cancelbutton
  $Readuser.controls.AddRange(@($u_label,$u_input,$u_search_button,$okbutton,$cancelbutton,$UserInfo))
  $Readuser.ShowDialog()
   
  #return  $script:rc
 }
 