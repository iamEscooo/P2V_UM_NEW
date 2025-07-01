################################################################################ 
#
#  Name    : \\somvat202005\pps_share\P2V_scripts\P2V_UM_20x\\Form1.ps1  
#  Version : 0.1
#  Author  :
#  Date    : 5/30/2025
#
 #  Generated with ConvertForm module version 2.0.0
#  PowerShell version 5.1.14393.8062
#
#  Invocation Line   : Convert-Form -path $s -destination $d -encoding ascii -force
#  Source            : \\somvat202005\pps_share\P2V_scripts\P2V_UM_20x\P2V_UM\Form1.Designer.cs
################################################################################

function Get-ScriptDirectory
{ #Return the directory name of this script
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

$ScriptPath = Get-ScriptDirectory

# Loading external assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$P2V_UM_form1 = New-Object System.Windows.Forms.Form

$progressBar1 = New-Object System.Windows.Forms.ProgressBar
$textBox1 = New-Object System.Windows.Forms.TextBox
$label1 = New-Object System.Windows.Forms.Label
$checkBox1 = New-Object System.Windows.Forms.CheckBox
$button1 = New-Object System.Windows.Forms.Button
$radioButton1 = New-Object System.Windows.Forms.RadioButton
#
# progressBar1
#
$progressBar1.Location = New-Object System.Drawing.Point(60, 666)
$progressBar1.Name = "progressBar1"
$progressBar1.Size = New-Object System.Drawing.Size(618, 23)
$progressBar1.TabIndex = 0
#
# textBox1
#
$textBox1.Location = New-Object System.Drawing.Point(174, 95)
$textBox1.Name = "textBox1"
$textBox1.Size = New-Object System.Drawing.Size(100, 20)
$textBox1.TabIndex = 1
#
# label1
#
$label1.AutoSize = $true
$label1.Location = New-Object System.Drawing.Point(171, 79)
$label1.Name = "label1"
$label1.Size = New-Object System.Drawing.Size(35, 13)
$label1.TabIndex = 2
$label1.Text = "label1"
#
# checkBox1
#
$checkBox1.AutoSize = $true
$checkBox1.Location = New-Object System.Drawing.Point(91, 171)
$checkBox1.Name = "checkBox1"
$checkBox1.Size = New-Object System.Drawing.Size(80, 17)
$checkBox1.TabIndex = 3
$checkBox1.Text = "checkBox1"
$checkBox1.UseVisualStyleBackColor = $true
#
# button1
#
$button1.Location = New-Object System.Drawing.Point(319, 231)
$button1.Name = "button1"
$button1.Size = New-Object System.Drawing.Size(75, 23)
$button1.TabIndex = 4
$button1.Text = "button1"
$button1.UseVisualStyleBackColor = $true
#
# radioButton1
#
$radioButton1.AutoSize = $true
$radioButton1.Location = New-Object System.Drawing.Point(121, 303)
$radioButton1.Name = "radioButton1"
$radioButton1.Size = New-Object System.Drawing.Size(85, 17)
$radioButton1.TabIndex = 5
$radioButton1.TabStop = $true
$radioButton1.Text = "radioButton1"
$radioButton1.UseVisualStyleBackColor = $true

function OnCheckedChanged_radioButton1 {
	[void][System.Windows.Forms.MessageBox]::Show("The event handler radioButton1.Add_CheckedChanged is not implemented.")
}

$radioButton1.Add_CheckedChanged( { OnCheckedChanged_radioButton1 } )

#
# P2V_UM_form1
#
$P2V_UM_form1.ClientSize = New-Object System.Drawing.Size(935, 716)
$P2V_UM_form1.Controls.Add($radioButton1)
$P2V_UM_form1.Controls.Add($button1)
$P2V_UM_form1.Controls.Add($checkBox1)
$P2V_UM_form1.Controls.Add($label1)
$P2V_UM_form1.Controls.Add($textBox1)
$P2V_UM_form1.Controls.Add($progressBar1)
$P2V_UM_form1.Name = "P2V_UM_form1"
$P2V_UM_form1.Text = "Select 1"

function OnFormClosing_P2V_UM_form1{ 
	# $this parameter is equal to the sender (object)
	# $_ is equal to the parameter e (eventarg)

	# The CloseReason property indicates a reason for the closure :
	#   if (($_).CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing)

	#Sets the value indicating that the event should be canceled.
	($_).Cancel= $False
}

$P2V_UM_form1.Add_FormClosing( { OnFormClosing_P2V_UM_form1} )

$P2V_UM_form1.Add_Shown({$P2V_UM_form1.Activate()})
$ModalResult=$P2V_UM_form1.ShowDialog()
# Release the Form
$P2V_UM_form1.Dispose()
