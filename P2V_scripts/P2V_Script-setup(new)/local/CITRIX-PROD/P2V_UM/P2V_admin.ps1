

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#-------------------------------------------------
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
  $My_Path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
  } else {
    $My_Path = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    if (!$My_Path){ $My_Path = "." }
  }
if (!$workdir) {$workdir=$My_Path}
. "$workdir/lib/P2V_include.ps1"

$user=$env:UserDomain+"/"+$env:UserName
$client=$env:ComputerName

#----- Set FORM variables

#---  main window ---
$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '1185,800'
$Form.text = "P2V-Admin"
$Form.Font = 'Microsoft Sans Serif,10'
$form.backcolor= "LightSteelBlue"
$Form.TopMost = $false
$Form.Icon="$workdir/P2V.ico"

#---- Title

$Title = New-Object system.Windows.Forms.Label

$Title.width = 400	
$Title.height = 30
$Title.location = New-Object System.Drawing.Point(175,20)
$Title.Font = 'Microsoft Sans Serif, 20.25pt, style=Bold'
$Title.Anchor= "Top,Bottom, Left, Right"
$Title.Text = "P2V Administration"

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
$UsageInfo.Font = 'Microsoft Sans Serif, 10pt'
$UsageInfo.backcolor= "LightSteelBlue"
$UsageInfo.multiline = $TRUE
$UsageInfo.ReadOnly = $TRUE
$UsageInfo.Anchor= "Top,Bottom, Left, Right"
$UsageInfo.TextAlign = "Right"
$UsageInfo.Lines  = "user: [$user]"
$UsageInfo.Lines += "computer: [$client]"
$UsageInfo.Lines += "started at: "+(get-date -format "[dd/MM/yyyy HH:mm:ss]")
$UsageInfo.BorderStyle="None"

#---- Dateinfo
$Dateinfo = New-Object system.Windows.Forms.Label

$Dateinfo.width = 400	
$Dateinfo.height = 20
$Dateinfo.location = New-Object System.Drawing.Point(775,50)
$Dateinfo.Font = 'Microsoft Sans Serif, 8.25pt'
$Dateinfo.Anchor= "Top,Bottom, Left, Right"
$Dateinfo.Text = "started at "
$Dateinfo.Text += 
$Dateinfo.TextAlign = "MiddleRight"

#--  Button1  - check Uptime
$Button1 = New-Object system.Windows.Forms.Button
$Button1.text = "Check Server Uptime"
$Button1.width = 140
$Button1.height = 40
$Button1.location = New-Object System.Drawing.Point(15,130)
$Button1.Font = 'Microsoft Sans Serif,10'

$Button1.Add_Click({
   $TextBox1.lines = "check server uptimes`n"
   $ProgressBar1.Value=0
   $statusfield.backcolor= "LightSteelBlue"
   $statusfield.text= "running ..."
   $Form.Refresh()
   . "$workdir/lib/admin_central_uptime.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value += 2
     $Form.Refresh()
    }
  $ProgressBar1.Value = 100
  $statusfield.backcolor ="0,192,0"
  $statusfield.text= "finished !"
  $Form.Refresh()
   #$TextBox1.Lines =(ping "www.google.com"| Out-String); $Form.Refresh()
  
})

#--  Button2 - check Uptime
$Button2 = New-Object system.Windows.Forms.Button
$Button2.text = "Check User Sessions"
$Button2.width = 140
$Button2.height = 40
$Button2.location = New-Object System.Drawing.Point(15,180)
$Button2.Font = 'Microsoft Sans Serif,10'

