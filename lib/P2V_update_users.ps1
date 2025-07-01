param(
    [string]$tenantUrl = "https://ips-test.ww.omv.com/P2V_TRAINING",
    [string]$workingDir = Join-Path $PSScriptRoot "..\P2V_UM_data\output\AUCERNAusermgmt\P2V_TRAINING",
    [string]$workgroupsFile = "",
	[string]$usersFile = "",
    [string]$userWorkgroupsFile = "",
	[bool]$overwrite=$true,
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


# Function that does the main processing for users
Function Process-Users($usersFromCsv, $currentUsers, $analyzeOnly, $tenant)
{
    $usersLookup=@{}
    $currentUsers | %{ $usersLookup["$($_.logOnId)"] = $_ }

    $newUsers = @()
    $updateOperations = @{}

    foreach($userKey in $usersFromCsv.Keys.GetEnumerator())
    {
	    $u_change=$false
        $userInCsv = $usersFromCsv[$userKey];

        if ($usersLookup.ContainsKey($userKey))
        {
            $existingUser = $usersLookup[$userKey];
            $usersLookup.Remove($userKey);

            $updateUserOperations = @()
						
            if ($userInCsv.Description -ne $existingUser.Description)
            {
                if (!$u_change) {$form1 -f "";$form_status -f "[$($userKey)]","[CHANGE]";$u_change=$true}
				write-host "|    Description (as-is): [($($existingUser.Description))]"
				write-host "|    Description (to-be): [($($userInCsv.Description))]"
				$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/description"
                    value = $userInCsv.Description
                }
            }   
            if ($userInCsv.DisplayName -ne $existingUser.DisplayName)
            {
                if (!$u_change) {$form1 -f "";$form_status -f "[$($userKey)]","[CHANGE]";$u_change=$true}
				write-host "|    DisplayName (as-is): [$($existingUser.DisplayName)]"
				write-host "|    DisplayName (to-be): [$($userInCsv.DisplayName)]"
				$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/DisplayName"
                    value = $userInCsv.DisplayName
                }
            }   
            if($userInCsv.IsDeactivated -ne $existingUser.isDeactivated)
            {
			    if (!$u_change) {$form1 -f "";$form_status -f "[$($userKey)]","[CHANGE]";$u_change=$true}
				write-host "|    IsDeactivated (as-is): [$($existingUser.IsDeactivated)]"
				write-host "|    IsDeactivated (to-be): [$($userInCsv.IsDeactivated)]"
			    
                $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isDeactivated"
                    value = $userInCsv.IsDeactivated
                }
            }

            if($userInCsv.IsAccountLocked -ne $existingUser.isAccountLocked)
            {
			    if (!$u_change) {$form1 -f "";$form_status -f "[$($userKey)]","[CHANGE]";$u_change=$true}
				write-host "|    IsAccountLocked (as-is): [$($existingUser.IsAccountLocked)]"
				write-host "|    IsAccountLocked (to-be): [$($userInCsv.IsAccountLocked)]"
                
                $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isAccountLocked"
                    value = $userInCsv.IsAccountLocked
                }
            }
            if ($userInCsv.EmailAddress -and $existingUser.emailAddress)
			{
             if($($userInCsv.EmailAddress) -ne $($existingUser.emailAddress))
             {
                if (!$u_change) {$form1 -f "";$form_status -f "[$($userKey)]","[CHANGE]";$u_change=$true}
				write-host "|    EmailAddress (as-is): [$($existingUser.EmailAddress)]"
				write-host "|    EmailAddress (to-be): [$($userInCsv.EmailAddress)]"
				
                $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/emailAddress"
                    value = $userInCsv.EmailAddress
                }
             }
			} 
            if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$existingUser.id.ToString()] = $updateUserOperations                
            }                     
        }
        else
        {
  			$form_status -f "[$($userKey)]","[ ADD  ]"
			$secret=""
			if ($userInCsv.authenticationMethod -eq "LOCAL")
			{ $secret="Plan2Value"}
			
            $newUsers += [PSCustomObject]@{
                logOnId              = $userInCsv.LogOnId
                domain               = $userInCsv.Domain
                displayName          = $userInCsv.DisplayName
                description          = $userInCsv.Description
                isDeactivated        = $userInCsv.IsDeactivated
                isAccountLocked      = $userInCsv.IsAccountLocked
                useADEmailAddress    = $False
				emailAddress         = $userInCsv.EmailAddress
                authenticationMethod = $userInCsv.authenticationMethod
		        password             = $secret
			}
        }       
    }

    # foreach($nonExistingUserKey in $usersLookup.Keys.GetEnumerator())
    #{
    #    Write-Warning " User $($nonExistingUserKey) exists in PlanningSpace but not in the users CSV file. Please check if this user needs to be removed."
    #} 
	
	Write-warning "[$($usersLookup.Count)] users exist in PS but not in the CSV file. Manual check required!"
	<# if (($cont=read-host ($form1 -f "deactivate [$($usersLookup.Count)] users? (y/n)")) -like "y")	
	{
        foreach($nonExistingUserKey in $usersLookup.Keys.GetEnumerator())
        {
           Write-host " deactivating user $($nonExistingUserKey)  (no op)"
        }	
	    	
	} #>
	
	$tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
    $base64AuthInfo ="$($tenant.base64AuthInfo)"
    $apiUrl = "$($tenantUrl)/planningspace/api/v1/users/bulk"
	#$newUsers = @($newUsers)
	
        
    if ($newUsers.Count -gt 0)
    {
	   if (($cont=read-host ($form1 -f "add [$($newUsers.Count)] users? (y/n)")) -like "y")	
        {
            #$newUsers|format-table|out-host
			
            #$token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
			
			# ConvertTo-Json @($newUsers)
			
			# "calling  $apiUrl   Post"
			# pause
			# $body = [System.Text.Encoding]::UTF8.GetBytes( (ConvertTo-Json @($newUsers)))
            # $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body (ConvertTo-Json @($body)) -ContentType "application/json"
			# Write-Output " > Add users result:"
			# $result |% { write-host "$($_.key) :";$($_.value).response|format-list }
			# $result |convertto-Json|out-host
			# Write-Output "Finished creating new users."
			# $linesep
			 
	        # $form1 -f "Creating new users..."
	      
            foreach ($a in $newUsers)
		        {
 	              $body = $a|convertto-json
			      $body = [System.Text.Encoding]::UTF8.GetBytes($body)
			      $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
			      if ($result) {$rc="[DONE]"}else {$rc="[ERROR]"} 
		          $form_status -f $a.displayName,$rc
				}	   
	    }
    } else
    { 
	   $form1 -f "add [$($newUsers.Count)] users -> no activity needed"
    }
	pause
    $form1 -f "" 
    if ($updateOperations.Count -gt 0)
    {
	   if (($cont=read-host ($form1 -f "update [$($updateOperations.Count)] users? (y/n)")) -like "y")	
	     { 
           Write-Output "Updating existing users..."
           #$token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
           $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
           
		   if ($result) {$rc="[DONE]"}else {$rc="[FAIL]"}
		   $form_status -f "Finished updating existing users",$rc
           
        }
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
    $count_existing=0
    foreach($nonExistingWorkgroupKey in $workgroupsLookup.Keys.GetEnumerator())
    {
        Write-Log (" Workgroup $($nonExistingWorkgroupKey) exists in PlanningSpace but not in the workgroups CSV file. Please check if this workgroup needs to be removed.",1)
		$count_existing++
    }
    $form1 -f "[$count_existing] workgroup(s) exist in P2V but not in CSV file"
      
    if (($cont=read-host ($form1 -f "add [$($newWorkgroups.Count)] workgroups? (y/n)")) -notlike "y")	
	#if ($analyzeOnly)
    {
        return
    }

    $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
    $newWorkgroups = @($newWorkgroups)
    if ($newWorkgroups.Count -gt 0)
    {
        Write-Output " Creating new workgroups... $apiUrl"
        #$token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
        $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body (ConvertTo-Json @($newWorkgroups)) -ContentType "application/json"
        Write-Output " Creation result:"
        $result | Write-Output
        Write-Output "Finished creating new workgroups."
    }

    if ($updateOperations.Count -gt 0)
    {
        Write-Output "Updating existing users..."
       # $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
	    $updateOperations |convertto-Json
        $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
        Write-Output " Update result:"
        $result | Write-Output
        Write-Output "Finished updating existing users."
    }
}

