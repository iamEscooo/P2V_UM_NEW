#=================================================================
#  P2V_dialog_func.psm1
#  Dialog Forms and Utilities for P2V User Management
#=================================================================

<#
.SYNOPSIS
    Different dialog forms for P2V User Management.
.DESCRIPTION
    Provides functions for interactive dialogs in P2V User Management scripts.
    Includes Yes/No/All and customizable message box dialogs for user confirmation and actions.
.PARAMETER menufile
    <filename> Path to menu file (not directly used here).
.PARAMETER xamldir
    <directory> Path to XAML directory (not directly used here).
.PARAMETER fcolor
    <colorcode> Foreground color for menu buttons (e.g. 'lightblue' or '#003366').
.PARAMETER bcolor
    <colorcode> Background color for menu buttons (e.g. 'lightblue' or '#003366').
.INPUTS
    User interaction only; no pipeline input.
.OUTPUTS
    Dialog result string/value.
.EXAMPLE
    ask_continue -title "Apply changes?" -msg "Apply changes to file xyz ?" -button 4
    ask_YesNoAll -title "Apply changes?" -msg "Apply changes to file xyz ?"
.NOTES
    name:   P2V_dialog_func.psm1
    ver:    1.0
    author: M.Kufner
#>

#=================================================================
# SECTION: DIALOG FUNCTIONS
#=================================================================

#---------------------------------------------------
# FUNCTION: ask_continue
#---------------------------------------------------
<#
.SYNOPSIS
    Shows a standard Windows message box dialog.
.DESCRIPTION
    Presents a configurable MessageBox dialog for user confirmation.
.PARAMETER msg
    The question or message text to display.
.PARAMETER title
    The dialog window title.
.PARAMETER button
    Integer specifying button layout:
        0: OK
        1: OK, Cancel
        2: Abort, Retry, Ignore
        3: Yes, No, Cancel
        4: Yes, No
        5: Retry, Cancel
.PARAMETER icon
    Integer specifying icon:
        0: None
        16: Stop/Error
        32: Question
        48: Exclamation/Warning
        64: Information
.EXAMPLE
    ask_continue -title "Apply changes?" -msg "Apply changes to file xyz ?" -button 4
.NOTES
    name:   ask_continue
    author: M.Kufner
#>
Function ask_continue {
    param (
        $msg = "-- Question? --",
        $title = "Question",
        $button = 4,
        $icon = 0
    )
    $Result = [System.Windows.Forms.MessageBox]::Show($msg, $title, $button, $icon)
    return $result
}

#---------------------------------------------------
# FUNCTION: ask_YesNoAll
#---------------------------------------------------
<#
.SYNOPSIS
    Presents a custom dialog box with Yes, No, Yes to All, and No to All options.
.DESCRIPTION
    Opens a modal form with four buttons for more granular user choice than standard dialogs.
.PARAMETER msg
    The question or message text to display.
.PARAMETER title
    The dialog window title.
.EXAMPLE
    ask_YesNoAll -title "Apply changes?" -msg "Apply changes to file xyz ?"
.NOTES
    name:   ask_YesNoAll
    author: M.Kufner
#>
Function ask_YesNoAll {
    param (
        $msg = "-- Question? --",
        $title = "Question"
    )
    #$workdir|out-host # (uncomment for debug)
    $Allbox = New-Object system.Windows.Forms.Form
    $Allbox.ClientSize = '400,200'
    $Allbox.text = $title
    $Allbox.Font = 'Microsoft Sans Serif,8.25pt'
    $Allbox.Icon = "$workdir\P2V.ico"
    $Allbox.Formborderstyle = "FixedDialog"
    $Allbox.Acceptbutton = $u_search_button
    $Allbox.Cancelbutton = $cancelbutton

    # Background panel for aesthetics
    $background = New-Object system.Windows.Forms.PictureBox
    $background.width = 400
    $background.height = 145
    $background.location = New-Object System.Drawing.Point(0,0)
    $background.backcolor = "white"
    $background.Anchor = "Top, Bottom, Left, Right"

    # Message text field
    $msg_field = New-Object system.Windows.Forms.TextBox
    $msg_field.multiline = $true
    $msg_field.ReadOnly = $True
    $msg_field.width = 370
    $msg_field.height = 115
    $msg_field.location = New-Object System.Drawing.Point(15,15)
    $msg_field.Font = 'Microsoft Sans Serif,8.25pt'
    $msg_field.Backcolor = "white"
    $msg_field.BorderStyle = "None"
    $msg_field.TextAlign = "center"
    $msg_field.Scrollbars = "none"
    $msg_field.Anchor = "Top, Bottom, Left, Right"
    $msg_field.margin = "20,20,20,20"
    $msg_field.text = $msg
    $msg_field.bringtofront()

    # Yes button
    $yes_button = New-Object system.Windows.Forms.Button
    $yes_button.text = "Yes"
    $yes_button.width = 80
    $yes_button.height = 25
    $yes_button.location = New-Object System.Drawing.Point(15,160)
    $yes_button.Font = 'Microsoft Sans Serif,8.25pt'
    $yes_button.DialogResult = [System.Windows.Forms.DialogResult]::YES
    $yes_button.Add_Click({
        $result = $yes_button.text
        $allbox.Close()
    })

    # No button
    $no_button = New-Object system.Windows.Forms.Button
    $no_button.text = "No"
    $no_button.width = 80
    $no_button.height = 25
    $no_button.location = New-Object System.Drawing.Point(110,160)
    $no_button.Font = 'Microsoft Sans Serif,8.25pt'
    $no_button.DialogResult = [System.Windows.Forms.DialogResult]::NO
    $no_button.Add_Click({
        $result = $no_button.text
        $allbox.Close()
    })

    # Yes to All button
    $yesall_button = New-Object system.Windows.Forms.Button
    $yesall_button.text = "Yes to All"
    $yesall_button.width = 80
    $yesall_button.height = 25
    $yesall_button.location = New-Object System.Drawing.Point(205,160)
    $yesall_button.Font = 'Microsoft Sans Serif,8.25pt'
    $yesall_button.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $yesall_button.Add_Click({
        $result = "YesAll"
        $allbox.Close()
    })

    # No to All button
    $noall_button = New-Object system.Windows.Forms.Button
    $noall_button.text = "No to All"
    $noall_button.width = 80
    $noall_button.height = 25
    $noall_button.location = New-Object System.Drawing.Point(300,160)
    $noall_button.Font = 'Microsoft Sans Serif,8.25pt'
    $noall_button.DialogResult = [System.Windows.Forms.DialogResult]::ABORT
    $noall_button.Add_Click({
        $result = "NoAll"
        $allbox.Close()
    })

    $allbox.controls.AddRange(@($background, $yes_button, $no_button, $yesall_button, $noall_button, $msg_field))
    $msg_field.bringtofront()
    $allbox.showdialog()

    return $result
}

#=================================================================
# SECTION: MODULE EXPORTS
#=================================================================
# Export current date/time for dialog session reference
$dialog_date = get-date

Export-ModuleMember -Variable dialog_date
Export-ModuleMember -Function * -Alias *
