param(
    [string]$tenantUrl = "https://ips-test.ww.omv.com/P2V_TRAINING",
    [string]$workingDir = "\\somvat202005\PPS_share\P2V_UM_data\",
    [bool]$analyzeOnly = $False
)
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"
$user=$env:UserDomain+"/"+$env:UserName 

#----- Set config variables

$output_path = $output_path_base + "\AUCERNAusermgmt"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

Function Get-FileName($initialDirectory)
{ #Function to get filename
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
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
Function Validate-CsvFile($checkfile)
{
    $result = Test-Path $checkfile
    if (!$result) 
    {
        Write-Error "CSV file $($checkfile) does not exist."
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
	$domainUsers = $users #| Where-Object { $_.authenticationMethod -ne "LOCAL" }
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
    Import-Csv $usersFile | %{ $hash["$($_.LogonId)"] = $_ }
    return $hash
}

# Function to get user workgroups from CSV file
Function Get-UserWorkgroupsFromCsv($userWorkgroupsFile)
{
    $hash=@{}
    Import-Csv $userWorkgroupsFile | %{ $hash["$($_.LogonId)\$($_.Workgroup)"] = $_ }
    return $hash
}

# Function that does the main processing for users
Function Process-Users($usersFromCsv, $currentUsers, $analyzeOnly, $tenant)
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
                authenticationMethod = $userInCsv.authenticationMethod
            }
        }       
    }

    foreach($nonExistingUserKey in $usersLookup.Keys.GetEnumerator())
    {
        Write-Warning " User $($nonExistingUserKey) exists in PlanningSpace but not in the users CSV file. Please check if this user needs to be removed."
    }
	if (($cont=read-host ($form1 -f "deactivate [$($usersLookup.Count)] users? (y/n)")) -like "y")	
	{
        foreach($nonExistingUserKey in $usersLookup.Keys.GetEnumerator())
        {
           Write-host " deactivating user $($nonExistingUserKey)"
		   
		   
        }	
	    	
	}
    
	if (($cont=read-host ($form1 -f "add [$($newUsers.Count)] users? (y/n)")) -notlike "y")	
    #if ($analyzeOnly)
    {
        return
    }

    $apiUrl = "$($tenantUrl)/planningspace/api/v1/users/bulk"
    $newUsers = @($newUsers)
    if ($newUsers.Count -gt 0)
    {
        Write-Output " Creating new users..."
		$newUsers|format-table|out-host
		pause
        
        $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body (ConvertTo-Json @($newUsers)) -ContentType "application/json"
        Write-Output " Creation result:"
        $result |% { write-host "$($_.key) :";$($_.value).response|format-list }
		get-type $result
        Write-Output "Finished creating new users."
    }

    if ($updateOperations.Count -gt 0)
    {
        Write-Output "Updating existing users..."
        #$token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
        $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
        Write-Output " Update result:"
        $result | Write-Output
        Write-Output "Finished updating existing users."
    }
}