# Function that does the main processing for user workgroups
Function Process-UserWorkgroups($userWorkgroupsFromCsv, $currentWorkgroups, $currentUsers, $analyzeOnly, $tenant)
{
    $workgroupsLookup=@{}
    $currentWorkgroups | %{ $workgroupsLookup[$($_.Name)] = $_ }

    $usersLookup=@{}
    $usersLookupByLogonId=@{}
    $currentUsers | %{ $usersLookup["$($_.id)"] = $_ }
    $currentUsers | %{ $usersLookupByLogonId["$($_.logOnId)"] = $_ }

    $updateOperations = @{}

	#<# # DEBUG
	 $form1 -f ">>DEBUG start"
	 # $currentusers|format-table
	 # $linesep
  	 # $currentWorkgroups|format-table
	 # $linesep
	 $userWorkgroupsFromCsv|format-table
	 $form1 -f ">>DEBUG end"
	 out-host
	pause
	# DEBUG END #>
	
	
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
						    $form_user -f "[DEL]","$($user.logonId)","$($currentWorkgroup.name)"
                            # Write-Output " $($user.logonId) will be removed from $($currentWorkgroup.name) workgroup"

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
				$form_user -f "[ADD]","$($user.logonId)","$($workgroup.name)"
                # Write-Output " $($user.domain)\$($user.logonId) will be added to $($workgroup.name) workgroup"
            }            
        }
    }
	
    if (($cont=read-host ($form1 -f "overwrite [$($updateOperations.Count)] user/workgroup assignments? (y/n)")) -like "y" -and $updateOperations.Count -gt 0)	
    #if ($updateOperations.Count -gt 0 -and !$analyzeOnly)
    {
        Write-Output "Updating existing user workgroups..."
		$tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
        $base64AuthInfo ="$($tenant.base64AuthInfo)"
        $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
       # $token = Get-PlanningSpaceAuthToken -tenantUrl $tenantUrl
	   $linesep
	   "updateOperations:"
	   $updateOperations|format-table|out-host #ConvertTo-Json
	   $linesep
	   pause
        $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers  @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
        Write-Output " Update result:"
        if ($result) {$rc="[DONE]"}else {$rc="[FAIL]"}
        $form_status -f "Finished updating existing user workgroups",$rc
    }
}


