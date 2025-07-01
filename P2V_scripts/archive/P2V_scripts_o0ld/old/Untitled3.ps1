[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,400)  

############################################## Start functions

function procInformation {

$wks = $DropDownBox.SelectedItem.ToString()

try {
$prcInfo = gwmi win32_processor -computer $wks -ErrorAction STOP

if ($procName.Checked -eq $true) {$Name = "Proc type: $($prcInfo.Name)"}
if ($procLoad.Checked -eq $true) {$Load = "Proc load: $($prcInfo.LoadPercentage) %"}
if ($procSpeed.Checked -eq $true) {$Freq = "Proc frequency: $($prcInfo.CurrentClockSpeed) MHz"}

$outputBox.text = "$Name `n$Load `n$Freq" 

       } #end try

catch {$outputBox.text = "`nOperation could not be completed"}

                           } # end procInformation                  

############################################## end functions

############################################## Start group boxes

$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Location = New-Object System.Drawing.Size(250,20) 
$groupBox.size = New-Object System.Drawing.Size(130,100) 
$groupBox.text = "Processor Info:" 
$Form.Controls.Add($groupBox) 

############################################## end group boxes

############################################## Start check boxes

$procName = New-Object System.Windows.Forms.checkbox
$procName.Location = New-Object System.Drawing.Size(10,20)
$procName.Size = New-Object System.Drawing.Size(100,20)
$procName.Checked = $true
$procName.Text = "Type"
$groupBox.Controls.Add($procName)

$procLoad = New-Object System.Windows.Forms.checkbox
$procLoad.Location = New-Object System.Drawing.Size(10,40)
$procLoad.Size = New-Object System.Drawing.Size(100,20)
$procLoad.Text = "Load"
$groupBox.Controls.Add($procLoad)

$procSpeed = New-Object System.Windows.Forms.checkbox
$procSpeed.Location = New-Object System.Drawing.Size(10,60)
$procSpeed.Size = New-Object System.Drawing.Size(100,20)
$procSpeed.Text = "Frequency"
$groupBox.Controls.Add($procSpeed)

############################################## end check boxes

############################################## Start drop down boxes

$DropDownBox = New-Object System.Windows.Forms.ComboBox
$DropDownBox.Location = New-Object System.Drawing.Size(20,50) 
$DropDownBox.Size = New-Object System.Drawing.Size(180,20) 
$DropDownBox.DropDownHeight = 200 
$Form.Controls.Add($DropDownBox) 

$wksList=@("hrcomputer1","hrcomputer2","hrcomputer3","workstation1","workstation2","computer5","localhost")

foreach ($wks in $wksList) {
                      $DropDownBox.Items.Add($wks)
                              } #end foreach

############################################## end drop down boxes

############################################## Start text fields

$outputBox = New-Object System.Windows.Forms.RichTextBox 
$outputBox.Location = New-Object System.Drawing.Size(10,150) 
$outputBox.Size = New-Object System.Drawing.Size(565,200) 
$outputBox.MultiLine = $True 

$outputBox.ScrollBars = "Vertical" 
$Form.Controls.Add($outputBox) 

############################################## end text fields

############################################## Start buttons

$Button = New-Object System.Windows.Forms.Button 
$Button.Location = New-Object System.Drawing.Size(400,30) 
$Button.Size = New-Object System.Drawing.Size(110,80) 
$Button.Text = "Get Processor Info" 
$Button.Add_Click({procInformation}) 
$Form.Controls.Add($Button) 

############################################## end buttons

$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()