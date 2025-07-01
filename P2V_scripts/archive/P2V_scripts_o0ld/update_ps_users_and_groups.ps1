param(
    [string]$tenantUrl = "https://ips-test.ww.omv.com/P2V_TRAINING",
    [string]$workingDir = "\\somvat202005\PPS_share\P2V_UM_data\output\AUCERNAusermgmt\P2V_TRAINING",
    [bool]$analyzeOnly = $True
)
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"
$user=$env:UserDomain+"/"+$env:UserName 

#----- Set config variables

$output_path = $output_path_base + "\AUCERNAusermgmt"
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
Function Validate-WorkingDirectory($workingDir_l)
{
    $result = Test-Path $workingDir_l
    if (!$result)
    {
        Write-Error " Working directory $($workingDir_l) does not exist."
    }

    return $result
}

# Function to validate CSV files
Function Validate-CsvFiles($workgroupsFile, $usersFile, $userWorkgroupsFile)
{
    $result = Test-Path $workgroupsFile
    if (!$result) 
    {
        Write-Error " Workgroups CSV file $($workgroupsFile) does not exist."
        return $result
    }

    $result = Test-Path $usersFile
    if (!$result)
    {
        Write-Error " Users CSV file $($usersFile) does not exist."
        return $result
    }

    $result = Test-Path $userWorkgroupsFile
    if (!$result)
    {
        Write-Error " User workgroups CSV file $($userWorkgroupsFile) does not exist."
        return $result
    }

    return $result
}

# Function to get all PlanningSpace workgroups
Function Get-PlanningSpaceWorkgroups($tenantUrl, $token)
{
    $apiUrl = $tenantUrl + "/PlanningSpace/api/v1/workgroups?include=Users"
     $workgroups = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers  @{'Authorization' = "Basic $base64AuthInfo"}  
	return $workgroups
}

# Function to get all PlanningSpace Windows AD users
Function Get-PlanningSpaceWindowsADUsers($tenantUrl, $token)
{
    $apiUrl = $tenantUrl + "/PlanningSpace/api/v1/users"
    $users = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{'Authorization' = "Basic $base64AuthInfo"}  
	$domainUsers = $users | Where-Object { $_.authenticationMethod -ne "LOCAL" }
    return $domainUsers
}

# Function to get workgroups from CSV file
Function Get-WorkgroupsFromCsv($workgroupsFile)
{
    $hash=@{}
    Import-Csv $workgroupsFile | %{ $hash[$_.Name] = $_ }
    return $hash
}

# Function to get users from CSV file
Function Get-UsersFromCsv($usersFile)
{
    $hash=@{}
    Import-Csv $usersFile | %{ $hash["$($_.Domain)\$($_.LogonId)"] = $_ }
    return $hash
}

# Function to get user workgroups from CSV file
Function Get-UserWorkgroupsFromCsv($userWorkgroupsFile)
{
    $hash=@{}
    Import-Csv $userWorkgroupsFile | %{ $hash["$($_.Domain)\$($_.LogonId)\$($_.Workgroup)"] = $_ }
    return $hash
}

