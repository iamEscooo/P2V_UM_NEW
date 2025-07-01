#P2Vmenu_include.ps1
#
 # Based on: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
#

#xaml definitions

[xml]$xaml_start=@"
 <Window x:Class="WpfApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d"
        Title="INSERT_WINDOW_TITLE" Icon="INSERT_ICON_PATH" SizeToContent="WidthAndHeight" MaxHeight="800" MinHeight="200" MaxWidth="600" WindowStartupLocation="CenterScreen">
    <ScrollViewer Padding="10,0,10,10">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="150"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <!-- TODO: very hacky way to set maximum rows! -->
                <RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/>
            </Grid.RowDefinitions>
"@

[xml]$xaml_heading=@"
<TextBlock Text="INSERT_SECTION_HEADING" TextWrapping="Wrap" Grid.Row="INSERT_ROW" Grid.ColumnSpan="2" FontSize="25" Padding="5,10,0,5" /> 
"@

[xml]$xaml_item=@"            
<Button x:Name="INSERT_BUTTON_NAME" Grid.Row="INSERT_ROW" Grid.Column="0" Background="INSERT_BACKGROUND_COLOR" Foreground="INSERT_FOREGROUND_COLOR" MinHeight="50" VerticalAlignment="Top" Padding="10" Margin="0,5,0,5" >
<TextBlock TextWrapping="Wrap" TextAlignment="Center">INSERT_BUTTON_TEXT</TextBlock>
  </Button>
  <TextBlock TextWrapping="Wrap" Grid.Row="INSERT_ROW" Grid.Column="1" Padding="10,5,0,5" VerticalAlignment="Center">INSERT_DESCRIPTION</TextBlock> 
"@

[xml]$xaml_end=@"<Button x:Name="INSERT_BUTTON_NAME" Grid.Row="INSERT_ROW" Grid.Column="0" Background="INSERT_BACKGROUND_COLOR" Foreground="INSERT_FOREGROUND_COLOR" MinHeight="50" VerticalAlignment="Top" Padding="10" Margin="0,5,0,5" >
                <TextBlock TextWrapping="Wrap" TextAlignment="Center">INSERT_BUTTON_TEXT</TextBlock>
            </Button>
            <TextBlock TextWrapping="Wrap" Grid.Row="INSERT_ROW" Grid.Column="1" Padding="10,5,0,5" VerticalAlignment="Center">INSERT_DESCRIPTION</TextBlock>
"@


function Hide-Console {
    Write-Verbose 'Hiding PowerShell console...'
    # .NET method for hiding the PowerShell console window
    # https://stackoverflow.com/questions/40617800/opening-powershell-script-and-hide-command-prompt-but-not-the-gui
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) # 0 = hide
}

Function New-GuiHeading {
    param(
        [Parameter(Mandatory)][string]$name
    )
    #$string = Get-Content "$moduleRoot\xaml\heading.xaml"
	$string=$xaml_heading
    $string = $string.Replace('INSERT_SECTION_HEADING',(Get-XamlSafeString $name) )
    $string = $string.Replace('INSERT_ROW',$row)
    $script:row++

    return $string
}

Function New-GuiRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$item
    )
    Write-Verbose $item

    # $string = Get-Content "$moduleRoot\xaml\item.xaml"
	$string=$xaml_item
    $string = $string.Replace('INSERT_BACKGROUND_COLOR',$buttonBackgroundColor)
    $string = $string.Replace('INSERT_FOREGROUND_COLOR',$buttonForegroundColor)
    $string = $string.Replace('INSERT_BUTTON_TEXT',(Get-XamlSafeString $item.Name) )
    # Description is optional
    if ($item.Description) {
        $string = $string.Replace('INSERT_DESCRIPTION',(Get-XamlSafeString $item.Description) )
    }
    else {
        $string = $string.Replace('INSERT_DESCRIPTION','')
    }
    $string = $string.Replace('INSERT_BUTTON_NAME',$item.Reference)
    $string = $string.Replace('INSERT_ROW',$row)
    $script:row++

    return $string
}

Function Get-XamlSafeString {
    param(
        [Parameter(Mandatory)][string]$string
    )
    # https://docs.microsoft.com/en-us/dotnet/framework/wpf/advanced/how-to-use-special-characters-in-xaml
    # Order matters: &amp first
    $string = $string.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
    # Restore line breaks
    $string = $string -replace '&lt;\s*?LineBreak\s*?\/\s*?&gt;','<LineBreak />'

    return $string
}

