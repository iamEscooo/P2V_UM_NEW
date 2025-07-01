param(
    [string]$tenantUrl = "https://ips-test.ww.omv.com/P2V_DEMO",
    [string]$workingDir = "\\somvat202005\PPS_Share\P2V_scripts\output\TrainingGAE"
    )
	
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

$user=$env:UserDomain+"/"+$env:UserName 

#----- Set config variables

#$output_path = $output_path_base + "\AUCERNAusermgmt"
$output_path = "D:\P2V_scripts\AUCERNAusermgmt"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

# Function to invoke interactive login via browser
Function Get-PlanningSpaceAuthToken ($tenantUrl)
{
    Add-Type -AssemblyName System.Windows.Forms

    $tenantUrl = $tenantUrl.Trim("/") + "/"
    $url = [System.Uri]$tenantUrl
    $script:returnUrl = ""

    $authUrl = "{0}/identity/connect/authorize?response_type=token&state=foo&client_id={1}%20web&scope=planningspace&redirect_uri={2}loginCallback.html" `
        -f $url.GetLeftPart([System.UriPartial]::Authority), $url.Segments[1].Trim("/"), [System.Uri]::EscapeUriString($tenantUrl)

    $popupForm = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=500;Height=700}
    $browser  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Url=$authUrl}
    $completedHandler  = {
            $script:returnUrl = $browser.Url.AbsoluteUri
            if ($script:returnUrl -match "error=[^&]*|access_token=[^&]*")
            {
                $popupForm.Close() 
            }
    }
    
    $browser.Add_DocumentCompleted($completedHandler)
    $popupForm.Controls.Add($browser)
    $browser.Dock = [System.Windows.Forms.DockStyle]::Fill

    $popupForm.Add_Shown({$popupForm.Activate()})
    $popupForm.ShowDialog() | Out-Null

    [RegEx]::Match(([System.Uri]$script:returnUrl).Fragment, "(access_token=)(.*?)(&)").Groups[2].Value
}

# Function to validate working directory
Function Validate-WorkingDirectory($workingDir)
{
    $result = Test-Path $workingDir
    if (!$result)
    {
        Write-Error "Working directory $($workingDir) does not exist. Please create it first."
    }

    return $result
}

# Function to delete existing CSV files
Function Delete-ExistingCsvFiles($workgroupsFile, $usersFile, $userWorkgroupsFile)
{
    if (Test-Path $workgroupsFile) 
    {
        Remove-Item $workgroupsFile
    }
    if (Test-Path $usersFile)
    {
        Remove-Item $usersFile
    }
    if (Test-Path $userWorkgroupsFile)
    {
        Remove-Item $userWorkgroupsFile
    }
}

# Function to get all PlanningSpace workgroups
Function Get-PlanningSpaceWorkgroups($tenantUrl, $token)
{
    $apiUrl = $tenantUrl + "/PlanningSpace/api/v1/workgroups"
    $workgroups = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{'Authorization' = "Basic $base64AuthInfo"}  
    return $workgroups
}

# Function to get all PlanningSpace Windows AD users
Function Get-PlanningSpaceWindowsADUsers($tenantUrl, $token)
{
    $apiUrl = $tenantUrl + "/PlanningSpace/api/v1/users?include=UserWorkgroups"
    $users = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{'Authorization' = "Basic $base64AuthInfo"}  
    $P2Vusers = $users #| Where-Object { $_.authenticationMethod -ne "LOCAL" }
    return $P2Vusers
}

# Function to save PlanningSpace workgroups to CSV file
Function Save-WorkgroupsToCsv($workgroups, $workgroupsFile)
{
   #$workgroups|format-table
    Add-Content -Path $workgroupsFile -Value 'Id,Name,Description,Comments'
    $workgroups | Sort-Object -Property name | foreach { "$($_.id),$($_.name),$($_.description),$($_.comments)"| Out-File $workgroupsFile -Append }
}

# Function to save PlanningSapce users and user workgroups to CSV files
Function Save-UserAndUserWorkgroupsToCsv($users, $usersFile, $workgroupsFile)
{
    Add-Content -Path $usersFile -Value 'LogonId,authenticationMethod,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress'
    Add-Content -Path $userWorkgroupsFile -Value 'LogonId,Workgroup'
    $orderedUsers = $users | Sort-Object -Property logOnId
	
	$count_u=1
    foreach ($user in $orderedUsers)
    {
	    write-host -nonewline ($form1 -f ("[{0,5}/{1,5}] loading ..." -f $count_u++,$orderedUsers.count))"`r"	|out-host
		
        
		($user.logOnId + "," + $user.authenticationMethod + "," + $user.domain + "," + $user.displayName + "," + $user.description + "," + $user.isDeactivated + "," + $user.isAccountLocked + "," + $user.emailAddress) | Out-File $usersFile -Append
    
        $userWorkgroups = $user.userWorkgroups
        foreach($tmpWgs in $userWorkgroups)
        {
            $hash = @{}
            $tmpWgs | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($tmpWgs | SELECT -exp $_) }
        
            foreach($wg in ($hash.Values | Sort-Object -Property Name))
            {
                $groupsHash = @{}
                $wg | Get-Member -MemberType Properties | select -exp "Name" | % { $groupsHash[$_] = ($wg | SELECT -exp $_) }
                ($user.logOnId + "," + $groupsHash["name"])| Out-File $userWorkgroupsFile -Append
            }
        }
		
	    
    }
}