# Function that does the main processing for workgroups
Function Process-Workgroups($workgroupsFromCsv, $currentWorkgroups, $analyzeOnly, $tenant)
{
    $workgroupsLookup=@{}
    $currentWorkgroups | %{ $workgroupsLookup[$($_.Name)] = $_ }

    $newWorkgroups = @()
    $updateOperations = @{}


    foreach($workgroupKey in $workgroupsFromCsv.Keys.GetEnumerator())
    {
	    $wg_change=$false
        $workgroupInCsv = $workgroupsFromCsv[$workgroupKey];

        if ($workgroupsLookup.ContainsKey($workgroupKey))
        {
		   
            $existingWorkgroup = $workgroupsLookup[$workgroupKey];
            $workgroupsLookup.Remove($workgroupKey);

            $updateWorkgroupOperations = @()

            if ($workgroupInCsv.Description -ne $existingWorkgroup.description)
            {
			    if (!$wg_change) {$form1 -f "";$form_status -f "[$($workgroupKey)]","[CHANGE]";$wg_change=$true}
                write-host "|    Description (as-is): $($existingWorkgroup.description)"
				write-host "|    Description (to-be): $($workgroupInCsv.Description)"
                $updateWorkgroupOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/description"
                    value = $workgroupInCsv.Description
                }
            }   

            if($workgroupInCsv.Comments -ne $existingWorkgroup.comments)
            {
			    if (!$wg_change) {$form1 -f "";$form_status -f "[$($workgroupKey)]","[CHANGE]";$wg_change=$true}
				write-host "|    Comments (as-is): $($existingWorkgroup.comments)"
				write-host "|    Comments (to-be): $($workgroupInCsv.Comments)"
                
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
            $form1 -f ""
			$form_status -f "[$($workgroupKey)]","[ ADD  ]"
			
            $newWorkgroups += [PSCustomObject]@{
                name = $workgroupInCsv.Name
                description = $workgroupInCsv.Description
                comments = $workgroupInCsv.Comments
            }
        }       
    }
    $count_existing=0
    foreach($nonExistingWorkgroupKey in $workgroupsLookup.Keys.GetEnumerator())
    {
        # $form1 -f "Workgroup $($nonExistingWorkgroupKey) exists in PlanningSpace but not in the workgroups CSV file. Please check if this workgroup needs to be removed."
		$count_existing++
    }
    $form1 -f ""  
	$form1 -f "[$count_existing] workgroup(s) exist in P2V but not in CSV file "
	$form1 -f "      Please check if these workgroups need to be removed."
    $form1 -f ""  
	
	$tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
    $base64AuthInfo ="$($tenant.base64AuthInfo)"
    $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
		
	$newWorkgroups = @($newWorkgroups)
    if ($newWorkgroups.Count -gt 0)
    {
	   if (($cont=read-host ($form1 -f "add [$($newWorkgroups.Count)] workgroups? (y/n)")) -like "y")	
	   { 
           $form1 -f " Creating new workgroups..."
           #$token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
           $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body (ConvertTo-Json @($newWorkgroups)) -ContentType "application/json"
           $form1 -f " Creation result:"
           $result | Write-Output
           $form1 -f "Finished creating new workgroups."
		   $linesep
       } 
	} else
    { 
	   $form1 -f "add [$($newWorkgroups.Count)] workgroups -> no activity needed"
    }
    $form1 -f ""  
	#$updateOperations|format-table|out-host
	
    if ($updateOperations.Count -gt 0)
    {
	  if (($cont=read-host ($form1 -f "update [$($updateOperations.Count)] workgroups? (y/n)")) -like "y")	
	  { 
	
         $form1 -f "Updating existing groups..."
        # $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
	    #$updateOperations |convertto-Json
         $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
         $form1 -f " Update result:"
         $result | Write-Output
         $form1 -f "Finished updating existing groups."
		 $linesep
	  }
    }else
    { 
	   $form1 -f "update [$($updateOperations.Count)] workgroups -> no activity needed"
    }
	$form1 -f "" 
}

