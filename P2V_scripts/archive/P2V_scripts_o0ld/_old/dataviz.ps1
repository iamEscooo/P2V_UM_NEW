# Palantir IPS Admin API
# PowerShell script example: Create a simple chart of data from the Server Monitor API

# Uses the .NET DataVisualization.Charting library
# Thanks to https://www.sqlshack.com/create-charts-from-sql-server-data-using-powershell/
# for the chart functions New-Chart, New-ChartSeries and Display-Chart

# Before using this script you need to:
#  1. Load the .NET code assembly into your shell with the command:
#      Add-Type -AssemblyName "System.Windows.Forms.DataVisualization"
#  2. Load the script 'PS-DataVizChart.ps1' containing the chart functions


# Get data from the IPS Admin API
$serverUrl = 'https://ips-test.ww.omv.com'

# API request must use dates expressed in Epoch Time (i.e. the number of seconds since 01/01/1970)
$dateMinus1day =[math]::Round((Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s)) - (3600*24)
$dat = Invoke-RestMethod -Uri "$serverUrl/monitor/api/metricgroups/1/servers/1/historicaldata?startDate=$dateMinus1day" -UseDefaultCredentials

<# DATA TO BE PLOTTED
N = $dat.timeline.count
X points = $dat.timeline
Y points = $dat.metricData[0].data
Y axis title = $dat.metricData[0].metricItemName
#>

# Create a chart object
$ChartTitle      = ("IPS Server Monitor - Server 1 - last 24 hours - {0}" -f $dat.metricData[0].metricItemName)
$Chart1 = New-Chart -width 1024 -height 800 -ChartTitle $ChartTitle -WithChartArea $true -WithChartLegend $false
$ChartSeriesType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
$ChartSeriesHTMLColor = $null

# Chart area settings
$Chart1.ChartAreas[0].Name              = "DefaultArea"
$Chart1.ChartAreas[0].AxisY.Title       = $dat.metricData[0].metricItemName
$Chart1.ChartAreas[0].AxisX.Title       = "Time"
$Chart1.ChartAreas[0].AxisX.LabelStyle.Format = "yyyy-MM-dd HH:mm"
  
# Chart Legend  
# [NOT USED]
#$ChartLegend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
#$ChartLegend.name = "Chart Legend"
#$Chart1.Legends.Add($ChartLegend)

# Chart Series creation
$ChartSeries = New-ChartSeries -SeriesName "Series" -LegendName "Chart Legend" –ChartAreaName "DefaultArea" -ChartType $ChartSeriesType -HTMLColor $ChartSeriesHTMLColor
$Chart1.Series.Add($ChartSeries)
 
Foreach ($i in 1..$dat.timeline.count) {
    [void]$Chart1.Series["Series"].Points.AddXY(
        (Get-Date -Date "01/01/1970").AddSeconds($dat.timeline[$i-1]), $dat.metricData[0].data[$i-1] 
        # converting Epoch Time values in $dat to date-time objects
    )
}

# Display the chart object
Display-Chart -Chart2Display $Chart1 -Title 'IPS Server monitor $serverUrl'