#------------------ START OF SCRIPT LOGIC -----------------------------

# Log summary of passed parameters
cls
$tenants=@{}

P2V_header -app $My_name -path $My_Path


# get tenants to sync
$tenants= select_PS_tenants
  
#  $tenants|%{$linesep;$($_.name)} ### ??????
   
#
$form1 -f " export user / workgroups from the tenants"
# $tenants.keys|% {$form1 -f " > $_"  }

#-- 1  check tenant /select tenant
foreach ($ts in $tenants.keys)
{
    $t=$tenants[$ts]
    $tenant=$t.tenant
	    
    $form1 -f ">>> $tenant <<<"|out-host
	
    $base64AuthInfo ="$($t.base64AuthInfo)"
	$tenantURL  ="$($t.ServerURL)/$($t.tenant)"
    $workingDir =$output_path +"\$tenant"

	# Initialize CSV file paths
    $workgroupsFile = $workingDir + "\P2V_$($tenant)_G.csv"
    $usersFile = $workingDir +"\P2V_$($tenant)_U.csv"
    $userWorkgroupsFile = $workingDir + "\P2V_$($tenant)_UG.csv"

	
    # Delete existing CSV file(s)
    createdir_ifnotexists ($output_path)
    createdir_ifnotexists ($workingDir)

    Delete-ExistingCsvFiles -workgroupsFile $workgroupsFile -usersFile $usersFile -userWorkgroupsFile $userWorkgroupsFile

    # Get all configured PlanngingSpace workgroups and users
    $form1 -f  "Getting all PlanningSpace workgroups and non-local users"|out-host
    $workgroups = Get-PlanningSpaceWorkgroups -tenantUrl $tenantUrl -token $base64AuthInfo 
    $P2Vusers = Get-PlanningSpaceWindowsADUsers -tenantUrl $tenantUrl -token $base64AuthInfo
    $form1 -f  "Finished getting all PlanningSpace workgroups and Windows AD users."|out-host
    #$workgroups
    # Save workgroups and users to CSV files
    $form1 -f  "Started saving workgroups and users to CSV files..."|out-host
    Save-WorkgroupsToCsv -workgroups $workgroups -workgroupsFile $workgroupsFile
    Save-UserAndUserWorkgroupsToCsv -users $P2Vusers -usersFile $usersFile -workgroupsFile $workgroupsFile
    $form1 -f  "Finished saving workgroups and users to CSV files."|out-host
    $form1 -f  "Workgroups: $($workgroupsFile)"|out-host
    $form1 -f  "Users: $($usersFile)"|out-host
    $form1 -f  "User Workgroups: $($userWorkgroupsFile)"|out-host
    $form1 -f  "Output Directory: $($workingDir)"|out-host
}

P2V_footer -app $my_name
pause