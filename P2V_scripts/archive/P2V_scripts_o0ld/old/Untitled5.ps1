param(
  [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
  [bool]$analyzeOnly = $True
)
#-------------------------------------------------
#  Set config variables

#$workdir     = "\\somvat202005\PPS_Share\P2V_scripts"

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir + "\output\AD-groups"
$u_w_file= $output_path + "\Myuserworkgroup.csv"
$OMV_domain="ww"

function P2V_dialog 
{
<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Untitled
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form1                           = New-Object system.Windows.Forms.Form
$Form1.ClientSize                = '640,480'
$Form1.text                      = "Check P2V User account"
$Form1.TopMost                   = $false

$button1                         = New-Object system.Windows.Forms.Button
$button1.text                    = "Check user"
$button1.width                   = 100
$button1.height                  = 30
$button1.location                = New-Object System.Drawing.Point(115,435)
$button1.Font                    = 'Microsoft Sans Serif,10'
$button1.Add_Click({    })


$button2                         = New-Object system.Windows.Forms.Button
$button2.text                    = "Exit"
$button2.width                   = 100
$button2.height                  = 30
$button2.location                = New-Object System.Drawing.Point(425,435)
$button2.Font                    = 'Microsoft Sans Serif,10'
$button2.Add_Click({$Form1.Close()})

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "Check Active Directory"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 95
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(15,75)
$CheckBox1.Font                  = 'Microsoft Sans Serif,10'

$xkey                            = New-Object system.Windows.Forms.TextBox
$xkey.multiline                  = $false
$xkey.width                      = 100
$xkey.height                     = 20
$xkey.location                   = New-Object System.Drawing.Point(160,30)
$xkey.Font                       = 'Microsoft Sans Serif,10'

$Output                          = New-Object system.Windows.Forms.ListView
$Output.text                     = "listView"
$Output.width                    = 600
$Output.height                   = 300
$Output.location                 = New-Object System.Drawing.Point(15,120)

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Enter X-Key to check:"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(15,35)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Select Tenants to check:"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(344,35)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$CheckBox2                       = New-Object system.Windows.Forms.CheckBox
$CheckBox2.text                  = "Check Planningspace"
$CheckBox2.AutoSize              = $false
$CheckBox2.width                 = 95
$CheckBox2.height                = 20
$CheckBox2.location              = New-Object System.Drawing.Point(135,75)
$CheckBox2.Font                  = 'Microsoft Sans Serif,10'

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "comboBox"
$ComboBox1.width                 = 200
$ComboBox1.height                = 100
@('item1','item2','item3','item4') | ForEach-Object {[void] $ComboBox1.Items.Add($_)}
$ComboBox1.location              = New-Object System.Drawing.Point(350,60)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'

$Form1.controls.AddRange(@($button1,$button2,$CheckBox1,$TextBox1,$Output,$Label1,$Label2,$CheckBox2,$ComboBox1))


#main part
$Form1.Add_Shown({$Form1.Activate()})
[void]$Form1.ShowDialog()
}
 
 P2V_dialog ()