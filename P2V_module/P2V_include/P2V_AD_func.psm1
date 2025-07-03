#=================================================================
#  P2V_AD_func.psm1
#  Active Directory Utility Functions for P2V User Management
#=================================================================

<#
.SYNOPSIS
    Utility functions for interacting with Active Directory in P2V User Management.
.DESCRIPTION
    This module provides functions to:
      - Select users and groups from Active Directory
      - Retrieve user and group properties
      - Export user lists to CSV
      - Show dialog GUIs for user interaction
.PARAMETER menufile
    <filename> Path to the menu definition file.
.PARAMETER xamldir
    <directory> Path to the directory containing XAML definitions.
.PARAMETER fcolor
    <colorcode> Foreground color for menu buttons (e.g. 'lightblue' or '#003366').
.PARAMETER bcolor
    <colorcode> Background color for menu buttons (e.g. 'lightblue' or '#003366').
.INPUTS
    Data that can be piped into the functions (see individual function documentation).
.OUTPUTS
    Objects, CSV files, or UI dialogs depending on the function.
.EXAMPLE
    See individual function help for examples.
.NOTES
    name:   P2V_AD_func.psm1
    ver:    1.0
    author: M.Kufner
#>

#=================================================================
# SECTION: VARIABLES
#=================================================================
# (No global variables defined in this module, but functions may define local collections.)

#=================================================================
# SECTION: FUNCTIONS - Active Directory Operations
#=================================================================

#---------------------------------------------------
# FUNCTION: get_AD_user
#---------------------------------------------------
<#
.SYNOPSIS
    Finds and selects a user from Active Directory.
.DESCRIPTION
    Allows searching for a user by xkey or search string. Returns a user profile object with key properties.
    If multiple users are found, presents an Out-GridView to select a single user.
.PARAMETER searchstring
    A string to search by (Givenname, Surname, or Name).
.PARAMETER xkey
    The sAMAccountName (username) to search for directly.
.OUTPUTS
    Returns the selected user as a PSObject, or $False if not found.
#>
Function get_AD_user {
    param (
        [string]$searchstring= "",
        [string]$xkey=""
    )
    # Main user object that will be populated
    # $ad_user_selected=@{}

    # Prefer xkey if provided
    if ($xkey) { $searchstring = $xkey }
    while (!$ad_user_selected) {
        $a = @{}
        while (-not $searchstring) { $searchstring = ""; return $False }
        # Try direct xkey match first
        if ($xkey -and ([ADSISearcher] "(sAMAccountName=$xkey)").FindOne()) {
            $u_res = Get-ADUser -Identity $xkey.Trim() -Properties * |
                Select Name, Givenname, surname, SamAccountName, UserPrincipalName, EmailAddress, Department, distinguishedName, lastlogon, lastLogonTimestamp, accountExpires, comment, description, extensionAttribute8, Enabled
            if ($u_res) { Write-Progress "X-KEY [$xkey] found!!" }
        } else {
            # If not found, do a broader search
            $ad_user = '*' + $searchstring.Trim() + '*'
            $u_res = Get-ADUser -SearchBase "DC=ww,DC=omv,DC=com" -Filter { (Givenname -like $ad_user) -or (Surname -like $ad_user) -or (Name -like $ad_user) } -Properties * |
                Select Name, Givenname, surname, SamAccountName, UserPrincipalName, EmailAddress, Department, distinguishedName, lastlogon, lastLogonTimestamp, accountExpires, comment, description, extensionAttribute8, Enabled
            if ($u_res) { Write-Output "search string [$searchstring] found!!" }
        }
        $u_count = $u_res.Count
        $searchstring = "" # reset search string

        # Optionally show results for debugging
        if ($debug) { $u_res | Out-GridView -Title "u_res" -Wait }

        # Select relevant properties for the selected user(s)
        $ad_user_selected = $u_res | Select Givenname, surname, SamAccountName, EmailAddress, Enabled, Department, lastlogon, accountExpires, UserPrincipalName, extensionAttribute8

        # No results found
        if (!$ad_user_selected) {
            $form_err -f "ERROR", "[$u_res] not found or no user selected" | Out-Host
            $ad_user_selected = ""
        } else {
            # Format and clean up properties
            $ad_user_selected | % {
                $_.lastLogon = [datetime]::FromFileTime($_.lastlogon).ToString('yyyy-MM-dd HH:mm:ss')
                $_.accountExpires = [datetime]::FromFileTime($_.accountExpires).ToString('yyyy-MM-dd HH:mm:ss')
            }
            # If multiple results, prompt for single selection
            if ($u_count -gt 1) {
                $ad_user_selected = $ad_user_selected | Out-GridView -Title "select user from AD" -OutputMode Single
            }
            # Add display properties
            Add-Member -InputObject $ad_user_selected -Name 'displayName' -Type NoteProperty -Value "$($ad_user_selected.surname) $($ad_user_selected.Givenname) ($($ad_user_selected.SamAccountName))"
            Add-Member -InputObject $ad_user_selected -Name 'logOnId' -Type NoteProperty -Value "$($ad_user_selected.UserPrincipalName)"
            Add-Member -InputObject $ad_user_selected -Name 'OrgID'  -Type NoteProperty  -Value "$($ad_user_selected.extensionAttribute8)"
            $ad_user_selected.PSObject.Properties.Remove('extensionAttribute8')
            $ad_user_selected.Department = $ad_user_selected.Department -replace '[,]', ''
            $ad_user_selected.Department = $($ad_user_selected.Department).Trim()
            $ad_user_selected.Department = "$($ad_user_selected.OrgID):$($ad_user_selected.Department)"
        }
    }
    Write-Progress -Completed -Activity "close progress bar"
    return $ad_user_selected
}

