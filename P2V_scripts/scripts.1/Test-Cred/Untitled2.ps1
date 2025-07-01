#Generated Form Function
function GenerateForm1 {

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$form1 = New-Object System.Windows.Forms.Form
$richTextBox1 = New-Object System.Windows.Forms.RichTextBox
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
$handler_form1_Load= 
{
    #$richTextBox1.Text = "Das ist ein Testlink: file:///C:\windows\explorer.exe"
    $richTextBox1.Text = "General Purpose P2V request: https://omv.service-now.com/sp?id=sc_cat_item&sys_id=0f8009641bec559023805352604bcbf6"
}

$handler_richTextBox1_LinkClicked= 
{
    start $_.LinkText
}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$form1.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 296
$System_Drawing_Size.Width = 438
$form1.ClientSize = $System_Drawing_Size
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$form1.Name = "form1"
$form1.Text = "DataGridView Link Column Beispiel"
$form1.add_Load($handler_form1_Load)

$richTextBox1.Anchor = 15
$richTextBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 12
$richTextBox1.Location = $System_Drawing_Point
$richTextBox1.Name = "richTextBox1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 272
$System_Drawing_Size.Width = 414
$richTextBox1.Size = $System_Drawing_Size
$richTextBox1.TabIndex = 0
$richTextBox1.Text = ""

$richTextBox1.add_LinkClicked($handler_richTextBox1_LinkClicked)

$form1.Controls.Add($richTextBox1)

#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm1

