

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#-------------------------------------------------
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
  $My_Path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
  } else {
    $My_Path = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    if (!$My_Path){ $My_Path = "." }
  }
if (!$workdir) {$workdir=$My_Path;$libdir="$workdir\lib"}
. "$libdir\P2V_forms.ps1"
. "$libdir\P2V_include.ps1"
. "$libdir\check_userprofile.ps1"
. "$libdir\check_P2V_user.ps1"
. "$libdir\P2V_super_sync.ps1"
. "$libdir\P2V_export_AD_users.ps1"
. "$libdir\P2V_export_users.ps1"
. "$libdir\P2V_calculate_groups_dependencies.ps1"
. "$libdir\P2V_calculate_groups_bd.ps1"
. "$libdir\P2V_set_profiles.ps1"
. "$libdir\P2V_calculate_groups.ps1"

$user=$env:UserDomain+"/"+$env:UserName
$client=$env:ComputerName

$color_back = "Tan"

$usr_sel= @{}
$usr_xkey=""
#----- Set FORM variables
#----------------------------------------------------------------
#---  user searchstring input

#----------------------------------------------------------------

#---  main window ---
$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '1185,800'
$Form.text = "P2V Usermanagement"
$Form.Font = 'Microsoft Sans Serif,10'
$form.backcolor= $color_back
$Form.Formborderstyle = "Fixed3D"
$Form.MaximizeBox=$False
$Form.MinimizeBox=$False
$Form.TopMost = $false
$Form.Autovalidate ="EnableAllowFocusChange"
$Form.Icon="$workdir/P2V.ico"

#---- Title

$Title = New-Object system.Windows.Forms.Label

$Title.width = 400	
$Title.height = 30
$Title.location = New-Object System.Drawing.Point(175,20)
$Title.Font = 'Microsoft Sans Serif, 20pt, style=Bold'
$Title.Anchor= "Top, Left"
$Title.Text = "Plan2Value Usermanagement"

#---- Logo

$Logo = 
$Logo = New-Object system.Windows.Forms.PictureBox

$Logo.width = 100
$Logo.height = 100
$Logo.location = New-Object System.Drawing.Point(35,15)
$Logo.Image= New-Object System.Drawing.Bitmap "$workdir/P2V.png"
$Logo.Sizemode = "Zoom"
$Logo.Font = 'Microsoft Sans Serif,10'
$Logo.Anchor= "Top, Left"
$logo.BorderStyle="Fixed3D"

#---- Usageinfo

$UsageInfo = New-Object system.Windows.Forms.textbox

$UsageInfo.width = 400	
$UsageInfo.height = 100
$UsageInfo.location = New-Object System.Drawing.Point(775,20)
$UsageInfo.Font = 'Microsoft Sans Serif, 8.25pt'
$UsageInfo.backcolor= $color_back
$UsageInfo.multiline = $TRUE
$UsageInfo.ReadOnly = $TRUE
$UsageInfo.Anchor= "Top,Bottom, Left, Right"
$UsageInfo.TextAlign = "Right"
$UsageInfo.Lines  = "user: [$user]"
$UsageInfo.Lines += "computer: [$client]"
$UsageInfo.Lines += "started at: "+(get-date -format "[dd/MM/yyyy HH:mm:ss]")
$UsageInfo.BorderStyle="None"


#---- Usageinfo

$UserSelectedInfo = New-Object System.Windows.Forms.textbox


$UserSelectedInfo.width = 150	
$UserSelectedInfo.height = 470
$UserSelectedInfo.location = New-Object System.Drawing.Point(15,200)
$UserSelectedInfo.Font = 'Microsoft Sans Serif, 8.25pt'