#---------------------------------------------------
# FUNCTION: get_AD_userlist
#---------------------------------------------------
<#
.SYNOPSIS
    Get all members of a given Active Directory group.
.DESCRIPTION
    Returns all users in the specified AD group, with key properties.
    If $all is $False, prompts for user selection via Out-GridView.
.PARAMETER ad_group
    The AD group name.
.PARAMETER all
    If $True, returns all users. If $False, allows multi-select.
.OUTPUTS
    PSObject array of user profiles, or $False if group not found.
#>
Function get_AD_userlist {
    param(
        [string]$ad_group = "dlg.WW.ADM-Services.P2V.access.production",
        [bool]  $all = $False
    )
    if ($check_group = Get-ADGroup -Identity $ad_group) {
        # Group found; gather user entries
        $entries = Get-ADGroupMember -Identity $ad_group | Get-ADUser -Properties * | Select Givenname, Surname, SamAccountName, EmailAddress, comment, Department, lastlogon, accountExpires, UserPrincipalName, extensionAttribute8, distinguishedName, description
        $entries | %{
            $_.lastLogon = [datetime]::FromFileTime($_.lastlogon).ToString('yyyy-MM-dd HH:mm:ss')
            $_.accountExpires = [datetime]::FromFileTime($_.accountExpires).ToString('yyyy-MM-dd HH:mm:ss')
            if ("$($_.distinguishedName)" -match "Deactivates") { $_.comment = "DEACTIVATED" }
            else { $_.comment = "ACTIVE" }
            Add-Member -InputObject $_ -Name 'displayName' -Type NoteProperty -Value "$($_.surname) $($_.Givenname) ($($_.SamAccountName))"
            Add-Member -InputObject $_ -Name 'logOnId' -Type NoteProperty -Value "$($_.UserPrincipalName)"
            Add-Member -InputObject $_ -Name 'OrgID' -Type NoteProperty -Value "$($_.extensionAttribute8)"
            $_.PSObject.Properties.Remove('extensionAttribute8')
            $_.Department = $_.Department -replace '[,]', ''
            $_.Department = $($_.Department).Trim()
            $_.Department = "$($_.OrgID):$($_.Department)"
        }
        if ($all) { $ADgroup_members[$ad_group] = $entries }
        else { $entries = $entries | Out-GridView -Title "select (multiple) user(s)" -OutputMode Multiple }
    } else {
        $form_status -f "AD:  $ad_group", "[ERROR]"
        $entries = $false
    }
    return $entries
}

#---------------------------------------------------
# FUNCTION: get_AD_groups
#---------------------------------------------------
<#
.SYNOPSIS
    Loads AD group data from a CSV file.
.DESCRIPTION
    Imports group definitions from $adgroupfile and stores them in $all_adgroups.
    (Extend this function for further group logic as needed.)
