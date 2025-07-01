#-----------------------------------------
# P2V_lock_allusers 
#
#  name:   check_locked_user.ps1 
#  ver:    0.1
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $long =  false (default)   - short summary 
# $long =  true              - all AD entries
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string]$tenant="",
  [int]$max_days=365,
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  [bool]$checkOnly = $False
)
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$user=$env:UserDomain+"/"+$env:UserName
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#----- Set config variables
$output_path = $output_path_base + "\$My_name"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

#[ERROR]: missing argument(s)  
#
#correct usage:  
#$My_name  -tenant ttt  [-lock l] [-deactivate d] [-checkonly c]#
#
#    ttt ... existing tenant
#  optional
#       l ... TRUE to lock  / FALSE to unlock 
#       d ... TRUE to deactivate / FALSE to activate
#       c ... TRUE : only check status / FALSE change settings (default:TRUE)
#"

#----- start main part
P2V_header -app $My_name -path $My_path 

#----- user / profiles to keep even without login

$UserProfilesToSkip = @("A02.profile.PetroVR",
						"A03.profile.CAPDAT",
						"PetroVR"
					   )


$tenants=select_PS_tenants -multiple $true -all $false
Write-Output -NoEnumerate ($form1 -f "tenants selected:")
$tenants.keys|% { Write-Output -NoEnumerate ($form1 -f " > $($tenants[$_].tenant)" )}
Write-Output -NoEnumerate ($linesep  )


#----- check whether xkey is member of workgroups in P2V

  
foreach ($ts in $tenants.keys)
{
	$t               = $tenants[$ts]
	$tenant          = $t.tenant
	$tenantURL       = "$($t.ServerURL)/$($t.tenant)"
	$base64AuthInfo  = $t.base64AuthInfo   
	$accessgroup     = $t.ADgroup

    $form1 -f "--> $tenant <--"
    Write-Output -NoEnumerate ($form1 -f "lock all inactive users in  [$tenant]")
    $linesep

	$UsersFromTenantList        = @{}
	$UsersFromTenantListNever   = @{}
	$UsersFromTenantListMaxDays = @{}
	$UsersFromTenant            = @{}
	# $max_days=365 -> as parameter
	
	$UsersFromTenantList= get_PS_userlist $t 
	$UsersFromTenantList|%{$UsersFromTenant[$($_.LogonID)]=$_}
	$UsersFromTenantList=$UsersFromTenantList|Where { ($_.authenticationMethod -ne "LOCAL") }   #skip local users
	
    Write-Output -NoEnumerate ($form1 -f "LOCAL users are skipped")
	$UsersFromTenantListNever=$UsersFromTenantList| select id, displayName,logOnId,description,isAccountLocked,isDeactivated,lastlogin |where {(! $($_.lastlogin)) -and ( ! $($_.isDeactivated))}  # |out-gridview -Title "NEVER logged in"
	
	$UsersFromTenantListMaxDays=($UsersFromTenantList|select id, displayName,logOnId,description,isAccountLocked,isDeactivated,lastlogin |where {( $($_.lastlogin)) -and ( ! $($_.isDeactivated)) -and ((New-Timespan -start (get-date -date "$($_.lastlogin)") -end (get-date -uformat "%Y-%m-%dT%TZ")).days -gt $max_days)}) 
	# ,(New-Timespan -start (get-date -date $($_.lastlogin)) -end (get-date))
    #(New-Timespan -start (get-date -date "lastlogin") -end 
	
	write-output $linesep
	
	write-output ($form_status -f " Active and NEVER logged in: ",$UsersFromTenantListNever.count)
		   
    $updateOperations = @{}
	$updateUserOperations =@()
    # retrieve all users incl. workgroups


	 $UsersFromTenantListNever =  $UsersFromTenantListNever |out-gridview -Title "ACTIVE and NEVER logged in - select user(s) to deactivate" -OutputMode multiple
     write-output ($form_status -f "users selected for de-activation: ",$UsersFromTenantListNever.count)
	 
	 if (($cont=read-host ($form1 -f "deactivate $($UsersFromTenantListNever.count) users? (y/n)")) -like "y")	
	 {
		 foreach ($u in $UsersFromTenantListNever)
		 {
			$updateUserOperations =@()
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isDeactivated"
                    value = $true
            }
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/description"
			         value = "[deactivated due to inactivity] - $($u.description)"
            }
			# 
			 
		    if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$u.id.ToString()] = $updateUserOperations                
            } 
			
			$result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
			
			if ($result) {$status="[DONE]"} else	{$status="[FAIL]"}
			
			write-output  ($form_status -f "     deactivating $($u.displayName)[$($u.logOnId)]",$status)
			Write-Log -logtext "user=$user,script=$My_name,tenant=$tenant,uid=$($u.id)/$($u.logOnId)/$($u.displayName) deactivated as user never logged in, $status" -level 0
						
		 }
		
		 
	 }
	 
	write-output $linesep
    write-output ($form_status -f " Active and not  logged in for $max_days days:",$UsersFromTenantListMaxDays.count)

    $UsersFromTenantListMaxDays=$UsersFromTenantListMaxDays |out-gridview -Title "ACTIVE and not logged in for $max_days days - select user(s) to lock" -OutputMode multiple
	write-output ($form_status -f "users selected to lock",$UsersFromTenantListMaxDays.count)
      
	if (($cont=read-host ($form1 -f "lock $($UsersFromTenantListMaxDays.count) users? (y/n)")) -like "y")	
	 {
		 foreach ($u in $UsersFromTenantListMaxDays)
		 {
			$updateUserOperations =@()
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isAccountLocked"
                    value = $true
            }
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/description"
			        value = "[locked due to inactivity $max_days] - $($u.description)"
            }
			# 
			 
		    if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$u.id.ToString()] = $updateUserOperations                
            } 
			
			$result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
			
			if ($result) {$status="[DONE]"} else	{$status="[FAIL]"}
			
			write-output  ($form_status -f "     locking $($u.displayName)[$($u.logOnId)]",$status)
			Write-Log -logtext "user=$user,script=$My_name,tenant=$tenant,uid=$($u.id)/$($u.logOnId)/$($u.displayName) locked as user has not logged in for $max_days days, $status" -level 0
						
		 }
			 
	 }
}
	 write-output $linesep
     P2V_footer -app $MyInvocation.MyCommand
     
    