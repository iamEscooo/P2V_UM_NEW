$date = Get-Date -Format dd.MM.yyyy
$ver=Get-Date -Format hh.mm.ss



$Button1_Click = 
{
Write-host "Test Button1" -ForegroundColor Green
}

$button2_click
{}

$Button20_Click = 
{
Write-host "Test Button20" -ForegroundColor Green
}

$Button21_Click = 
{
Write-host "Test Button21" -ForegroundColor Green
}

$Button22_Click = 
{
Write-host "Test Button22" -ForegroundColor Green
}

$Button23_Click = 
{
Write-host "Test Button23" -ForegroundColor Green
}

$Button24_Click = 
{
Write-host "Test Button24" -ForegroundColor Green
}

$Button25_Click = 
{
Write-host "Test Button25" -ForegroundColor Green
}

$Button3_Click = 
{
           Write-host "Test Button3" -ForegroundColor Green
}

$Button4_Click = 
{
Write-host "Test Button4" -ForegroundColor Green
}

Function OUTPUT 
{
$showstatussh = {ping localhost}

       $textboxResults.Text = .$showstatussh

}

$Button6_Click = 
{
  Write-Host "Exiting..."
[Environment]::Exit(0)
}

Function EnableButton {
    $Button20.Enabled = $true
    $Button21.Enabled = $true
    $Button22.Enabled = $true
    $Button23.Enabled = $true
    $Button24.Enabled = $true
    $Button25.Enabled = $true
}
Function DisableButton {
    $Button20.Enabled = $false
    $Button21.Enabled = $false
    $Button22.Enabled = $false
    $Button23.Enabled = $false
    $Button24.Enabled = $false
    $Button25.Enabled = $false
}
Function Generate-Form {

    Add-Type -AssemblyName System.Windows.Forms    
    Add-Type -AssemblyName System.Drawing
    $Icon                            = New-Object system.drawing.icon ("\\somvat202005\PPS_share\P2V_scripts\omv.ico")

    # Build Form
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Windows form"
    $Form.Size = New-Object System.Drawing.Size(500,450)
    $Form.StartPosition = "CenterScreen"
    $Form.Topmost = $True
	$Form.Icon    = $Icon
    $okButton = New-Object System.Windows.Forms.Button

    # Add Button

    $Button2 = New-Object System.Windows.Forms.Button
    $Button2.Location = New-Object System.Drawing.Size(30,20)
    $Button2.Size = New-Object System.Drawing.Size(140,35)
    $Button2.Text = "Enable rights buttons"
    $Form.Controls.Add($Button2)

    $Button1 = New-Object System.Windows.Forms.Button
    $Button1.Location = New-Object System.Drawing.Size(30,60)
    $Button1.Size = New-Object System.Drawing.Size(140,35)
    $Button1.Text = "Button1"
    $Form.Controls.Add($Button1)
   
    $Button20 = New-Object System.Windows.Forms.Button
    $Button20.Location = New-Object System.Drawing.Size(200,20)
    $Button20.Size = New-Object System.Drawing.Size(160,35)
    $Button20.Text = "Disable rights buttons"
    $Button20.Enabled=$False
    $Form.Controls.Add($Button20)

    $Button21 = New-Object System.Windows.Forms.Button
    $Button21.Location = New-Object System.Drawing.Size(200,60)
    $Button21.Size = New-Object System.Drawing.Size(160,35)
    $Button21.Text = "Button21"
    $Button21.Enabled=$False
    $Form.Controls.Add($Button21)

    $Button22 = New-Object System.Windows.Forms.Button
    $Button22.Location = New-Object System.Drawing.Size(200,100)
    $Button22.Size = New-Object System.Drawing.Size(160,35)
    $Button22.Text = "Button22"
    $Button22.Enabled=$False
    $Form.Controls.Add($Button22)

    $Button23 = New-Object System.Windows.Forms.Button
    $Button23.Location = New-Object System.Drawing.Size(200,140)
    $Button23.Size = New-Object System.Drawing.Size(160,35)
    $Button23.Text = "Button23"
    $Button23.Enabled=$False
    $Form.Controls.Add($Button23)

    $Button24 = New-Object System.Windows.Forms.Button
    $Button24.Location = New-Object System.Drawing.Size(200,180)
    $Button24.Size = New-Object System.Drawing.Size(160,35)
    $Button24.Text = "Button24"
    $Button24.Enabled=$False
    $Form.Controls.Add($Button24)

    $Button25 = New-Object System.Windows.Forms.Button
    $Button25.Location = New-Object System.Drawing.Size(200,220)
    $Button25.Size = New-Object System.Drawing.Size(160,35)
    $Button25.Text = "Button25"
    $Button25.Enabled=$False
    $Form.Controls.Add($Button25)

    $Button3 = New-Object System.Windows.Forms.Button
    $Button3.Location = New-Object System.Drawing.Size(30,100)
    $Button3.Size = New-Object System.Drawing.Size(140,35)
    $Button3.Text = "Button3"
    $Form.Controls.Add($Button3)
    
    $Button4 = New-Object System.Windows.Forms.Button
    $Button4.Location = New-Object System.Drawing.Size(30,140)
    $Button4.Size = New-Object System.Drawing.Size(140,35)
    $Button4.Text = "Button4"
    $Form.Controls.Add($Button4)
    
    $Button5 = New-Object System.Windows.Forms.Button
    $Button5.Location = New-Object System.Drawing.Size(30,180)
    $Button5.Size = New-Object System.Drawing.Size(140,35)
    $Button5.Text = "Output"
    $Form.Controls.Add($Button5)

    $Button6 = New-Object System.Windows.Forms.Button
    $Button6.Location = New-Object System.Drawing.Size(30,220)
    $Button6.Size = New-Object System.Drawing.Size(140,35)
    $Button6.Text = "Quit"
    $Form.Controls.Add($Button6)

    <# $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,300)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Please enter the information in the space below:'
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,320)
    $textBox.Size = New-Object System.Drawing.Size(260,20)
    $form.Controls.Add($textBox) #>

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,350)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)


$textboxResults = New-Object System.Windows.Forms.TextBox
$textboxResults.Location = New-Object System.Drawing.Point(300,300)
$textboxResults.Size = New-Object System.Drawing.Size(180,100)
$textboxResults.MultiLine = $True 
$textboxResults.ScrollBars = "Vertical"

$Form.Controls.AddRange( $textboxResults)

    #Add Button event 
    $Button1.Add_Click($Button1_Click)
    $Button2.Add_Click({EnableButton})
    $Button20.Add_Click({DisableButton})
    $Button21.Add_Click($Button21_Click)
    $Button22.Add_Click($Button22_Click)
    $Button23.Add_Click($Button23_Click)
    $Button24.Add_Click($Button24_Click)
    $Button25.Add_Click($Button25_Click)
    $Button3.Add_Click($Button3_Click)
    $Button4.Add_Click($Button4_Click)
    $Button5.Add_Click({OUTPUT})
    $Button6.Add_Click($Button6_Click)



         #Show the Form 
    $form.ShowDialog()| Out-Null 




 } #End Function 

 #Call the Function 
Generate-Form