$Button2.Add_Click({
    $TextBox1.lines = "Check User Sessions"
    $ProgressBar1.Value=0
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/admin_central_check_user_session.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

 #--  Button3
$Button3 = New-Object system.Windows.Forms.Button
$Button3.text = "Check Servers"
$Button3.width = 140
$Button3.height = 40
$Button3.location = New-Object System.Drawing.Point(15,230)
$Button3.Font = 'Microsoft Sans Serif,10'

$Button3.Add_Click({
   $TextBox1.lines =$Button3.text
    $ProgressBar1.Value=0
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/admin_check_server.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
    
})

#--  Button4 - Check Browers versions
$Button4 = New-Object system.Windows.Forms.Button
$Button4.text = "Check Browers versions"
$Button4.width = 140
$Button4.height = 40
$Button4.location = New-Object System.Drawing.Point(15,280)
$Button4.Font = 'Microsoft Sans Serif,10'

$Button4.Add_Click({
   $TextBox1.lines = $Button4.text 
    $ProgressBar1.Value=0
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/admin_check_chrome.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#--  Button5 - Check P2V AD groups
$Button5 = New-Object system.Windows.Forms.Button
$Button5.text = "Check certificates"
$Button5.width = 140
$Button5.height = 40
$Button5.location = New-Object System.Drawing.Point(15,330)
$Button5.Font = 'Microsoft Sans Serif,10'

$Button5.Add_Click({
   $TextBox1.lines = $Button5.text
    $ProgressBar1.Value=0
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/admin_check_certificates.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#--  Button6 - Check IPS Server
$Button6 = New-Object system.Windows.Forms.Button
$Button6.text = "Check IPS Server"
$Button6.width = 140
$Button6.height = 40
$Button6.location = New-Object System.Drawing.Point(15,380)
$Button6.Font = 'Microsoft Sans Serif,10'

$Button6.Add_Click({
    $TextBox1.lines = $Button6.text
    $ProgressBar1.Value=0
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/admin_check_ips.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#--  Button7 - Check Admins
$Button7 = New-Object system.Windows.Forms.Button
$Button7.text = "Check Admins"
$Button7.width = 140
$Button7.height = 40
$Button7.location = New-Object System.Drawing.Point(15,430)
$Button7.Font = 'Microsoft Sans Serif,10'

$Button7.Add_Click({
    $TextBox1.lines = $Button7.text
    $ProgressBar1.Value=0
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/admin_check_P2V_admins.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#--  Button8 - check Uptime
$Button8 = New-Object system.Windows.Forms.Button
$Button8.text = "Check Lastlogin"
$Button8.width = 140
$Button8.height = 40
$Button8.location = New-Object System.Drawing.Point(15,480)
$Button8.Font = 'Microsoft Sans Serif,10'

$Button8.Add_Click({
    $TextBox1.lines = $Button8.text
    $ProgressBar1.Value=0
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
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})

#--  Button9 - P2V_export_AD_users.ps1
$Button9 = New-Object system.Windows.Forms.Button
$Button9.text = "Export AD userlists"
$Button9.width = 140
$Button9.height = 40
$Button9.location = New-Object System.Drawing.Point(15,530)
$Button9.Font = 'Microsoft Sans Serif,10'

$Button9.Add_Click({
    $TextBox1.lines = $Button9.text
    $ProgressBar1.Value=0
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/P2V_export_AD_users.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
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
$Button10.width = 140
$Button10.height = 40
$Button10.location = New-Object System.Drawing.Point(15,580)
$Button10.Font = 'Microsoft Sans Serif,10'

$Button10.Add_Click({
   $TextBox1.lines = $Button10.text
    $ProgressBar1.Value=0
	$statusfield.text= "running ..."
    $Form.Refresh()
  . "$workdir/lib/P2V_export_users.ps1"| out-string -Stream | foreach-object {
    $TextBox1.lines = $TextBox1.lines + $_
    $TextBox1.Select($TextBox1.Text.Length, 0)
    $TextBox1.ScrollToCaret()
    $ProgressBar1.Value = ($ProgressBar1.Value + 2 ) % 100
    $Form.Refresh()
    }
	  $ProgressBar1.Value = 100   
	  $statusfield.text= "finished !"
      $Form.Refresh()
	
	
})


#--  Exitbutton
$ExitButton = New-Object system.Windows.Forms.Button
$ExitButton.text = "Exit"
$ExitButton.width = 140
$ExitButton.height = 40
#$ExitButton.backcolor= "255,128,0"
$ExitButton.location = New-Object System.Drawing.Point(15,680)
$ExitButton.Font = 'Microsoft Sans Serif,10'

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
$statusfield.Anchor= "Top,Bottom,left"
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


#--  activate GUI

$Form.controls.AddRange(@($Button1,$Button2,$Button3,$Button4,$Button5,$Button6,$Button7,$Button8,$Button9,$Button10,$ExitButton,$statusfield, $ProgressBar1,$TextBox1, $Logo, $Title,$UsageInfo))

[void]$Form.ShowDialog()