# Function that does the main processing for user workgroups
Function Process-UserWorkgroups($userWorkgroupsFromCsv, $currentWorkgroups, $currentUsers, $analyzeOnly, $tenantUrl)
{
    $workgroupsLookup=@{}
    $currentWorkgroups | %{ $workgroupsLookup[$($_.Name)] = $_ }

    $usersLookup=@{}
    $usersLookupByLogonId=@{}
    $currentUsers | %{ $usersLookup["$($_.id)"] = $_ }
    $currentUsers | %{ $usersLookupByLogonId["$($_.logOnId)"] = $_ }

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

                    if (!$userWorkgroupsFromCsv.ContainsKey("$($user.logonId)\$($currentWorkgroup.name)"))
                    {
                        if (!$currentWorkgroup.name -eq "Everyone")
                        {
                            Write-Output " $($user.logonId) will be removed from $($currentWorkgroup.name) workgroup"

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
                        $userWorkgroupsFromCsv.Remove("$($user.logonId)\$($currentWorkgroup.name)")
                    }
                }                
            }
        }              
    }

    # second pass add users to workgroups
    foreach($userWorkgroupInCsv in $userWorkgroupsFromCsv.Values)
    {
	    		    
       <#  if ((!$workgroupsLookup) -or !($($userWorkgroupInCsv.Workgroup)))
		{
		 write-host '<DEBUG>  ' 
	     write-host '$workgroupsLookup'
		 $workgroupsLookup|format-table|out-host
		 write-host '$userWorkgroupInCsv.Workgroup'
		 $linesep
		 $userWorkgroupInCsv.Workgroup|format-table|out-host
		 write-host '<\DEBUG>  ' 
		 pause
		 
		} #>
   
        if ($($userWorkgroupInCsv.Workgroup) -and ($workgroupsLookup.ContainsKey( $userWorkgroupInCsv.Workgroup)))
        {
            $user = $usersLookupByLogonId["$($userWorkgroupInCsv.LogOnId)"]
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
    if (($cont=read-host ($form1 -f "add [$($updateOperations.Count)] user/workgroup assignments? (y/n)")) -like "y" -and $updateOperations.Count -gt 0)	
    #if ($updateOperations.Count -gt 0 -and !$analyzeOnly)
    {
        Write-Output "Updating existing user workgroups..."
        $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
       # $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
        $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
        Write-Output " Update result:"
        $result | Write-Output
        Write-Output "Finished updating existing user workgroups."
    }
}


#------------------ START OF SCRIPT LOGIC -----------------------------

# Log summary of passed parameters
cls

P2V_header -app $My_name -path $My_Path

Write-Output "This script will only create new workgroups and users and update existing ones."
Write-Output "Please note that this script will only warn on workgroups and users that can possibly be deleted. Please login to PlanningSpace application to perform the actual deletion."

# Initialize CSV file paths
$workgroupsFile = $workingDir + "\P2V_Workgroups.csv"
$usersFile = $workingDir +"\P2V_Users.csv"
$userWorkgroupsFile = $workingDir + "\P2V_UserWorkgroups.csv"

do{
write-host -nonewline "|> select Workgroup file:  "
$workgroupsFile = Get-FileName ($workingDir)
write-host "[$workgroupsFile]"
}until(($cont=read-host ("continue with selected file in $tenant? (y/n)")) -like "y")


#-- 1  check tenant /select tenant

# $t= select_PS_tenants -multiple $false
# $tenant=$t.tenant

$tenants= select_PS_tenants -multiple $true

# Load CSV files
$form1 -f "Loading from input CSV files..."
$workgroupsFromCsv = Get-WorkgroupsFromCsv -workgroupsFile $workgroupsFile
# $usersFromCsv = Get-UsersFromCsv -usersFile $usersFile
# $userWorkgroupsFromCsv = Get-UserWorkgroupsFromCsv -userWorkgroupsFile $userWorkgroupsFile
$form1 -f "Finished loading from input CSV files."

foreach ($ts in $tenants.keys)
{
   $t  = $tenants[$ts]
   $tenant=$t.tenant

$tenantURL  ="$($t.ServerURL)/$($t.tenant)"
$workingDir =$output_path +"\$tenant"
# Initialize CSV file paths
$linesep
$form1 -f "---> $tenant <---"
# Ensure that the working directory and CSV files exist
$form1 -f  "Validating working directory ..."
$form1 -f  "> $($workingDir)"
if (!(Validate-WorkingDirectory $workingDir))       { exit }
if (!(Validate-CsvFile -checkfile $workgroupsFile)) { exit }
$form1 -f  "Finished validating working directory."

# Load current PlanningSpace workgroups and users
$form1 -f "Getting current PlanningSpace workgroups and users..."
#$currentWorkgroups = Get-PlanningSpaceWorkgroups -tenantUrl $tenantUrl -token $base64AuthInfo 
$currentWorkgroups = get_PS_grouplist -tenant $t

#$currentUsers = Get-PlanningSpaceWindowsADUsers -tenantUrl $tenantUrl -token $base64AuthInfo
# $currentWorkgroups = Get-PlanningSpaceWorkgroups -tenantUrl $tenantUrl -token $token
# $currentUsers = Get-PlanningSpaceWindowsADUsers -tenantUrl $tenantUrl -token $token
$form1 -f  "Finished getting current PlanningSpace workgroups and users..."
$form1 -f  ""

# Process users
# Write-Output "Processing new and updated users..."
# Process-Users -usersFromCsv $usersFromCsv -currentUsers $currentUsers -analyzeOnly $analyzeOnly -tenantUrl $tenantUrl
# Write-Output "Finished processing new and updated users."
# Write-Output ""

# Process workgroups
# Write-Output "Processing new and updated workgroups..."
Process-Workgroups -workgroupsFromCsv $workgroupsFromCsv -currentWorkgroups $currentWorkgroups -analyzeOnly $analyzeOnly -tenant $t
# Write-Output "Finished processing new and updated workgroups."
# Write-Output ""

# Process user workgroups
# Write-Output "Processing updated user workgroups..."
#$token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
# $currentWorkgroups = Get-PlanningSpaceWorkgroups -tenantUrl $tenantUrl -token $token
# $currentUsers = Get-PlanningSpaceWindowsADUsers -tenantUrl $tenantUrl -token $token
# Process-UserWorkgroups -workgroupsFromCsv $workgroupsFromCsv -userWorkgroupsFromCsv $userWorkgroupsFromCsv -currentWorkgroups $currentWorkgroups -currentUsers $currentUsers -analyzeOnly $analyzeOnly -tenantUrl $tenantUrl
# Write-Output "Finished processing updated user workgroups..."

}
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----