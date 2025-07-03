#-------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-Module "$scriptRoot\P2V_module\P2V_config.psd1" -Global -verbose
Import-Module "$scriptRoot\P2V_module\P2V_include.psd1" -Global -verbose
Import-Module "$scriptRoot\P2V_module\P2V_dialog_func.psd1" -Global -verbose
Import-Module "$scriptRoot\P2V_module\P2V_AD_func.psd1" -Global -verbose
Import-Module "$scriptRoot\P2V_module\P2V_PS_func.psd1" -Global -verbose


#"-- PSModulePath:"|out-host
#$env:PSModulePath -split ';' |out-host

if ($PSScriptRoot)
{
  #	 "-- PSScriptRoot:"|out-host
  #   $PSScriptRoot
	$my_root = $PSScriptRoot
	
}
else
{
  #	 "-- PWD:"|out-host
  #   $PWD.Path 
	$my_root = $PWD.Path
}


#import-module -name "$PSScriptRoot\P2V_module.psd1" -verbose
#import-module "p2v_mod.psd1"
#-------------------------------------------------
[System.Windows.Forms.Application]::EnableVisualStyles()

#-------------------------------------------------
#$script:usr_sel= @{}
$global:usr_sel= @{}
$global:usr_xkey=""


P2V_init -root $my_root

#-------------------------------------------------
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
  $My_Path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
  } else {
    $My_Path = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    if (!$My_Path){ $My_Path = "." }
  }

if (!$workdir) {$workdir=$my_root;$libdir="$workdir\lib"} 

$script:P2V_icon="$workdir\P2V.ico"

if ($debug)
{
	write-output $workdir
	write-output " variables":
	Get-Variable -Scope 0|ft

	write-output "PSScriptRoot: [$PSScriptRoot]"
	write-output "Workdir:      [$workdir]"
	write-output "Libdir:       [$libdir]"
  
}



#. "$libdir\P2V_include.ps1"
#. "$libdir\P2V_super_sync.ps1"
. "$libdir\P2V_export_users.ps1"
. "$libdir\P2V_calculate_groups_dependencies.ps1"
. "$libdir\P2V_set_profiles.ps1"
. "$libdir\P2V_calculate_groups.ps1"
#. $libdir\check_userprofile.ps1
#. "$libdir\check_P2V_user.ps1"
#. "$libdir\P2V_export_AD_users.ps1"
#. "$libdir\P2V_calculate_groups_bd.ps1"





#----- Set FORM variables
#----------------------------------------------------------------
#---  user searchstring input


#----------------------------------------------------------------
#---  main window ---
$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '1185,800'
$Form.text = "P2V Usermanagement"
$Form.Font = 'Microsoft Sans Serif,10'
#$form.backcolor= "LightSteelBlue"
$Form.Formborderstyle = "Fixed3D"
$Form.MaximizeBox=$False
$Form.MinimizeBox=$False
$Form.TopMost = $false
$Form.Autovalidate ="EnableAllowFocusChange"
$Form.Icon="$workdir/P2V.ico"

#-------------------------------------------------
#---- Title 

$Title = New-Object system.Windows.Forms.Label

$Title.width = 400	
$Title.height = 100
$Title.location = New-Object System.Drawing.Point(175,20)
$Title.Font = 'Microsoft Sans Serif, 20pt, style=Bold'
$Title.Anchor= "Top, Left"
$Title.Text = "Plan2Value Usermanagement"
$Title.Text += " -- single user mode -- "

#-------------------------------------------------
#---- Logo

#$Logo = 
$Logo = New-Object system.Windows.Forms.PictureBox

$Logo.width = 100
$Logo.height = 100
$Logo.location = New-Object System.Drawing.Point(35,15)
$Logo.Image= New-Object System.Drawing.Bitmap "$workdir/P2V.png"
$Logo.Sizemode = "Zoom"
$Logo.Font = 'Microsoft Sans Serif,10'
$Logo.Anchor= "Top, Left"
$logo.BorderStyle="Fixed3D"

#---- Functions
#---------------------------------------------------
function Show-ToolTip {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Windows.Forms.Control]$control,
        [string]$text = $null,
        [int]$duration = 1000
    )
    if ([string]::IsNullOrWhiteSpace($text)) { $text = $control.Tag }
    $pos = [System.Drawing.Point]::new($control.Right, $control.Top)
    $obj_tt.Show($text,$form, $pos, $duration)
}

function Paint_FocusBorder([System.Windows.Forms.Control]$control) {
    # get the parent control (usually the form itself)
    $parent = $control.Parent
    $parent.Refresh()
    if ($control.Focused) {
        $control.BackColor = "LightBlue"
        $pen = [System.Drawing.Pen]::new('Red', 2)
    }
    else {
        $control.BackColor = "White"
        $pen = [System.Drawing.Pen]::new($parent.BackColor, 2)
    }
    $rect = [System.Drawing.Rectangle]::new($control.Location, $control.Size)
    $rect.Inflate(1,1)
    $parent.CreateGraphics().DrawRectangle($pen, $rect)
}
##### to be moved to a module
function Write-P2VDebug {
    param([string]$msg)
    if ($global:P2V_Debug) {
        if ($TextBox1) {
            $TextBox1.AppendText("DEBUG: $msg`r`n")
        } else {
            Write-Host "DEBUG: $msg"
        }
    }
}