# Function that does the main processing for users
Function Process-Users($usersFromCsv, $currentUsers, $analyzeOnly, $tenantUrl)
{
    $usersLookup=@{}
    $currentUsers | %{ $usersLookup["$($_.logOnId)"] = $_ }

    $newUsers = @()
    $updateOperations = @{}


    foreach($userKey in $usersFromCsv.Keys.GetEnumerator())
    {
        $userInCsv = $usersFromCsv[$userKey];

        if ($usersLookup.ContainsKey($userKey))
        {
            $existingUser = $usersLookup[$userKey];
            $usersLookup.Remove($userKey);

            $updateUserOperations = @()

            if ($userInCsv.Description -ne $existingUser.description)
            {
                Write-Output " [$($userKey)] Description will be changed to $($userInCsv.Description)"
                $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/description"
                    value = $userInCsv.Description
                }
            }   

            if($userInCsv.IsDeactivated -ne $existingUser.isDeactivated)
            {
                Write-Output " [$($userKey)] isDeactivated will be changed to $($userInCsv.IsDeactivated)"
                $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isDeactivated"
                    value = $userInCsv.IsDeactivated
                }
            }

            if($userInCsv.IsAccountLocked -ne $existingUser.isAccountLocked)
            {
                Write-Output " [$($userKey)] isAccountLocked will be changed to $($userInCsv.IsAccountLocked)"
                $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isAccountLocked"
                    value = $userInCsv.IsAccountLocked
                }
            }

            if($userInCsv.EmailAddress -ne $existingUser.emailAddress)
            {
                Write-Output " [$($userKey)] emailAddress will be changed to $($userInCsv.EmailAddress)"
                $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/emailAddress"
                    value = $userInCsv.EmailAddress
                }
            }

            if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$existingUser.id.ToString()] = $updateUserOperations                
            }                     
        }
        else
        {
            Write-Output " New user $($userKey) will be created."
            $newUsers += [PSCustomObject]@{
                logOnId = $userInCsv.LogOnId
                domain = $userInCsv.Domain
                displayName = $userInCsv.DisplayName
                description = $userInCsv.Description
                isDeactivated = $userInCsv.IsDeactivated
                isAccountLocked = $userInCsv.IsAccountLocked
                emailAddress = $userInCsv.EmailAddress
                authenticationMethod = "SAML2"
            }
        }       
    }

    foreach($nonExistingUserKey in $usersLookup.Keys.GetEnumerator())
    {
        Write-Warning " User $($nonExistingUserKey) exists in PlanningSpace but not in the users CSV file. Please check if this user needs to be removed."
    }

    if ($analyzeOnly)
    {
        return
    }

    $apiUrl = "$($tenantUrl)/planningspace/api/v1/users/bulk"
    $newUsers = @($newUsers)
    if ($newUsers.Count -gt 0)
    {
        Write-Output " Creating new users..."
        $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
        $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body (ConvertTo-Json @($newUsers)) -ContentType "application/json"
        Write-Output " Creation result:"
        $result | Write-Output
        Write-Output "Finished creating new users."
    }

    if ($updateOperations.Count -gt 0)
    {
        Write-Output "Updating existing users..."
        $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
        $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
        Write-Output " Update result:"
        $result | Write-Output
        Write-Output "Finished updating existing users."
    }
}

# Function that does the main processing for workgroups
Function Process-Workgroups($workgroupsFromCsv, $currentWorkgroups, $analyzeOnly, $tenantUrl)
{
    $workgroupsLookup=@{}
    $currentWorkgroups | %{ $workgroupsLookup[$($_.Name)] = $_ }

    $newWorkgroups = @()
    $updateOperations = @{}


    foreach($workgroupKey in $workgroupsFromCsv.Keys.GetEnumerator())
    {
        $workgroupInCsv = $workgroupsFromCsv[$workgroupKey];

        if ($workgroupsLookup.ContainsKey($workgroupKey))
        {
            $existingWorkgroup = $workgroupsLookup[$workgroupKey];
            $workgroupsLookup.Remove($workgroupKey);

            $updateWorkgroupOperations = @()

            if ($workgroupInCsv.Description -ne $existingWorkgroup.description)
            {
                Write-Output " [$($workgroupKey)] Description will be changed to $($workgroupInCsv.Description)"
                $updateWorkgroupOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/description"
                    value = $workgroupInCsv.Description
                }
            }   

            if($workgroupInCsv.Comments -ne $existingWorkgroup.comments)
            {
                Write-Output " [$($workgroupKey)] comments will be changed to $($workgroupInCsv.Comments)"
                $updateWorkgroupOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/comments"
                    value = $workgroupInCsv.Comments
                }
            }

            if ($updateWorkgroupOperations.Count -gt 0)
            {
                $updateOperations[$existingWorkgroup.id.ToString()] = $updateWorkgroupOperations                
            }                     
        }
        else
        {
            Write-Output " New workgroup $($workgroupKey) will be created."
            $newWorkgroups += [PSCustomObject]@{
                name = $workgroupInCsv.Name
                description = $workgroupInCsv.Description
                comments = $workgroupInCsv.Comments
            }
        }       
    }

    foreach($nonExistingWorkgroupKey in $workgroupsLookup.Keys.GetEnumerator())
    {
        Write-Warning " Workgroup $($nonExistingWorkgroupKey) exists in PlanningSpace but not in the workgroups CSV file. Please check if this workgroup needs to be removed."
    }

    if ($analyzeOnly)
    {
        return
    }

    $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
    $newWorkgroups = @($newWorkgroups)
    if ($newWorkgroups.Count -gt 0)
    {
        Write-Output " Creating new workgroups..."
        $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
        $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body (ConvertTo-Json @($newWorkgroups)) -ContentType "application/json"
        Write-Output " Creation result:"
        $result | Write-Output
        Write-Output "Finished creating new workgroups."
    }

    if ($updateOperations.Count -gt 0)
    {
        Write-Output "Updating existing users..."
        $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
        $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
        Write-Output " Update result:"
        $result | Write-Output
        Write-Output "Finished updating existing users."
    }
}