Function New-GuiForm {
    # Based on: https://foxdeploy.com/2015/05/14/part-iii-using-advanced-gui-elements-in-powershell/
    param (
        [Parameter(Mandatory)][array]$inputXml # XML has not been converted to object yet
    )
    # Process raw XML
    $inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*','<Window'

    # Read XAML
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$xaml = $inputXML
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    try {
        $form = [Windows.Markup.XamlReader]::Load($reader)
    }
    catch {
        Write-Warning "Unable to parse XML!
Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them).
Note that this module does not currently work with PowerShell 7-preview and the VS Code integrated console."
        throw
    }

    # Load XAML button objects in PowerShell
    $script:buttons = @()
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        try {
            $script:buttons += $Form.FindName($_.Name)
        }
        catch {
            throw
        }
    }

    return $form
}

Function Invoke-ButtonAction {
    param(
        [Parameter(Mandatory)][string]$buttonName
    )
    Write-Verbose "$buttonName clicked"

    # Get relevant CSV row
    $csvMatch = $csvData | Where-Object {$_.Reference -eq $buttonName}
    Write-Verbose $csvMatch

    # Pipe match to Start-Script function
    # Lets us check CSV data via parameter validation
    try {
        $csvMatch | Start-Script -ErrorAction Stop
    }
    catch {
        Write-Error $_
    }
}

Function Start-Script {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateSet('cmd','powershell_file','powershell_inline','pwsh_file','pwsh_inline','exit')]
        [string]$method,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string]$command,

        [Parameter(ValueFromPipelineByPropertyName)][string]$arguments
    )
    if ($method -eq 'exit') {  exit}
    # Handle cmd first
    if ($method -eq 'cmd') {
        if ($arguments) {
            # Using .NET directly, as Start-Process adds a trailing space to arguments
            # https://social.technet.microsoft.com/Forums/en-US/97be1de5-f31e-416e-9752-ed60c39c0383/powershell-40-startprocess-adds-extra-space-to-commandline
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.FileName = $command
            $process.StartInfo.Arguments = $arguments
            # Set process working directory to PowerShell working directory
            # Mimics behaviour of exe called from cmd prompt
            $process.StartInfo.WorkingDirectory = $PWD
            $process.Start()
        }
        else {
            Start-Process -FilePath $command -Verbose:$verbose
        }
        return
    }

    # Begin constructing PowerShell arguments
    $psArguments = @()
    $psArguments += '-ExecutionPolicy Bypass'
    $psArguments += '-NoLogo'
    if ($noExit) {
        # Global -NoExit switch
        $psArguments += '-NoExit'
    }
    if ($arguments) {
        # Additional PS arguments from CSV
        # PowerShell doesn't seem to care if it gets the same argument twice
        $psArguments += $arguments
    }

    # Set Start-Process params according to CSV method
    $splitMethod = $method.Split('_')
    $encodedCommand = [Convert]::ToBase64String( [System.Text.Encoding]::Unicode.GetBytes($command) )
    switch ($splitMethod[0]) {
        powershell {
            $filePath = 'powershell.exe'
        }
        pwsh {
            $filePath = 'pwsh.exe'
        }
    }
    switch ($splitMethod[1]) {
        file {
            $psArguments += "-File `"$command`""
        }
        inline {
            $psArguments += "-EncodedCommand `"$encodedCommand`""
        }
    }

    # Launch process
    $psArguments | ForEach-Object { Write-Verbose $_ }
    Start-Process -FilePath $filePath -ArgumentList $psArguments -Verbose:$verbose
}


