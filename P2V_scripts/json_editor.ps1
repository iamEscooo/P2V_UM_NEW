Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "JSON Editor"
$form.Size = New-Object System.Drawing.Size(1200, 600)
$form.StartPosition = "CenterScreen"

# Create a DataGridView control
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10, 10)
$dataGridView.Size = New-Object System.Drawing.Size(1100, 500)
$dataGridView.AllowUserToAddRows = $true

$form.Controls.Add($dataGridView)

# Create an open file button
$buttonOpenFile = New-Object System.Windows.Forms.Button
$buttonOpenFile.Location = New-Object System.Drawing.Point(10, 520)
$buttonOpenFile.Size = New-Object System.Drawing.Size(100, 25)
$buttonOpenFile.Text = "Open File"
$filePath = $null
$buttonOpenFile.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "JSON Files (*.json)|*.json"
    $openFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
    $result = $openFileDialog.ShowDialog()
    
    if ($result -eq "OK") {
        $filePath = $openFileDialog.FileName
        $json = Get-Content -Path $filePath | ConvertFrom-Json
        
        # Create a DataTable to hold the JSON data
        $dataTable = New-Object System.Data.DataTable
        
        # Add columns to the DataTable for members' details
        $dataTable.Columns.Add("xkey") | Out-Null
        $dataTable.Columns.Add("DisplayName") | Out-Null
        $dataTable.Columns.Add("logonID") | Out-Null
        $dataTable.Columns.Add("Requestdate") | Out-Null
        $dataTable.Columns.Add("Description") | Out-Null
        $dataTable.Columns.Add("Comment") | Out-Null
        
        # Add columns to the DataTable for additional fields
        $dataTable.Columns.Add("BDID") | Out-Null
        $dataTable.Columns.Add("BDname") | Out-Null
        $dataTable.Columns.Add("Bdcontact") | Out-Null
        $dataTable.Columns.Add("Comment2") | Out-Null
        $dataTable.Columns.Add("Approval") | Out-Null
        
        # Add rows to the DataTable for members' details
        foreach ($item in $json) {
            $item.Members | ForEach-Object {
                $row = $dataTable.NewRow()
                $row["xkey"] = $_.xkey
                $row["DisplayName"] = $_.DisplayName
                $row["logonID"] = $_.logonID
                $row["Requestdate"] = $_.Requestdate
                $row["Description"] = $_.Description
                $row["Comment"] = $_.Comment
                $row["BDID"] = $item.BDID
                $row["BDname"] = $item.BDname
                $row["Bdcontact"] = $item.Bdcontact
                $row["Comment2"] = $item.Comment
                $row["Approval"] = $item.Approval
                $dataTable.Rows.Add($row)
            }
        }
        
        # Bind the DataTable to the DataGridView
        $dataGridView.DataSource = $dataTable
        
        # Adjust the column widths
        $dataGridView.AutoResizeColumns([System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells)
        $dataGridView.Columns["BDID"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
        $dataGridView.Columns["BDname"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
        $dataGridView.Columns["Bdcontact"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
        $dataGridView.Columns["Comment2"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
        $dataGridView.Columns["Approval"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
    }
})
$form.Controls.Add($buttonOpenFile)

# Create a save button
$buttonSave = New-Object System.Windows.Forms.Button
$buttonSave.Location = New-Object System.Drawing.Point(120, 520)
$buttonSave.Size = New-Object System.Drawing.Size(100, 25)
$buttonSave.Text = "Save"
$buttonSave.Add_Click({
    if ($dataGridView.DataSource) {
        $dataTable = $dataGridView.DataSource
        
        # Create a new JSON object
        $newJson = @()
        
        # Convert the DataTable back to a JSON array
        $groupedData = $dataTable | Group-Object -Property BDID
        foreach ($group in $groupedData) {
            $item = [PSCustomObject]@{
                "BDID" = $group.Group[0].BDID
                "BDname" = $group.Group[0].BDname
                "Bdcontact" = $group.Group[0].Bdcontact
                "Comment" = $group.Group[0].Comment2
                "Approval" = $group.Group[0].Approval
                "Members" = $group.Group | Select-Object -Property xkey, DisplayName, logonID, Requestdate, Description, Comment
            }
            
            $newJson += $item
        }
        
        # Convert the JSON object to JSON string
        $jsonString = $newJson | ConvertTo-Json -Depth 100
        
        # Create a SaveFileDialog to specify the file path for saving
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.Filter = "JSON Files (*.json)|*.json"
        $saveFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
        $result = $saveFileDialog.ShowDialog()
        
        if ($result -eq "OK") {
            $saveFilePath = $saveFileDialog.FileName
            
            # Save the JSON string to the file
            $jsonString | Set-Content -Path $saveFilePath -Encoding UTF8
        }
    }
})
$form.Controls.Add($buttonSave)

# Show the form
$form.ShowDialog()