# Function that does the main processing for user workgroups
Function Process-UserWorkgroups($userWorkgroupsFromCsv, $currentWorkgroups, $currentUsers, $analyzeOnly, $tenantUrl)
{
    $workgroupsLookup=@{}
    $currentWorkgroups | %{ $workgroupsLookup[$($_.Name)] = $_ }

    $usersLookup=@{}
    $usersLookupByLogonId=@{}
    $currentUsers | %{ $usersLookup["$($_.id)"] = $_ }
    $currentUsers | %{ $usersLookupByLogonId["$($_.domain)\$($_.logOnId)"] = $_ }

    $updateOperations = @{}

    # first pass: check for users that are removed from workgroups
    foreach($currentWorkgroup in $currentWorkgroups)
    {   
        foreach($tmpUsers in $currentWorkgroup.users)
        {
            $hash = @{}
            $tmpUsers | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($tmpUsers | SELECT -exp $_) }

            foreach($userId in $hash.Keys)
            {
                if ($usersLookup.ContainsKey($userId))
                {
                    $user = $usersLookup[$userId]

                    if (!$userWorkgroupsFromCsv.ContainsKey("$($user.domain)\$($user.logonId)\$($currentWorkgroup.name)"))
                    {
                        if (!$currentWorkgroup.name -eq "Everyone")
                        {
                            Write-Output " $($user.domain)\$($user.logonId) will be removed from $($currentWorkgroup.name) workgroup"

                            if (!$updateOperations.ContainsKey("$($currentWorkgroup.id)"))
                            {
                                $updateOperations["$($currentWorkgroup.id)"] = @()
                            }
                            $updateOperations["$($currentWorkgroup.id)"] += [PSCustomObject]@{
                                op = "remove"
                                path = "/users/$($userId)"
                                value = ""
                            }
                        }                        
                    }
                    else
                    {
                        $userWorkgroupsFromCsv.Remove("$($user.domain)\$($user.logonId)\$($currentWorkgroup.name)")
                    }
                }                
            }
        }              
    }

    # second pass add users to workgroups
    foreach($userWorkgroupInCsv in $userWorkgroupsFromCsv.Values)
    {
        if ($workgroupsLookup.ContainsKey($userWorkgroupInCsv.Workgroup))
        {
            $user = $usersLookupByLogonId["$($userWorkgroupInCsv.Domain)\$($userWorkgroupInCsv.LogOnId)"]
            $workgroup = $workgroupsLookup[$userWorkgroupInCsv.Workgroup]

            if ($user -and !$user.isDeactivated)
            {
                if (!$updateOperations.ContainsKey("$($workgroup.id)"))
                {
                    $updateOperations["$($workgroup.id)"] = @()
                }
                $updateOperations["$($workgroup.id)"] += [PSCustomObject]@{
                    op = "add"
                    path = "/users/$($user.id)"
                    value = ""
                }

                Write-Output " $($user.domain)\$($user.logonId) will be added to $($workgroup.name) workgroup"
            }            
        }
    }

    if ($updateOperations.Count -gt 0 -and !$analyzeOnly)
    {
        Write-Output "Updating existing user workgroups..."
        $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
        $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
        $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{"Authorization"="Bearer " + $token} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
        Write-Output " Update result:"
        $result | Write-Output
        Write-Output "Finished updating existing user workgroups."
    }
}


#------------------ START OF SCRIPT LOGIC -----------------------------

# Log summary of passed parameters
cls