Function Show_P2Vmenu {
    <#
    .SYNOPSIS
        Use a CSV file to make a graphical menu of PowerShell scripts. Easy to customise and fast to launch.
    .DESCRIPTION
        Do you have favourite scripts that go forgotten?

        Does your organisation have scripts that would be useful to frontline staff who are not comfortable with the command line?

        This module uses a CSV file to make a graphical menu of PowerShell scripts.

        You can also add Windows programs and files to the menu.
    .PARAMETER csvPath
        Path to CSV file that defines the menu.

        See CSV reference: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    .PARAMETER windowTitle
        Custom title for the menu window.
    .PARAMETER buttonForegroundColor
        Custom button foreground (text) color.

        Hex codes (e.g. #C00077) and color names (e.g. Azure) are valid.

        See .NET Color Class: https://docs.microsoft.com/en-us/dotnet/api/system.windows.media.colors
    .PARAMETER buttonBackgroundColor
        Custom button background color.
    .PARAMETER iconPath
        Path to .ico file for use in menu.
    .PARAMETER hideConsole
        Hide the PowerShell console that the menu is called from.

        Note: This means you won't be able to see any errors from button clicks. If things aren't working, this should be the first thing you stop using.
    .PARAMETER noExit
        Start all PowerShell instances with -NoExit ("Does not exit after running startup commands.")

        Note: You can set -NoExit on individual menu items by using the Arguments column.

        See CSV reference: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    .EXAMPLE
        Show-ScriptMenuGui -csvPath '.\example_data.csv' -Verbose
    .NOTES
        Run New-ScriptMenuGuiExample to get some example files
    .LINK
        https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    #>
    #[CmdletBinding()]
    param(
        [string][Parameter(Mandatory)]$csvPath,
        [string]$windowTitle = 'PowerShell Script Menu',
        [string]$buttonForegroundColor = 'White',
        [string]$buttonBackgroundColor = '#366EE8',
        [string]$iconPath,
        [switch]$hideConsole,
        [switch]$noExit
    )
    Write-Verbose 'Show-P2Vmenu started'

    # -Verbose value, to pass to select cmdlets
    $verbose = $false
    try {
        if ($PSBoundParameters['Verbose'].ToString() -eq 'True') {
            $verbose = $true
        }
    }
    catch {}

    $csvData = Import-CSV -Path $csvPath -ErrorAction Stop
    Write-Verbose "Got $($csvData.Count) CSV rows"

    # Add unique Reference to each item
    # Used as x:Name of button and to look up action on click
    $i = 0
    $csvData | ForEach-Object {
        $_ | Add-Member -Name Reference -MemberType NoteProperty -Value "button$i"
        $i++
    }

    # Begin constructing XAML
    # $xaml = Get-Content "$moduleRoot\xaml\start.xaml"
	$xaml = $xaml_start
    $xaml = $xaml.Replace('INSERT_WINDOW_TITLE',$windowTitle)
    if ($iconPath) {
        # TODO: change taskbar icon?
        # WPF wants the absolute path
        $iconPath = (Resolve-Path $iconPath).Path
        $xaml = $xaml.Replace('INSERT_ICON_PATH',$iconPath)
    }
    else {
        # No icon specified
        $xaml = $xaml.Replace('Icon="INSERT_ICON_PATH" ','')
    }

    # Add CSV data to XAML
    # Row counter
    $script:row = 0
    # Not using Group-Object as PS7-preview4 does not preserve original order
    $sections = $csvData.Section | Where-Object {-not [string]::IsNullOrEmpty($_) } | Get-Unique
    # Generate GUI rows
    ForEach ($section in $sections) {
        Write-Verbose "Adding GUI Section: $section..."
        # Section Heading
        $xaml += New-GuiHeading $section
        $csvData | Where-Object {$_.Section -eq $section} | ForEach-Object {
            # Add items
            $xaml += New-GuiRow $_
        }
    }
    Write-Verbose 'Adding any items with blank Section...'
    $csvData | Where-Object { [string]::IsNullOrEmpty($_.Section) } | ForEach-Object {
        $xaml += New-GuiRow $_
        # TODO: spacing at top of window is untidy with no Sections (minor)
    }
    Write-Verbose "Added $($row) GUI rows"

    # Finish constructing XAML
    #$xaml += Get-Content "$moduleRoot\xaml\end.xaml"
	$xaml += $xaml_end

    Write-Verbose 'Creating XAML objects...'
    $form = New-GuiForm -inputXml $xaml

    Write-Verbose "Found $($buttons.Count) buttons"
    Write-Verbose 'Adding click actions...'
    ForEach ($button in $buttons) {
        $button.Add_Click( {
            # Use object in pipeline to identify script to run
            Invoke-ButtonAction $_.Source.Name
        } )
    }

    if ($hideConsole) {
        if ($global:error[0].Exception.CommandInvocation.MyCommand.ModuleName -ne 'PSScriptMenuGui') {
            # Do not hide console if there have been errors
            Hide-Console | Out-Null
        }
    }

    Write-Verbose 'Showing dialog...'
    $Form.ShowDialog() | Out-Null
}

Function New-ScriptMenuGuiExample {
    <#
    .SYNOPSIS
        Creates an example set of files for PSScriptMenuGui
    .PARAMETER path
        Path of output folder
    .EXAMPLE
        New-ScriptMenuGuiExample -path 'PSScriptMenuGui_example'
    .LINK
        https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    #>
    [CmdletBinding()]
    param (
        [string]$path = 'PSScriptMenuGui_example'
    )

    # Ensure folder exists
    if (-not (Test-Path -Path $path -PathType Container) ) {
        New-Item -Path $path -ItemType 'directory' -Verbose | Out-Null
    }

    Write-Verbose "Copying example files to $path..." -Verbose
    Copy-Item -Path "$moduleRoot\examples\*" -Destination $path
}

