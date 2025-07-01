#region Setup
param (
  [string]$menufile,               # path to menu-definition FILE
  [string]$fcolor  = 'White',      # foregroundcolor
  [string]$bcolor  = '#003366',    # backgroundcolor
  [string]$xamldir = '',          # path to xaml directory
  [string]$system  = '',           # System
  [switch]$help,                   # show help
  [switch]$h,                      # show help
  [switch]$v                       # verbose mode - more chatty
  )

<#
.SYNOPSIS
	P2V_menu displays a menu based on an CSV configuration file
.DESCRIPTION
	P2V_menu displays a menu based on an CSV configuration file.
	Based on the great menu script from 
	Based on: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
	just added an "EXIT" option

.PARAMETER menufile <filename>
	CSV file 
	
.PARAMETER xamldir <directory>
	CSV file 
	
.PARAMETER fcolor  <colorcode>
	foregroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.PARAMETER bcolor  <colorcode>
	backgroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
	Detail on what the script does, if this is needed.

#>
# +--- local functions ---+
function show_usage
{
 write-host 
 "P2V_menu  -menufile '<file_name>' [-fcolor '<colorcode>'] [-bcolor '<colorcode>'] [-xamldir '<directory>']  [-system '<system>'] [-v] [[-h]|[-help]]"
 write-host ""
 write-host " -menufile <file_name> : Path to CSV file that defines the menu"
 
 write-host " -fcolor  <colorcode>  : forgroundcolor of menubuttons  "
 write-host "                         colorcode = colorname like 'lightblue'  or HEXcode like #003366"
 
 write-host " -bcolor  <colorcode>  : backgroundcolor of menubuttons"
 write-host "                         colorcode = colorname like 'lightblue'  or HEXcode like #003366"
 
 write-host " -xamldir <directory>  : path to config directory"
 
 write-host " -system  <system>     : one of < 'P2V_DEV', 'P2V_TEST', 'P2V_TRAINING', 'P2V_UPDATE', 'P2V_PROD' >"
 write-host " -v                    : (verbose) app to be more chatty .."
 write-host " -h, -help             : this message"
 write-host ""
 write-host ""
 pause
}

# $system is one of
# DEV
# TEST
# TRAINING
# UPDATE
# PROD
#-------------------------------------------------

#--- P2vmenu_include  begin ---
#P2Vmenu_include.ps1
#
 # Based on: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
#



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
    $string = Get-Content "$xamldir\heading.xaml"
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

    $string = Get-Content "$xamldir\item.xaml"
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
    if ($method -eq 'exit') { $Form.Close(); exit}
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
            # Start-Process -FilePath $command -Verbose:$verbose
			& $command 
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
    $xaml = Get-Content "$xamldir\start.xaml"
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
    $xaml += Get-Content "$xamldir\end.xaml"
	
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
    #$Form.Add_Closing({$_.Cancel = $true})
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

#--- P2vmenu_include  end ---
#---------- M A I N   P A R T --------------

if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript")
 { $My_path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }
 else
 { $My_path  = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0]) 
     if (!$My_path ){ $My_path  = "." } }

#$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
#$My_path=Split-Path $($MyInvocation.MyCommand.Path)

if ($h -or $help) {show_usage ; exit}

if (!$menufile) {$menufile= Read-Host "> Please enter menu-file "}
if (!(Test-path $menufile)){write-host "menufile $menufile not found`n";show_usage ; exit}

if (!$xamldir) 
{
  if ($v) {"overwrite xamldir [$xamldir] "}
  $xamldir="$My_Path\xaml"
}
#if (!$moduleRoot) {$moduleRoot="$workdir\xaml" }
if (!$menufile) {show_usage ; exit}
if ($v)
{
"+-- check --+`n
 xamldir    : [$xamldir]
 menufile   : [$menufile]
 bcolor     : [$bcolor]
 fcolor     : [$fcolor]
 system     : [$system]
 moduleroot : [$moduleroot]
"|out-host
pause
}
# check variables


#  . "$workdir\P2Vmenu_include.ps1"  OLD call ext. lib -file
$user=$env:UserDomain+"/"+$env:UserName
$client=$env:ComputerName
  
$system_args =@{}
  
$system_args["DEV"] = @{   
bgcolor  =  '#966482';
fgcolor  =  "black";   
wintitle =  "Plan2Value Development: [$user@$client]";
menufile =  "$workdir\config\P2V_dev.menu"  
} 
  
$system_args["TEST"] = @{
   bgcolor =  "";
   fgcolor =  "";
   wintitle = "Plan2Value Test: [$user@$client]";
   menufile =  "$workdir\config\P2V_test.menu"
} 
$system_args["TRAINING"] = @{
   bgcolor =  "";
   fgcolor =  "";
   wintitle = "Plan2Value Training: [$user@$client]";
   menufile =  "$workdir\config\P2V_training.menu"
} 
$system_args["UPDATE"] = @{
   bgcolor =  "";
   fgcolor =  "";
   wintitle = "Plan2Value Update: [$user@$client]";
   menufile =  "$workdir\config\P2V_update.menu"
} 
$system_args["PROD"] = @{
   bgcolor =  "";
   fgcolor =  "";
   wintitle = "Plan2Value PRODUCTION: [$user@$client]";
   menufile =  "$workdir\config\P2V_prod.menu"
} 

#966482
 
#Set-Location $PSScriptRoot
# Remove-Module PSScriptMenuGui -ErrorAction SilentlyContinue
# try {
    # Import-Module PSScriptMenuGui -ErrorAction Stop
# }
# catch {
    # Write-Warning $_
    # Write-Verbose 'Attempting to import from parent directory...' -Verbose
    # Import-Module '..\'
# }
#endregion

#call menu
$win_title="Plan2Value $system ["+$user+"@"+$client+"]"
#$win_title
$menu_args = @{
    csvPath = $menufile
    windowTitle = "$win_title"
    buttonForegroundColor = $fcolor
    buttonBackgroundColor = $bcolor
    iconPath = '.\P2V.ico'
    hideConsole = $false
    noExit = $false
    Verbose = $v
}
#Show-ScriptMenuGui @menu_args
write-host "opening menu-configuration from`n$menufile"
Show_P2Vmenu @menu_args