function GetProfileFromAD {
    param([string]$xkey)
    $profiles = @()
    try {
        $adGroups = Get-ADPrincipalGroupMembership -Identity $xkey | Select -ExpandProperty Name
    } catch {
        Write-P2VDebug "Get-ADPrincipalGroupMembership failed: $($_ | Out-String)"
        # Fallback: enumerate group membership manually
        $adGroups = Get-ADUser $xkey -Properties MemberOf | Select-Object -ExpandProperty MemberOf |
            ForEach-Object {
                ($_ -split ',')[0] -replace '^CN='
            }
    }
    # Only proceed if $adgroupfile is set and not empty
    if (-not $adgroupfile -or !(Test-Path $adgroupfile)) {
        Write-P2VDebug "adgroupfile not set or does not exist: $adgroupfile"
        return @()
    }
    $map = Import-Csv $adgroupfile | Where-Object { $_.category -eq 'PROFILE' }
    foreach ($g in $adGroups) {
        $hit = $map | Where-Object { $_.ADgroup -eq $g }
        if ($hit) { $profiles += $hit.PSgroup }
    }
    $profiles | Select-Object -Unique
}

function Assign-P2VProfile {
    param ([object]$User)
    Write-P2VDebug "Assign-P2VProfile started for $($User.SamAccountName)"
    $xkey = $User.SamAccountName
    $upn  = $User.UserPrincipalName
    Write-P2VDebug "xkey: $xkey, upn: $upn"

    #---- determine profile from AD
    $profiles = GetProfileFromAD -xkey $xkey
    if (!$profiles) {
        [System.Windows.Forms.MessageBox]::Show("No profile detected from AD. Please select manually.","No Profile Detected",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
        $all = Import-Csv "$config_path/SEC20_profiles_workgroups.csv" | Select -ExpandProperty profile -Unique
        $sel = $all | Out-GridView -Title 'Select profile' -OutputMode Single
        if ($sel) { $profiles = @($sel) } else { return }
    }

    #---- build profile to group mapping
    $profileGroups = @{}
    Import-Csv "$config_path/SEC20_profiles_workgroups.csv" | ForEach-Object {
        $profileGroups[$_.profile] += @($_.groups)
    }

    #---- select tenants
    $tenants = select_PS_tenants -multiple $true -all $false
    foreach ($key in $tenants.Keys) {
        $t = $tenants[$key]
        $userEntry = P2V_get_userlist -tenant $t | Where-Object { $_.logOnId -eq $upn }
        if (!$userEntry) {
            [System.Windows.Forms.MessageBox]::Show("$upn not found in tenant $($t.tenant)","User Not Found",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
            continue
        }

        $groups  = Get-PSGroupList -tenant $t
        $gIndex  = @{}
        if ($groups) {
            $groups | ForEach-Object { $gIndex[$_.name] = $_.id }
        } else {
            Write-P2VDebug "No groups returned for tenant $($t.tenant)"
        }

        $update  = @{}
        foreach ($p in $profiles) {
            foreach ($wg in $profileGroups[$p]) {
                $gid = $gIndex[$wg]
                if ($gid) {
                    if (-not $update.ContainsKey($gid)) { $update[$gid] = @() }
                    $update[$gid] += [PSCustomObject]@{ op='add'; path="/users/$($userEntry.id)"; value='' }
                }
            }
        }

        if ($update.Count -gt 0) {
            $body = $update | ConvertTo-Json
            if ($update.Count -eq 1) { $body = "[ $body ]" }
            $body = [System.Text.Encoding]::UTF8.GetBytes($body)
            $apiUrl = "$($t.ServerURL)/$($t.tenant)/planningspace/api/v1/workgroups/bulk"
            Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{Authorization="Basic $($t.base64AuthInfo)"} -Body $body -ContentType 'application/json'
            [System.Windows.Forms.MessageBox]::Show("Updated tenant $($t.tenant)","Success",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            [System.Windows.Forms.MessageBox]::Show("No groups to update for tenant $($t.tenant)","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
}

#-------------------------------------------------
#---- Usageinfo

$UsageInfo = New-Object system.Windows.Forms.textbox

$UsageInfo.width = 1000	
$UsageInfo.height = 100
$UsageInfo.location = New-Object System.Drawing.Point(20,760)
$UsageInfo.Font = 'Microsoft Sans Serif, 8pt'

$UsageInfo.multiline = $FALSE
$UsageInfo.ReadOnly = $TRUE
$UsageInfo.Anchor= "Top,Bottom, Left, Right"
$UsageInfo.TextAlign = "left"
$UsageInfo.Lines  = "user: [$user] computer: [$client] in [$my_root] started at: "+(get-date -format "[dd/MM/yyyy HH:mm:ss]")
$UsageInfo.BorderStyle="None"

#-------------------------------------------------
#---- groupbox 1 (single user)
$groupbox1 = New-Object system.Windows.Forms.Groupbox
$groupbox1.width   = 150
$groupbox1.height  = 280
$groupbox1.location = New-Object System.Drawing.Point(10,125)
$groupbox1.Font = 'Microsoft Sans Serif, 8.25pt'
$groupbox1.text = "single user actions"
$groupbox1.Flatstyle ="Standard"
$groupbox1.Margin.All = 5

#-------------------------------------------------
#---- groupbox 2 (tenant activites)
$groupbox2 = New-Object system.Windows.Forms.Groupbox
$groupbox2.width   = 150
$groupbox2.height  = 280
$groupbox2.location = New-Object System.Drawing.Point(10,410)
$groupbox2.Font = 'Microsoft Sans Serif, 8.25pt'
$groupbox2.text = "tenant actions"
$groupbox2.Flatstyle ="Standard"
$groupbox2.Margin.All = 5


#-------------------------------------------------
#---- selected user
$selected_user= New-Object system.Windows.Forms.textbox

$selected_user.width = 800	
$selected_user.height = 100
$selected_user.location = New-Object System.Drawing.Point(700,30)
$selected_user.Font =  'Lucida Console,9'

$selected_user.multiline = $TRUE
$selected_user.ReadOnly = $TRUE
$selected_user.Anchor= "Top,Bottom, Left, Right"
$selected_user.TextAlign = "Left"
$selected_user.Lines  = "selected user: [ -- no user selected -- ]"

$selected_user.BorderStyle="None"

#-------------------------------------------------
#--  Button1  - select / change user
$Button1 = New-Object system.Windows.Forms.Button
$Button1.text = "select / change user"
$Button1.Enabled = $true
$Button1.width = 140
$Button1.height = 25
$Button1.location = New-Object System.Drawing.Point(15,145)
$Button1.Font = 'Microsoft Sans Serif, 8.25pt'
$Button1.Tag = "!! HELP !!"

$Button1.Add_Click({
   $TextBox1.lines = $Button1.text
   $ProgressBar1.Value=0
   $statusfield.backcolor="Control"
   $statusfield.text= "running ..."
   $Form.Refresh()
   
   # ask_continue -title "Button1 - get_AD_user_GUI" -msg "select / change user" -button 0 -icon 64 
   
   if (($cont=get_AD_user_GUI -title "Check user profile") -eq "OK" )
   {
	  $selected_user.Lines  = "selected user: $($global:usr_sel.displayname)"
	  $selected_user.Lines += ""
      $selected_user.Lines += "X-KEY:         $($global:usr_sel.SamAccountName)"
	  $selected_user.Lines += "UPN/LoginID:   $($global:usr_sel.UserPrincipalName)"
      $selected_user.Lines += "Department:    $($global:usr_sel.department)"
	  
	  $TextBox1.lines  = "user $($global:usr_sel.SamAccountName) selected"
	  $global:usr_xkey=$($global:usr_sel.SamAccountName)
	 
	    $TextBox1.Lines +=  " "
	    $TextBox1.Lines += "user:           $($global:usr_sel.displayName)"
	    $TextBox1.Lines += "xkey:           $($global:usr_sel.SamAccountName)"
	    $TextBox1.Lines += "LogonID:        $($global:usr_sel.logOnId)"
	    $TextBox1.Lines += "Email:          $($global:usr_sel.EmailAddress)"
	    $TextBox1.Lines += "Department:     $($global:usr_sel.Department)"
	    $TextBox1.Lines += "Comment:        $($global:usr_sel.comment)"
		$TextBox1.Lines +=  " "
		$TextBox1.Lines +=  $linesep
	
	  write-host  $($global:usr_sel).Value |out-host
      $selected_user.Lines += ""
	  
      $Form.Refresh()
      #check_userprofile -xkey $($global:usr_sel.SamAccountName)| out-string -Stream | foreach-object {
	 
       $ProgressBar1.Value = ($ProgressBar1.Value + 1 ) % 100
    #   $Form.Refresh()
    #  }
      $ProgressBar1.Value = 100
	  $statusfield.backcolor ="0,192,0"
      $statusfield.text= "finished !"
      $Form.Refresh()
   } else
   {
	  $statusfield.text= "aborted !"
      $Form.Refresh()
   }
   <# {
      $TextBox1.lines = $TextBox1.lines + "cancelled by user ..."   
      $ProgressBar1.Value = 100
      $statusfield.text= "cancelled by user !"
      $Form.Refresh()
   } #>
})
<# write-output "Add_GotFocus" 
$Button1.Add_GotFocus({ Paint_FocusBorder $this })
write-output "Add_LostFocus"
$Button1.Add_LostFocus({ Paint_FocusBorder $this })
write-output "Add_LostFocus"
$Button1.Add_MouseEnter({ Show-ToolTip $this })   # you can play with the other parameters -text and -duration
write-output "Add_MouseLeave"
$Button1.Add_MouseLeave({ $obj_tt.Hide($form) })
#>
#-------------------------------------------------
#--  Button2 - check base user setup (AD,tenants)
$Button2 = New-Object system.Windows.Forms.Button
$Button2.text = "Check base user setup"
$Button2.Enabled = $true
$Button2.width = 140
$Button2.height = 25
$Button2.location = New-Object System.Drawing.Point(15,175)
$Button2.Font = 'Microsoft Sans Serif, 8.25pt'

$Button2.Add_Click({
    $TextBox1.lines = $Button2.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	# ask_continue -title "Button2 - check_userprofile" -msg "Check base user setup" -button 0 -icon 64
	
	if (!$usr_xkey)  
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{
  	  $Textbox1.AppendText("`n")
      #$TextBox1.AppendText("searching [$($global:usr_sel.displayname)]-$($global:usr_sel.SamAccountName)`n")
      #$Form.Refresh()
	  write-Log -logtext "[$user] started check_userprofile -xkey $($global:usr_sel.SamAccountName)"
      check_userprofile -xkey $($global:usr_sel.SamAccountName)| out-string -Stream | foreach-object {
       $Textbox1.AppendText("$_`r`n")
	   $ProgressBar1.Value = ($ProgressBar1.Value + 1 ) % 100
     #  $Form.Refresh()
      }
      $ProgressBar1.Value = 100
	   $statusfield.backcolor ="0,192,0"
      $statusfield.text= "finished !"
      $Form.Refresh()
     
	}	  	
})

#-------------------------------------------------
#--  Button3 - Check P2V User permissions
$Button3 = New-Object system.Windows.Forms.Button
$Button3.text = "Check P2V permissions"
$Button3.Enabled = $true
$Button3.width = 140
$Button3.height = 25
$Button3.location = New-Object System.Drawing.Point(15,200)
$Button3.Font = 'Microsoft Sans Serif, 8.25pt'

$Button3.Add_Click({
   $TextBox1.lines =$Button3.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	
	if (!$usr_xkey)  
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{
  	write-Log -logtext "[$user] started check_P2V_user -xkey $($global:usr_sel.SamAccountName)"
    check_P2V_user -xkey $($global:usr_sel.SamAccountName)| out-string -Stream | foreach-object {
	       $Textbox1.AppendText("$_`r`n")
           $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    #       $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	}   
})

#-------------------------------------------------
#--  Button4 - Lock User
$Button4 = New-Object system.Windows.Forms.Button
$Button4.text = "Lock User"
$Button4.Enabled = $true
$Button4.width = 140
$Button4.height = 25
$Button4.location = New-Object System.Drawing.Point(15,225)
$Button4.Font = 'Microsoft Sans Serif, 8.25pt'

$Button4.Add_Click({
    $TextBox1.lines = $Button4.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()

	if (!$usr_xkey)   
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{
		
	  # ask_continue -title "Button4 - P2V_lock_user" -msg "P2V_lock_user" -button 0 -icon 64
	  write-Log -logtext "[$user] started P2V_lock_user -xkey $($global:usr_sel.SamAccountName)"
       P2V_lock_user -xkey $($global:usr_sel.SamAccountName) | out-string -Stream | foreach-object {
       $TextBox1.lines = $TextBox1.lines + $_
       $TextBox1.Select($TextBox1.Text.Length, 0)
       $TextBox1.ScrollToCaret()
       $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
       $Form.Refresh()
      }
	   $ProgressBar1.Value = 100   
	   $statusfield.backcolor ="0,192,0"
	   $statusfield.text= "finished !"
       $Form.Refresh()
	}
})

#-------------------------------------------------
#--  Button4_1 - Unlock User
$Button4_1 = New-Object system.Windows.Forms.Button
$Button4_1.text = "Unlock User"
$Button4_1.Enabled = $true
$Button4_1.width = 140
$Button4_1.height = 25
$Button4_1.location = New-Object System.Drawing.Point(15,250)
$Button4_1.Font = 'Microsoft Sans Serif, 8.25pt'

$Button4_1.Add_Click({
    $TextBox1.lines = $Button4_1.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	
    if (!$usr_xkey)    
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{
		
	  # ask_continue -title "Button4_1 - P2V_unlock_user" -msg "P2V_lock_user" -button 0 -icon 64
	  write-Log -logtext "[$user] started P2V_unlock_user -xkey $($global:usr_sel.SamAccountName)"
       P2V_unlock_user -xkey $($global:usr_sel.SamAccountName) | out-string -Stream | foreach-object {
       $TextBox1.lines = $TextBox1.lines + $_
       $TextBox1.Select($TextBox1.Text.Length, 0)
       $TextBox1.ScrollToCaret()
       $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
       $Form.Refresh()
      }
	   $ProgressBar1.Value = 100   
	   $statusfield.backcolor ="0,192,0"
	   $statusfield.text= "finished !"
       $Form.Refresh()
	}
})

#-------------------------------------------------
#--  Button4_2 - Deactivate User
$Button4_2 = New-Object system.Windows.Forms.Button
$Button4_2.text = "Deactivate User"
$Button4_2.Enabled = $true
$Button4_2.width = 140
$Button4_2.height = 25
$Button4_2.location = New-Object System.Drawing.Point(15,275)
$Button4_2.Font = 'Microsoft Sans Serif, 8.25pt'

$Button4_2.Add_Click({
    $TextBox1.lines = $Button4_2.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	
    if (!$usr_xkey) 
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{		
	  # ask_continue -title "Button4_2 - P2V_deactivate_user" -msg "P2V_lock_user" -button 0 -icon 64
	  write-Log -logtext "[$user] started P2V_deactivate_user -xkey $($global:usr_sel.SamAccountName)"
       P2V_deactivate_user -xkey $($global:usr_sel.SamAccountName) | out-string -Stream | foreach-object {
       $TextBox1.lines = $TextBox1.lines + $_
       $TextBox1.Select($TextBox1.Text.Length, 0)
       $TextBox1.ScrollToCaret()
       $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
       $Form.Refresh()
      }
	   $ProgressBar1.Value = 100   
	   $statusfield.backcolor ="0,192,0"
	   $statusfield.text= "finished !"
       $Form.Refresh()
	}
})

#-------------------------------------------------
#--  Button4_3 - Activate User
$Button4_3 = New-Object system.Windows.Forms.Button
$Button4_3.text = "Activate User"
$Button4_3.Enabled = $true
$Button4_3.width = 140
$Button4_3.height = 25
$Button4_3.location = New-Object System.Drawing.Point(15,300)
$Button4_3.Font = 'Microsoft Sans Serif, 8.25pt'

$Button4_3.Add_Click({
    $TextBox1.lines = $Button4_3.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()

	if (!$usr_xkey)
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{
		
	  # ask_continue -title "Button4_3 - P2V_activate_user" -msg "P2V_lock_user" -button 0 -icon 64
	  write-Log -logtext "[$user] started P2V_activate_user -xkey $($global:usr_sel.SamAccountName)"
       P2V_activate_user -xkey $($global:usr_sel.SamAccountName) | out-string -Stream | foreach-object {
       $TextBox1.lines = $TextBox1.lines + $_
       $TextBox1.Select($TextBox1.Text.Length, 0)
       $TextBox1.ScrollToCaret()
       $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
       $Form.Refresh()
      }
	   $ProgressBar1.Value = 100   
	   $statusfield.backcolor ="0,192,0"
	   $statusfield.text= "finished !"
       $Form.Refresh()
	}
})
#-------------------------------------------------
#--  Button5 - Check P2V AD groups
$Button5 = New-Object system.Windows.Forms.Button
$Button5.text = "sync user"
$Button5.Enabled = $True
$Button5.width = 140
$Button5.height = 25
$Button5.location = New-Object System.Drawing.Point(15,325)
$Button5.Font = 'Microsoft Sans Serif, 8.25pt'

$Button5.Add_Click({
   $TextBox1.lines = $Button5.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	if (!$usr_xkey)
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{
	# ask_continue -title "Button5_1 - P2V_sync_user" -msg "sync metadata" -button 0 -icon 64
	write-Log -logtext "[$user] started P2V_sync_user -xkey $($global:usr_sel.SamAccountName)"
    P2V_sync_user -xkey $($global:usr_sel.SamAccountName) | out-string -Stream | foreach-object {
    	$Textbox1.AppendText("$_`r`n")
        $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    #   $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	   $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	}
})
#-------------------------------------------------
#--  Button5_1 - Check P2V AD groups
$Button5_1 = New-Object system.Windows.Forms.Button
$Button5_1.text = "add / change profiles"
$Button5_1.Enabled = $True
$Button5_1.width = 140
$Button5_1.height = 25
$Button5_1.location = New-Object System.Drawing.Point(15,350)
$Button5_1.Font = 'Microsoft Sans Serif, 8.25pt'
$Button5_1.BackColor='IndianRed'

$Button5_1.Add_Click({
   $TextBox1.lines = $Button5_1.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	
	if (!$usr_xkey)
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{
	 #ask_continue -title "Button5 - P2V_set_profiles" -msg "add / change profiles" -button 0 -icon 64
	write-Log -logtext "[$user] started P2V_set_profiles "
    P2V_set_profiles| out-string -Stream | foreach-object {
    	$Textbox1.AppendText("$_`r`n")
        $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    #   $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	   $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	}
})
#-------------------------------------------------
#--  Button6 
$Button6 = New-Object system.Windows.Forms.Button
$Button6.text = "P2V Super Sync"
$Button6.Enabled = $true
$Button6.width = 140
$Button6.height = 25
$Button6.location = New-Object System.Drawing.Point(15,375)
$Button6.Font = 'Microsoft Sans Serif, 8.25pt'
$Button6.BackColor='IndianRed'

$Button6.Add_Click({
   $TextBox1.lines = $Button6.text 
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	
	#ask_continue -title "Button6 - P2V_super_sync" -msg "P2V Super Sync" -button 0 -icon 64
	if (!$usr_xkey)
	{
		ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
	}else
	{
		
	   ask_continue -title "Button6 - P2V_super_sync" -msg "P2V Super Sync" -button 0 -icon 64
	   write-Log -logtext "[$user] started P2V_super_sync -xkey $($global:usr_sel.SamAccountName) "
       P2V_super_sync -xkey $($global:usr_sel.SamAccountName) | out-string -Stream | foreach-object {
       $TextBox1.lines = $TextBox1.lines + $_
       $TextBox1.Select($TextBox1.Text.Length, 0)
       $TextBox1.ScrollToCaret()
       $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
       $Form.Refresh()
    }
	
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	}
	
})

#-------------------------------------------------
#--  Button7
$Button7 = New-Object system.Windows.Forms.Button
$Button7.text = "Check workgroup dep"
$Button7.Enabled = $true
$Button7.width = 140
$Button7.height = 25
$Button7.location = New-Object System.Drawing.Point(15,430)
$Button7.Font = 'Microsoft Sans Serif, 8.25pt'
$Button7.BackColor='IndianRed'

$Button7.Add_Click({
    $TextBox1.lines = $Button7.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	
	ask_continue -title "Button7 - P2V_calculate_groups_dependencies" -msg "Check workgroup dep" -button 0 -icon 64
	
	write-Log -logtext "[$user] started P2V_calculate_groups_dependencies"
    P2V_calculate_groups_dependencies| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	   $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#-------------------------------------------------
#--  Button8
$Button8 = New-Object system.Windows.Forms.Button
$Button8.text = "Check BD"
$Button8.Enabled = $true
$Button8.width = 140
$Button8.height = 25
$Button8.location = New-Object System.Drawing.Point(15,455)
$Button8.Font = 'Microsoft Sans Serif, 8.25pt'

$Button8.Add_Click({
    $TextBox1.lines = $Button8.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	ask_continue -title "Button8 - P2V_calculate_groups_bd" -msg "Check BDgroups" -button 0 -icon 64
	write-Log -logtext "[$user] started P2V_calculate_groups_bd "
    P2V_calculate_groups_bd| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
      $statusfield.text= "finished !"
	  $Form.Refresh()
	
	
})

#-------------------------------------------------
#--  Button9
$Button9 = New-Object system.Windows.Forms.Button
$Button9.text = "Check Templates"
$Button9.Enabled = $true
$Button9.width = 140
$Button9.height = 25
$Button9.location = New-Object System.Drawing.Point(15,480)
$Button9.Font = 'Microsoft Sans Serif, 8.25pt'
$Button9.BackColor='IndianRed'

$Button9.Add_Click({
    $TextBox1.lines = $Button9.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	
	ask_continue -title "Button9 - P2V_calculate_tmp_groups" -msg "Check Templates" -button 0 -icon 64
	write-Log -logtext "[$user] started P2V_calculate_tmp_groups "
    P2V_calculate_tmp_groups| out-string -Stream | foreach-object {
	  $Textbox1.AppendText("$_`r`n")
      $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
	  $Form.Refresh()
    }
	$ProgressBar1.Value = 100   
	$statusfield.text= "finished !"
    $Form.Refresh()
	
})


#-------------------------------------------------
#--  Button9_1
$Button9_1 = New-Object system.Windows.Forms.Button
$Button9_1.text = "lock inactive users"
$Button9_1.Enabled = $true
$Button9_1.width = 140
$Button9_1.height = 25
$Button9_1.location = New-Object System.Drawing.Point(15,505)
$Button9_1.Font = 'Microsoft Sans Serif, 8.25pt'
$Button9_1.BackColor='IndianRed'

$Button9_1.Add_Click({
    $TextBox1.lines = $Button9_1.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
    $Form.Refresh()
	
	ask_continue -title "Button9_1 - lock inactive users" -msg "lock inactive users" -button 0 -icon 64
	write-Log -logtext "[$user] started P2V_lock_inactive_users "
    P2V_lock_inactive_users| out-string -Stream | foreach-object {
	  $Textbox1.AppendText("$_`r`n")
      $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
	  $Form.Refresh()
    }
	$ProgressBar1.Value = 100   
	$statusfield.text= "finished !"
    $Form.Refresh()
	
})
#-------------------------------------------------
#--  Button10
$Button10 = New-Object system.Windows.Forms.Button
$Button10.text = "Export AD userlists"
$Button10.Enabled = $true
$Button10.width = 140
$Button10.height = 25
$Button10.location = New-Object System.Drawing.Point(15,530)
$Button10.Font = 'Microsoft Sans Serif, 8.25pt'

$Button10.Add_Click({
   $TextBox1.lines = $Button10.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
	$Form.Refresh()
	
	ask_continue -title "Button10 - P2V_export_AD_users" -msg "Export AD userlists" -button 0 -icon 64
	write-Log -logtext "[$user] started P2V_export_AD_users "
    P2V_export_AD_users| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#-------------------------------------------------
#--  Button11
$Button11 = New-Object system.Windows.Forms.Button
$Button11.text = "P2V_export_users"
$Button11.Enabled = $true
$Button11.width = 140
$Button11.height = 25
$Button11.location = New-Object System.Drawing.Point(15,555)
$Button11.Font = 'Microsoft Sans Serif, 8.25pt'

$Button11.Add_Click({
   $TextBox1.lines = $Button11.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
	$Form.Refresh()
	
	ask_continue -title "Button11 - P2V_export_users" -msg "P2V_export_users" -button 0 -icon 64
	write-Log -logtext "[$user] started P2V_export_users"
    P2V_export_users| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})


#-------------------------------------------------
#--  Button12 
$Button12 = New-Object system.Windows.Forms.Button
$Button12.text = "check UPNs"
$Button12.Enabled = $true
$Button12.width = 140
$Button12.height = 25
$Button12.location = New-Object System.Drawing.Point(15,580)
$Button12.Font = 'Microsoft Sans Serif, 8.25pt'

$Button12.Add_Click({
    $TextBox1.lines = $Button12.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
	$Form.Refresh()
	
ask_continue -title "Button12 - P2V_check_UPNs" -msg "Check UPNs and Department changes" -button 0 -icon 64
	write-Log -logtext "[$user] started P2V_check_UPNs "
    P2V_check_UPNs| out-string -Stream | foreach-object {
	
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
		
	
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#-------------------------------------------------
#--  Button13 
$Button13 = New-Object system.Windows.Forms.Button
$Button13.text = "sync AD-groups"
$Button13.Enabled = $true
$Button13.width = 140
$Button13.height = 25
$Button13.location = New-Object System.Drawing.Point(15,605)
$Button13.Font = 'Microsoft Sans Serif, 8.25pt'

$Button13.Add_Click({
   $TextBox1.lines = $Button13.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
	$Form.Refresh()
	
	#ask_continue -title "Button13 - P2V_check_data_access" -msg "sync AD-groups" -button 0 -icon 64
	  write-Log -logtext "[$user] started P2V_check_data_access "
	P2V_check_data_access|out-string -Stream| foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	
	
	
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#-------------------------------------------------
#--  Button14 
$Button14 = New-Object system.Windows.Forms.Button
$Button14.text = "check variables"
$Button14.Enabled = $true
$Button14.width = 140
$Button14.height = 25
$Button14.location = New-Object System.Drawing.Point(15,630)
$Button14.Font = 'Microsoft Sans Serif, 8.25pt'

$Button14.Add_Click({
   $TextBox1.lines = $Button14.text
    $ProgressBar1.Value=0
	$statusfield.backcolor="Control"
	$statusfield.text= "running ..."
	$Form.Refresh()
	
	#ask_continue -title "Button14 -check variables " -msg "Button14 selected - check variables" -button 0 -icon 64
	#(write-output ($global:usr_sel)+$linesep+(Get-Module -name "*P2V*")+$linesep+(Get-ADDomainController |select Hostname,Name,IPv4Address)+$linesep+(dir env:)+$linesep+ ($(import-csv $adgroupfile  )|convertto-json))	
	 
	 (write-output ($P2V_userlist)+$linesep+($ADgroup_members)+$linesep+($AD_userlist)      )|out-string -Stream| foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	Foreach ($i in $P2V_userlist.keys) {$P2V_userlist[$i].list|out-gridview -title "P2V userlist:$i / $($P2V_userlist[$i].createdate) /$($P2V_userlist[$i].count)" -wait  }
	Foreach ($i in $ADgroup_members.keys){$ADgroup_members[$i].list|out-gridview -title "AD groupmembers: $i / $($ADgroup_members[$i].createdate) /$($ADgroup_members[$i].count)" -wait  }
	Foreach ($i in $AD_userlist.keys) {$AD_userlist[$i].list|out-gridview -title "AD userlist from: $i / $($AD_userlist[$i].createdate) /$($AD_userlist[$i].count)" -wait  }
	
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#-------------------------------------------------
# --- Debugging setup ---
$global:P2V_Debug = $true # Set to $false to turn off debug globally

function Write-P2VDebug {
    param([string]$msg)
    if ($global:P2V_Debug) {
        if ($TextBox1) {
            $TextBox1.AppendText("DEBUG: $msg`r`n")
        } else {
            Write-Host "DEBUG: $msg"
        }
    }
}

# --- Assign Profile Button ---
$ButtonAssignProfile = New-Object System.Windows.Forms.Button
$ButtonAssignProfile.text = "Assign Profile"
$ButtonAssignProfile.Enabled = $true
$ButtonAssignProfile.width = 140
$ButtonAssignProfile.height = 25
$ButtonAssignProfile.location = New-Object System.Drawing.Point(15, 685)  # adjust as needed
$ButtonAssignProfile.Font = 'Microsoft Sans Serif, 8.25pt'

$ButtonAssignProfile.Add_Click({
    $TextBox1.AppendText("$($ButtonAssignProfile.text)`r`n")
    $ProgressBar1.Value = 0
    $statusfield.backcolor = "Control"
    $statusfield.text = "running ..."
    $Form.Refresh()

    Write-P2VDebug "Assign Profile button clicked"
    Write-P2VDebug "usr_xkey = $usr_xkey"
    Write-P2VDebug "global:usr_sel = $($global:usr_sel | Out-String)"

    if (!$usr_xkey) {
        ask_continue -title "missing user" -msg "Please select user first" -button 0 -icon 48
        $statusfield.text = "aborted !"
        $Form.Refresh()
        Write-P2VDebug "No user selected, aborting."
        return
    }

    try {
        Write-P2VDebug "Calling Assign-P2VProfile"
        Assign-P2VProfile -User $global:usr_sel | Out-String -Stream | ForEach-Object {
            $TextBox1.AppendText("$_`r`n")
            $TextBox1.Select($TextBox1.Text.Length, 0)
            $TextBox1.ScrollToCaret()
            $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
            $Form.Refresh()
        }
        Write-P2VDebug "Assign-P2VProfile completed"
        $ProgressBar1.Value = 100
        $statusfield.backcolor = "0,192,0"
        $statusfield.text = "finished !"
        $Form.Refresh()
    }
    catch {
        $TextBox1.AppendText("Error: $($_ | Out-String)`r`n")
        Write-P2VDebug "ERROR Exception: $($_ | Out-String)"
        $TextBox1.Select($TextBox1.Text.Length, 0)
        $TextBox1.ScrollToCaret()
        $ProgressBar1.Value = 100
        $statusfield.backcolor = "Red"
        $statusfield.text = "error !"
        $Form.Refresh()
    }
})

$Form.Controls.Add($ButtonAssignProfile)

#-------------------------------------------------
#--  Exitbutton
$ExitButton = New-Object system.Windows.Forms.Button
$ExitButton.text = "EXIT"
$ExitButton.width = 140
$ExitButton.height = 25
#$ExitButton.backcolor= "255,128,0"
$ExitButton.location = New-Object System.Drawing.Point(20,700)
$ExitButton.Font = 'Microsoft Sans Serif, 8.25pt, style=Bold'

$ExitButton.Add_Click({
   
   $form.Close()
})

#-------------------------------------------------
# -- Progressbar
$ProgressBar1 = New-Object system.Windows.Forms.ProgressBar
$ProgressBar1.width = 1000
$ProgressBar1.height = 20
$ProgressBar1.location = New-Object System.Drawing.Point(175,735)
$ProgressBar1.Maximum = 100
$ProgressBar1.Minimum = 0
$ProgressBar1.Value=0

$ProgressBar1.Anchor= "Bottom, Left, Right"

#-------------------------------------------------
# -- Statusfield
$statusfield = New-Object system.Windows.Forms.Label
$statusfield.width = 140
$statusfield.height = 20
$statusfield.location = New-Object System.Drawing.Point(15,735)
$statusfield.Font = 'Microsoft Sans Serif,10'
$statusfield.text=""
$statusfield.TextAlign = "MiddleCenter"
$statusfield.Anchor= "Top,left"
#$statusfield.BorderStyle = "FixedSingle"

#-------------------------------------------------
# -- Inputfield
$userinputBox = New-Object system.Windows.Forms.TextBox
$userinputBox.multiline = $false
$userinputBox.ReadOnly = $false
$userinputBox.width = 500
$userinputBox.height = 600
$userinputBox.location = New-Object System.Drawing.Point(660,20)
$userinputBox.Font = 'Lucida Console,9'
$userinputBox.Scrollbars = "None" 
$userinputBox.Anchor= "Top,left,Right"

#-------------------------------------------------
# -- Outputbox
$TextBox1 = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline = $true
$TextBox1.ReadOnly = $True
$TextBox1.width = 1000
$TextBox1.height = 600
$TextBox1.location = New-Object System.Drawing.Point(175,130)
$TextBox1.Font = 'Lucida Console,9'
$TextBox1.Backcolor = "255, 255, 220"
$TextBox1.Scrollbars = "Both" 
$TextBox1.Anchor= "Top, Bottom, Left, Right"
$TextBox1.add_TextChanged({
    $TextBox1.SelectionStart = $TextBox1.Text.Length
    $TextBox1.ScrollToCaret()
})

#-------------------------------------------------
#--  activate GUI
# EXCLUDED $Button8,
$Form.controls.AddRange(@($Button1,$Button2,$Button3,$Button4,$Button4_1,$Button4_2,$Button4_3,$Button5,$Button5_1,$Button6,$Button7,$Button8,$Button9,$Button9_1,$Button10,$Button11,$Button12,$Button13,$Button14,$ExitButton,$statusfield, $ProgressBar1,$TextBox1, $Logo, $Title,$UsageInfo,$selected_user,$groupbox1,$groupbox2))

# $form.Add_Shown({Paint_FocusBorder $Button1})


[void]$Form.ShowDialog()

# clean-up
# $obj_tt.Dispose()
$Form.Dispose()

Remove-Module P2V*

