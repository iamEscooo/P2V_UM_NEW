<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Untitled
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Mainmenu                        = New-Object system.Windows.Forms.Form
$Mainmenu.ClientSize             = New-Object System.Drawing.Point(699,545)
$Mainmenu.text                   = "search AD user"
$Mainmenu.TopMost                = $false

$Panel1                          = New-Object system.Windows.Forms.Panel
$Panel1.height                   = 55
$Panel1.width                    = 677
$Panel1.location                 = New-Object System.Drawing.Point(8,8)

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 238
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(185,22)
$TextBox1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "search"
$Button1.width                   = 178
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(485,10)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Enter searchstring"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(19,27)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "cancel"
$Button2.width                   = 234
$Button2.height                  = 30
$Button2.location                = New-Object System.Drawing.Point(232,510)
$Button2.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $true
$TextBox2.width                  = 673
$TextBox2.height                 = 400
$TextBox2.location               = New-Object System.Drawing.Point(8,102)
$TextBox2.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "output:"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(19,78)
$Label2.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Mainmenu.controls.AddRange(@($Panel1,$TextBox1,$Label1,$Button2,$TextBox2,$Label2))
$Panel1.controls.AddRange(@($Button1))

$Button2.Add_Click({ return  })
$Button2.Add_MouseClick({ return })
$Button1.Add_MouseClick({  })
$Button1.Add_Enter({  })
$Button1.Add_Click({  })


$mainmenu.ShowDialog()| Out-Null
