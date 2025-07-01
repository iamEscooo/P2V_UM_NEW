# PS-DataVizChart.ps1
# Functions to access the .NET DataVisualization.Charting library from PowerShell

# Thanks to https://www.sqlshack.com/create-charts-from-sql-server-data-using-powershell/
# for publishing these functions

# Before using these functions, you need to load the .NET code assembly into your active shell with the command:
#   Add-Type -AssemblyName "System.Windows.Forms.DataVisualization"

Function New-Chart() {
    param (
        [cmdletbinding()]
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $True)]
        [int]$width,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $True)]
        [int]$height,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [string]$ChartTitle,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [string]$ChartTitleFont = $null,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [System.Drawing.ContentAlignment]$ChartTitleAlign = [System.Drawing.ContentAlignment]::TopCenter,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [System.Drawing.Color]$ChartColor = [System.Drawing.Color]::White,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [boolean]$WithChartArea = $true,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [boolean]$WithChartLegend = $false
    )
    
    $CurrentChart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
    
    if($CurrentChart -eq $null) {
        throw "Unable to create Chart object"
    }
    
    $CurrentChart.Width         = $width 
    $CurrentChart.Height        = $height 
    $CurrentChart.BackColor     = $ChartColor
    
    if($WithChartArea) {
        $CurrentChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        
        if($CurrentChartArea -eq $null) {
            throw "Unable to create CharArea object"
        }
        $CurrentChart.ChartAreas.Add($CurrentChartArea)
    }
    
    if([String]::isNullOrEmpty($ChartTitleFont)) {
        $ChartTitleFont = "Arial,13pt"
    }
    
    if(-Not [String]::isNullOrEmpty($ChartTitle)) {
        [void]$CurrentChart.Titles.Add($ChartTitle)
        $CurrentChart.Titles[0].Font        = $ChartTitleFont
        $CurrentChart.Titles[0].Alignment   = $ChartTitleAlign
    }
    
    $CurrentChart
}

Function New-ChartSeries() {
    param (
        [cmdletbinding()]
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $True)]
        [String]$SeriesName,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [int]$BorderWidth = 3,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [boolean]$IsVisibleInLegend = $true,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [string]$ChartAreaName = $null,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [string]$LegendName    = $null,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [string]$HTMLColor     = $null,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]$ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
    )
    
    $CurrentChartSeries = New-Object  System.Windows.Forms.DataVisualization.Charting.Series
    
    if($CurrentChartSeries -eq $null) {
        throw "Unable to create Chart Series"
    }
    
    $CurrentChartSeries.Name                = $SeriesName
    $CurrentChartSeries.ChartType           = $ChartType 
    $CurrentChartSeries.BorderWidth         = $BorderWidth 
    $CurrentChartSeries.IsVisibleInLegend   = $IsVisibleInLegend 
    
    if(-Not([string]::isNullOrEmpty($ChartAreaName))) {
        $CurrentChartSeries.ChartArea = $ChartAreaName
    }
    
    if(-Not([string]::isNullOrEmpty($LegendName))) {
        $CurrentChartSeries.Legend = $LegendName
    }
    
    if(-Not([string]::isNullOrEmpty($HTMLColor))) {
        $CurrentChartSeries.Color = $HTMLColor
    }
    
    $CurrentChartSeries
}

function Display-Chart() {
    param (
        [cmdletbinding()]
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $True)]
        [System.Windows.Forms.DataVisualization.Charting.Chart]$Chart2Display,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [string]$Title = "New Chart",
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [int]$width,
        [parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, Mandatory = $False)]
        [int]$height
    )
    
    if($Chart2Display -eq $null) {
        throw "Null value provided for Chart2Display parameter"
    }
    
    $Chart2Display.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
                    [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    
    $WindowsFormObj         = New-Object Windows.Forms.Form
    $WindowsFormObj.Text    = $Title
    
    if($width -eq $null -or $width -lt $Chart2Display.Width) {
        $width = $Chart2Display.Width  * 1.2
    }
    
    if($height -eq $null -or $height -lt $Chart2Display.Height) {
        $height = $Chart2Display.Height * 1.2
    }
    
    $WindowsFormObj.Width   = $width
    $WindowsFormObj.Height  = $height
    
    $WindowsFormObj.Controls.Add($Chart2Display)
    $WindowsFormObj.Add_Shown({$WindowsFormObj.Activate()})
    #$WindowsFormObj.CenterToScreen()
    $WindowsFormObj.ShowDialog() | Out-Null
}