$UserSelectedInfo.multiline = $TRUE
$UserSelectedInfo.ReadOnly = $TRUE
$UserSelectedInfo.Anchor= "Top,Bottom, Left, Right"
$UserSelectedInfo.TextAlign = "Left"
$UserSelectedInfo.Lines  =">> no user selected <<"
$UserSelectedInfo.Lines +=" "
$UserSelectedInfo.backcolor= $color_back
#$UserSelectedInfo.Items.Add("user: [$user]`ncomputer: [$client]")
#$UserSelectedInfo.Items.Add("started at: "+(get-date -format "[dd/MM/yyyy HH:mm:ss]"))
$UserSelectedInfo.BorderStyle="None"

#--  Button1  - check Uptime
$Button1 = New-Object system.Windows.Forms.Button
$Button1.text = "Select User"
$Button1.Enabled = $true
$Button1.width = 140
$Button1.height = 25
$Button1.location = New-Object System.Drawing.Point(15,130)
$Button1.Font = 'Microsoft Sans Serif, 8.25pt'


$Button1.Add_Click({
   $TextBox1.lines = $Button1.text+"`r`n"
   $ProgressBar1.Value=0
   $statusfield.backcolor=$color_back
   #$statusfield.text= "running ..."
   $global:usr_sel=""
   $Form.Refresh()
   if (($cont=get_AD_user_GUI -title "Check user profile") -eq "OK" )
   {
      #LISTBOX:  $UserSelectedInfo.Items.Add("$($global:usr_sel.displayname)")
	 $UserSelectedInfo.Lines  ="user selected:"
      $UserSelectedInfo.Lines +=" " 
	  $UserSelectedInfo.Lines  += "$($global:usr_sel.displayName)"
	  #$UserSelectedInfo.Lines += "$($global:usr_sel.SamAccountName)"
	    $UserSelectedInfo.Lines += "$($global:usr_sel.logOnId)"
	  #  $UserSelectedInfo.Lines += "$($global:usr_sel.EmailAddress)"
	  #  $UserSelectedInfo.Lines += "$($global:usr_sel.Department)"
	    #$UserSelectedInfo.Lines += "$($global:usr_sel.comment)"
	  
	  $UserSelectedInfo.Refresh()


      # $TextBox1.AppendText("searching [$($global:usr_sel.displayname)]-$($global:usr_sel.SamAccountName)`n")
      # $Form.Refresh()
      # check_userprofile -xkey $($global:usr_sel.SamAccountName)| out-string -Stream | foreach-object {
	   # $Textbox1.AppendText("$_`r`n")
       # $ProgressBar1.Value = ($ProgressBar1.Value + 1 ) % 100
      $Form.Refresh()
      # }
      # $ProgressBar1.Value = 100
	  # $statusfield.backcolor ="0,192,0"
      # $statusfield.text= "finished !"
      # $Form.Refresh()
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
<# $Button1.Add_Click({
   $TextBox1.lines = $Button1.text+"`r`n"
   $ProgressBar1.Value=0
   $statusfield.backcolor="Control"
   $statusfield.text= "running ..."
   $Form.Refresh()
  
   if (($cont=get_AD_user_GUI -title "Check user profile") -eq "OK" )
   {
      $TextBox1.AppendText("searching [$($global:usr_sel.displayname)]-$($global:usr_sel.SamAccountName)`n")
      $Form.Refresh()
      check_userprofile -xkey $($global:usr_sel.SamAccountName)| out-string -Stream | foreach-object {
	   $Textbox1.AppendText("$_`r`n")
       $ProgressBar1.Value = ($ProgressBar1.Value + 1 ) % 100
    #   $Form.Refresh()
      }
      $ProgressBar1.Value = 100
	  $statusfield.backcolor ="0,192,0"
      $statusfield.text= "finished !"
      $Form.Refresh()
   } else
   {
	  $statusfield.text= "aborted !"
      $Form.Refresh()
   }
   # {
   #   $TextBox1.lines = $TextBox1.lines + "cancelled by user ..."   
   #   $ProgressBar1.Value = 100
   #   $statusfield.text= "cancelled by user !"
   #   $Form.Refresh()
   #} 
})
#>
#--  Button2 - check Uptime
$Button2 = New-Object system.Windows.Forms.Button
$Button2.text = "Check P2V User Profile"
$Button2.Enabled = $true
$Button2.width = 140
$Button2.height = 25
$Button2.location = New-Object System.Drawing.Point(175,100)
$Button2.Font = 'Microsoft Sans Serif, 8.25pt'

$Button2.Add_Click({
    $TextBox1.lines = $Button2.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
	  
    if (($cont=get_AD_user_GUI -title "Check P2V user profile") -eq "OK" )
    {
      #$TextBox1.AppendText("searching [$($global:usr_sel.displayname)]-$($global:usr_sel.SamAccountName)`n")
      #$Form.Refresh()
      check_P2V_user  -xkey $($global:usr_sel.SamAccountName)| out-string -Stream | foreach-object {
       $Textbox1.AppendText("$_`r`n")
	   $ProgressBar1.Value = ($ProgressBar1.Value + 1 ) % 100
     #  $Form.Refresh()
      }
      $ProgressBar1.Value = 100
	   $statusfield.backcolor ="0,192,0"
      $statusfield.text= "finished !"
      $Form.Refresh()
    } else
   {
	  $statusfield.text= "aborted !"
      $Form.Refresh()
   } 
	  	
})

 #--  Button3
$Button3 = New-Object system.Windows.Forms.Button
$Button3.text = "P2V Super Sync"
$Button3.Enabled = $true
$Button3.width = 140
$Button3.height = 25
$Button3.location = New-Object System.Drawing.Point(330,100)
$Button3.Font = 'Microsoft Sans Serif, 8.25pt'

$Button3.Add_Click({
   $TextBox1.lines =$Button3.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
    P2V_super_sync| out-string -Stream | foreach-object {
	       $Textbox1.AppendText("$_`r`n")
           $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    #       $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
	    
})

#--  Button4 - Check IPS Server
$Button4 = New-Object system.Windows.Forms.Button
$Button4.text = "apply profiles"
$Button4.Enabled = $true
$Button4.width = 140
$Button4.height = 25
$Button4.location = New-Object System.Drawing.Point(485,100)
$Button4.Font = 'Microsoft Sans Serif, 8.25pt'

$Button4.Add_Click({
    $TextBox1.lines = $Button4.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
    P2V_set_profiles| out-string -Stream | foreach-object {
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

#--  Button5 - Check P2V AD groups
$Button5 = New-Object system.Windows.Forms.Button
$Button5.text = "Check workgroup dep"
$Button5.Enabled = $True
$Button5.width = 140
$Button5.height = 25
$Button5.location = New-Object System.Drawing.Point(640,100)
$Button5.Font = 'Microsoft Sans Serif, 8.25pt'

$Button5.Add_Click({
   $TextBox1.lines = $Button5.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
    P2V_calculate_groups_dependencies| out-string -Stream | foreach-object {
    	$Textbox1.AppendText("$_`r`n")
        $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    #   $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	   $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
})

#--  Button6 - Check Browers versions
$Button6 = New-Object system.Windows.Forms.Button
$Button6.text = "Check BD "
$Button6.Enabled = $true
$Button6.width = 140
$Button6.height = 25
$Button6.location = New-Object System.Drawing.Point(795,100)
$Button6.Font = 'Microsoft Sans Serif, 8.25pt'

$Button6.Add_Click({
   $TextBox1.lines = $Button6.text 
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
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

#--  Button7 - Check Admins
$Button7 = New-Object system.Windows.Forms.Button
$Button7.text = "Check Templates"
$Button7.Enabled = $true
$Button7.width = 140
$Button7.height = 25
$Button7.location = New-Object System.Drawing.Point(950,100)
$Button7.Font = 'Microsoft Sans Serif, 8.25pt'

$Button7.Add_Click({
    $TextBox1.lines = $Button7.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
    P2V_calculate_tmp_groups| out-string -Stream | foreach-object {
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

#--  Button8 - check Uptime
$Button8 = New-Object system.Windows.Forms.Button
$Button8.text = "action1"
$Button8.Enabled = $false
$Button8.width = 140
$Button8.height = 25
$Button8.location = New-Object System.Drawing.Point(1105,100)
$Button8.Font = 'Microsoft Sans Serif, 8.25pt'

$Button8.Add_Click({
    $TextBox1.lines = $Button8.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/admin_check_P2V_lastlogin.ps1"| out-string -Stream | foreach-object {
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

#--  Button9 - P2V_export_AD_users.ps1
$Button9 = New-Object system.Windows.Forms.Button
$Button9.text = "Export AD userlists"
$Button9.Enabled = $true
$Button9.width = 140
$Button9.height = 25
$Button9.location = New-Object System.Drawing.Point(15,410)
$Button9.Font = 'Microsoft Sans Serif, 8.25pt'

$Button9.Add_Click({
    $TextBox1.lines = $Button9.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
    P2V_export_AD_users| out-string -Stream | foreach-object {
	  $Textbox1.AppendText("$_`r`n")
      $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
	  $Form.Refresh()
    }
	$ProgressBar1.Value = 100   
	$statusfield.text= "finished !"
    $Form.Refresh()
	
})

#--  Button10 - P2V_export_users
$Button10 = New-Object system.Windows.Forms.Button
$Button10.text = "P2V_export_users"
$Button10.Enabled = $true
$Button10.width = 140
$Button10.height = 25
$Button10.location = New-Object System.Drawing.Point(15,445)
$Button10.Font = 'Microsoft Sans Serif, 8.25pt'

$Button10.Add_Click({
   $TextBox1.lines = $Button10.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
	$Form.Refresh()
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

#--  Button11 - P2V_export_users
$Button11 = New-Object system.Windows.Forms.Button
$Button11.text = "P2V sync status"
$Button11.Enabled = $true
$Button11.width = 140
$Button11.height = 25
$Button11.location = New-Object System.Drawing.Point(15,480)
$Button11.Font = 'Microsoft Sans Serif, 8.25pt'

$Button11.Add_Click({
   $TextBox1.lines =$Button11.text
    $ProgressBar1.Value=0
	$statusfield.backcolor=$color_back
	$statusfield.text= "running ..."
    $Form.Refresh()
    P2V_super_sync -xkey $($global:usr_sel.SamAccountName) | out-string -Stream | foreach-object {
	       $Textbox1.AppendText("$_`r`n")
           $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    #       $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.backcolor ="0,192,0"
	  $statusfield.text= "finished !"
      $Form.Refresh()
})
#--  Exitbutton
$ExitButton = New-Object system.Windows.Forms.Button
$ExitButton.text = "Exit"
$ExitButton.width = 140
$ExitButton.height = 25
#$ExitButton.backcolor= "255,128,0"
$ExitButton.location = New-Object System.Drawing.Point(15,680)
$ExitButton.Font = 'Microsoft Sans Serif, 8.25pt'

$ExitButton.Add_Click({
   
   $form.Close()
})

# -- Progressbar
$ProgressBar1 = New-Object system.Windows.Forms.ProgressBar
$ProgressBar1.width = 1000
$ProgressBar1.height = 20
$ProgressBar1.location = New-Object System.Drawing.Point(175,735)
$ProgressBar1.Maximum = 100
$ProgressBar1.Minimum = 0
$ProgressBar1.Value=0

$ProgressBar1.Anchor= "Bottom, Left, Right"

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
#--  activate GUI
# EXCLUDED $Button8,
$Form.controls.AddRange(@($Button1,$Button2,$Button3,$Button4,$Button5,$Button6,$Button7,$Button9,$Button10,$Button11,$ExitButton,$statusfield, $ProgressBar1,$TextBox1, $Logo, $Title,$UsageInfo,$UserSelectedInfo))

[void]$Form.ShowDialog()