#------------------ START OF SCRIPT LOGIC -----------------------------

# Log summary of passed parameters
cls

P2V_header -app $My_name -path $My_Path

Write-Output "This script will only create new workgroups and users and update existing ones."
Write-Output "Please note that this script will only warn on workgroups and users that can possibly be deleted. Please login to PlanningSpace application to perform the actual deletion."


# Initialize CSV file paths
# $workgroupsFile = $workingDir + "\P2V_Workgroups.csv"
# $usersFile = $workingDir +"\P2V_Users.csv"
# $userWorkgroupsFile = $workingDir + "\P2V_UserWorkgroups.csv"
# Write-Output ""
# write-output "workingDIR = $workingdir"

# Initialize CSV file paths
# $workgroupsFile = $workingDir + "\P2V_Workgroups.csv"
# $usersFile = $workingDir +"\P2V_Users.csv"
# $userWorkgroupsFile = $workingDir + "\P2V_UserWorkgroups.csv"

$workingDir = Join-Path $PSScriptRoot "..\P2V_UM_data\GoLivePrep"

do{ #select files to load
write-host -nonewline "select User file:                      "
$usersFile = Get-FileName ($workingDir)
write-host $usersFile
write-host -nonewline "select Workgroup file:                 "
$workgroupsFile = Get-FileName ($workingDir)
write-host $workgroupsFile
write-host -nonewline "select Workgroup-User assignment file: "
$userWorkgroupsFile = Get-FileName ($workingDir)
write-host $userWorkgroupsFile
}until(($cont=read-host ("continue with selected files in $tenant? (y/n)")) -like "y")


#-- 1  check tenant /select tenant

$tenants= select_PS_tenants -multiple $true

# Load CSV files
$form1 -f "Loading from input CSV files..."
# $workgroupsFromCsv = Get-WorkgroupsFromCsv -workgroupsFile $workgroupsFile
$usersFromCsv = Get-UsersFromCsv -usersFile $usersFile
$userWorkgroupsFromCsv = Get-UserWorkgroupsFromCsv -userWorkgroupsFile $userWorkgroupsFile
$form1 -f "Finished loading from input CSV files."

foreach ($ts in $tenants.keys)
{
   $t = $tenants[$ts]
   $tenant=$t.tenant

   $tenantURL  ="$($t.ServerURL)/$($t.tenant)"
   $workingDir =$output_path +"\$tenant"
   # Initialize CSV file paths
   $linesep
   $form1 -f "---> $tenant <---"

   $form1 -f  "Validating working directory ..."
   $form1 -f  "> $($workingDir)"
   if (!(Validate-WorkingDirectory $workingDir))           { exit }
   if (!(Validate-CsvFile -checkfile $usersFile))          { exit }
   if (!(Validate-CsvFile -checkfile $userWorkgroupsFile)) { exit }
   $form1 -f  "Finished validating working directory."

   # Load current PlanningSpace workgroups and users
   $form1 -f "Getting current PlanningSpace workgroups and users..."
   #$currentWorkgroups = Get-PlanningSpaceWorkgroups -tenantUrl $tenantUrl -token $base64AuthInfo 
   # $currentWorkgroups = get_PS_grouplist -tenant $t
   $currentUsers      = get_PS_userlist -tenant $t
   $currentWorkgroups = get_PS_grouplist -tenant $t
   
   $form1 -f  "Finished getting current PlanningSpace workgroups and users..."
   $form1 -f  ""

   # Process users
   $form1 -f  "Processing new and updated users..."
   Process-Users -usersFromCsv $usersFromCsv -currentUsers $currentUsers -analyzeOnly $analyzeOnly -tenant $t
   $form1 -f   "Finished processing new and updated users."
   $form1 -f   ""
   
   # Process user workgroups
   $form1 -f  "Processing new and updated workgroups..."
   Process-UserWorkgroups -workgroupsFromCsv $workgroupsFromCsv -userWorkgroupsFromCsv $userWorkgroupsFromCsv -currentWorkgroups $currentWorkgroups -currentUsers $currentUsers -analyzeOnly $analyzeOnly -tenant $t
   $form1 -f "Finished processing new and updated workgroups."
   $form1 -f  ""
   $linesep
}


P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----