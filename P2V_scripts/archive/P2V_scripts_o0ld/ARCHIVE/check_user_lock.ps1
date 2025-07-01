param(
  [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
  [string]$xkey="x449222",
  [bool]$analyzeOnly = $True

)
#-------------------------------------------------
#  Set config variables

#$workdir     = "\\somvat202005\PPS_Share\P2V_scripts"

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir + "\output\AD-groups"
$u_w_file= $output_path + "\Myuserworkgroup.csv"
$OMV_domain="ww"

#-------------------------------------------------
#----- functions
# Function to get all PlanningSpace workgroups
Function Get-PlanningSpaceWorkgroups($tenantUrl, $token)
{
  $apiUrl = $tenantUrl + "/PlanningSpace/api/v1/workgroups"
  $hash = @{}
  $workgroups = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{"Authorization"="Bearer " + $token} 
  foreach ($i in $workgroups) {$hash[$($i.id)]=$($i.name) }

  return $hash
}

# Function to get all PlanningSpace Windows AD users
Function Get-PlanningSpaceUsers($tenantUrl, $token)
{
  $apiUrl = $tenantUrl + "/PlanningSpace/api/v1/users?include=UserWorkgroups"
  $users = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{"Authorization"="Bearer " + $token} 
  $domainUsers = $users #| Where-Object { $_.authenticationMethod -eq "WINDOWS_AD" }
  return $domainUsers
}

#-------------------------------------------------
#----- start main part

 $linesep="+-------------------------------------------------------------------------------+"
 $form=   "|  {0,-13}{1,-73}|"
 $form1=  "   {0,-20}{1,-70}"
     
 #         0         1         2         3         4         5         6         7         8
 
cls
$user= $xkey
#While (($user= Read-Host -Prompt ' >>> Input the user name (0=exit)') -ne "0") 
#{
  $result=@()

#----- check whether xkey exists in AD and retrieve core information
  write-host -ForegroundColor yellow $linesep
  write-host "         Active Directory ($user)     "
  write-host -ForegroundColor yellow $linesep
  
  $result=Get-ADUser -Filter {Name -like $user} -properties * |select GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Enabled,PasswordExpired ,LockedOut,lockoutTime
  # select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Country,Company,Department,EmployeeNumber, Enabled, HomeDirectory ,PasswordExpired ,LockedOut,lockoutTime
  if(!$result) 
  { 
    write-Host -ForegroundColor Red "  !! [$user] does not exist in Active DirectorySOMVAT002002 !!" 
  } else     
  { 
    $result 
    
    $dep=$($result.Department) -replace '[\W]', ' '
    #format: LogonId,Domain,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress,
    Write-Host "$($result.Name),ww,$($result.Surname) $($result.GivenName),$dep,FALSE,FALSE,,"
#----- check whether xkey is member of ADgroups of P2V
    Write-Host -ForegroundColor yellow $linesep
    write-host "   P2V AD group memberships for $($result.SamAccountName)"
    Write-Host -ForegroundColor yellow "$linesep
"



    foreach ($i in import-csv $adgroupfile)
    {
      if (Get-ADGroupMember -Identity $($i.ADgroup)|where {$($_.SamAccountName) -eq $($result.SamAccountName)}) 
      { $i.ADgroup }
    }

#----- check whether xkey is member of workgroups in P2V
    Write-Host -ForegroundColor yellow "
$linesep  "
    write-host "   P2V Planningspace group memberships for $($result.SamAccountName)"
    Write-Host -ForegroundColor yellow $linesep

    $all_systems = @()
    $all_systems =import-csv $tenantfile

    foreach ($i in $all_systems)
    {
      $out        =" --- {0,-15} ---" -f $($i.tenant)
	  $authURL    ="$($i.ServerURL)/identity/connect/token"
      $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
          
      write-host -ForegroundColor yellow "$out"

    # start authentication 
      $authResponse = Invoke-RestMethod -Method Post -Uri $authURL -headers @{'Content-Type'= 'application/x-www-form-urlencoded'} -body "grant_type=password&username=$($i.usern)&password=$($i.passw)&scope=planningspace&client_id=$($i.tenant)+resource_owner&client_secret="
       
    # retrieve all users incl. workgroups
      $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -header @{'Authorization' = 'Bearer ' + $authResponse.access_token} #|where {$($_.logOnId) -like $($result.SamAccountName)}
      $resp=$resp |where {$($_.logOnId) -like $($result.SamAccountName)}
    
      if ($resp) 
      {
        $form1 -f "account","$($resp.logOnId) / $($resp.displayName)"
        # $form -f "displayName",$($resp.displayName)
        $form1 -f "locked ?",$($resp.isAccountLocked)
        $form1 -f "deactivated ?",$($resp.isDeactivated)
        # $form -f "is deactivated ?",$($resp.isDeactivated)

        # $resp |select logOnId, displayName, isDeactivated, isAccountLocked,UserWorkgroups|format-list
        #"    - {0}({1}) is deactivated: {2,6} " -f $($resp.logOnId),$($resp.displayName),$($resp.isDeactivated)
        #"    - {0}({1}) is locked     : {2,6}" -f $($resp.logOnId),$($resp.displayName),$($resp.isAccountLocked)
      
    #    write-host -nonewline "   workgroups: `n   "    
    #
    #    foreach($tmpWgs in $($resp.userWorkgroups))
    #    {
    #      $hash = @{}
    #      $tmpWgs | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($tmpWgs | SELECT -exp $_) }
    #     
    #      foreach($wg in ($hash.Values | Sort-Object -Property Name))
    #      {
    #        $groupsHash = @{}
    #        $wg | Get-Member -MemberType Properties | select -exp "Name" | % { $groupsHash[$_] = ($wg | SELECT -exp $_) }
    #        write-host -nonewline  "["$groupsHash["name"]"] "
    #      }
    #    }
    #    Write-host "`n"
        } else 
        {
          write-host -ForegroundColor Red "    $($result.SamAccountName) does not exist"
        }
      }
    }
  write-host  -ForegroundColor yellow $linesep
#} # end while