P2V_header -app $My_name -path $My_Path


#-- 1  check tenant /select tenant
if(!$tenant) {$t= P2V_get_tenant($tenantfile)}
$tenant=$t.tenant

$authURL    ="$($t.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t.name, $t.API)))
$tenantURL  ="$($t.ServerURL)/$($t.tenant)"
$workingDir =$output_path +"\$tenant"
# Initialize CSV file paths
$workgroupsFile = $workingDir + "\P2V_Workgroups.csv"
$usersFile = $workingDir +"\P2V_Users.csv"
$userWorkgroupsFile = $workingDir + "\P2V_UserWorkgroups.csv"
Write-Output "This script will only create new workgroups and users and update existing ones."
Write-Output "Please note that this script will only warn on workgroups and users that can possibly be deleted. Please login to PlanningSpace application to perform the actual deletion."
Write-Output ""
write-output "workingDIR = $workingdir"

# Initialize CSV file paths
$workgroupsFile = $workingDir + "\P2V_Workgroups.csv"
$usersFile = $workingDir +"\P2V_Users.csv"
$userWorkgroupsFile = $workingDir + "\P2V_UserWorkgroups.csv"

# Ensure that the working directory and CSV files exist
Write-Output "Validating working directory $($workingDir)..."
if (!(Validate-WorkingDirectory $workingDir))
{
    exit 
}
if (!(Validate-CsvFiles -workgroupsFile $workgroupsFile -usersFile $usersFile -userWorkgroupsFile $userWorkgroupsFile))
{
    exit
}
Write-Output "Finished validating working directory $($workingDir)."

# Load CSV files
Write-Output "Loading from input CSV files..."
$workgroupsFromCsv = Get-WorkgroupsFromCsv -workgroupsFile $workgroupsFile
$usersFromCsv = Get-UsersFromCsv -usersFile $usersFile
$userWorkgroupsFromCsv = Get-UserWorkgroupsFromCsv -userWorkgroupsFile $userWorkgroupsFile
Write-Output "Finished loading from input CSV files."

# Get authentication token interactively
# $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
# if (!$token)
# {
    # Write-Error "Failed to login to tenant $($tenantUrl)."
    # exit
# }

# Load current PlanningSpace workgroups and users
Write-Output "Getting current PlanningSpace workgroups and users..."
$currentWorkgroups = Get-PlanningSpaceWorkgroups -tenantUrl $tenantUrl -token $base64AuthInfo 
$currentUsers = Get-PlanningSpaceWindowsADUsers -tenantUrl $tenantUrl -token $base64AuthInfo
# $currentWorkgroups = Get-PlanningSpaceWorkgroups -tenantUrl $tenantUrl -token $token
# $currentUsers = Get-PlanningSpaceWindowsADUsers -tenantUrl $tenantUrl -token $token
Write-Output "Finished getting current PlanningSpace workgroups and users..."
Write-Output ""

# Process users
Write-Output "Processing new and updated users..."
Process-Users -usersFromCsv $usersFromCsv -currentUsers $currentUsers -analyzeOnly $analyzeOnly -tenantUrl $tenantUrl
Write-Output "Finished processing new and updated users."
Write-Output ""

# Process workgroups
Write-Output "Processing new and updated workgroups..."
Process-Workgroups -workgroupsFromCsv $workgroupsFromCsv -currentWorkgroups $currentWorkgroups -analyzeOnly $analyzeOnly -tenantUrl $tenantUrl
Write-Output "Finished processing new and updated workgroups."
Write-Output ""

# Process user workgroups
Write-Output "Processing updated user workgroups..."
$token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
$currentWorkgroups = Get-PlanningSpaceWorkgroups -tenantUrl $tenantUrl -token $token
$currentUsers = Get-PlanningSpaceWindowsADUsers -tenantUrl $tenantUrl -token $token
Process-UserWorkgroups -workgroupsFromCsv $workgroupsFromCsv -userWorkgroupsFromCsv $userWorkgroupsFromCsv -currentWorkgroups $currentWorkgroups -currentUsers $currentUsers -analyzeOnly $analyzeOnly -tenantUrl $tenantUrl
Write-Output "Finished processing updated user workgroups..."
Write-Output ""