#>
Function get_AD_groups {
    $all_adgroups = @{}
    $all_adgroups = Import-Csv $adgroupfile
    # Further processing can be added here (for reporting or logic)
}

#---------------------------------------------------
# FUNCTION: get_AD_user_GUI
#---------------------------------------------------
<#
.SYNOPSIS
    GUI dialog for AD user selection.
.DESCRIPTION
    Opens a Windows Form dialog for the user to search and select an AD user.
.PARAMETER msg
    Message to display in the dialog.
.PARAMETER title
    Title of the dialog window.
.EXAMPLE
    get_AD_user_GUI -title "Apply changes?" -msg "Apply changes to file xyz ?"
.OUTPUTS
    Returns the dialog result string ("OK", "ABORT", etc).
#>
Function get_AD_user_GUI {
    param (
        $msg= "enter xkey or searchstring: ",
        $title= "user selection"
    )
    $script:rc = $FALSE
    $Readuser = New-Object system.Windows.Forms.Form
    $Readuser.ClientSize = '400,230'
    $Readuser.text = $title
    $Readuser.Font = 'Microsoft Sans Serif,10'
    $Readuser.Icon = "$workdir/P2V.ico"
    $Readuser.Formborderstyle = "FixedDialog"
    $Readuser.Acceptbutton = $u_search_button
    $Readuser.Cancelbutton = $cancelbutton

    # --- Create label for prompt ---
    $u_label = New-Object system.Windows.Forms.Label
    $u_label.width = 180
    $u_label.height = 20
    $u_label.location = New-Object System.Drawing.Point(15,15)
    $u_label.Font = 'Microsoft Sans Serif, 8.25pt'
    $u_label.Anchor = "Top,Bottom, Left, Right"
    $u_label.TextAlign = "MiddleRight"
    $u_label.Text = $msg

    # --- Create textbox for input ---
    $u_input = New-Object system.Windows.Forms.textbox
    $u_input.width = 175
    $u_input.height = 20
    $u_input.location = New-Object System.Drawing.Point(210,15)
    $u_input.Font = 'Microsoft Sans Serif, 8.25pt'
    $u_input.Anchor = "Top,Bottom, Left, Right"
    $u_input.TextAlign = "Left"
    $u_input.Text = "<user - xkey>"

    # --- Search button ---
    $u_search_button = New-Object system.Windows.Forms.Button
    $u_search_button.width = 140
    $u_search_button.height = 25
    $u_search_button.location = New-Object System.Drawing.Point(130,45)
    $u_search_button.Font = 'Microsoft Sans Serif, 8.25pt'
    $u_search_button.Anchor = "Top,Bottom, Left, Right"
    $u_search_button.Text = "search user"
    $u_search_button.Add_Click({
        $adserver = Get-ADDomainController | Select Hostname,Name,IPv4Address
        $Userinfo.Lines =  "searching <$($u_input.Text)> in Active Directory"
        $Userinfo.Lines += " contacting $($adserver.HostName) ($($adserver.IPv4Address))"
        $Readuser.Refresh()
        $global:usr_sel = get_AD_user -xkey $u_input.Text
        if ($global:usr_sel) {
            $Userinfo.Lines =  " "
            $Userinfo.Lines += "user:           $($global:usr_sel.displayName)"
            $Userinfo.Lines += "xkey:           $($global:usr_sel.SamAccountName)"
            $Userinfo.Lines += "LogonID:        $($global:usr_sel.logOnId)"
            $Userinfo.Lines += "Email:          $($global:usr_sel.EmailAddress)"
            $Userinfo.Lines += "Department:     $($global:usr_sel.Department)"
            $Userinfo.Lines += "Comment:        $($global:usr_sel.comment)"
            $Readuser.Acceptbutton = $okbutton
        } else {
            $Userinfo.Lines =  " error in search - please retry "
        }
        $Readuser.Refresh()
    })

    # --- OK / continue button ---
    $okbutton = New-Object system.Windows.Forms.Button
    $okbutton.width = 140
    $okbutton.height = 25
    $okbutton.location = New-Object System.Drawing.Point(15,195)
    $okbutton.Font = 'Microsoft Sans Serif, 8.25pt'
    $okbutton.Anchor = "Top,Bottom, Left, Right"
    $okbutton.Text = "continue"
    $okbutton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okbutton.Add_Click({
        if ($global:usr_sel) {
            $script:rc = $True
            $Readuser.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "No user selected. Please search and select a user before continuing.",
                "No User Selected",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
    })

    # --- Cancel/Exit button ---
    $cancelbutton = New-Object system.Windows.Forms.Button
    $cancelbutton.width = 140
    $cancelbutton.height = 25
    $cancelbutton.location = New-Object System.Drawing.Point(245,195)
    $cancelbutton.Font = 'Microsoft Sans Serif, 8.25pt'
    $cancelbutton.Anchor = "Top,Bottom, Left, Right"
    $cancelbutton.Text = "Exit"
    $cancelbutton.DialogResult = [System.Windows.Forms.DialogResult]::ABORT
    $cancelbutton.Add_Click({
        $Readuser.Close()
    })

    # --- Output textbox for user info ---
    $Userinfo = New-Object system.Windows.Forms.textbox
    $Userinfo.width = 370
    $Userinfo.height = 100
    $Userinfo.location = New-Object System.Drawing.Point(15,80)
    $Userinfo.Font = 'Lucida Console,9'
    $Userinfo.multiline = $TRUE
    $Userinfo.ReadOnly = $TRUE
    $Userinfo.Anchor = "Top,Bottom, Left, Right"
    $Userinfo.TextAlign = "left"
    $Userinfo.Lines  = ""
    $Userinfo.BorderStyle = "fixedsingle"

    $Readuser.Acceptbutton = $u_search_button
    $Readuser.Cancelbutton = $cancelbutton
    $Readuser.Controls.AddRange(@($u_label,$u_input,$u_search_button,$okbutton,$cancelbutton,$UserInfo))
    $result = $Readuser.ShowDialog()
    return $result.ToString()
}

#---------------------------------------------------
# FUNCTION: P2V_export_AD_users
#---------------------------------------------------
<#
.SYNOPSIS
    Exports a list of AD users and their P2V profiles to a CSV file.
.DESCRIPTION
    Iterates over all selected AD groups, retrieves user details, and writes to a CSV.
#>
Function P2V_export_AD_users {
    $output_path = Join-Path $workdir "P2V_UM_data\sec 2.0"
    $outfile = $output_path + "P2V_SAMLusers_profiles_AUTO.csv"
    P2V_header -app $MyInvocation.MyCommand -path $My_path
    createdir_ifnotexists -check_path $output_path  -verbose $true
    Delete-ExistingFile -file $outfile

    Write-Output ($form1 -f "exporting userlists  from Active Directory")

    $sel_categories = "SPECIAL","DATA","PROFILE"
    $all_adgroups = @{}
    $all_adgroups = Import-Csv $adgroupfile | Where { ($_.PSgroup -ne "") -and ($sel_categories -contains $_.category) }

    # User collector
    $all_users = @{}

    Add-Content -Path $outfile -Value 'DisplayName,xkey,logonID,profile,ptype,Description,ADgroup'

    foreach ($a in $all_adgroups) {
        $usr = @{}
        Write-Progress "checking  $($a.ADgroup)"
        if ($check_group = Get-ADGroup -identity $a.ADgroup ) {
            $members = @{}
            Write-Progress "loading  $($a.ADgroup)"
            $members = Get-ADGroupMember -Identity $a.ADgroup | Select Name
            $members | % {
                if ($all_users.Keys -notcontains $_.Name) {
                    $all_users["$($_.Name)"] = get_AD_user -xkey $_.Name
                }
                $usr = $all_users["$($_.Name)"]
                Add-Content -Path $outfile -Value "$($usr.displayName),$($usr.SamAccountName),$($usr.logOnId),$($a.PSgroup),$($a.category),$($usr.Description),$($a.ADgroup)"
            }
            Write-Output -NoEnumerate ($form_status -f "$($a.ADgroup)", ("[{0,3}]" -f $($members.Count)))
        }
    }
    Write-Progress "loading finished" -completed
    Write-Output ($form1 -f "result are stored in $outfile")
    P2V_footer -app $MyInvocation.MyCommand
}

#=================================================================
# SECTION: EXPORTS - Make all functions and variables public
#=================================================================
Export-ModuleMember -Variable '*'
Export-ModuleMember -Function * -Alias *
